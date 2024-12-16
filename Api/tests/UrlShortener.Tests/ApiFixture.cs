using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using UrlShortener.Api;
using UrlShortener.Core.Urls.Add;
using UrlShortener.Core.Urls.List;
using UrlShortener.Libraries.Testing.Extensions;
using UrlShortener.Tests.TestDoubles;

namespace UrlShortener.Tests;

public class ApiFixture : WebApplicationFactory<IApiAssemblyMarker>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureTestServices(
            services =>
            {
                var inMemoryStore = new InMemoryUrlDataStore();
                services.Remove<IUrlDataStore>();
                services
                    .AddSingleton<IUrlDataStore>(
                        inMemoryStore);
                
                services.Remove<IUserUrlsReader>();
                services
                    .AddSingleton<IUserUrlsReader>(
                        inMemoryStore);
                
                services.Remove<ITokenRangeApiClient>();
                services.AddSingleton<ITokenRangeApiClient, FakeTokenRangeApiClient>();
                
                services.AddAuthentication(defaultScheme: "TestScheme")
                    .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>(
                        "TestScheme", options => { });
                
                services.AddAuthorization(options =>
                {
                    options.DefaultPolicy = new AuthorizationPolicyBuilder()
                        .RequireAuthenticatedUser()
                        .Build();
                    options.FallbackPolicy = null;
                });

            }
        );
        
        base.ConfigureWebHost(builder);
    }
}