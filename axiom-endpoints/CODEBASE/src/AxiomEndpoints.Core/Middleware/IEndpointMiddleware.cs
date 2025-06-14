using System.Collections.Frozen;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Base interface for endpoint middleware
/// </summary>
public interface IEndpointMiddleware
{
    int Order { get; }
    bool IsEnabled(IContext context);
}

/// <summary>
/// Pre-execution middleware
/// </summary>
public interface IEndpointFilter : IEndpointMiddleware
{
    ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context);
}

/// <summary>
/// Post-execution middleware
/// </summary>
public interface IEndpointResultFilter : IEndpointMiddleware
{
    ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context);
}

/// <summary>
/// Exception handling middleware
/// </summary>
public interface IEndpointExceptionFilter : IEndpointMiddleware
{
    ValueTask<Result<TResponse>> OnExceptionAsync<TResponse>(
        Exception exception,
        EndpointFilterContext context);
}

/// <summary>
/// Filter context with access to endpoint metadata
/// </summary>
public record EndpointFilterContext
{
    public required IContext Context { get; init; }
    public required EndpointMetadata Metadata { get; init; }
    public required object Request { get; init; }
    public required Type EndpointType { get; init; }
    public required FrozenDictionary<string, object> Properties { get; init; }
}

/// <summary>
/// Attribute base for middleware
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
public abstract class EndpointFilterAttribute : Attribute, IEndpointFilter
{
    public virtual int Order { get; set; }

    public virtual bool IsEnabled(IContext context) => true;

    public abstract ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context);
}

/// <summary>
/// Base class for result filters as attributes
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true)]
public abstract class EndpointResultFilterAttribute : Attribute, IEndpointResultFilter
{
    public virtual int Order { get; set; }

    public virtual bool IsEnabled(IContext context) => true;

    public abstract ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context);
}

/// <summary>
/// Middleware pipeline builder
/// </summary>
public interface IMiddlewarePipeline<TRequest, TResponse>
{
    ValueTask<Result<TResponse>> ExecuteAsync(
        TRequest request,
        IContext context,
        Func<TRequest, IContext, ValueTask<Result<TResponse>>> handler);
}

/// <summary>
/// Unit type for filters that don't return a value
/// </summary>
public readonly struct Unit
{
    public static readonly Unit Value = new();
}

/// <summary>
/// Endpoint metadata for middleware
/// </summary>
public record EndpointMetadata
{
    public required Type EndpointType { get; init; }
    public required string Template { get; init; }
    public required HttpMethod Method { get; init; }
    public Type? RequestType { get; init; }
    public Type? ResponseType { get; init; }
    public string? Summary { get; init; }
    public string? Description { get; init; }
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();
    
    // Authentication/Authorization
    public bool RequiresAuthentication { get; init; }
    public bool RequiresAuthorization { get; init; }
    public string? AuthorizationPolicy { get; init; }
    public bool AllowAnonymous { get; init; }
    public string[] RequiredRoles { get; init; } = Array.Empty<string>();
    public string[] RequiredPolicies { get; init; } = Array.Empty<string>();
    
    // Advanced routing properties
    public AxiomEndpoints.Core.ApiVersion? Version { get; init; }
    public FrozenDictionary<string, AxiomEndpoints.Core.IRouteConstraint> Constraints { get; init; } = FrozenDictionary<string, AxiomEndpoints.Core.IRouteConstraint>.Empty;
    public bool HasQueryParameters { get; init; }
    public AxiomEndpoints.Core.QueryParameterMetadata? QueryMetadata { get; init; }
    
    // Caching
    public CachePolicyInfo? CachePolicy { get; init; }
    public int CacheDuration { get; init; }
    public string? CacheVaryByQuery { get; init; }
    public string? CacheVaryByHeader { get; init; }
    
    // Rate limiting and CORS
    public RateLimitPolicyInfo? RateLimitPolicy { get; init; }
    public string? CorsPolicy { get; init; }
    
    // Documentation
    public RouteDocumentationInfo? Documentation { get; init; }
    
    // Additional metadata
    public FrozenDictionary<string, object> Metadata { get; init; } = FrozenDictionary<string, object>.Empty;

    public static EndpointMetadata FromType<TEndpoint>()
    {
        var type = typeof(TEndpoint);
        return new EndpointMetadata
        {
            EndpointType = type,
            Template = $"/{type.Name.ToLowerInvariant()}",
            Method = HttpMethod.Get
        };
    }

    public static EndpointMetadata FromType(Type endpointType)
    {
        return new EndpointMetadata
        {
            EndpointType = endpointType,
            Template = $"/{endpointType.Name.ToLowerInvariant()}",
            Method = HttpMethod.Get
        };
    }
}

/// <summary>
/// Marker interface for endpoint metadata
/// </summary>
public interface IEndpointMetadata
{
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
/// Rate limiting policy information
/// </summary>
public record RateLimitPolicyInfo
{
    public required string PolicyName { get; init; }
    public int PermitLimit { get; init; } = 100;
    public TimeSpan Window { get; init; } = TimeSpan.FromMinutes(1);
    public int QueueLimit { get; init; } = 0;
}

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
/// Constraint validation result
/// </summary>
public record ConstraintValidationResult
{
    public bool IsValid { get; init; }
    public string? ErrorMessage { get; init; }
    public string? ParameterName { get; init; }
    
    public static ConstraintValidationResult Success() => new() { IsValid = true };
    public static ConstraintValidationResult Failure(string message, string? parameterName = null) =>
        new() { IsValid = false, ErrorMessage = message, ParameterName = parameterName };
}