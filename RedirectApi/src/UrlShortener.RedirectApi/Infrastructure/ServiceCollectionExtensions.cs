using Microsoft.Azure.Cosmos;
using StackExchange.Redis;

namespace UrlShortener.RedirectApi.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddUrlReader(this IServiceCollection services, 
        string cosmosConnectionString,
        string databaseName, string containerName,
        string redisConnectionString)
    {
        services.AddSingleton<CosmosClient>(s => 
            new CosmosClient(connectionString: cosmosConnectionString));
        
        services.AddSingleton<IConnectionMultiplexer>(s => 
            ConnectionMultiplexer.Connect(redisConnectionString));
        
        services.AddSingleton<IShortenedUrlReader>(s =>
        {
            var cosmosClient = s.GetRequiredService<CosmosClient>();
            var container = cosmosClient.GetContainer(databaseName, containerName);
            var redisConnectionMultiplexer = s.GetRequiredService<IConnectionMultiplexer>();

            return new RedisUrlReader(
                new CosmosShortenedUrlReader(container),
                redisConnectionMultiplexer);
        });

        return services;
    }
}