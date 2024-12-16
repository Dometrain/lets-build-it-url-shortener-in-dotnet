using Azure.Identity;
using HealthChecks.CosmosDb;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using StackExchange.Redis;
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

        return response switch
        {
            { Found: true, LongUrl: not null }
                => Results.Redirect(response.LongUrl, true),
            _ => Results.NotFound()
        };
    });

app.Run();
