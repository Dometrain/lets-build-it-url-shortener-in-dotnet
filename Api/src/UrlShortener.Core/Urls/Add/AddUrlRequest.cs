namespace UrlShortener.Core.Urls.Add;

public record AddUrlRequest(Uri LongUrl, string CreatedBy);