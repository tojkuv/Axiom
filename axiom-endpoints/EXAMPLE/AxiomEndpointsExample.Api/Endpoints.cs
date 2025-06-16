using AxiomEndpoints.Core;
using Microsoft.EntityFrameworkCore;

namespace AxiomEndpointsExample.Api;

// Health check endpoint
public class HealthEndpoint : IAxiom<Routes.Health, ApiResponse<object>>
{
    public async ValueTask<Result<ApiResponse<object>>> HandleAsync(Routes.Health route, IContext context)
    {
        await Task.CompletedTask;
        var response = new ApiResponse<object>
        {
            Data = new { status = "healthy", timestamp = DateTime.UtcNow },
            Message = "Service is running"
        };
        return response.Success();
    }
}

// User endpoints
public class GetUsersV1Endpoint : IAxiom<Routes.V1.Users.Index, PagedResponse<UserDto>>
{
    private readonly AppDbContext _dbContext;

    public GetUsersV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<PagedResponse<UserDto>>> HandleAsync(Routes.V1.Users.Index route, IContext context)
    {
        var users = await _dbContext.Users
            .Take(20)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                Name = u.Name,
                Bio = u.Bio,
                CreatedAt = u.CreatedAt,
                Status = u.Status,
                PostsCount = u.Posts.Count
            })
            .ToListAsync();

        var response = new PagedResponse<UserDto>
        {
            Data = users,
            Page = 1,
            Limit = 20,
            TotalCount = await _dbContext.Users.CountAsync(),
            TotalPages = 1,
            HasNextPage = false,
            HasPreviousPage = false
        };
        return response.Success();
    }
}

public class GetUserByIdV1Endpoint : IAxiom<Routes.V1.Users.ById, ApiResponse<UserDto>>
{
    private readonly AppDbContext _dbContext;

    public GetUserByIdV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<ApiResponse<UserDto>>> HandleAsync(Routes.V1.Users.ById route, IContext context)
    {
        var user = await _dbContext.Users
            .Where(u => u.Id == route.Id)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                Name = u.Name,
                Bio = u.Bio,
                CreatedAt = u.CreatedAt,
                Status = u.Status,
                PostsCount = u.Posts.Count
            })
            .FirstOrDefaultAsync();

        if (user == null)
        {
            return ResultFactory.NotFound<ApiResponse<UserDto>>($"User with ID {route.Id} not found");
        }

        var response = new ApiResponse<UserDto>
        {
            Data = user,
            Message = "User retrieved successfully"
        };
        return response.Success();
    }
}

public class SearchUsersV1Endpoint : IAxiom<Routes.V1.Users.Search, PagedResponse<UserDto>>
{
    private readonly AppDbContext _dbContext;

    public SearchUsersV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<PagedResponse<UserDto>>> HandleAsync(Routes.V1.Users.Search route, IContext context)
    {
        var query = _dbContext.Users.AsQueryable();

        // Apply search filter
        if (!string.IsNullOrEmpty(route.Query.Search))
        {
            query = query.Where(u => u.Name.Contains(route.Query.Search) || u.Email.Contains(route.Query.Search));
        }

        // Apply status filter
        if (route.Query.Status.HasValue)
        {
            query = query.Where(u => u.Status == route.Query.Status.Value);
        }

        // Apply sorting
        query = route.Query.Sort switch
        {
            UserSortBy.Name => route.Query.Order == SortOrder.Asc ? query.OrderBy(u => u.Name) : query.OrderByDescending(u => u.Name),
            UserSortBy.Email => route.Query.Order == SortOrder.Asc ? query.OrderBy(u => u.Email) : query.OrderByDescending(u => u.Email),
            UserSortBy.PostsCount => route.Query.Order == SortOrder.Asc ? query.OrderBy(u => u.Posts.Count) : query.OrderByDescending(u => u.Posts.Count),
            _ => route.Query.Order == SortOrder.Asc ? query.OrderBy(u => u.CreatedAt) : query.OrderByDescending(u => u.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling((double)totalCount / route.Query.Limit);

        var users = await query
            .Skip((route.Query.Page - 1) * route.Query.Limit)
            .Take(route.Query.Limit)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                Name = u.Name,
                Bio = u.Bio,
                CreatedAt = u.CreatedAt,
                Status = u.Status,
                PostsCount = u.Posts.Count
            })
            .ToListAsync();

        var response = new PagedResponse<UserDto>
        {
            Data = users,
            Page = route.Query.Page,
            Limit = route.Query.Limit,
            TotalCount = totalCount,
            TotalPages = totalPages,
            HasNextPage = route.Query.Page < totalPages,
            HasPreviousPage = route.Query.Page > 1
        };
        return response.Success();
    }
}

// Legacy API endpoint
public class LegacyApiEndpoint : IAxiom<Routes.LegacyApi, ApiResponse<object>>
{
    public async ValueTask<Result<ApiResponse<object>>> HandleAsync(Routes.LegacyApi route, IContext context)
    {
        await Task.CompletedTask;
        var response = new ApiResponse<object>
        {
            Data = new { message = "Legacy API still supported", version = "1.0" },
            Message = "This endpoint supports legacy clients"
        };
        return response.Success();
    }
}