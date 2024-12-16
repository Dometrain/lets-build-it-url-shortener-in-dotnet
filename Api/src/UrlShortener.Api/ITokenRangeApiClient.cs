using UrlShortener.Core;

namespace UrlShortener.Api;

public interface ITokenRangeApiClient
{
    Task<TokenRange?> AssignRangeAsync(string machineKey, CancellationToken cancellationToken);
}