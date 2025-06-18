using System.Collections.Immutable;

namespace AxiomEndpoints.SourceGenerators;

/// <summary>
/// Enhanced route information for advanced routing features
/// </summary>
internal sealed class AdvancedRouteInfo
{
    public string TypeName { get; set; } = string.Empty;
    public string FullTypeName { get; set; } = string.Empty;
    public string Namespace { get; set; } = string.Empty;
    public string Template { get; set; } = string.Empty;
    public ImmutableArray<RouteParameter> Parameters { get; set; } = ImmutableArray<RouteParameter>.Empty;
    public ImmutableArray<RouteConstraintInfo> Constraints { get; set; } = ImmutableArray<RouteConstraintInfo>.Empty;
    public bool IsNested { get; set; }
    public string? ParentTypeName { get; set; }
    public ApiVersionInfo? Version { get; set; }
    public VersioningStrategy VersioningStrategy { get; set; } = VersioningStrategy.Url;
    public bool IsOptional { get; set; }
    public ImmutableArray<string> OptionalSegments { get; set; } = ImmutableArray<string>.Empty;
    public bool IsHierarchical { get; set; }
    public string? ParentRouteType { get; set; }
    public bool HasAlternatives { get; set; }
    public ImmutableArray<string> AlternativeTemplates { get; set; } = ImmutableArray<string>.Empty;
    public bool HasQueryParameters { get; set; }
    public QueryParameterMetadataInfo? QueryMetadata { get; set; }
    public HttpMethod HttpMethod { get; set; } = HttpMethod.Get;
    public bool RequiresAuthentication { get; set; }
    public ImmutableArray<string> RequiredRoles { get; set; } = ImmutableArray<string>.Empty;
    public ImmutableArray<string> RequiredPolicies { get; set; } = ImmutableArray<string>.Empty;
    public CachePolicyInfo? CachePolicy { get; set; }
    public RateLimitPolicyInfo? RateLimitPolicy { get; set; }
    public RouteDocumentationInfo? Documentation { get; set; }
    public ImmutableDictionary<string, object> Metadata { get; set; } = ImmutableDictionary<string, object>.Empty;
}

internal sealed class RouteConstraintInfo
{
    public string ParameterName { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string? Pattern { get; set; }
    public string? Min { get; set; }
    public string? Max { get; set; }
    public ImmutableArray<string> AllowedValues { get; set; } = ImmutableArray<string>.Empty;
}

internal sealed class ApiVersionInfo
{
    public int Major { get; set; }
    public int Minor { get; set; }
    public string? Status { get; set; }
}

internal enum VersioningStrategy
{
    Url,
    Header,
    QueryString
}

internal enum HttpMethod
{
    Get,
    Post,
    Put,
    Delete,
    Patch,
    Head,
    Options
}

internal sealed class QueryParameterMetadataInfo
{
    public ImmutableArray<QueryParameterInfo> Parameters { get; set; } = ImmutableArray<QueryParameterInfo>.Empty;
    public ImmutableArray<string> RequiredParameters { get; set; } = ImmutableArray<string>.Empty;
}

internal sealed class QueryParameterInfo
{
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool IsRequired { get; set; }
    public string? DefaultValue { get; set; }
    public RouteConstraintInfo? Constraint { get; set; }
    public string? Description { get; set; }
}

internal sealed class CachePolicyInfo
{
    public string Duration { get; set; } = "";
    public bool VaryByUser { get; set; }
    public ImmutableArray<string> VaryByHeaders { get; set; } = ImmutableArray<string>.Empty;
    public ImmutableArray<string> VaryByQueryParams { get; set; } = ImmutableArray<string>.Empty;
    public bool NoCache { get; set; }
}

internal sealed class RateLimitPolicyInfo
{
    public int RequestsPerMinute { get; set; }
    public int RequestsPerHour { get; set; }
    public int RequestsPerDay { get; set; }
    public string? ByKey { get; set; }
}

internal sealed class RouteDocumentationInfo
{
    public string Summary { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public ImmutableArray<string> Tags { get; set; } = ImmutableArray<string>.Empty;
    public bool Deprecated { get; set; }
    public ImmutableDictionary<string, string> ParameterDescriptions { get; set; } = ImmutableDictionary<string, string>.Empty;
    public ImmutableDictionary<int, string> ResponseDescriptions { get; set; } = ImmutableDictionary<int, string>.Empty;
}