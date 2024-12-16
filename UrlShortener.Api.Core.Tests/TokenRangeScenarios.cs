using UrlShortener.Core;

namespace UrlShortener.Api.Core.Tests;

public class TokenRangeScenarios
{
    [Fact]
    public void When_start_token_is_greater_than_end_token_then_throws_exception()
    {
        var act = () => new TokenRange(10, 5);
        
        act.Should()
            .Throw<ArgumentException>()
            .WithMessage("End must be greater than or equal to start");
    }

}