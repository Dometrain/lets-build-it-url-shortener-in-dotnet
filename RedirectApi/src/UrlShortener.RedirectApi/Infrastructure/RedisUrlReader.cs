using StackExchange.Redis;

namespace UrlShortener.RedirectApi.Infrastructure;

public class RedisUrlReader : IShortenedUrlReader
{
    private readonly IShortenedUrlReader _reader;
    private readonly IDatabase _cache;

    public RedisUrlReader(IShortenedUrlReader reader, IConnectionMultiplexer redis)
    {
        _reader = reader;
        _cache = redis.GetDatabase();
    }
    
    public async Task<ReadLongUrlResponse> GetLongUrlAsync(string shortUrl, CancellationToken cancellationToken)
    {
        var cachedUrl = await _cache.StringGetAsync(shortUrl);
        if (cachedUrl.HasValue)
            return new ReadLongUrlResponse(true, cachedUrl.ToString());

        var getUrlResponse = await _reader.GetLongUrlAsync(shortUrl, cancellationToken);

        if (!getUrlResponse.Found)
            return getUrlResponse;

        await _cache.StringSetAsync(shortUrl, getUrlResponse.LongUrl);

        return getUrlResponse;
    }
}