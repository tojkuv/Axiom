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
/// Endpoint metadata for middleware - composed of focused metadata types
/// </summary>
public record EndpointMetadata
{
    public required Type EndpointType { get; init; }
    public required string Template { get; init; }
    public required HttpMethod Method { get; init; }
    public Type? RequestType { get; init; }
    public Type? ResponseType { get; init; }
    
    // Advanced routing properties
    public AxiomEndpoints.Core.ApiVersion? Version { get; init; }
    public FrozenDictionary<string, AxiomEndpoints.Core.IRouteConstraint> Constraints { get; init; } = FrozenDictionary<string, AxiomEndpoints.Core.IRouteConstraint>.Empty;
    public bool HasQueryParameters { get; init; }
    public AxiomEndpoints.Core.QueryParameterMetadata? QueryMetadata { get; init; }
    
    // Focused metadata types
    public AuthMetadata Auth { get; init; } = AuthMetadata.None;
    public CacheMetadata Cache { get; init; } = CacheMetadata.None;
    public RateLimitMetadata RateLimit { get; init; } = RateLimitMetadata.None;
    public DocsMetadata Docs { get; init; } = DocsMetadata.None;
    
    // Additional metadata
    public FrozenDictionary<string, object> Metadata { get; init; } = FrozenDictionary<string, object>.Empty;

    // Legacy properties for backward compatibility
    public bool RequiresAuthentication => Auth.RequiresAuthentication;
    public bool RequiresAuthorization => Auth.RequiresAuthorization;
    public string? AuthorizationPolicy => Auth.AuthorizationPolicy;
    public bool AllowAnonymous => Auth.AllowAnonymous;
    public string[] RequiredRoles => Auth.RequiredRoles;
    public string[] RequiredPolicies => Auth.RequiredPolicies;
    
    public CachePolicyInfo? CachePolicy => Cache.CachePolicy;
    public int CacheDuration => Cache.CacheDuration;
    public string? CacheVaryByQuery => Cache.CacheVaryByQuery;
    public string? CacheVaryByHeader => Cache.CacheVaryByHeader;
    
    public RateLimitPolicyInfo? RateLimitPolicy => RateLimit.RateLimitPolicy;
    public string? CorsPolicy => RateLimit.CorsPolicy;
    
    public string? Summary => Docs.Summary;
    public string? Description => Docs.Description;
    public IReadOnlyList<string> Tags => Docs.Tags;
    public RouteDocumentationInfo? Documentation => Docs.Documentation;

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

    public static EndpointMetadata Create(
        Type endpointType,
        string template,
        HttpMethod method,
        Type? requestType = null,
        Type? responseType = null,
        AuthMetadata? auth = null,
        CacheMetadata? cache = null,
        RateLimitMetadata? rateLimit = null,
        DocsMetadata? docs = null) => new()
    {
        EndpointType = endpointType,
        Template = template,
        Method = method,
        RequestType = requestType,
        ResponseType = responseType,
        Auth = auth ?? AuthMetadata.None,
        Cache = cache ?? CacheMetadata.None,
        RateLimit = rateLimit ?? RateLimitMetadata.None,
        Docs = docs ?? DocsMetadata.None
    };
}

/// <summary>
/// Marker interface for endpoint metadata
/// </summary>
public interface IEndpointMetadata
{
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