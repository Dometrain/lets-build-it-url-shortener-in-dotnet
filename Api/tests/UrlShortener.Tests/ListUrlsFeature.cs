using System.Net;
using System.Net.Http.Json;
using System.Security.Policy;
using UrlShortener.Core.Urls.Add;
using UrlShortener.Core.Urls.List;

namespace UrlShortener.Tests;

[Collection("Api collection")]
public class ListUrlsFeature
{
    private const string UrlsEndpoint = "/api/urls";
    private readonly HttpClient _client;

    public ListUrlsFeature(ApiFixture fixture)
    {
        _client = fixture.CreateClient();
    }

    [Fact]
    public async Task Should_return_200_ok_with_list_of_urls()
    {
        await AddUrl();

        var response = await _client.GetAsync(UrlsEndpoint);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var urls = await response.Content
            .ReadFromJsonAsync<ListUrlsResponse>();
        urls!.Urls.Should().NotBeEmpty();
    }

    private async Task<AddUrlResponse?> AddUrl(string? url = null)
    {
        url ??= $"https://{Guid.NewGuid()}.tests";

        var response = await _client.PostAsJsonAsync(UrlsEndpoint,
            new AddUrlRequest(new Uri(url), ""));
        return await response.Content.ReadFromJsonAsync<AddUrlResponse>();
    }

    [Fact]
    public async Task Should_return_url_when_created_first()
    {
        var urlCreated = await AddUrl("https://testing-in-list.tests");
        
        var getResponse = await _client.GetAsync(UrlsEndpoint);
        var urls = await getResponse.Content
            .ReadFromJsonAsync<ListUrlsResponse>();

        urls!.Urls.Should()
            .Contain(url => url.ShortUrl == urlCreated!.ShortUrl);
    }

    [Fact]
    public async Task Should_return_only_the_number_of_urls_requested()
    {
        await AddUrl();
        await AddUrl();
        await AddUrl();
        
        var getResponse = await _client.GetAsync("/api/urls?pageSize=2");
        var urls = await getResponse.Content
            .ReadFromJsonAsync<ListUrlsResponse>();
        
        urls!.Urls.Should().HaveCount(2);
    }
    
    [Fact]
    public async Task Should_be_able_to_continue_to_next_page()
    {
        await AddUrl();
        await AddUrl();
        await AddUrl();
        
        var getFirstPageResponse = await _client.GetAsync("/api/urls?pageSize=2");
        var firstPageUrls = await getFirstPageResponse.Content
            .ReadFromJsonAsync<ListUrlsResponse>();
        
        var getNewPageResponse = await _client.GetAsync($"/api/urls?pageSize=2&continuation={firstPageUrls!.ContinuationToken}");
        var newPageUrls = await getNewPageResponse.Content
            .ReadFromJsonAsync<ListUrlsResponse>();

        newPageUrls!.Urls.Should()
            .NotIntersectWith(firstPageUrls!.Urls);
    }
    
    
    
    
    
}