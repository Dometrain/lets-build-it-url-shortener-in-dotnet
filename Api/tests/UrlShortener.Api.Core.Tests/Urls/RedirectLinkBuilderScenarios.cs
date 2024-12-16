using UrlShortener.Core.Urls;

namespace UrlShortener.Api.Core.Tests.Urls;

public class RedirectLinkBuilderScenarios
{
    [Fact] 
    public void Should_return_complete_link_when_short_url_is_provided()
    {
        var redirectServiceEndpoint = new Uri("https://redirect-service.com/r/");
        const string shortUrl = "abc123";
        var expectedUri = new Uri("https://redirect-service.com/r/abc123");
        var redirectLinkBuilder = new RedirectLinkBuilder(redirectServiceEndpoint);
        
        var result = redirectLinkBuilder.LinkTo(shortUrl);

        result.Should().Be(expectedUri);
    }
}