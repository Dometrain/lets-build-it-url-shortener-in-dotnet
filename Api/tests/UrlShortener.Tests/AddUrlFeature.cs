using System.Net;
using System.Net.Http.Json;
using UrlShortener.Core.Urls.Add;

namespace UrlShortener.Tests;

public class AddUrlFeature : IClassFixture<ApiFixture>
{
    private readonly HttpClient _client;

    public AddUrlFeature(ApiFixture fixture)
    {
        _client = fixture.CreateClient();
    }

    [Fact]
    public async Task Given_long_url_Should_return_short_url()
    {
        var response = await _client.PostAsJsonAsync("/api/urls",
            new AddUrlRequest(new Uri("https://dometrain.com"), ""));
        
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var addUrlResponse = await response.Content.ReadFromJsonAsync<AddUrlResponse>();
        addUrlResponse!.ShortUrl.Should().NotBeNull();
    }
}