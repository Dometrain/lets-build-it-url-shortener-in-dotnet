namespace UrlShortener.RedirectApi.Infrastructure;

public record ReadLongUrlResponse(bool Found, string? LongUrl);