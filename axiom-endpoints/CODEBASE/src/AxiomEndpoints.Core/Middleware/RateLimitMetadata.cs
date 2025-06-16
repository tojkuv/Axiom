namespace AxiomEndpoints.Core.Middleware;

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
/// Rate limiting and CORS metadata for endpoints
/// </summary>
public record RateLimitMetadata
{
    public RateLimitPolicyInfo? RateLimitPolicy { get; init; }
    public string? CorsPolicy { get; init; }

    public static RateLimitMetadata None => new();

    public static RateLimitMetadata WithPolicy(string policyName, int permitLimit = 100, TimeSpan? window = null) => new()
    {
        RateLimitPolicy = new RateLimitPolicyInfo
        {
            PolicyName = policyName,
            PermitLimit = permitLimit,
            Window = window ?? TimeSpan.FromMinutes(1)
        }
    };

    public static RateLimitMetadata WithCors(string corsPolicy) => new()
    {
        CorsPolicy = corsPolicy
    };

    public static RateLimitMetadata WithBoth(
        string rateLimitPolicy,
        string corsPolicy,
        int permitLimit = 100,
        TimeSpan? window = null) => new()
    {
        RateLimitPolicy = new RateLimitPolicyInfo
        {
            PolicyName = rateLimitPolicy,
            PermitLimit = permitLimit,
            Window = window ?? TimeSpan.FromMinutes(1)
        },
        CorsPolicy = corsPolicy
    };
}