namespace UrlShortener.Core.Urls;

public class RedirectLinkBuilder
{
    private readonly Uri _redirectServiceEndpoint;

    public RedirectLinkBuilder(Uri redirectServiceEndpoint)
    {
        _redirectServiceEndpoint = redirectServiceEndpoint;
    }

    public Uri LinkTo(string shortUrl)
    {
        return new Uri(_redirectServiceEndpoint, shortUrl);
    }
}