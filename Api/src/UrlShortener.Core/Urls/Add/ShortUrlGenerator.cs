namespace UrlShortener.Core.Urls.Add;

public class ShortUrlGenerator
{
    private readonly TokenProvider _tokenProvider;

    public ShortUrlGenerator(TokenProvider tokenProvider)
    {
        _tokenProvider = tokenProvider;
    }
    public string  GenerateUniqueUrl()
    {
        return _tokenProvider
            .GetToken()
            .EncodeToBase62();
    }
}