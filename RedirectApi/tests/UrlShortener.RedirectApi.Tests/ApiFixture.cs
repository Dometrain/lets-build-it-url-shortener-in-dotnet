using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
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

    public Task InitializeAsync()
    {
        return _redisContainer.StartAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(
            services =>
            {
                services.Remove<IShortenedUrlReader>();
                services.AddSingleton<IShortenedUrlReader>(
                    new RedisUrlReader(ShortenedUrlReader,
                        ConnectionMultiplexer.Connect(RedisConnectionString))
                );
            });
        base.ConfigureWebHost(builder);
    }


    public Task DisposeAsync()
    {
        return _redisContainer.StopAsync();
    }
}