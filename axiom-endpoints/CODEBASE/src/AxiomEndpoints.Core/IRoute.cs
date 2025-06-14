using System.Collections.Frozen;
using System.Text.RegularExpressions;
using System.Numerics;

namespace AxiomEndpoints.Core;

/// <summary>
/// Enhanced route interface with query parameters and constraints
/// </summary>
public interface IRoute<TSelf> where TSelf : IRoute<TSelf>
{
    static abstract FrozenDictionary<string, object> Metadata { get; }
    static virtual string Template => typeof(TSelf).Name; // Will be enhanced by source generator
    static virtual RouteConstraints? Constraints => null;
    static virtual ApiVersion? Version => null;
}

/// <summary>
/// Route with query parameters
/// </summary>
public interface IRouteWithQuery<TSelf, TQuery> : IRoute<TSelf>
    where TSelf : IRouteWithQuery<TSelf, TQuery>
    where TQuery : IQueryParameters
{
    TQuery Query { get; }
}

/// <summary>
/// Marker interface for query parameter types
/// </summary>
public interface IQueryParameters
{
    static abstract QueryParameterMetadata GetMetadata();
}

/// <summary>
/// Route constraints definition
/// </summary>
public record RouteConstraints
{
    public FrozenDictionary<string, IRouteConstraint> ParameterConstraints { get; init; } =
        FrozenDictionary<string, IRouteConstraint>.Empty;

    public FrozenSet<string> RequiredParameters { get; init; } =
        FrozenSet<string>.Empty;

    public FrozenDictionary<string, object> DefaultValues { get; init; } =
        FrozenDictionary<string, object>.Empty;
}

/// <summary>
/// Base interface for route constraints
/// </summary>
public interface IRouteConstraint
{
    bool IsValid(string? value);
    string ErrorMessage { get; }
    string ConstraintString { get; }
}

/// <summary>
/// API versioning information
/// </summary>
public record ApiVersion(int Major, int Minor = 0, string? Status = null)
{
    public override string ToString() => Status is null
        ? $"v{Major}.{Minor}"
        : $"v{Major}.{Minor}-{Status}";
}

/// <summary>
/// Metadata for query parameter binding
/// </summary>
public record QueryParameterMetadata
{
    public required FrozenDictionary<string, QueryParameterInfo> Parameters { get; init; }
    public required FrozenSet<string> RequiredParameters { get; init; }
}

public record QueryParameterInfo
{
    public required string Name { get; init; }
    public required Type Type { get; init; }
    public required bool IsRequired { get; init; }
    public required object? DefaultValue { get; init; }
    public required IRouteConstraint? Constraint { get; init; }
    public required string? Description { get; init; }
}