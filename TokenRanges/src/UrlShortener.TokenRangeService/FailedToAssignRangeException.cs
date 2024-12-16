namespace UrlShortener.TokenRangeService;

public class FailedToAssignRangeException : Exception
{
    public FailedToAssignRangeException(string message) : base(message)
    {
    }
}