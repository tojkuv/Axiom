using AxiomEndpoints.Core;
using Microsoft.EntityFrameworkCore;
using System.Net.Http;

namespace AxiomEndpointsExample.Api;

// Health check endpoint
public class HealthEndpoint : IRouteAxiom<Routes.Health, ApiResponse<object>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
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
public class GetUsersV1Endpoint : IRouteAxiom<Routes.V1.Users.Index, PagedResponse<UserDto>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly AppDbContext _dbContext;

    public GetUsersV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<PagedResponse<UserDto>>> HandleAsync(Routes.V1.Users.Index route, IContext context)
    {
        var users = await _dbContext.Users
            .Where(u => u.Status == UserStatus.Active)
            .Take(20)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                Name = u.Name,
                Bio = u.Bio,
                CreatedAt = u.CreatedAt,
                Status = u.Status,
                PostsCount = _dbContext.Posts.Count(p => p.AuthorId == u.Id)
            })
            .ToListAsync(context.CancellationToken);

        var totalActiveUsers = await _dbContext.Users
            .Where(u => u.Status == UserStatus.Active)
            .CountAsync(context.CancellationToken);
        
        // Ensure totalPages is at least 1, even when no users exist
        var totalPages = totalActiveUsers == 0 ? 1 : (int)Math.Ceiling((double)totalActiveUsers / 20);
        
        var response = new PagedResponse<UserDto>
        {
            Data = users,
            Page = 1,
            Limit = 20,
            TotalCount = totalActiveUsers,
            TotalPages = totalPages,
            HasNextPage = totalPages > 1,
            HasPreviousPage = false
        };
        return response.Success();
    }
}

public class GetUserByIdV1Endpoint : IRouteAxiom<Routes.V1.Users.ById, ApiResponse<UserDto>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly AppDbContext _dbContext;

    public GetUserByIdV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<ApiResponse<UserDto>>> HandleAsync(Routes.V1.Users.ById route, IContext context)
    {
        // Check for malformed GUID - only if we get Guid.Empty AND the original string was not actually the empty GUID
        if (route.Id == Guid.Empty)
        {
            var routeValues = context.HttpContext.Request.RouteValues;
            if (routeValues.TryGetValue("Id", out var idValue) && 
                idValue is string idString && 
                !string.IsNullOrEmpty(idString) && 
                idString != "00000000-0000-0000-0000-000000000000" &&
                !Guid.TryParse(idString, out _)) // Only return BadRequest if it's truly malformed
            {
                return ResultFactory.Failure<ApiResponse<UserDto>>(AxiomError.Validation($"Invalid GUID format: {idString}"));
            }
        }

        // Debug: Log the incoming GUID
        Console.WriteLine($"[DEBUG] Looking for user with ID: {route.Id}");
        
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

        // Debug: Log the result
        Console.WriteLine($"[DEBUG] User found: {user != null}, Email: {user?.Email}");

        if (user == null)
        {
            // Debug: Check what users actually exist
            var allUserIds = await _dbContext.Users.Select(u => u.Id).ToListAsync();
            Console.WriteLine($"[DEBUG] Available user IDs: {string.Join(", ", allUserIds)}");
            
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

public class SearchUsersV1Endpoint : IRouteAxiom<Routes.V1.Users.Search, PagedResponse<UserDto>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly AppDbContext _dbContext;

    public SearchUsersV1Endpoint(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async ValueTask<Result<PagedResponse<UserDto>>> HandleAsync(Routes.V1.Users.Search route, IContext context)
    {
        // Handle case where route.Query is null due to binding issues
        var searchQuery = route.Query ?? ExtractSearchQueryFromContext(context);
        
        var query = _dbContext.Users.AsQueryable();

        // Apply search filter
        if (!string.IsNullOrEmpty(searchQuery.Search))
        {
            query = query.Where(u => u.Name.Contains(searchQuery.Search) || u.Email.Contains(searchQuery.Search));
        }

        // Apply status filter - default to Active users only
        if (searchQuery.Status.HasValue)
        {
            query = query.Where(u => u.Status == searchQuery.Status.Value);
        }
        else
        {
            // Default to active users only
            query = query.Where(u => u.Status == UserStatus.Active);
        }

        // Apply sorting
        query = searchQuery.Sort switch
        {
            UserSortBy.Name => searchQuery.Order == SortOrder.Asc ? query.OrderBy(u => u.Name) : query.OrderByDescending(u => u.Name),
            UserSortBy.Email => searchQuery.Order == SortOrder.Asc ? query.OrderBy(u => u.Email) : query.OrderByDescending(u => u.Email),
            UserSortBy.PostsCount => searchQuery.Order == SortOrder.Asc ? query.OrderBy(u => u.Posts.Count) : query.OrderByDescending(u => u.Posts.Count),
            _ => searchQuery.Order == SortOrder.Asc ? query.OrderBy(u => u.CreatedAt) : query.OrderByDescending(u => u.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var totalPages = (int)Math.Ceiling((double)totalCount / searchQuery.Limit);

        var users = await query
            .Skip((searchQuery.Page - 1) * searchQuery.Limit)
            .Take(searchQuery.Limit)
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
            Page = searchQuery.Page,
            Limit = searchQuery.Limit,
            TotalCount = totalCount,
            TotalPages = totalPages,
            HasNextPage = searchQuery.Page < totalPages,
            HasPreviousPage = searchQuery.Page > 1
        };
        return response.Success();
    }

    private static UserSearchQuery ExtractSearchQueryFromContext(IContext context)
    {
        var httpContext = context.HttpContext;
        var queryParams = httpContext.Request.Query;

        return new UserSearchQuery
        {
            Search = queryParams.TryGetValue("search", out var search) ? search.FirstOrDefault() : null,
            Status = queryParams.TryGetValue("status", out var statusValue) && 
                    Enum.TryParse<UserStatus>(statusValue.FirstOrDefault(), true, out var status) ? status : null,
            Page = queryParams.TryGetValue("page", out var pageValue) && 
                  int.TryParse(pageValue.FirstOrDefault(), out var page) && page > 0 ? page : 1,
            Limit = queryParams.TryGetValue("limit", out var limitValue) && 
                   int.TryParse(limitValue.FirstOrDefault(), out var limit) && limit > 0 && limit <= 100 ? limit : 20,
            Sort = queryParams.TryGetValue("sort", out var sortValue) && 
                  Enum.TryParse<UserSortBy>(sortValue.FirstOrDefault(), true, out var sort) ? sort : UserSortBy.CreatedAt,
            Order = queryParams.TryGetValue("order", out var orderValue) && 
                   Enum.TryParse<SortOrder>(orderValue.FirstOrDefault(), true, out var order) ? order : SortOrder.Desc
        };
    }
}

// Legacy API endpoint
public class LegacyApiEndpoint : IRouteAxiom<Routes.LegacyApi, ApiResponse<object>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
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