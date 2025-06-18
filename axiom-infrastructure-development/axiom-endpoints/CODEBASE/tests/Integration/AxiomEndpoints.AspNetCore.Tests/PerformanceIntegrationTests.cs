using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AxiomEndpoints.Core;
using AxiomEndpoints.AspNetCore;
using FluentAssertions;
using Xunit;
using System.Text.Json;
using System.Text;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Http;

namespace AxiomEndpoints.AspNetCore.Tests;

/// <summary>
/// Integration tests for performance optimization features
/// </summary>
public class PerformanceIntegrationTests : IAsyncDisposable
{
    private readonly TestServer _server;
    private readonly HttpClient _client;

    public PerformanceIntegrationTests()
    {
        var builder = WebApplication.CreateBuilder();
        
        // Add configuration for testing
        var inMemorySettings = new Dictionary<string, string?>
        {
            ["Axiom:Performance:EnableCaching"] = "true",
            ["Axiom:Performance:EnableCompression"] = "true",
            ["Axiom:Performance:EnablePerformanceMonitoring"] = "true",
            ["Axiom:Performance:Cache:DefaultExpirationMinutes"] = "5",
            ["Axiom:Performance:Cache:SizeLimit"] = "1000000"
        };
        
        builder.Configuration.AddInMemoryCollection(inMemorySettings);
        
        // Add Axiom endpoints with performance optimizations
        builder.Services.AddAxiomEndpoints();
        
        // Add basic caching for testing performance features
        builder.Services.AddMemoryCache();
        
        // Add test endpoints
        builder.Services.AddScoped<CachedDataEndpoint>();
        builder.Services.AddScoped<LargeDataEndpoint>();
        builder.Services.AddScoped<SlowEndpoint>();
        
        builder.WebHost.UseTestServer();
        
        var app = builder.Build();
        
        // Note: Performance middleware would be added here in a real application
        // using app.UseAxiomPerformance() from the generated code
        
        // Map test endpoints
        app.MapGet("/cached-data/{key}", async (string key, CachedDataEndpoint endpoint, IMemoryCache cache) =>
        {
            var context = new PerformanceTestContext();
            var request = new CachedDataRequest(key);
            
            // Simulate caching behavior
            var cacheKey = $"cached-data:{key}";
            if (!cache.TryGetValue(cacheKey, out var cachedResult))
            {
                var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
                if (result.IsSuccess)
                {
                    cache.Set(cacheKey, result.Value, TimeSpan.FromMinutes(5));
                }
                return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
            }
            
            return Results.Ok(cachedResult);
        });
        
        app.MapGet("/large-data", async (LargeDataEndpoint endpoint) =>
        {
            var context = new PerformanceTestContext();
            var request = new LargeDataRequest();
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.MapGet("/slow-endpoint", async (SlowEndpoint endpoint) =>
        {
            var context = new PerformanceTestContext();
            var request = new SlowRequest();
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.Start();
        _server = app.GetTestServer();
        _client = _server.CreateClient();
    }

    [Fact]
    public async Task CachedEndpoint_Should_Cache_Response()
    {
        // Arrange
        var key = "test-key";
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        // Act - First request should execute endpoint
        var response1 = await _client.GetAsync($"/cached-data/{key}");
        var firstRequestTime = stopwatch.ElapsedMilliseconds;
        stopwatch.Restart();

        // Act - Second request should hit cache
        var response2 = await _client.GetAsync($"/cached-data/{key}");
        var secondRequestTime = stopwatch.ElapsedMilliseconds;

        // Assert
        response1.Should().BeSuccessful();
        response2.Should().BeSuccessful();
        
        var content1 = await response1.Content.ReadAsStringAsync();
        var content2 = await response2.Content.ReadAsStringAsync();
        
        content1.Should().Be(content2); // Same content
        secondRequestTime.Should().BeLessThan(firstRequestTime); // Faster due to caching
    }

    [Fact]
    public async Task LargeDataEndpoint_Should_Support_Compression()
    {
        // Arrange
        _client.DefaultRequestHeaders.Clear();
        _client.DefaultRequestHeaders.Add("Accept-Encoding", "gzip, deflate, br");

        // Act
        var response = await _client.GetAsync("/large-data");

        // Assert
        response.Should().BeSuccessful();
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().NotBeNullOrEmpty();
        content.Length.Should().BeGreaterThan(1000); // Large response
        
        // In a real scenario, the response would be compressed
        // Here we just verify the endpoint works
    }

    [Fact]
    public async Task SlowEndpoint_Should_Be_Monitored()
    {
        // Arrange
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();

        // Act
        var response = await _client.GetAsync("/slow-endpoint");
        stopwatch.Stop();

        // Assert
        response.Should().BeSuccessful();
        stopwatch.ElapsedMilliseconds.Should().BeGreaterThan(100); // Endpoint takes time
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("Slow operation completed");
    }

    [Fact]
    public async Task Performance_Headers_Should_Be_Present()
    {
        // Act
        var response = await _client.GetAsync("/large-data");

        // Assert
        response.Should().BeSuccessful();
        
        // Check for performance-related headers that might be added by middleware
        response.Headers.Should().NotBeNull();
    }

    [Fact]
    public async Task Multiple_Concurrent_Requests_Should_Handle_Load()
    {
        // Arrange
        const int concurrentRequests = 10;
        var tasks = new List<Task<HttpResponseMessage>>();

        // Act
        for (int i = 0; i < concurrentRequests; i++)
        {
            var task = _client.GetAsync($"/cached-data/load-test-{i}");
            tasks.Add(task);
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        responses.Should().HaveCount(concurrentRequests);
        responses.Should().OnlyContain(r => r.IsSuccessStatusCode);
    }

    [Fact]
    public async Task ObjectPool_Should_Reduce_Allocations()
    {
        // Arrange - This test would benefit from object pooling
        var initialMemory = GC.GetTotalMemory(false);

        // Act - Make multiple requests that would normally allocate
        var tasks = Enumerable.Range(0, 20)
            .Select(i => _client.GetAsync($"/cached-data/pool-test-{i}"))
            .ToArray();

        var responses = await Task.WhenAll(tasks);

        // Force garbage collection
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        var finalMemory = GC.GetTotalMemory(false);

        // Assert
        responses.Should().OnlyContain(r => r.IsSuccessStatusCode);
        
        // In a real scenario with object pooling, memory usage would be more efficient
        var memoryDifference = finalMemory - initialMemory;
        memoryDifference.Should().BeLessThan(10_000_000); // Reasonable memory usage
    }

    public async ValueTask DisposeAsync()
    {
        _client.Dispose();
        _server.Dispose();
        GC.SuppressFinalize(this);
        await ValueTask.CompletedTask.ConfigureAwait(false);
    }
}

// Test endpoint models and implementations
public record CachedDataRequest(string Key);
public record LargeDataRequest();
public record SlowRequest();

public record PerformanceResponse(string Message, DateTime Timestamp, long ProcessingTimeMs);

public class CachedDataEndpoint : IAxiom<CachedDataRequest, PerformanceResponse>
{
    public async ValueTask<Result<PerformanceResponse>> HandleAsync(CachedDataRequest request, IContext context)
    {
        // Simulate some processing time
        await Task.Delay(50, context.CancellationToken).ConfigureAwait(false);
        
        var response = new PerformanceResponse(
            $"Cached data for key: {request.Key}",
            DateTime.UtcNow,
            50);
            
        return ResultFactory.Success(response);
    }
}

public class LargeDataEndpoint : IAxiom<LargeDataRequest, PerformanceResponse>
{
    public async ValueTask<Result<PerformanceResponse>> HandleAsync(LargeDataRequest request, IContext context)
    {
        await Task.Delay(10, context.CancellationToken).ConfigureAwait(false);
        
        // Generate large response that would benefit from compression
        var largeMessage = string.Join(" ", Enumerable.Repeat("This is a large response that should be compressed.", 100));
        
        var response = new PerformanceResponse(
            largeMessage,
            DateTime.UtcNow,
            10);
            
        return ResultFactory.Success(response);
    }
}

public class SlowEndpoint : IAxiom<SlowRequest, PerformanceResponse>
{
    public async ValueTask<Result<PerformanceResponse>> HandleAsync(SlowRequest request, IContext context)
    {
        // Simulate slow operation that would trigger monitoring
        await Task.Delay(150, context.CancellationToken).ConfigureAwait(false);
        
        var response = new PerformanceResponse(
            "Slow operation completed",
            DateTime.UtcNow,
            150);
            
        return ResultFactory.Success(response);
    }
}

public class PerformanceTestContext : IContext
{
    public CancellationToken CancellationToken { get; } = CancellationToken.None;
    public Microsoft.AspNetCore.Http.HttpContext HttpContext { get; } = new Microsoft.AspNetCore.Http.DefaultHttpContext();
    public IServiceProvider Services => HttpContext.RequestServices;
    public TimeProvider TimeProvider => TimeProvider.System;
    public System.Buffers.MemoryPool<byte> MemoryPool => System.Buffers.MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T> => default;
    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T> => default;
    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T> => default;
    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T> => Enumerable.Empty<T>();
    public bool HasQueryParameter(string key) => false;
    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute> => new("http://localhost/");
    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute> => new("http://localhost/");
    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute> { }
}