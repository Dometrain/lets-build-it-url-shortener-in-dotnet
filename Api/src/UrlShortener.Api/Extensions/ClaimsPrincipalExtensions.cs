using System.Security.Authentication;
using System.Security.Claims;

namespace UrlShortener.Api.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static string GetUserEmail(this ClaimsPrincipal self)
    {
        return self.FindFirstValue("preferred_username")
               ?? throw new AuthenticationException("Missing preferred_username claim");
    }
}