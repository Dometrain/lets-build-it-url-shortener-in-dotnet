namespace UrlShortener.Core.Urls.Add;

public record AddUrlResponse(string Id, Uri LongUrl, Uri ShortUrl);