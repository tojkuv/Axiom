using System;

namespace AxiomEndpoints.Core.Attributes;

/// <summary>
/// Base attribute for HTTP method endpoints
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public abstract class HttpMethodAttribute : Attribute
{
    /// <summary>
    /// The route template for this endpoint
    /// </summary>
    public string Template { get; }
    
    /// <summary>
    /// Optional name for the endpoint
    /// </summary>
    public string? Name { get; set; }
    
    /// <summary>
    /// Tags for OpenAPI documentation
    /// </summary>
    public string[]? Tags { get; set; }
    
    /// <summary>
    /// HTTP method for this endpoint
    /// </summary>
    public abstract string HttpMethod { get; }

    protected HttpMethodAttribute(string template)
    {
        Template = template ?? throw new ArgumentNullException(nameof(template));
    }
}

/// <summary>
/// Marks a method as a GET endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class GetAttribute : HttpMethodAttribute
{
    public override string HttpMethod => "GET";
    
    public GetAttribute(string template) : base(template) { }
}

/// <summary>
/// Marks a method as a POST endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class PostAttribute : HttpMethodAttribute
{
    public override string HttpMethod => "POST";
    
    public PostAttribute(string template) : base(template) { }
}

/// <summary>
/// Marks a method as a PUT endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class PutAttribute : HttpMethodAttribute
{
    public override string HttpMethod => "PUT";
    
    public PutAttribute(string template) : base(template) { }
}

/// <summary>
/// Marks a method as a DELETE endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class DeleteAttribute : HttpMethodAttribute
{
    public override string HttpMethod => "DELETE";
    
    public DeleteAttribute(string template) : base(template) { }
}

/// <summary>
/// Marks a method as a PATCH endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class PatchAttribute : HttpMethodAttribute
{
    public override string HttpMethod => "PATCH";
    
    public PatchAttribute(string template) : base(template) { }
}

/// <summary>
/// Provides metadata for OpenAPI documentation
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class OpenApiAttribute : Attribute
{
    /// <summary>
    /// Summary for the endpoint
    /// </summary>
    public string Summary { get; }
    
    /// <summary>
    /// Description for the endpoint
    /// </summary>
    public string? Description { get; set; }
    
    /// <summary>
    /// Tags for grouping endpoints
    /// </summary>
    public string[]? Tags { get; set; }
    
    /// <summary>
    /// Whether this endpoint is deprecated
    /// </summary>
    public bool Deprecated { get; set; }

    public OpenApiAttribute(string summary)
    {
        Summary = summary ?? throw new ArgumentNullException(nameof(summary));
    }
}

/// <summary>
/// Specifies parameter binding from query string
/// </summary>
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class FromQueryAttribute : Attribute
{
    /// <summary>
    /// Name of the query parameter (defaults to parameter name)
    /// </summary>
    public string? Name { get; set; }
    
    /// <summary>
    /// Default value if parameter is missing
    /// </summary>
    public object? DefaultValue { get; set; }
    
    /// <summary>
    /// Whether this parameter is required
    /// </summary>
    public bool Required { get; set; } = false;
}

/// <summary>
/// Specifies parameter binding from route values
/// </summary>
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class FromRouteAttribute : Attribute
{
    /// <summary>
    /// Name of the route parameter (defaults to parameter name)
    /// </summary>
    public string? Name { get; set; }
}

/// <summary>
/// Specifies parameter binding from request body
/// </summary>
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class FromBodyAttribute : Attribute
{
    /// <summary>
    /// Whether the body parameter is required
    /// </summary>
    public bool Required { get; set; } = true;
}

/// <summary>
/// Specifies parameter binding from request header
/// </summary>
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class FromHeaderAttribute : Attribute
{
    /// <summary>
    /// Name of the header (defaults to parameter name)
    /// </summary>
    public string? Name { get; set; }
    
    /// <summary>
    /// Whether this header is required
    /// </summary>
    public bool Required { get; set; } = false;
}

/// <summary>
/// Specifies parameter binding from DI services
/// </summary>
[AttributeUsage(AttributeTargets.Parameter)]
public sealed class FromServicesAttribute : Attribute
{
}

/// <summary>
/// Specifies response caching for the endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class ResponseCacheAttribute : Attribute
{
    /// <summary>
    /// Cache duration in seconds
    /// </summary>
    public int Duration { get; set; }
    
    /// <summary>
    /// Cache location
    /// </summary>
    public string Location { get; set; } = "Any";
    
    /// <summary>
    /// Whether to vary by query string
    /// </summary>
    public bool VaryByQueryKeys { get; set; } = false;
    
    /// <summary>
    /// Headers to vary cache by
    /// </summary>
    public string[]? VaryByHeader { get; set; }
}

/// <summary>
/// Specifies rate limiting for the endpoint
/// </summary>
[AttributeUsage(AttributeTargets.Method)]
public sealed class RateLimitAttribute : Attribute
{
    /// <summary>
    /// Number of requests allowed
    /// </summary>
    public int Requests { get; }
    
    /// <summary>
    /// Time window in seconds
    /// </summary>
    public int WindowSeconds { get; }
    
    /// <summary>
    /// Rate limit policy name
    /// </summary>
    public string? Policy { get; set; }

    public RateLimitAttribute(int requests, int windowSeconds)
    {
        Requests = requests;
        WindowSeconds = windowSeconds;
    }
}