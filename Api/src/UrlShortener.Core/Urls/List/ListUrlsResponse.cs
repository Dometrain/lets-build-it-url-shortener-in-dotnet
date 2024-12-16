namespace UrlShortener.Core.Urls.List;

public record ListUrlsResponse(IEnumerable<UrlItem> Urls, string? ContinuationToken = null);

public record UrlItem(string ShortUrl, string LongUrl, DateTimeOffset CreatedOn);