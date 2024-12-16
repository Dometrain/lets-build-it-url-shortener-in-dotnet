namespace UrlShortener.Api;

public class EnvironmentManager : IEnvironmentManager
{
    public void FatalError()
    {
        Environment.Exit(-1);
    }
}

public interface IEnvironmentManager
{
    public void FatalError();
}