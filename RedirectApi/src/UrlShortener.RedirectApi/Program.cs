using System.Diagnostics;
using System.Runtime.InteropServices.JavaScript;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.Exporter;
using HealthChecks.CosmosDb;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using StackExchange.Redis;
using UrlShortener.RedirectApi;
using UrlShortener.RedirectApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

var keyVaultName = builder.Configuration["KeyVaultName"];
if (!string.IsNullOrEmpty(keyVaultName))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri($"https://{keyVaultName}.vault.azure.net/"),
        new DefaultAzureCredential());
}

builder.Services.AddHealthChecks()
    .AddAzureCosmosDB(optionsFactory: _ => new AzureCosmosDbHealthCheckOptions()
    {
        DatabaseId = builder.Configuration["DatabaseName"]!
    })
    .AddRedis(provider =>
            provider.GetRequiredService<IConnectionMultiplexer>(),
        failureStatus: HealthStatus.Degraded);

builder.Services.AddUrlReader(
    cosmosConnectionString: builder.Configuration["CosmosDb:ConnectionString"]!,
    databaseName: builder.Configuration["DatabaseName"]!,
    containerName: builder.Configuration["ContainerName"]!,
    redisConnectionString: builder.Configuration["Redis:ConnectionString"]!);

var applicationName = builder.Environment.ApplicationName ?? "RedirectApi";

var telemetryConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];

builder.Logging.AddOpenTelemetry(
    options =>
    {
        options.SetResourceBuilder(
            ResourceBuilder
                .CreateDefault()
                .AddService(serviceName: applicationName));

        options.IncludeFormattedMessage = true;
        
        if (telemetryConnectionString is not null)
            options.AddAzureMonitorLogExporter(o => { o.ConnectionString = telemetryConnectionString; });
        else
            options.AddConsoleExporter();
    });


builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(serviceName: applicationName))
    .WithTracing(
        tracing =>
        {
            tracing.AddSource("Azure.*");
            tracing.AddAspNetCoreInstrumentation();
            tracing.AddHttpClientInstrumentation();
            tracing.AddRedisInstrumentation();
            tracing.AddSource("Azure.Cosmos.Operation");

            if (telemetryConnectionString is not null)
                tracing.AddAzureMonitorTraceExporter(o => { o.ConnectionString = telemetryConnectionString; });
            else
                tracing.AddConsoleExporter();
        }
    )
    .WithMetrics(
        metrics =>
        {
            metrics
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddMeter(ApplicationDiagnostics.Meter.Name);
            
            if (telemetryConnectionString is not null)
                metrics.AddAzureMonitorMetricExporter(o => { o.ConnectionString = telemetryConnectionString; });
            else 
                metrics.AddConsoleExporter();
        });


var app = builder.Build();

app.MapHealthChecks("/healthz", new HealthCheckOptions()
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapGet("/", () => "Redirect API");

app.MapGet("r/{shortUrl}",
    async (string shortUrl, IShortenedUrlReader reader, CancellationToken cancellationToken) =>
    {
        var response = await reader.GetLongUrlAsync(shortUrl, cancellationToken);

        if(response.Found)
            ApplicationDiagnostics.RedirectExecutedCounter.Add(1);
        
        Activity.Current?.SetTag("Year", DateTime.Today.Year); // Dumb example
        
        return response switch
        {
            { Found: true, LongUrl: not null }
                => Results.Redirect(response.LongUrl, true),
            _ => Results.NotFound()
        };
    });

app.Run();