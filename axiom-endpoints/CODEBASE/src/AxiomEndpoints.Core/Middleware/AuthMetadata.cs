namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Authentication and authorization metadata for endpoints
/// </summary>
public record AuthMetadata
{
    public bool RequiresAuthentication { get; init; }
    public bool RequiresAuthorization { get; init; }
    public string? AuthorizationPolicy { get; init; }
    public bool AllowAnonymous { get; init; }
    public string[] RequiredRoles { get; init; } = Array.Empty<string>();
    public string[] RequiredPolicies { get; init; } = Array.Empty<string>();

    public static AuthMetadata None => new();
    
    public static AuthMetadata Anonymous => new()
    {
        AllowAnonymous = true
    };

    public static AuthMetadata Authenticated => new()
    {
        RequiresAuthentication = true
    };

    public static AuthMetadata WithRoles(params string[] roles) => new()
    {
        RequiresAuthentication = true,
        RequiresAuthorization = true,
        RequiredRoles = roles
    };

    public static AuthMetadata WithPolicy(string policy) => new()
    {
        RequiresAuthentication = true,
        RequiresAuthorization = true,
        AuthorizationPolicy = policy
    };
}