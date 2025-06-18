using System.Collections.Frozen;

namespace AxiomEndpoints.Core;

/// <summary>
/// Route with optional parameters
/// </summary>
public interface IOptionalRoute<TSelf> : IRoute<TSelf>
    where TSelf : IOptionalRoute<TSelf>
{
    static abstract OptionalRouteParameters GetOptionalParameters();
}

public record OptionalRouteParameters
{
    public required FrozenSet<string> OptionalSegments { get; init; }
    public required FrozenDictionary<string, object> DefaultValues { get; init; }
}

/// <summary>
/// Versioned route
/// </summary>
public interface IVersionedRoute<TSelf> : IRoute<TSelf>
    where TSelf : IVersionedRoute<TSelf>
{
    static new abstract ApiVersion Version { get; }
    static VersioningStrategy VersioningStrategy => VersioningStrategy.Url;
}

public enum VersioningStrategy
{
    Url,        // /v1/users
    Header,     // X-API-Version: 1
    QueryString // ?api-version=1
}

/// <summary>
/// Route with complex hierarchy
/// </summary>
public interface IHierarchicalRoute<TSelf, TParent> : IRoute<TSelf>
    where TSelf : IHierarchicalRoute<TSelf, TParent>
    where TParent : IRoute<TParent>
{
    TParent Parent { get; }
}

/// <summary>
/// Route with alternatives (for migration scenarios)
/// </summary>
public interface IAlternativeRoute<TSelf> : IRoute<TSelf>
    where TSelf : IAlternativeRoute<TSelf>
{
    static abstract FrozenSet<string> AlternativeTemplates { get; }
}

/// <summary>
/// Route with catch-all parameters
/// </summary>
public interface ICatchAllRoute<TSelf> : IRoute<TSelf>
    where TSelf : ICatchAllRoute<TSelf>
{
    static abstract string CatchAllParameterName { get; }
}

/// <summary>
/// Route that supports middleware
/// </summary>
public interface IMiddlewareRoute<TSelf> : IRoute<TSelf>
    where TSelf : IMiddlewareRoute<TSelf>
{
    static abstract Type[] MiddlewareTypes { get; }
}

/// <summary>
/// Route with custom metadata
/// </summary>
public interface IMetadataRoute<TSelf> : IRoute<TSelf>
    where TSelf : IMetadataRoute<TSelf>
{
    static new abstract FrozenDictionary<string, object> Metadata { get; }
}

/// <summary>
/// Route that requires authentication
/// </summary>
public interface IAuthenticatedRoute<TSelf> : IRoute<TSelf>
    where TSelf : IAuthenticatedRoute<TSelf>
{
    static virtual string[] RequiredRoles => [];
    static virtual string[] RequiredPolicies => [];
    static virtual bool AllowAnonymous => false;
}

/// <summary>
/// Route with custom caching policy
/// </summary>
public interface ICacheableRoute<TSelf> : IRoute<TSelf>
    where TSelf : ICacheableRoute<TSelf>
{
    static abstract CachePolicy CachePolicy { get; }
}

public record CachePolicy
{
    public TimeSpan Duration { get; init; }
    public bool VaryByUser { get; init; }
    public string[] VaryByHeaders { get; init; } = [];
    public string[] VaryByQueryParams { get; init; } = [];
    public bool NoCache { get; init; }
}

/// <summary>
/// Route with rate limiting
/// </summary>
public interface IRateLimitedRoute<TSelf> : IRoute<TSelf>
    where TSelf : IRateLimitedRoute<TSelf>
{
    static abstract RateLimitPolicy RateLimitPolicy { get; }
}

public record RateLimitPolicy
{
    public int RequestsPerMinute { get; init; }
    public int RequestsPerHour { get; init; }
    public int RequestsPerDay { get; init; }
    public string? ByKey { get; init; } // "user", "ip", "apikey"
}

/// <summary>
/// Route with OpenAPI documentation
/// </summary>
public interface IDocumentedRoute<TSelf> : IRoute<TSelf>
    where TSelf : IDocumentedRoute<TSelf>
{
    static abstract RouteDocumentation Documentation { get; }
}

public record RouteDocumentation
{
    public required string Summary { get; init; }
    public required string Description { get; init; }
    public string[]? Tags { get; init; }
    public bool Deprecated { get; init; }
    public Dictionary<string, string>? ParameterDescriptions { get; init; }
    public Dictionary<int, string>? ResponseDescriptions { get; init; }
}