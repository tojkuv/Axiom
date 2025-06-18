using System.Diagnostics;

namespace AxiomEndpointsExample.Api;

/// <summary>
/// Custom performance monitoring middleware that demonstrates the features
/// that would be provided by the generated AxiomPerformanceMonitoringMiddleware
/// </summary>
public class PerformanceMonitoringMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceMonitoringMiddleware> _logger;
    private readonly IMetricsCollector _metricsCollector;
    private readonly int _slowRequestThreshold;

    public PerformanceMonitoringMiddleware(
        RequestDelegate next,
        ILogger<PerformanceMonitoringMiddleware> logger,
        IMetricsCollector metricsCollector,
        IConfiguration configuration)
    {
        _next = next;
        _logger = logger;
        _metricsCollector = metricsCollector;
        _slowRequestThreshold = configuration.GetValue<int>("Axiom:Performance:SlowRequestThresholdMs", 1000);
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var endpoint = context.GetEndpoint()?.DisplayName ?? context.Request.Path.ToString();
        var initialMemory = GC.GetTotalMemory(false);

        // Hook into OnStarting to add headers before response starts
        context.Response.OnStarting(() =>
        {
            // Only add headers if response hasn't started yet
            if (!context.Response.HasStarted)
            {
                try
                {
                    context.Response.Headers["X-Performance-Time"] = stopwatch.ElapsedMilliseconds.ToString();
                    var currentMemory = GC.GetTotalMemory(false);
                    var memoryUsed = currentMemory - initialMemory;
                    context.Response.Headers["X-Performance-Memory"] = memoryUsed.ToString();
                }
                catch
                {
                    // Ignore header setting errors
                }
            }
            return Task.CompletedTask;
        });

        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            var finalMemory = GC.GetTotalMemory(false);
            var memoryUsed = finalMemory - initialMemory;

            // Record metrics
            _metricsCollector.RecordRequestMetrics(
                endpoint,
                stopwatch.ElapsedMilliseconds,
                memoryUsed,
                context.Response.StatusCode);

            // Log slow requests
            if (stopwatch.ElapsedMilliseconds > _slowRequestThreshold)
            {
                _logger.LogWarning(
                    "Slow request detected: {Endpoint} took {ElapsedMs}ms (Memory: {MemoryUsed} bytes, Status: {StatusCode})",
                    endpoint,
                    stopwatch.ElapsedMilliseconds,
                    memoryUsed,
                    context.Response.StatusCode);
            }

            // Log memory pressure
            if (memoryUsed > 1_000_000) // > 1MB
            {
                _logger.LogWarning(
                    "High memory usage detected: {Endpoint} used {MemoryUsed:N0} bytes",
                    endpoint,
                    memoryUsed);
            }
        }
    }
}