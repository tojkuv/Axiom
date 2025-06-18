namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Route documentation information
/// </summary>
public record RouteDocumentationInfo
{
    public string? Summary { get; init; }
    public string? Description { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();
    public bool IsDeprecated { get; init; }
    public string? DeprecationMessage { get; init; }
}

/// <summary>
/// Documentation metadata for endpoints
/// </summary>
public record DocsMetadata
{
    public string? Summary { get; init; }
    public string? Description { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();
    public RouteDocumentationInfo? Documentation { get; init; }

    public static DocsMetadata None => new();

    public static DocsMetadata WithSummary(string summary, string? description = null) => new()
    {
        Summary = summary,
        Description = description,
        Documentation = new RouteDocumentationInfo
        {
            Summary = summary,
            Description = description
        }
    };

    public static DocsMetadata WithTags(params string[] tags) => new()
    {
        Tags = tags,
        Documentation = new RouteDocumentationInfo
        {
            Tags = tags
        }
    };

    public static DocsMetadata WithFull(
        string summary,
        string? description = null,
        string[]? tags = null,
        bool isDeprecated = false,
        string? deprecationMessage = null) => new()
    {
        Summary = summary,
        Description = description,
        Tags = tags ?? Array.Empty<string>(),
        Documentation = new RouteDocumentationInfo
        {
            Summary = summary,
            Description = description,
            Tags = tags ?? Array.Empty<string>(),
            IsDeprecated = isDeprecated,
            DeprecationMessage = deprecationMessage
        }
    };

    public static DocsMetadata Deprecated(string message, string? summary = null) => new()
    {
        Summary = summary,
        Documentation = new RouteDocumentationInfo
        {
            Summary = summary,
            IsDeprecated = true,
            DeprecationMessage = message
        }
    };
}