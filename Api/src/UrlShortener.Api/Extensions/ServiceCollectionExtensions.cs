using UrlShortener.Core;
using UrlShortener.Core.Urls;
using UrlShortener.Core.Urls.Add;

namespace UrlShortener.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddUrlFeature(this IServiceCollection services)
    {
        services.AddScoped<AddUrlHandler>();
        services.AddSingleton<TokenProvider> (_ =>
        {
            var tokenProvider = new TokenProvider();
            tokenProvider.AssignRange(1, 1000);
            return tokenProvider;
        });
        services.AddScoped<ShortUrlGenerator>();


        return services;
    }
}
