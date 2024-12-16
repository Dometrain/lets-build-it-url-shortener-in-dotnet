using System.Collections.Concurrent;
using UrlShortener.Core;

namespace UrlShortener.Api.Core.Tests;

public class TokenProviderScenarios
{
    private TokenProvider _provider = new();

    [Fact]
    public void Should_get_the_token_from_start()
    {
        _provider.AssignRange(5, 10);

        _provider.GetToken().Should().Be(5);
    }
    
    [Fact]
    public void Should_increment_token_on_get()
    {
        _provider.AssignRange(5, 10);
        _provider.GetToken();
        
        _provider.GetToken().Should().Be(6);
    }
    
    [Fact]
    public void Should_not_return_same_token_twice()
    {
        ConcurrentBag<long> tokens = [];
        const int start = 1;
        const int end = 10000;
        _provider.AssignRange(start, end);

        Parallel.ForEach(Enumerable.Range(start, end),
            _ => tokens.Add(_provider.GetToken())
        );

        tokens.Should().OnlyHaveUniqueItems();
    }
    
    [Fact]
    public void Should_use_multiple_ranges()
    {
        _provider.AssignRange(1, 2);
        _provider.AssignRange(42, 45);
        _provider.GetToken(); // 1
        _provider.GetToken(); // 2

        var token = _provider.GetToken(); // 42

        token.Should().Be(42);
    }

    [Fact]
    public void Should_trigger_reaching_range_limit_event_when_range_is_at_80_percent()
    {
        _provider.AssignRange(1, 10);
        bool eventTriggered = false;
        _provider.ReachingRangeLimit += (sender, args) =>
        {
            eventTriggered = true;
        };

        for (int i = 0; i < 8; i++)
        {  
            _provider.GetToken();
        }

        eventTriggered.Should().BeTrue();
    }
}