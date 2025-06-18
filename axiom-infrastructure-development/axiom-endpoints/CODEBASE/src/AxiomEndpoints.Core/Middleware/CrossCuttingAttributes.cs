using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Primitives;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Response compression attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class CompressAttribute : EndpointResultFilterAttribute
{
    public string[]? CompressionTypes { get; set; }
    public int MinimumSizeBytes { get; set; } = 1024;

    public override ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess)
        {
            var response = context.Context.HttpContext.Response;
            
            // Set compression headers if not already set
            if (!response.Headers.ContainsKey("Content-Encoding"))
            {
                var acceptEncoding = context.Context.HttpContext.Request.Headers.TryGetValue("Accept-Encoding", out StringValues encoding) ? encoding.ToString() : "";
                
                if (acceptEncoding.Contains("gzip"))
                {
                    response.Headers["Content-Encoding"] = "gzip";
                }
                else if (acceptEncoding.Contains("deflate"))
                {
                    response.Headers["Content-Encoding"] = "deflate";
                }
                else if (acceptEncoding.Contains("br"))
                {
                    response.Headers["Content-Encoding"] = "br";
                }
            }
        }

        return ValueTask.FromResult(result);
    }
}

/// <summary>
/// CORS policy attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class CorsAttribute : EndpointFilterAttribute
{
    public string PolicyName { get; }
    public string[]? AllowedOrigins { get; set; }
    public string[]? AllowedMethods { get; set; }
    public string[]? AllowedHeaders { get; set; }
    public bool AllowCredentials { get; set; }

    public CorsAttribute(string policyName)
    {
        PolicyName = policyName;
        Order = -950; // Run early, after auth
    }

    public override ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var response = context.Context.HttpContext.Response;
        var request = context.Context.HttpContext.Request;

        // Set CORS headers
        if (AllowedOrigins != null && AllowedOrigins.Length > 0)
        {
            var origin = request.Headers.TryGetValue("Origin", out StringValues originValue) ? originValue.ToString() : "";
            if (AllowedOrigins.Contains("*") || AllowedOrigins.Contains(origin))
            {
                response.Headers["Access-Control-Allow-Origin"] = AllowedOrigins.Contains("*") ? "*" : origin;
            }
        }

        if (AllowedMethods != null && AllowedMethods.Length > 0)
        {
            response.Headers["Access-Control-Allow-Methods"] = string.Join(", ", AllowedMethods);
        }

        if (AllowedHeaders != null && AllowedHeaders.Length > 0)
        {
            response.Headers["Access-Control-Allow-Headers"] = string.Join(", ", AllowedHeaders);
        }

        if (AllowCredentials)
        {
            response.Headers["Access-Control-Allow-Credentials"] = "true";
        }

        return ValueTask.FromResult(ResultFactory.Success(Unit.Value));
    }
}

/// <summary>
/// Feature flag attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class FeatureFlagAttribute : EndpointFilterAttribute
{
    public string FeatureName { get; }
    public bool RequiredState { get; set; } = true;

    public FeatureFlagAttribute(string featureName)
    {
        FeatureName = featureName;
        Order = -950; // Run early
    }

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var featureManager = context.Context.HttpContext.RequestServices
            .GetService<IFeatureManager>();

        if (featureManager != null)
        {
            var isEnabled = await featureManager.IsEnabledAsync(FeatureName);
            
            if (isEnabled != RequiredState)
            {
                return ResultFactory.Failure<Unit>(new AxiomError(
                    "FEATURE_DISABLED",
                    $"Feature '{FeatureName}' is not available",
                    ErrorType.NotImplemented));
            }
        }

        return ResultFactory.Success(Unit.Value);
    }
}

/// <summary>
/// Security headers attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class SecurityHeadersAttribute : EndpointResultFilterAttribute
{
    public bool IncludeXFrameOptions { get; set; } = true;
    public bool IncludeXContentTypeOptions { get; set; } = true;
    public bool IncludeXXssProtection { get; set; } = true;
    public bool IncludeReferrerPolicy { get; set; } = true;
    public string? ContentSecurityPolicy { get; set; }

    public override ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess)
        {
            var response = context.Context.HttpContext.Response;

            if (IncludeXFrameOptions)
            {
                response.Headers["X-Frame-Options"] = "DENY";
            }

            if (IncludeXContentTypeOptions)
            {
                response.Headers["X-Content-Type-Options"] = "nosniff";
            }

            if (IncludeXXssProtection)
            {
                response.Headers["X-XSS-Protection"] = "1; mode=block";
            }

            if (IncludeReferrerPolicy)
            {
                response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
            }

            if (!string.IsNullOrEmpty(ContentSecurityPolicy))
            {
                response.Headers["Content-Security-Policy"] = ContentSecurityPolicy;
            }

            response.Headers["X-Powered-By"] = "AxiomEndpoints";
        }

        return ValueTask.FromResult(result);
    }
}

/// <summary>
/// Timeout attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class TimeoutAttribute : EndpointFilterAttribute
{
    public TimeSpan Timeout { get; }

    public TimeoutAttribute(int timeoutSeconds)
    {
        Timeout = TimeSpan.FromSeconds(timeoutSeconds);
        Order = -100; // Run late in pre-execution
    }

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        using var timeoutCts = new CancellationTokenSource(Timeout);
        using var combinedCts = CancellationTokenSource.CreateLinkedTokenSource(
            context.Context.CancellationToken, 
            timeoutCts.Token);

        // Replace the cancellation token in context (if possible)
        // Note: This is a simplified implementation
        // In a real implementation, you'd need to replace the context's cancellation token

        return ResultFactory.Success(Unit.Value);
    }
}

/// <summary>
/// Response type attribute for content negotiation
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ProducesAttribute : Attribute, IEndpointMetadata
{
    public string[] ContentTypes { get; }
    public Type? ResponseType { get; set; }

    public ProducesAttribute(params string[] contentTypes)
    {
        ContentTypes = contentTypes;
    }
}

/// <summary>
/// Request type attribute for model binding
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ConsumesAttribute : Attribute, IEndpointMetadata
{
    public string[] ContentTypes { get; }

    public ConsumesAttribute(params string[] contentTypes)
    {
        ContentTypes = contentTypes;
    }
}

/// <summary>
/// Simple feature manager interface
/// </summary>
public interface IFeatureManager
{
    ValueTask<bool> IsEnabledAsync(string featureName);
    ValueTask<bool> IsEnabledAsync<TContext>(string featureName, TContext context);
}

/// <summary>
/// Default feature manager implementation
/// </summary>
public class DefaultFeatureManager : IFeatureManager
{
    private readonly Dictionary<string, bool> _features = new();

    public void SetFeature(string name, bool enabled)
    {
        _features[name] = enabled;
    }

    public ValueTask<bool> IsEnabledAsync(string featureName)
    {
        return ValueTask.FromResult(_features.GetValueOrDefault(featureName, false));
    }

    public ValueTask<bool> IsEnabledAsync<TContext>(string featureName, TContext context)
    {
        return IsEnabledAsync(featureName);
    }
}