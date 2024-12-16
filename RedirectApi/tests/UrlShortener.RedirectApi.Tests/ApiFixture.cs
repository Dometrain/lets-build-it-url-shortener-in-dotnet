using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using Testcontainers.Redis;
using UrlShortener.Libraries.Testing.Extensions;
using UrlShortener.RedirectApi.Infrastructure;
using UrlShortener.RedirectApi.Tests.TestDoubles;

namespace UrlShortener.RedirectApi.Tests;

public class ApiFixture : WebApplicationFactory<IRedirectApiAssemblyMarker>, IAsyncLifetime
{
    private readonly RedisContainer _redisContainer = new RedisBuilder()
        .Build();

    public string RedisConnectionString => _redisContainer.GetConnectionString();

    public InMemoryShortenedUrlReader ShortenedUrlReader { get; } = new();

    public async Task InitializeAsync()
    {
        await _redisContainer.StartAsync();
        Environment.SetEnvironmentVariable("Redis__ConnectionString", RedisConnectionString);
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(
            services =>
            {
                services.Remove<IShortenedUrlReader>();
                services.AddSingleton<IShortenedUrlReader>(
                    s =>
                        new RedisUrlReader(ShortenedUrlReader,
                            ConnectionMultiplexer.Connect(RedisConnectionString),
                            s.GetRequiredService<ILogger<RedisUrlReader>>())
                );
            });
        base.ConfigureWebHost(builder);
    }


    public Task DisposeAsync()
    {
        return _redisContainer.StopAsync();
    }
}