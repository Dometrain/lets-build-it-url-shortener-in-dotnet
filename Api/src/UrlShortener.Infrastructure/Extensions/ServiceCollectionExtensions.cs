using HealthChecks.CosmosDb;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UrlShortener.Core.Urls.Add;
using UrlShortener.Core.Urls.List;

namespace UrlShortener.Infrastructure.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCosmosUrlDataStore(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        services.AddSingleton<CosmosClient>(s =>
            new CosmosClient(configuration["CosmosDb:ConnectionString"]!));

        services.AddSingleton<IUrlDataStore>(s =>
        {
            var cosmosClient = s.GetRequiredService<CosmosClient>();

            var container =
                cosmosClient.GetContainer(
                    configuration["DatabaseName"]!,
                    configuration["ContainerName"]!);

            return new CosmosDbUrlDataStore(container);
        });
        
        services.AddSingleton<IUserUrlsReader>(s =>
        {
            var cosmosClient = s.GetRequiredService<CosmosClient>();

            var container =
                cosmosClient.GetContainer(
                    configuration["ByUserDatabaseName"]!,
                    configuration["ByUserContainerName"]!);

            return new CosmosUserUrlsReader(container);
        });
        
        return services;
    }
    
    public static IHealthChecksBuilder AddCosmosHealthCheck(this IHealthChecksBuilder builder,
        IConfiguration configuration)
    {
        builder.AddAzureCosmosDB(optionsFactory: _ => new AzureCosmosDbHealthCheckOptions()
        {
            DatabaseId = configuration["DatabaseName"]!
        });
        return builder;
    }

}