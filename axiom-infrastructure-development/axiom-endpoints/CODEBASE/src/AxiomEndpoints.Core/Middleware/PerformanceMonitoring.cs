using System.Collections.Concurrent;
using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Interface for collecting performance metrics from endpoint requests
/// </summary>
public interface IMetricsCollector
{
    /// <summary>
    /// Record performance metrics for a request
    /// </summary>
    void RecordRequestMetrics(string endpoint, long responseTimeMs, long memoryUsed, int statusCode);
    
    /// <summary>
    /// Get metrics for a specific endpoint
    /// </summary>
    EndpointMetrics GetMetrics(string endpoint);
    
    /// <summary>
    /// Get all collected metrics
    /// </summary>
    Dictionary<string, EndpointMetrics> GetAllMetrics();
    
    /// <summary>
    /// Clear all collected metrics
    /// </summary>
    void ClearMetrics();
}

/// <summary>
/// Thread-safe implementation of metrics collector
/// </summary>
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

/// <summary>
/// Performance metrics for an endpoint
/// </summary>
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
/// Configuration options for performance monitoring
/// </summary>
public class PerformanceMonitoringOptions
{
    /// <summary>
    /// Whether performance monitoring is enabled
    /// </summary>
    public bool EnablePerformanceMonitoring { get; set; } = true;
    
    /// <summary>
    /// Whether to track memory usage
    /// </summary>
    public bool EnableMemoryTracking { get; set; } = true;
    
    /// <summary>
    /// Threshold in milliseconds for slow request detection
    /// </summary>
    public int SlowRequestThresholdMs { get; set; } = 1000;
    
    /// <summary>
    /// Whether to add performance headers to responses
    /// </summary>
    public bool AddPerformanceHeaders { get; set; } = true;
    
    /// <summary>
    /// Threshold in bytes for high memory usage warnings
    /// </summary>
    public long HighMemoryThresholdBytes { get; set; } = 1_000_000; // 1MB
    
    /// <summary>
    /// Whether to enable detailed logging
    /// </summary>
    public bool EnableDetailedLogging { get; set; } = false;
}

/// <summary>
/// Performance monitoring middleware for Axiom endpoints
/// </summary>
public class PerformanceMonitoringMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceMonitoringMiddleware> _logger;
    private readonly IMetricsCollector _metricsCollector;
    private readonly PerformanceMonitoringOptions _options;

    public PerformanceMonitoringMiddleware(
        RequestDelegate next,
        ILogger<PerformanceMonitoringMiddleware> logger,
        IMetricsCollector metricsCollector,
        IConfiguration configuration)
    {
        _next = next;
        _logger = logger;
        _metricsCollector = metricsCollector;
        _options = new PerformanceMonitoringOptions
        {
            EnablePerformanceMonitoring = configuration.GetValue<bool>("Axiom:Performance:EnablePerformanceMonitoring", true),
            EnableMemoryTracking = configuration.GetValue<bool>("Axiom:Performance:EnableMemoryTracking", true),
            SlowRequestThresholdMs = configuration.GetValue<int>("Axiom:Performance:SlowRequestThresholdMs", 1000),
            AddPerformanceHeaders = configuration.GetValue<bool>("Axiom:Performance:AddPerformanceHeaders", true),
            HighMemoryThresholdBytes = configuration.GetValue<long>("Axiom:Performance:HighMemoryThresholdBytes", 1_000_000),
            EnableDetailedLogging = configuration.GetValue<bool>("Axiom:Performance:EnableDetailedLogging", false)
        };
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (!_options.EnablePerformanceMonitoring)
        {
            await _next(context);
            return;
        }

        var stopwatch = Stopwatch.StartNew();
        var endpoint = context.GetEndpoint()?.DisplayName ?? context.Request.Path.ToString();
        var initialMemory = _options.EnableMemoryTracking ? GC.GetTotalMemory(false) : 0;

        // Hook into OnStarting to add headers before response starts
        if (_options.AddPerformanceHeaders)
        {
            context.Response.OnStarting(() =>
            {
                if (!context.Response.HasStarted)
                {
                    try
                    {
                        context.Response.Headers["X-Performance-Time"] = stopwatch.ElapsedMilliseconds.ToString();
                        if (_options.EnableMemoryTracking)
                        {
                            var currentMemory = GC.GetTotalMemory(false);
                            var memoryUsed = currentMemory - initialMemory;
                            context.Response.Headers["X-Performance-Memory"] = memoryUsed.ToString();
                        }
                    }
                    catch
                    {
                        // Ignore header setting errors
                    }
                }
                return Task.CompletedTask;
            });
        }

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            var finalMemory = _options.EnableMemoryTracking ? GC.GetTotalMemory(false) : 0;
            var memoryUsed = _options.EnableMemoryTracking ? finalMemory - initialMemory : 0;

            // Record metrics
            _metricsCollector.RecordRequestMetrics(
                endpoint,
                stopwatch.ElapsedMilliseconds,
                memoryUsed,
                context.Response.StatusCode);

            // Log slow requests
            if (stopwatch.ElapsedMilliseconds > _options.SlowRequestThresholdMs)
            {
                if (_options.EnableDetailedLogging)
                {
                    _logger.LogWarning(
                        "Slow request detected: {Endpoint} took {ElapsedMs}ms (Memory: {MemoryUsed} bytes, Status: {StatusCode})",
                        endpoint,
                        stopwatch.ElapsedMilliseconds,
                        memoryUsed,
                        context.Response.StatusCode);
                }
                else
                {
                    _logger.LogWarning(
                        "Slow request: {Endpoint} took {ElapsedMs}ms",
                        endpoint,
                        stopwatch.ElapsedMilliseconds);
                }
            }

            // Log high memory usage
            if (_options.EnableMemoryTracking && memoryUsed > _options.HighMemoryThresholdBytes)
            {
                _logger.LogWarning(
                    "High memory usage: {Endpoint} used {MemoryUsed:N0} bytes",
                    endpoint,
                    memoryUsed);
            }

            // Detailed logging for all requests if enabled
            if (_options.EnableDetailedLogging)
            {
                _logger.LogDebug(
                    "Request completed: {Method} {Path} -> {StatusCode} in {ElapsedMs}ms (Memory: {MemoryUsed} bytes)",
                    context.Request.Method,
                    context.Request.Path,
                    context.Response.StatusCode,
                    stopwatch.ElapsedMilliseconds,
                    memoryUsed);
            }
        }
    }
}