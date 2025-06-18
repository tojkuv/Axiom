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

// =================================================================
// PERFORMANCE OPTIMIZATION DEMONSTRATION ENDPOINTS
// =================================================================

/// <summary>
/// Demonstrates caching with user statistics
/// </summary>
public class GetUserStatsEndpoint : IRouteAxiom<Routes.V1.Users.Stats, ApiResponse<UserStatsDto>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IDataService _dataService;

    public GetUserStatsEndpoint(IDataService dataService)
    {
        _dataService = dataService;
    }

    public async ValueTask<Result<ApiResponse<UserStatsDto>>> HandleAsync(Routes.V1.Users.Stats route, IContext context)
    {
        var stats = await _dataService.GetUserStatsAsync(route.UserId, context.CancellationToken);
        
        var response = new ApiResponse<UserStatsDto>
        {
            Data = stats,
            Message = "User statistics retrieved (cached for 5 minutes)"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Demonstrates caching with active users list
/// </summary>
public class GetActiveUsersEndpoint : IRouteAxiom<Routes.V1.Users.Active, ApiResponse<List<UserDto>>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IDataService _dataService;

    public GetActiveUsersEndpoint(IDataService dataService)
    {
        _dataService = dataService;
    }

    public async ValueTask<Result<ApiResponse<List<UserDto>>>> HandleAsync(Routes.V1.Users.Active route, IContext context)
    {
        var users = await _dataService.GetActiveUsersAsync(context.CancellationToken);
        
        var response = new ApiResponse<List<UserDto>>
        {
            Data = users,
            Message = $"Retrieved {users.Count} active users (cached for 10 minutes)"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Demonstrates caching with recent posts
/// </summary>
public class GetRecentPostsEndpoint : IRouteAxiom<Routes.V1.Posts.Recent, ApiResponse<List<PostDto>>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IDataService _dataService;

    public GetRecentPostsEndpoint(IDataService dataService)
    {
        _dataService = dataService;
    }

    public async ValueTask<Result<ApiResponse<List<PostDto>>>> HandleAsync(Routes.V1.Posts.Recent route, IContext context)
    {
        var limit = Math.Min(route.Limit ?? 10, 50); // Cap at 50 for performance
        var posts = await _dataService.GetRecentPostsAsync(limit, context.CancellationToken);
        
        var response = new ApiResponse<List<PostDto>>
        {
            Data = posts,
            Message = $"Retrieved {posts.Count} recent posts (cached for 3 minutes)"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Demonstrates expensive computation with caching
/// </summary>
public class GetExpensiveDataEndpoint : IRouteAxiom<Routes.V1.Data.Expensive, ApiResponse<object>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IDataService _dataService;

    public GetExpensiveDataEndpoint(IDataService dataService)
    {
        _dataService = dataService;
    }

    public async ValueTask<Result<ApiResponse<object>>> HandleAsync(Routes.V1.Data.Expensive route, IContext context)
    {
        var data = await _dataService.GetExpensiveDataAsync(route.Key, context.CancellationToken);
        
        var response = new ApiResponse<object>
        {
            Data = data,
            Message = "Expensive computation result (cached for 30 minutes)"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Demonstrates object pooling with report generation
/// </summary>
public class GenerateUserReportEndpoint : IRouteAxiom<Routes.V1.Reports.User, ApiResponse<string>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IReportService _reportService;

    public GenerateUserReportEndpoint(IReportService reportService)
    {
        _reportService = reportService;
    }

    public async ValueTask<Result<ApiResponse<string>>> HandleAsync(Routes.V1.Reports.User route, IContext context)
    {
        var report = await _reportService.GenerateUserReportAsync(route.UserId, context.CancellationToken);
        
        // Set content type for text response
        context.HttpContext.Response.ContentType = "text/plain";
        
        var response = new ApiResponse<string>
        {
            Data = report,
            Message = "User report generated using object pooling for memory efficiency"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Demonstrates object pooling with large report generation (compression-friendly)
/// </summary>
public class GenerateLargeReportEndpoint : IRouteAxiom<Routes.V1.Reports.Large, ApiResponse<string>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IReportService _reportService;

    public GenerateLargeReportEndpoint(IReportService reportService)
    {
        _reportService = reportService;
    }

    public async ValueTask<Result<ApiResponse<string>>> HandleAsync(Routes.V1.Reports.Large route, IContext context)
    {
        var reportType = route.Type ?? "default";
        var report = await _reportService.GenerateLargeReportAsync(reportType, context.CancellationToken);
        
        // Set content type for text response (will be compressed by middleware)
        context.HttpContext.Response.ContentType = "text/plain";
        
        var response = new ApiResponse<string>
        {
            Data = report,
            Message = "Large report generated (object pooling + compression)"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Performance metrics endpoint to view collected performance data
/// </summary>
public class GetPerformanceMetricsEndpoint : IRouteAxiom<Routes.V1.Metrics.Performance, ApiResponse<Dictionary<string, object>>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IMetricsCollector _metricsCollector;

    public GetPerformanceMetricsEndpoint(IMetricsCollector metricsCollector)
    {
        _metricsCollector = metricsCollector;
    }

    public async ValueTask<Result<ApiResponse<Dictionary<string, object>>>> HandleAsync(Routes.V1.Metrics.Performance route, IContext context)
    {
        await Task.CompletedTask;
        
        var allMetrics = _metricsCollector.GetAllMetrics();
        
        var summary = allMetrics.ToDictionary(
            kvp => kvp.Key,
            kvp => (object)new
            {
                TotalRequests = kvp.Value.TotalRequests,
                AverageResponseTimeMs = Math.Round(kvp.Value.AverageResponseTimeMs, 2),
                MinResponseTimeMs = kvp.Value.MinResponseTimeMs,
                MaxResponseTimeMs = kvp.Value.MaxResponseTimeMs,
                ErrorRate = Math.Round(kvp.Value.ErrorRate * 100, 2), // Convert to percentage
                AverageMemoryPerRequestBytes = Math.Round(kvp.Value.AverageMemoryPerRequest, 0),
                TotalMemoryUsedBytes = kvp.Value.TotalMemoryUsed
            }
        );

        var response = new ApiResponse<Dictionary<string, object>>
        {
            Data = summary,
            Message = "Performance metrics collected by monitoring middleware"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Slow endpoint to demonstrate performance monitoring
/// </summary>
public class SlowEndpointExample : IRouteAxiom<Routes.V1.Test.Slow, ApiResponse<object>>
{
    public static HttpMethod Method => HttpMethod.Get;

    public async ValueTask<Result<ApiResponse<object>>> HandleAsync(Routes.V1.Test.Slow route, IContext context)
    {
        var delay = Math.Min(route.DelayMs ?? 1000, 5000); // Cap at 5 seconds for safety
        
        // Simulate slow operation
        await Task.Delay(delay, context.CancellationToken);
        
        // Simulate memory allocation for monitoring
        var largeData = new byte[1024 * 1024]; // 1MB allocation
        Array.Fill(largeData, (byte)1);
        
        var response = new ApiResponse<object>
        {
            Data = new 
            { 
                message = "Slow operation completed",
                delayMs = delay,
                allocatedMemoryMB = largeData.Length / (1024 * 1024),
                timestamp = DateTime.UtcNow
            },
            Message = "This endpoint intentionally slow to demonstrate performance monitoring"
        };
        
        return response.Success();
    }
}

/// <summary>
/// Cache stress test endpoint
/// </summary>
public class CacheStressTestEndpoint : IRouteAxiom<Routes.V1.Test.CacheStress, ApiResponse<object>>
{
    public static HttpMethod Method => HttpMethod.Get;
    
    private readonly IDataService _dataService;

    public CacheStressTestEndpoint(IDataService dataService)
    {
        _dataService = dataService;
    }

    public async ValueTask<Result<ApiResponse<object>>> HandleAsync(Routes.V1.Test.CacheStress route, IContext context)
    {
        var iterations = Math.Min(route.Iterations ?? 10, 100); // Cap for safety
        var results = new List<object>();
        
        for (int i = 0; i < iterations; i++)
        {
            var key = $"stress_test_{i}";
            var data = await _dataService.GetExpensiveDataAsync(key, context.CancellationToken);
            results.Add(new { iteration = i, key, hasData = data != null });
        }
        
        var response = new ApiResponse<object>
        {
            Data = new
            {
                iterations,
                results = results.Take(10), // Return first 10 for response size
                totalResults = results.Count,
                message = "Cache stress test completed"
            },
            Message = $"Executed {iterations} cache operations"
        };
        
        return response.Success();
    }
}