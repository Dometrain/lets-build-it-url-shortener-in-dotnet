namespace UrlShortener.Core.Urls.List;

public class ListUrlsHandler
{
    private readonly IUserUrlsReader _userUrlsReader;
    private const int MaxPageSize = 20;

    public ListUrlsHandler(IUserUrlsReader userUrlsReader)
    {
        _userUrlsReader = userUrlsReader;
    }

    public async Task<ListUrlsResponse> HandleAsync(ListUrlsRequest request, CancellationToken cancellationToken)
    {
        return await _userUrlsReader.GetAsync(request.Author,
            int.Min(request.PageSize ?? MaxPageSize, MaxPageSize),
            request.ContinuationToken,
            cancellationToken);
    }
}