using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using UrlShortener.Api;
using UrlShortener.Core.Urls.Add;
using UrlShortener.Tests.Extensions;
using UrlShortener.Tests.TestDoubles;

namespace UrlShortener.Tests;

public class ApiFixture : WebApplicationFactory<IApiAssemblyMarker>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(
            services =>
            {
                services.Remove<IUrlDataStore>();
                services
                    .AddSingleton<IUrlDataStore>(
                        new InMemoryUrlDataStore());
                
                services.Remove<ITokenRangeApiClient>();
                services.AddSingleton<ITokenRangeApiClient, FakeTokenRangeApiClient>();
            }
        );
        
        base.ConfigureWebHost(builder);
    }
}