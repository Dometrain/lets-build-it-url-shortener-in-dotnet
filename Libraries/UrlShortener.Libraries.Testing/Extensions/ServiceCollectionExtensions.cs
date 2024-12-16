using Microsoft.Extensions.DependencyInjection;

namespace UrlShortener.Libraries.Testing.Extensions;

public static class ServiceCollectionExtensions
{
    public static void Remove<T>(this IServiceCollection services)
    {
        var descriptor = services.SingleOrDefault(d 
            => d.ServiceType == typeof(T));
        if (descriptor != null) services.Remove(descriptor);
    }
}