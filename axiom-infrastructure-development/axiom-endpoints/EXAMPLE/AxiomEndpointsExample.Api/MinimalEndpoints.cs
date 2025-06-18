using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Attributes;
using Microsoft.EntityFrameworkCore;

namespace AxiomEndpointsExample.Api;

/// <summary>
/// Example minimal endpoints demonstrating the new attribute-based syntax
/// These methods will be automatically discovered by the source generator
/// and converted into proper AxiomEndpoint classes
/// </summary>
public static class MinimalEndpoints
{
    [Get("/api/v2/users/{id:guid}")]
    [OpenApi("Get user by ID", Description = "Returns a user by their unique identifier")]
    public static async Task<Result<ApiResponse<UserResponse>>> GetUserById(
        [FromRoute] Guid id,
        [FromServices] AppDbContext context,
        CancellationToken cancellationToken = default)
    {
        var user = await context.Users.FindAsync(id, cancellationToken);
        if (user is null)
            return ResultFactory.NotFound<ApiResponse<UserResponse>>("User not found");

        var response = new ApiResponse<UserResponse>
        {
            Data = new UserResponse
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                CreatedAt = user.CreatedAt
            }
        };
        return ResultFactory.Success(response);
    }

    [Get("/api/v2/users")]
    [OpenApi("Search users", Description = "Returns a paginated list of users based on search criteria")]
    public static async Task<Result<PagedResponse<UserResponse>>> SearchUsers(
        [FromServices] AppDbContext context,
        [FromQuery] string searchTerm = "",
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var query = context.Users.AsQueryable();

        if (!string.IsNullOrEmpty(searchTerm))
        {
            query = query.Where(u => u.Name.Contains(searchTerm) || u.Email.Contains(searchTerm));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var users = await query
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new UserResponse
            {
                Id = u.Id,
                Name = u.Name,
                Email = u.Email,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var response = new PagedResponse<UserResponse>
        {
            Data = users,
            Page = pageNumber,
            Limit = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            HasNextPage = pageNumber < (int)Math.Ceiling(totalCount / (double)pageSize),
            HasPreviousPage = pageNumber > 1
        };
        return ResultFactory.Success(response);
    }

    [Post("/api/v2/users")]
    [OpenApi("Create user", Description = "Creates a new user")]
    public static async Task<Result<ApiResponse<UserResponse>>> CreateUser(
        [FromBody] CreateUserRequest request,
        [FromServices] AppDbContext context,
        CancellationToken cancellationToken = default)
    {
        // In a real implementation, this would use automatic validation
        if (string.IsNullOrEmpty(request.Name))
            return ResultFactory.Failure<ApiResponse<UserResponse>>(AxiomError.Validation("Name is required"));

        if (string.IsNullOrEmpty(request.Email))
            return ResultFactory.Failure<ApiResponse<UserResponse>>(AxiomError.Validation("Email is required"));

        var user = new User
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Email = request.Email,
            CreatedAt = DateTime.UtcNow
        };

        context.Users.Add(user);
        await context.SaveChangesAsync(cancellationToken);

        var response = new ApiResponse<UserResponse>
        {
            Data = new UserResponse
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                CreatedAt = user.CreatedAt
            }
        };
        return ResultFactory.Success(response);
    }

    [Put("/api/v2/users/{id:guid}")]
    [OpenApi("Update user", Description = "Updates an existing user")]
    public static async Task<Result<ApiResponse<UserResponse>>> UpdateUser(
        [FromRoute] Guid id,
        [FromBody] UpdateUserRequest request,
        [FromServices] AppDbContext context,
        CancellationToken cancellationToken = default)
    {
        var user = await context.Users.FindAsync(id, cancellationToken);
        if (user is null)
            return ResultFactory.NotFound<ApiResponse<UserResponse>>("User not found");

        if (!string.IsNullOrEmpty(request.Name))
            user.Name = request.Name;

        if (!string.IsNullOrEmpty(request.Email))
            user.Email = request.Email;

        user.UpdatedAt = DateTime.UtcNow;

        await context.SaveChangesAsync(cancellationToken);

        var response = new ApiResponse<UserResponse>
        {
            Data = new UserResponse
            {
                Id = user.Id,
                Name = user.Name,
                Email = user.Email,
                CreatedAt = user.CreatedAt
            }
        };
        return ResultFactory.Success(response);
    }

    [Delete("/api/v2/users/{id:guid}")]
    [OpenApi("Delete user", Description = "Deletes a user")]
    public static async Task<Result<ApiResponse<object>>> DeleteUser(
        [FromRoute] Guid id,
        [FromServices] AppDbContext context,
        CancellationToken cancellationToken = default)
    {
        var user = await context.Users.FindAsync(id, cancellationToken);
        if (user is null)
            return ResultFactory.NotFound<ApiResponse<object>>("User not found");

        context.Users.Remove(user);
        await context.SaveChangesAsync(cancellationToken);

        var response = new ApiResponse<object>
        {
            Data = new { Message = "User deleted successfully" }
        };
        return ResultFactory.Success(response);
    }
}

// Supporting DTOs for the minimal endpoints
public class CreateUserRequest
{
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
}

public class UpdateUserRequest
{
    public string? Name { get; set; }
    public string? Email { get; set; }
}

public class UserResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

