namespace UrlShortener.Core.Urls.List;

public interface IUserUrlsReader
{
    Task<UserUrls> GetAsync(string createdBy, 
        int pageSize,
        string? continuationToken,
        CancellationToken cancellationToken);
}

public record UserUrls(IEnumerable<UserUrlItem> Urls, string? ContinuationToken = null);
public record UserUrlItem(string ShortUrl, string LongUrl, DateTimeOffset CreatedOn);