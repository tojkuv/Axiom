using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Microsoft.Extensions.DependencyInjection;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Requires authenticated user
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AuthorizeAttribute : EndpointFilterAttribute
{
    public string? Policy { get; set; }
    public string? Roles { get; set; }
    public string? AuthenticationSchemes { get; set; }

    public override int Order => -1000; // Run early

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var httpContext = context.Context.HttpContext;

        // Check authentication
        if (!httpContext.User.Identity?.IsAuthenticated ?? true)
        {
            return ResultFactory.Failure<Unit>(new AxiomError(
                "UNAUTHORIZED",
                "Authentication required",
                ErrorType.Unauthorized));
        }

        // Check roles
        if (!string.IsNullOrEmpty(Roles))
        {
            var roles = Roles.Split(',', StringSplitOptions.RemoveEmptyEntries);
            if (!roles.Any(role => httpContext.User.IsInRole(role.Trim())))
            {
                return ResultFactory.Failure<Unit>(new AxiomError(
                    "FORBIDDEN",
                    "Insufficient permissions",
                    ErrorType.Forbidden));
            }
        }

        // Check policy
        if (!string.IsNullOrEmpty(Policy))
        {
            var authService = context.Context.HttpContext
                .RequestServices.GetRequiredService<IAuthorizationService>();

            var authResult = await authService.AuthorizeAsync(
                httpContext.User,
                context.Request,
                Policy);

            if (!authResult.Succeeded)
            {
                return ResultFactory.Failure<Unit>(new AxiomError(
                    "FORBIDDEN",
                    "Policy requirements not met",
                    ErrorType.Forbidden));
            }
        }

        return ResultFactory.Success(Unit.Value);
    }
}

/// <summary>
/// Allows anonymous access
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AllowAnonymousAttribute : Attribute, IEndpointMetadata
{
    // Marker attribute - handled by source generator
}

/// <summary>
/// Custom authorization requirement
/// </summary>
public abstract class AuthorizationRequirement : EndpointFilterAttribute
{
    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        if (!context.Context.HttpContext.User.Identity?.IsAuthenticated ?? true)
        {
            return ResultFactory.Failure<Unit>(new AxiomError(
                "UNAUTHORIZED",
                "Authentication required",
                ErrorType.Unauthorized));
        }

        var authorized = await IsAuthorizedAsync(
            context.Context.HttpContext.User,
            context.Request,
            context.Context);

        return authorized
            ? ResultFactory.Success(Unit.Value)
            : ResultFactory.Failure<Unit>(new AxiomError(
                "FORBIDDEN",
                GetFailureMessage(),
                ErrorType.Forbidden));
    }

    protected abstract ValueTask<bool> IsAuthorizedAsync(
        ClaimsPrincipal user,
        object request,
        IContext context);

    protected virtual string GetFailureMessage() => "Authorization requirement not met";
}

/// <summary>
/// Resource-based authorization
/// </summary>
public class ResourceOwnerAttribute : AuthorizationRequirement
{
    private readonly string _userIdProperty;

    public ResourceOwnerAttribute(string userIdProperty = "UserId")
    {
        _userIdProperty = userIdProperty;
    }

    protected override ValueTask<bool> IsAuthorizedAsync(
        ClaimsPrincipal user,
        object request,
        IContext context)
    {
        var userId = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
            return ValueTask.FromResult(false);

        var property = request.GetType().GetProperty(_userIdProperty);
        if (property == null)
            return ValueTask.FromResult(false);

        var resourceUserId = property.GetValue(request)?.ToString();
        return ValueTask.FromResult(userId == resourceUserId);
    }

    protected override string GetFailureMessage() => "User does not own this resource";
}

/// <summary>
/// Require specific scope authorization
/// </summary>
public class RequireScopeAttribute : AuthorizationRequirement
{
    private readonly string _scope;

    public RequireScopeAttribute(string scope)
    {
        _scope = scope;
    }

    protected override ValueTask<bool> IsAuthorizedAsync(
        ClaimsPrincipal user,
        object request,
        IContext context)
    {
        var scopes = user.FindFirst("scope")?.Value?.Split(' ') ?? Array.Empty<string>();
        return ValueTask.FromResult(scopes.Contains(_scope));
    }

    protected override string GetFailureMessage() => $"Required scope '{_scope}' not found";
}

/// <summary>
/// Require specific claim
/// </summary>
public class RequireClaimAttribute : AuthorizationRequirement
{
    private readonly string _claimType;
    private readonly string? _claimValue;

    public RequireClaimAttribute(string claimType, string? claimValue = null)
    {
        _claimType = claimType;
        _claimValue = claimValue;
    }

    protected override ValueTask<bool> IsAuthorizedAsync(
        ClaimsPrincipal user,
        object request,
        IContext context)
    {
        if (_claimValue == null)
        {
            return ValueTask.FromResult(user.HasClaim(_claimType, _claimValue));
        }
        
        return ValueTask.FromResult(user.Claims.Any(c => c.Type == _claimType));
    }

    protected override string GetFailureMessage() => 
        _claimValue == null 
            ? $"Required claim '{_claimType}' not found"
            : $"Required claim '{_claimType}' with value '{_claimValue}' not found";
}