namespace UrlShortener.Core.Urls.Add;

public class AddUrlHandler
{
    private readonly ShortUrlGenerator _shortUrlGenerator;
    private readonly IUrlDataStore _urlDataStore;
    private readonly TimeProvider _timeProvider;
    private readonly RedirectLinkBuilder _redirectLinkBuilder;

    public AddUrlHandler(ShortUrlGenerator shortUrlGenerator, IUrlDataStore urlDataStore,
        TimeProvider timeProvider, RedirectLinkBuilder redirectLinkBuilder)
    {
        _shortUrlGenerator = shortUrlGenerator;
        _urlDataStore = urlDataStore;
        _timeProvider = timeProvider;
        _redirectLinkBuilder = redirectLinkBuilder;
    }

    public async Task<Result<AddUrlResponse>> HandleAsync(AddUrlRequest request, CancellationToken cancellationToken)
    {
        if(string.IsNullOrEmpty(request.CreatedBy))
            return Errors.MissingCreatedBy;
        
        var shortened = new ShortenedUrl(request.LongUrl,
            _shortUrlGenerator.GenerateUniqueUrl(), 
            request.CreatedBy,
           _timeProvider.GetUtcNow());

        await _urlDataStore.AddAsync(shortened, cancellationToken);

        return new AddUrlResponse(
            shortened.ShortUrl,
            request.LongUrl, 
            _redirectLinkBuilder.LinkTo(shortened.ShortUrl));
    }
}