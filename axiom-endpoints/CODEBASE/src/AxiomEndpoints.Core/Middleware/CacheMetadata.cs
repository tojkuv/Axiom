namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Cache location options
/// </summary>
public enum CacheLocation
{
    Any,
    Client,
    Server,
    None
}

/// <summary>
/// Cache policy information
/// </summary>
public record CachePolicyInfo
{
    public TimeSpan Duration { get; init; }
    public string? VaryByQuery { get; init; }
    public string? VaryByHeader { get; init; }
    public bool VaryByUser { get; init; }
    public CacheLocation Location { get; init; }
}

/// <summary>
/// Caching metadata for endpoints
/// </summary>
public record CacheMetadata
{
    public CachePolicyInfo? CachePolicy { get; init; }
    public int CacheDuration { get; init; }
    public string? CacheVaryByQuery { get; init; }
    public string? CacheVaryByHeader { get; init; }

    public static CacheMetadata None => new();

    public static CacheMetadata WithDuration(TimeSpan duration, CacheLocation location = CacheLocation.Any) => new()
    {
        CachePolicy = new CachePolicyInfo
        {
            Duration = duration,
            Location = location
        },
        CacheDuration = (int)duration.TotalSeconds
    };

    public static CacheMetadata WithVaryBy(
        TimeSpan duration,
        string? varyByQuery = null,
        string? varyByHeader = null,
        bool varyByUser = false) => new()
    {
        CachePolicy = new CachePolicyInfo
        {
            Duration = duration,
            VaryByQuery = varyByQuery,
            VaryByHeader = varyByHeader,
            VaryByUser = varyByUser
        },
        CacheDuration = (int)duration.TotalSeconds,
        CacheVaryByQuery = varyByQuery,
        CacheVaryByHeader = varyByHeader
    };
}