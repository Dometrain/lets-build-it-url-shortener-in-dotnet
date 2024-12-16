using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UrlShortener.Core.Urls.Add;

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
        
        return services;
    }

}