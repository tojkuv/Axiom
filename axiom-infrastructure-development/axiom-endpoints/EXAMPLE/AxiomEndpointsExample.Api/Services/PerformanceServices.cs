using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using System.Collections.Concurrent;
using System.Text;

namespace AxiomEndpointsExample.Api;

/// <summary>
/// Interface for data service that demonstrates caching patterns
/// </summary>
public interface IDataService
{
    Task<UserStatsDto> GetUserStatsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<List<UserDto>> GetActiveUsersAsync(CancellationToken cancellationToken = default);
    Task<List<PostDto>> GetRecentPostsAsync(int limit = 10, CancellationToken cancellationToken = default);
    Task<object> GetExpensiveDataAsync(string key, CancellationToken cancellationToken = default);
}

/// <summary>
/// Data service implementation with caching to demonstrate performance optimizations
/// </summary>
public class DataService : IDataService
{
    private readonly AppDbContext _dbContext;
    private readonly IMemoryCache _cache;
    private readonly ILogger<DataService> _logger;

    public DataService(AppDbContext dbContext, IMemoryCache cache, ILogger<DataService> logger)
    {
        _dbContext = dbContext;
        _cache = cache;
        _logger = logger;
    }

    public async Task<UserStatsDto> GetUserStatsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"user_stats_{userId}";
        
        if (_cache.TryGetValue(cacheKey, out UserStatsDto? cachedStats))
        {
            _logger.LogInformation("Cache hit for user stats: {UserId}", userId);
            return cachedStats!;
        }

        _logger.LogInformation("Cache miss for user stats: {UserId}, querying database", userId);
        
        // Simulate complex calculation
        await Task.Delay(100, cancellationToken); // Simulate database query time
        
        var user = await _dbContext.Users
            .Where(u => u.Id == userId)
            .Select(u => new UserStatsDto
            {
                UserId = u.Id,
                Name = u.Name,
                PostCount = u.Posts.Count,
                CommentCount = u.Posts.Sum(p => p.Comments.Count),
                JoinedDate = u.CreatedAt,
                LastActivityDate = u.Posts.OrderByDescending(p => p.CreatedAt).Select(p => p.CreatedAt).FirstOrDefault()
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (user != null)
        {
            var cacheOptions = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5),
                SlidingExpiration = TimeSpan.FromMinutes(2),
                Priority = CacheItemPriority.Normal,
                Size = 1 // Approximate size for cache size limit
            };

            _cache.Set(cacheKey, user, cacheOptions);
            _logger.LogInformation("Cached user stats for: {UserId}", userId);
        }

        return user ?? new UserStatsDto { UserId = userId, Name = "Unknown User" };
    }

    public async Task<List<UserDto>> GetActiveUsersAsync(CancellationToken cancellationToken = default)
    {
        const string cacheKey = "active_users";
        
        if (_cache.TryGetValue(cacheKey, out List<UserDto>? cachedUsers))
        {
            _logger.LogInformation("Cache hit for active users list");
            return cachedUsers!;
        }

        _logger.LogInformation("Cache miss for active users, querying database");
        
        var users = await _dbContext.Users
            .Where(u => u.Status == UserStatus.Active)
            .Take(50) // Limit for performance
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
            .ToListAsync(cancellationToken);

        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
            Priority = CacheItemPriority.High,
            Size = users.Count
        };

        _cache.Set(cacheKey, users, cacheOptions);
        _logger.LogInformation("Cached {UserCount} active users", users.Count);

        return users;
    }

    public async Task<List<PostDto>> GetRecentPostsAsync(int limit = 10, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"recent_posts_{limit}";
        
        if (_cache.TryGetValue(cacheKey, out List<PostDto>? cachedPosts))
        {
            _logger.LogInformation("Cache hit for recent posts (limit: {Limit})", limit);
            return cachedPosts!;
        }

        _logger.LogInformation("Cache miss for recent posts, querying database");
        
        var posts = await _dbContext.Posts
            .Where(p => p.Status == PostStatus.Published)
            .OrderByDescending(p => p.CreatedAt)
            .Take(limit)
            .Select(p => new PostDto
            {
                Id = p.Id,
                Title = p.Title,
                Content = p.Content.Length > 200 ? p.Content.Substring(0, 200) + "..." : p.Content,
                Slug = p.Slug,
                Author = new UserDto
                {
                    Id = p.Author.Id,
                    Name = p.Author.Name,
                    Email = p.Author.Email,
                    Bio = p.Author.Bio,
                    CreatedAt = p.Author.CreatedAt,
                    Status = p.Author.Status,
                    PostsCount = 0 // Don't load this to avoid N+1
                },
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt,
                Status = p.Status,
                CommentsCount = p.Comments.Count
            })
            .ToListAsync(cancellationToken);

        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(3),
            Priority = CacheItemPriority.Normal,
            Size = posts.Count
        };

        _cache.Set(cacheKey, posts, cacheOptions);
        _logger.LogInformation("Cached {PostCount} recent posts", posts.Count);

        return posts;
    }

    public async Task<object> GetExpensiveDataAsync(string key, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"expensive_data_{key}";
        
        if (_cache.TryGetValue(cacheKey, out object? cachedData))
        {
            _logger.LogInformation("Cache hit for expensive data: {Key}", key);
            return cachedData!;
        }

        _logger.LogInformation("Cache miss for expensive data: {Key}, performing expensive operation", key);
        
        // Simulate expensive computation
        await Task.Delay(1000, cancellationToken);
        
        var data = new
        {
            Key = key,
            ComputedAt = DateTime.UtcNow,
            Data = Enumerable.Range(1, 1000).Select(i => new { Id = i, Value = $"Item_{i}_{key}" }).ToList(),
            ProcessingTimeMs = 1000
        };

        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30),
            Priority = CacheItemPriority.High,
            Size = 10 // Large data
        };

        _cache.Set(cacheKey, data, cacheOptions);
        _logger.LogInformation("Cached expensive data for key: {Key}", key);

        return data;
    }
}

/// <summary>
/// Report service that demonstrates object pooling for memory efficiency
/// </summary>
public interface IReportService
{
    Task<string> GenerateUserReportAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<string> GenerateLargeReportAsync(string reportType, CancellationToken cancellationToken = default);
}

public class ReportService : IReportService
{
    private readonly AppDbContext _dbContext;
    private readonly ILogger<ReportService> _logger;
    
    // Object pool for StringBuilder to reduce allocations
    private static readonly ConcurrentQueue<StringBuilder> _stringBuilderPool = new();
    private static readonly ConcurrentQueue<MemoryStream> _memoryStreamPool = new();

    public ReportService(AppDbContext dbContext, ILogger<ReportService> logger)
    {
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task<string> GenerateUserReportAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var sb = GetStringBuilder();
        
        try
        {
            _logger.LogInformation("Generating user report for: {UserId}", userId);
            
            var user = await _dbContext.Users
                .Include(u => u.Posts)
                .ThenInclude(p => p.Comments)
                .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user == null)
            {
                sb.AppendLine($"User Report - User Not Found: {userId}");
                sb.AppendLine($"Generated at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
                return sb.ToString();
            }

            // Build comprehensive report using pooled StringBuilder
            sb.AppendLine("=== USER PERFORMANCE REPORT ===");
            sb.AppendLine($"User ID: {user.Id}");
            sb.AppendLine($"Name: {user.Name}");
            sb.AppendLine($"Email: {user.Email}");
            sb.AppendLine($"Status: {user.Status}");
            sb.AppendLine($"Joined: {user.CreatedAt:yyyy-MM-dd}");
            sb.AppendLine();
            
            sb.AppendLine("=== ACTIVITY SUMMARY ===");
            sb.AppendLine($"Total Posts: {user.Posts.Count}");
            sb.AppendLine($"Total Comments Received: {user.Posts.Sum(p => p.Comments.Count)}");
            sb.AppendLine($"Average Comments per Post: {(user.Posts.Count > 0 ? user.Posts.Average(p => p.Comments.Count) : 0):F2}");
            sb.AppendLine();

            if (user.Posts.Any())
            {
                sb.AppendLine("=== POST DETAILS ===");
                foreach (var post in user.Posts.OrderByDescending(p => p.CreatedAt).Take(10))
                {
                    sb.AppendLine($"- {post.Title} (Comments: {post.Comments.Count}, Created: {post.CreatedAt:yyyy-MM-dd})");
                }
            }

            sb.AppendLine();
            sb.AppendLine($"Report Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
            
            return sb.ToString();
        }
        finally
        {
            ReturnStringBuilder(sb);
        }
    }

    public async Task<string> GenerateLargeReportAsync(string reportType, CancellationToken cancellationToken = default)
    {
        var sb = GetStringBuilder();
        
        try
        {
            _logger.LogInformation("Generating large report of type: {ReportType}", reportType);
            
            await Task.Delay(200, cancellationToken); // Simulate processing time
            
            sb.AppendLine($"=== LARGE {reportType.ToUpperInvariant()} REPORT ===");
            sb.AppendLine($"Generated at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
            sb.AppendLine();

            // Generate large amount of data to demonstrate object pooling efficiency
            for (int i = 1; i <= 1000; i++)
            {
                sb.AppendLine($"Section {i}: This is a large report section with data item {i}");
                sb.AppendLine($"  - Detail A: Value_{i}_A");
                sb.AppendLine($"  - Detail B: Value_{i}_B"); 
                sb.AppendLine($"  - Detail C: Value_{i}_C");
                
                if (i % 100 == 0)
                {
                    sb.AppendLine($"  *** Milestone reached: {i} sections processed ***");
                }
                
                sb.AppendLine();
            }

            sb.AppendLine("=== REPORT SUMMARY ===");
            sb.AppendLine($"Total sections: 1000");
            sb.AppendLine($"Report type: {reportType}");
            sb.AppendLine($"Size: {sb.Length:N0} characters");
            
            return sb.ToString();
        }
        finally
        {
            ReturnStringBuilder(sb);
        }
    }

    private static StringBuilder GetStringBuilder()
    {
        if (_stringBuilderPool.TryDequeue(out var sb))
        {
            sb.Clear(); // Reset for reuse
            return sb;
        }
        
        return new StringBuilder(capacity: 4096); // Pre-allocate reasonable capacity
    }

    private static void ReturnStringBuilder(StringBuilder sb)
    {
        if (sb.Capacity <= 32768) // Don't pool very large builders
        {
            _stringBuilderPool.Enqueue(sb);
        }
    }

    private static MemoryStream GetMemoryStream()
    {
        if (_memoryStreamPool.TryDequeue(out var ms))
        {
            ms.Position = 0;
            ms.SetLength(0);
            return ms;
        }
        
        return new MemoryStream();
    }

    private static void ReturnMemoryStream(MemoryStream ms)
    {
        if (ms.Capacity <= 1048576) // Don't pool streams larger than 1MB
        {
            _memoryStreamPool.Enqueue(ms);
        }
        else
        {
            ms.Dispose();
        }
    }
}

/// <summary>
/// Metrics collector for performance monitoring
/// </summary>
public interface IMetricsCollector
{
    void RecordRequestMetrics(string endpoint, long responseTimeMs, long memoryUsed, int statusCode);
    EndpointMetrics GetMetrics(string endpoint);
    Dictionary<string, EndpointMetrics> GetAllMetrics();
    void ClearMetrics();
}

public class MetricsCollector : IMetricsCollector
{
    private readonly ConcurrentDictionary<string, EndpointMetrics> _metrics = new();

    public void RecordRequestMetrics(string endpoint, long responseTimeMs, long memoryUsed, int statusCode)
    {
        var metrics = _metrics.GetOrAdd(endpoint, _ => new EndpointMetrics(endpoint));
        metrics.RecordRequest(responseTimeMs, memoryUsed, statusCode);
    }

    public EndpointMetrics GetMetrics(string endpoint)
    {
        return _metrics.GetValueOrDefault(endpoint) ?? new EndpointMetrics(endpoint);
    }

    public Dictionary<string, EndpointMetrics> GetAllMetrics()
    {
        return new Dictionary<string, EndpointMetrics>(_metrics);
    }

    public void ClearMetrics()
    {
        _metrics.Clear();
    }
}

public class EndpointMetrics
{
    private readonly object _lock = new();
    private long _totalRequests;
    private long _totalResponseTimeMs;
    private long _totalMemoryUsed;
    private long _errorCount;
    private long _minResponseTimeMs = long.MaxValue;
    private long _maxResponseTimeMs;

    public string Endpoint { get; }
    public long TotalRequests => _totalRequests;
    public double AverageResponseTimeMs => _totalRequests > 0 ? (double)_totalResponseTimeMs / _totalRequests : 0;
    public long MinResponseTimeMs => _minResponseTimeMs == long.MaxValue ? 0 : _minResponseTimeMs;
    public long MaxResponseTimeMs => _maxResponseTimeMs;
    public double ErrorRate => _totalRequests > 0 ? (double)_errorCount / _totalRequests : 0;
    public long TotalMemoryUsed => _totalMemoryUsed;
    public double AverageMemoryPerRequest => _totalRequests > 0 ? (double)_totalMemoryUsed / _totalRequests : 0;

    public EndpointMetrics(string endpoint)
    {
        Endpoint = endpoint;
    }

    public void RecordRequest(long responseTimeMs, long memoryUsed, int statusCode)
    {
        lock (_lock)
        {
            _totalRequests++;
            _totalResponseTimeMs += responseTimeMs;
            _totalMemoryUsed += memoryUsed;

            if (responseTimeMs < _minResponseTimeMs)
                _minResponseTimeMs = responseTimeMs;
            if (responseTimeMs > _maxResponseTimeMs)
                _maxResponseTimeMs = responseTimeMs;

            if (statusCode >= 400)
                _errorCount++;
        }
    }
}

/// <summary>
/// DTOs for performance demonstrations
/// </summary>
public record UserStatsDto
{
    public Guid UserId { get; init; }
    public string Name { get; init; } = string.Empty;
    public int PostCount { get; init; }
    public int CommentCount { get; init; }
    public DateTime JoinedDate { get; init; }
    public DateTime? LastActivityDate { get; init; }
}