using UrlShortener.Core.Urls;
using UrlShortener.Core.Urls.List;

namespace UrlShortener.Core.Extensions;

public static class UrlResponseExtensions
{
    public static ListUrlsResponse MapToResponse(this UserUrls urls, RedirectLinkBuilder redirectLinkBuilder)
    {
        var urlItems = urls.Urls.Select(url => url.MapToResponse(redirectLinkBuilder)).ToArray();
        return new ListUrlsResponse(urlItems, urls.ContinuationToken);
    }

    private static UrlItem MapToResponse(this UserUrlItem url, RedirectLinkBuilder redirectLinkBuilder)
    {
        return new UrlItem(
            url.ShortUrl,
            redirectLinkBuilder.LinkTo(url.ShortUrl),
            new Uri(url.LongUrl),
            url.CreatedOn);
    }
}