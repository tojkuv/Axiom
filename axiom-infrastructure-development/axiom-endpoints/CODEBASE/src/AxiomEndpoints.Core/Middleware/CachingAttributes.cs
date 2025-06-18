using Microsoft.Extensions.Caching.Distributed;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Primitives;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Response caching attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class CacheAttribute : EndpointFilterAttribute, IEndpointResultFilter
{
    public int DurationSeconds { get; set; } = 60;
    public string? VaryByQuery { get; set; }
    public string? VaryByHeader { get; set; }
    public bool VaryByUser { get; set; }
    public CacheLocation Location { get; set; } = CacheLocation.Any;

    public override int Order => -500; // Run after auth but before others

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        // Check if we have cached response
        var cache = context.Context.HttpContext.RequestServices
            .GetRequiredService<IDistributedCache>();

        var cacheKey = GenerateCacheKey(context);
        var cachedData = await cache.GetAsync(cacheKey, context.Context.CancellationToken);

        if (cachedData != null)
        {
            // Return cached response
            var updatedProperties = new Dictionary<string, object>(context.Properties);
            updatedProperties["CacheHit"] = true;
            updatedProperties["CachedResponse"] = cachedData;
            updatedProperties["CacheKey"] = cacheKey;

            // Set cache headers
            SetCacheHeaders(context.Context.HttpContext.Response);
        }

        return ResultFactory.Success(Unit.Value);
    }

    public async ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        // Check if we had a cache hit
        if (context.Properties.TryGetValue("CacheHit", out var cacheHit) &&
            (bool)cacheHit &&
            context.Properties.TryGetValue("CachedResponse", out var cachedData))
        {
            // Deserialize and return cached response
            var response = JsonSerializer.Deserialize<TResponse>((byte[])cachedData!);
            return ResultFactory.Success(response!);
        }

        // Cache successful responses
        if (result.IsSuccess && ShouldCache(context))
        {
            var cache = context.Context.HttpContext.RequestServices
                .GetRequiredService<IDistributedCache>();

            var cacheKey = GenerateCacheKey(context);
            var serialized = JsonSerializer.SerializeToUtf8Bytes(result.Value);

            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(DurationSeconds)
            };

            await cache.SetAsync(cacheKey, serialized, options, context.Context.CancellationToken);

            // Set cache headers
            SetCacheHeaders(context.Context.HttpContext.Response);
        }

        return result;
    }

    private string GenerateCacheKey(EndpointFilterContext context)
    {
        var keyBuilder = new StringBuilder($"axiom:{context.EndpointType.Name}");

        // Add route values (simplified - route values not available in this context)
        // foreach (var (key, value) in context.Context.HttpContext.Request.RouteValues)
        // {
        //     keyBuilder.Append($":{key}={value}");
        // }

        // Vary by query
        if (!string.IsNullOrEmpty(VaryByQuery))
        {
            var queryKeys = VaryByQuery.Split(',', StringSplitOptions.RemoveEmptyEntries);
            foreach (var key in queryKeys)
            {
                if (context.Context.HttpContext.Request.Query.TryGetValue(key, out var values))
                {
                    keyBuilder.Append($":q_{key}={string.Join(",", values.ToArray())}");
                }
            }
        }

        // Vary by header
        if (!string.IsNullOrEmpty(VaryByHeader))
        {
            var headerKeys = VaryByHeader.Split(',', StringSplitOptions.RemoveEmptyEntries);
            foreach (var key in headerKeys)
            {
                if (context.Context.HttpContext.Request.Headers.TryGetValue(key, out var values))
                {
                    keyBuilder.Append($":h_{key}={string.Join(",", values.ToArray())}");
                }
            }
        }

        // Vary by user
        if (VaryByUser)
        {
            var userId = context.Context.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!string.IsNullOrEmpty(userId))
            {
                keyBuilder.Append($":user={userId}");
            }
        }

        return keyBuilder.ToString();
    }

    private bool ShouldCache(EndpointFilterContext context)
    {
        // Don't cache if explicitly disabled
        if (context.Context.HttpContext.Response.Headers.TryGetValue("Cache-Control", out StringValues cacheControl) &&
            cacheControl.ToString().Contains("no-store"))
            return false;

        // Only cache GET requests by default
        var method = context.Context.HttpContext.Request.Method;
        return method == "GET" || method == "HEAD";
    }

    private void SetCacheHeaders(HttpResponse response)
    {
        response.Headers["Cache-Control"] = Location switch
        {
            CacheLocation.Client => $"private, max-age={DurationSeconds}",
            CacheLocation.Server => "no-cache",
            CacheLocation.Any => $"public, max-age={DurationSeconds}",
            _ => "no-store"
        };

        response.Headers["Vary"] = VaryByHeader ?? "Accept, Accept-Encoding";
    }
}


/// <summary>
/// Cache invalidation attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class InvalidateCacheAttribute : EndpointResultFilterAttribute
{
    public string[] Patterns { get; }

    public InvalidateCacheAttribute(params string[] patterns)
    {
        Patterns = patterns;
    }

    public override async ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess)
        {
            var cache = context.Context.HttpContext.RequestServices
                .GetRequiredService<IDistributedCache>();

            // Invalidate cache entries matching patterns
            foreach (var pattern in Patterns)
            {
                var key = InterpolatePattern(pattern, context);
                await cache.RemoveAsync(key, context.Context.CancellationToken);
            }
        }

        return result;
    }

    private string InterpolatePattern(string pattern, EndpointFilterContext context)
    {
        // Replace placeholders with actual values
        // e.g., "axiom:GetTodo:{id}" -> "axiom:GetTodo:123"
        var result = pattern;

        // Route values not available in this context
        // foreach (var (key, value) in context.Context.HttpContext.Request.RouteValues)
        // {
        //     result = result.Replace($"{{{key}}}", value?.ToString() ?? "");
        // }

        return result;
    }
}

/// <summary>
/// Cache tag attribute for group invalidation
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class CacheTagAttribute : EndpointResultFilterAttribute
{
    public string[] Tags { get; }

    public CacheTagAttribute(params string[] tags)
    {
        Tags = tags;
    }

    public override ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess)
        {
            // Add cache tags to response headers for cache tag-based invalidation
            var tagHeader = string.Join(",", Tags);
            context.Context.HttpContext.Response.Headers["X-Cache-Tags"] = tagHeader;
        }

        return ValueTask.FromResult(result);
    }
}