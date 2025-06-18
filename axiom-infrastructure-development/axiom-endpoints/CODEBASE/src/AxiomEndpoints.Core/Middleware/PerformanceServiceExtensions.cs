using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Extension methods for registering performance monitoring services
/// </summary>
public static class PerformanceServiceExtensions
{
    /// <summary>
    /// Add Axiom performance monitoring services to the service collection
    /// </summary>
    public static IServiceCollection AddAxiomPerformanceMonitoring(
        this IServiceCollection services,
        Action<PerformanceMonitoringOptions>? configureOptions = null)
    {
        // Register metrics collector as singleton to persist metrics across requests
        services.TryAddSingleton<IMetricsCollector, MetricsCollector>();
        
        // Configure options if provided
        if (configureOptions != null)
        {
            services.Configure(configureOptions);
        }

        return services;
    }

    /// <summary>
    /// Add Axiom object pooling services to the service collection
    /// </summary>
    public static IServiceCollection AddAxiomObjectPooling(
        this IServiceCollection services,
        Action<ObjectPoolingOptions>? configureOptions = null)
    {
        // Configure options if provided
        if (configureOptions != null)
        {
            services.Configure(configureOptions);
        }

        return services;
    }

    /// <summary>
    /// Add comprehensive Axiom performance services
    /// </summary>
    public static IServiceCollection AddAxiomPerformance(
        this IServiceCollection services,
        Action<PerformanceConfiguration>? configure = null)
    {
        var config = new PerformanceConfiguration();
        configure?.Invoke(config);

        // Add performance monitoring
        if (config.EnablePerformanceMonitoring)
        {
            services.AddAxiomPerformanceMonitoring(options =>
            {
                options.EnablePerformanceMonitoring = config.EnablePerformanceMonitoring;
                options.EnableMemoryTracking = config.EnableMemoryTracking;
                options.SlowRequestThresholdMs = config.SlowRequestThresholdMs;
                options.AddPerformanceHeaders = config.AddPerformanceHeaders;
                options.HighMemoryThresholdBytes = config.HighMemoryThresholdBytes;
                options.EnableDetailedLogging = config.EnableDetailedLogging;
            });
        }

        // Add object pooling
        if (config.EnableObjectPooling)
        {
            services.AddAxiomObjectPooling(options =>
            {
                options.EnableObjectPooling = config.EnableObjectPooling;
                options.StringBuilderPoolMaxSize = config.StringBuilderPoolMaxSize;
                options.StringBuilderMaxCapacity = config.StringBuilderMaxCapacity;
                options.StringBuilderInitialCapacity = config.StringBuilderInitialCapacity;
                options.MemoryStreamPoolMaxSize = config.MemoryStreamPoolMaxSize;
                options.MemoryStreamMaxCapacity = config.MemoryStreamMaxCapacity;
            });
        }

        return services;
    }

    /// <summary>
    /// Use Axiom performance monitoring middleware
    /// </summary>
    public static IApplicationBuilder UseAxiomPerformanceMonitoring(this IApplicationBuilder app)
    {
        return app.UseMiddleware<PerformanceMonitoringMiddleware>();
    }

    /// <summary>
    /// Use all Axiom performance middleware
    /// </summary>
    public static IApplicationBuilder UseAxiomPerformance(this IApplicationBuilder app)
    {
        return app.UseAxiomPerformanceMonitoring();
    }
}

/// <summary>
/// Comprehensive configuration for Axiom performance features
/// </summary>
public class PerformanceConfiguration
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
    /// Whether object pooling is enabled
    /// </summary>
    public bool EnableObjectPooling { get; set; } = true;
    
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
    
    /// <summary>
    /// Maximum size for StringBuilder pool
    /// </summary>
    public int StringBuilderPoolMaxSize { get; set; } = 50;
    
    /// <summary>
    /// Maximum capacity for pooled StringBuilders (in characters)
    /// </summary>
    public int StringBuilderMaxCapacity { get; set; } = 32768; // 32KB
    
    /// <summary>
    /// Initial capacity for new StringBuilders
    /// </summary>
    public int StringBuilderInitialCapacity { get; set; } = 4096; // 4KB
    
    /// <summary>
    /// Maximum size for MemoryStream pool
    /// </summary>
    public int MemoryStreamPoolMaxSize { get; set; } = 25;
    
    /// <summary>
    /// Maximum capacity for pooled MemoryStreams (in bytes)
    /// </summary>
    public long MemoryStreamMaxCapacity { get; set; } = 1048576; // 1MB
}