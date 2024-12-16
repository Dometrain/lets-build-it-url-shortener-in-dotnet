namespace UrlShortener.Core;

public static  class Errors
{
    public static Error MissingCreatedBy => new("missing_value", "Created by is required");
}