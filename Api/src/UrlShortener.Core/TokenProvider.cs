namespace UrlShortener.Core;

public class TokenProvider
{
    private readonly object _tokenLock = new();

    private long _token = 0;
    private TokenRange? _tokenRange;
    public void AssignRange(int start, int end)
    {
        AssignRange(new TokenRange(start, end));
    }
    
    public void AssignRange(TokenRange tokenRange)
    {
        _tokenRange = tokenRange;
        _token = tokenRange.Start;
    }

    public long GetToken()
    {
        lock (_tokenLock)
        {
            return _token++;
        }
    }
}