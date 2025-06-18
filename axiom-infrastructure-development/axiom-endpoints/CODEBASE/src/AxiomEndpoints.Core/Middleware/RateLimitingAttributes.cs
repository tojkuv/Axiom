using System.Security.Claims;
using Microsoft.Extensions.DependencyInjection;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Rate limiting attribute using .NET's built-in rate limiting
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class RateLimitAttribute : EndpointFilterAttribute
{
    public string Policy { get; }
    public int PermitLimit { get; set; } = 100;
    public TimeSpan Window { get; set; } = TimeSpan.FromMinutes(1);
    public int QueueLimit { get; set; } = 0;

    public RateLimitAttribute(string policy = "default")
    {
        Policy = policy;
        Order = -900; // Run after auth
    }

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var rateLimiter = context.Context.HttpContext.RequestServices
            .GetRequiredService<IRateLimiterService>();

        var key = GetRateLimitKey(context);
        var lease = await rateLimiter.AcquireAsync(Policy, key, context.Context.CancellationToken);

        if (!lease.IsAcquired)
        {
            // Add rate limit headers
            var response = context.Context.HttpContext.Response;
            response.Headers["X-RateLimit-Limit"] = PermitLimit.ToString();
            response.Headers["X-RateLimit-Remaining"] = "0";
            response.Headers["X-RateLimit-Reset"] = lease.ResetTime?.ToUnixTimeSeconds().ToString() ?? "";

            if (lease.RetryAfter.HasValue)
            {
                response.Headers["Retry-After"] = lease.RetryAfter.Value.TotalSeconds.ToString("0");
            }

            return ResultFactory.Failure<Unit>(new AxiomError(
                "RATE_LIMIT_EXCEEDED",
                "Too many requests",
                ErrorType.TooManyRequests));
        }

        // Add rate limit headers for successful requests
        context.Context.HttpContext.Response.OnStarting(() =>
        {
            var response = context.Context.HttpContext.Response;
            response.Headers["X-RateLimit-Limit"] = PermitLimit.ToString();
            response.Headers["X-RateLimit-Remaining"] = lease.Remaining.ToString();
            response.Headers["X-RateLimit-Reset"] = lease.ResetTime?.ToUnixTimeSeconds().ToString() ?? "";
            return Task.CompletedTask;
        });

        return ResultFactory.Success(Unit.Value);
    }

    protected virtual string GetRateLimitKey(EndpointFilterContext context)
    {
        // Default implementation uses user ID or IP address
        var user = context.Context.HttpContext.User;
        if (user.Identity?.IsAuthenticated == true)
        {
            return $"user:{user.FindFirst(ClaimTypes.NameIdentifier)?.Value}";
        }

        var ip = context.Context.HttpContext.Connection.RemoteIpAddress?.ToString();
        return $"ip:{ip}";
    }
}

/// <summary>
/// Custom rate limiting by specific property
/// </summary>
public class RateLimitByAttribute : RateLimitAttribute
{
    private readonly string _property;

    public RateLimitByAttribute(string property, string policy = "default") : base(policy)
    {
        _property = property;
    }

    protected override string GetRateLimitKey(EndpointFilterContext context)
    {
        var value = context.Request.GetType()
            .GetProperty(_property)?
            .GetValue(context.Request)?
            .ToString();

        return string.IsNullOrEmpty(value)
            ? base.GetRateLimitKey(context)
            : $"{_property}:{value}";
    }
}

/// <summary>
/// Rate limiting by IP address
/// </summary>
public class RateLimitByIpAttribute : RateLimitAttribute
{
    public RateLimitByIpAttribute(string policy = "default") : base(policy)
    {
    }

    protected override string GetRateLimitKey(EndpointFilterContext context)
    {
        var ip = context.Context.HttpContext.Connection.RemoteIpAddress?.ToString();
        return $"ip:{ip ?? "unknown"}";
    }
}

/// <summary>
/// Rate limiting by user
/// </summary>
public class RateLimitByUserAttribute : RateLimitAttribute
{
    public RateLimitByUserAttribute(string policy = "default") : base(policy)
    {
    }

    protected override string GetRateLimitKey(EndpointFilterContext context)
    {
        var user = context.Context.HttpContext.User;
        if (user.Identity?.IsAuthenticated == true)
        {
            var userId = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return $"user:{userId ?? "anonymous"}";
        }

        // Fallback to IP if not authenticated
        var ip = context.Context.HttpContext.Connection.RemoteIpAddress?.ToString();
        return $"anonymous_ip:{ip ?? "unknown"}";
    }
}

/// <summary>
/// Rate limiter service abstraction
/// </summary>
public interface IRateLimiterService
{
    ValueTask<RateLimitLease> AcquireAsync(
        string policy,
        string key,
        CancellationToken cancellationToken = default);
}

public record RateLimitLease
{
    public bool IsAcquired { get; init; }
    public int Remaining { get; init; }
    public DateTimeOffset? ResetTime { get; init; }
    public TimeSpan? RetryAfter { get; init; }
}

/// <summary>
/// Default rate limiter service implementation
/// </summary>
public class DefaultRateLimiterService : IRateLimiterService
{
    private readonly Dictionary<string, RateLimitPolicy> _policies = new();
    private readonly Dictionary<string, Dictionary<string, RateLimitState>> _states = new();
    private readonly object _lock = new();

    public void AddPolicy(string name, RateLimitPolicy policy)
    {
        lock (_lock)
        {
            _policies[name] = policy;
            _states[name] = new Dictionary<string, RateLimitState>();
        }
    }

    public ValueTask<RateLimitLease> AcquireAsync(
        string policy,
        string key,
        CancellationToken cancellationToken = default)
    {
        lock (_lock)
        {
            if (!_policies.TryGetValue(policy, out var policyConfig))
            {
                // Default policy - allow
                return ValueTask.FromResult(new RateLimitLease
                {
                    IsAcquired = true,
                    Remaining = int.MaxValue
                });
            }

            if (!_states[policy].TryGetValue(key, out var state))
            {
                state = new RateLimitState
                {
                    Count = 0,
                    ResetTime = DateTimeOffset.UtcNow.Add(policyConfig.Window)
                };
                _states[policy][key] = state;
            }

            // Check if window has expired
            if (DateTimeOffset.UtcNow > state.ResetTime)
            {
                state.Count = 0;
                state.ResetTime = DateTimeOffset.UtcNow.Add(policyConfig.Window);
            }

            // Check if limit exceeded
            if (state.Count >= policyConfig.PermitLimit)
            {
                return ValueTask.FromResult(new RateLimitLease
                {
                    IsAcquired = false,
                    Remaining = 0,
                    ResetTime = state.ResetTime,
                    RetryAfter = state.ResetTime - DateTimeOffset.UtcNow
                });
            }

            // Acquire permit
            state.Count++;
            return ValueTask.FromResult(new RateLimitLease
            {
                IsAcquired = true,
                Remaining = policyConfig.PermitLimit - state.Count,
                ResetTime = state.ResetTime
            });
        }
    }
}

public record RateLimitPolicy
{
    public int PermitLimit { get; init; } = 100;
    public TimeSpan Window { get; init; } = TimeSpan.FromMinutes(1);
    public int QueueLimit { get; init; } = 0;
}

internal class RateLimitState
{
    public int Count { get; set; }
    public DateTimeOffset ResetTime { get; set; }
}