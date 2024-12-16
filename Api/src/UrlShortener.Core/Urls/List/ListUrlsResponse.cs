namespace UrlShortener.Core.Urls.List;

public record ListUrlsResponse(IEnumerable<UrlItem> Urls, string? ContinuationToken = null);

public record UrlItem(
    string Id,
    Uri ShortUrl, 
    Uri LongUrl, DateTimeOffset CreatedOn);