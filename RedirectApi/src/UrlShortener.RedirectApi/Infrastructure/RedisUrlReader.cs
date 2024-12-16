using StackExchange.Redis;

namespace UrlShortener.RedirectApi.Infrastructure;

public class RedisUrlReader : IShortenedUrlReader
{
    private readonly IShortenedUrlReader _reader;
    private readonly IDatabase _cache;
    private readonly ILogger<RedisUrlReader> _logger;

    public RedisUrlReader(IShortenedUrlReader reader, IConnectionMultiplexer redis, ILogger<RedisUrlReader> logger)
    {
        _reader = reader;
        _logger = logger;
        _cache = redis.GetDatabase();
    }

    public async Task<ReadLongUrlResponse> GetLongUrlAsync(string shortUrl, CancellationToken cancellationToken)
    {
        try
        {
            var cachedUrl = await _cache.StringGetAsync(shortUrl);
            if (cachedUrl.HasValue)
                return new ReadLongUrlResponse(true, cachedUrl.ToString());
        }
        catch (RedisException redisException)
        {
            _logger.LogError(redisException, "Failed to read from cache");
        }

        var getUrlResponse = await _reader.GetLongUrlAsync(shortUrl, cancellationToken);

        if (!getUrlResponse.Found)
            return getUrlResponse;

        try
        {
            await _cache.StringSetAsync(shortUrl, getUrlResponse.LongUrl);
        }
        catch (RedisException redisException)
        {
            _logger.LogError(redisException, "Failed to write to cache");
        }

        return getUrlResponse;
    }
}