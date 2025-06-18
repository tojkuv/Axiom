using System.Collections.Immutable;
using FluentAssertions;
using Xunit;
using AxiomEndpoints.SourceGenerators;

namespace AxiomEndpoints.SourceGenerators.Tests;

/// <summary>
/// Detailed tests for the PerformanceOptimizationGenerator
/// </summary>
public class PerformanceOptimizationGeneratorTests
{
    private readonly CompilationInfo _testCompilation = new()
    {
        AssemblyName = "TestAssembly",
        RootNamespace = "TestNamespace"
    };

    [Fact]
    public void Should_Generate_Cache_Service_Interface()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public interface IAxiomCacheService");
        result.Should().Contain("Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default);");
        result.Should().Contain("Task SetAsync<T>(string key, T value, TimeSpan? expiration = null, CancellationToken cancellationToken = default);");
        result.Should().Contain("Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, TimeSpan? expiration = null, CancellationToken cancellationToken = default);");
    }

    [Fact]
    public void Should_Generate_Memory_Cache_Implementation()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomMemoryCacheService : IAxiomCacheService");
        result.Should().Contain("private readonly IMemoryCache _memoryCache;");
        result.Should().Contain("private readonly ConcurrentDictionary<string, SemaphoreSlim> _locks = new();");
        result.Should().Contain("Cache hit for key: {Key}");
        result.Should().Contain("Cache miss for key: {Key}");
    }

    [Fact]
    public void Should_Generate_Cache_Options()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomCacheOptions");
        result.Should().Contain("public TimeSpan DefaultExpiration { get; set; } = TimeSpan.FromMinutes(15);");
        result.Should().Contain("public long SizeLimit { get; set; } = 100_000_000;");
        result.Should().Contain("public bool EnableCompaction { get; set; } = true;");
    }

    [Fact]
    public void Should_Generate_Compression_Middleware()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomCompressionMiddleware");
        result.Should().Contain("private bool ShouldCompress(HttpContext context)");
        result.Should().Contain("private string GetBestCompressionType(HttpContext context)");
        result.Should().Contain("acceptEncoding.Contains(\"br\", StringComparison.OrdinalIgnoreCase)");
        result.Should().Contain("acceptEncoding.Contains(\"gzip\", StringComparison.OrdinalIgnoreCase)");
    }

    [Fact]
    public void Should_Generate_Compression_Options()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomCompressionOptions");
        result.Should().Contain("public bool EnableGzip { get; set; } = true;");
        result.Should().Contain("public bool EnableBrotli { get; set; } = true;");
        result.Should().Contain("public CompressionLevel GzipLevel { get; set; } = CompressionLevel.Optimal;");
        result.Should().Contain("\"application/json\"");
        result.Should().Contain("\"text/html\"");
    }

    [Fact]
    public void Should_Generate_Object_Pool_Interface()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public interface IAxiomObjectPool<T> where T : class");
        result.Should().Contain("T Get();");
        result.Should().Contain("void Return(T item);");
        result.Should().Contain("int Count { get; }");
        result.Should().Contain("int CountActive { get; }");
    }

    [Fact]
    public void Should_Generate_Object_Pool_Implementation()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomObjectPool<T> : IAxiomObjectPool<T> where T : class");
        result.Should().Contain("private readonly ConcurrentQueue<T> _objects = new();");
        result.Should().Contain("private readonly Func<T> _objectFactory;");
        result.Should().Contain("private readonly Action<T>? _resetAction;");
        result.Should().Contain("Interlocked.Decrement(ref _count);");
        result.Should().Contain("Interlocked.Increment(ref _countActive);");
    }

    [Fact]
    public void Should_Generate_StringBuilder_Pool()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public static class AxiomStringBuilderPool");
        result.Should().Contain("new StringBuilder(1024)");
        result.Should().Contain("sb => sb.Clear()");
        result.Should().Contain("public static string GetStringAndReturn(StringBuilder sb)");
    }

    [Fact]
    public void Should_Generate_MemoryStream_Pool()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public static class AxiomMemoryStreamPool");
        result.Should().Contain("new MemoryStream()");
        result.Should().Contain("ms => { ms.Position = 0; ms.SetLength(0); }");
    }

    [Fact]
    public void Should_Generate_Performance_Monitoring_Middleware()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomPerformanceMonitoringMiddleware");
        result.Should().Contain("var stopwatch = System.Diagnostics.Stopwatch.StartNew();");
        result.Should().Contain("var initialMemory = GC.GetTotalMemory(false);");
        result.Should().Contain("Slow request detected: {Endpoint} took {ElapsedMs}ms");
        result.Should().Contain("private static readonly ConcurrentDictionary<string, AxiomEndpointMetrics> EndpointMetrics = new();");
    }

    [Fact]
    public void Should_Generate_Endpoint_Metrics_Class()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomEndpointMetrics");
        result.Should().Contain("public double AverageResponseTimeMs => _totalRequests > 0 ? (double)_totalResponseTimeMs / _totalRequests : 0;");
        result.Should().Contain("public double ErrorRate => _totalRequests > 0 ? (double)_errorCount / _totalRequests : 0;");
        result.Should().Contain("public void RecordRequest(long responseTimeMs, long memoryUsed, int statusCode)");
        result.Should().Contain("if (statusCode >= 400)");
    }

    [Fact]
    public void Should_Generate_Performance_Options()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomPerformanceOptions");
        result.Should().Contain("public bool EnablePerformanceMonitoring { get; set; } = true;");
        result.Should().Contain("public int SlowRequestThresholdMs { get; set; } = 1000;");
        result.Should().Contain("public TimeSpan MetricsRetentionPeriod { get; set; } = TimeSpan.FromHours(24);");
    }

    [Fact]
    public void Should_Generate_Performance_Extensions()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public static class AxiomPerformanceExtensions");
        result.Should().Contain("public static IServiceCollection AddAxiomPerformance(");
        result.Should().Contain("public static IApplicationBuilder UseAxiomPerformance(this IApplicationBuilder app)");
        result.Should().Contain("public static async Task<Result<T>> WithCaching<T>(");
    }

    [Fact]
    public void Should_Generate_Performance_Configuration()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("public class AxiomPerformanceConfiguration");
        result.Should().Contain("public bool EnableCaching { get; set; } = true;");
        result.Should().Contain("public bool EnableCompression { get; set; } = true;");
        result.Should().Contain("public bool EnablePerformanceMonitoring { get; set; } = true;");
        result.Should().Contain("public AxiomCacheOptions Cache { get; set; } = new();");
        result.Should().Contain("public AxiomCompressionOptions Compression { get; set; } = new();");
    }

    [Fact]
    public void Should_Include_Required_Namespace()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("namespace TestNamespace.Generated.Performance;");
        result.Should().Contain("using System.Collections.Concurrent;");
        result.Should().Contain("using System.IO.Compression;");
        result.Should().Contain("using Microsoft.Extensions.Caching.Memory;");
        result.Should().Contain("using Microsoft.AspNetCore.ResponseCompression;");
    }

    [Fact]
    public void Should_Include_Proper_GeneratedCode_Attributes()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        result.Should().Contain("// <auto-generated/>");
        result.Should().Contain("#nullable enable");
    }

    [Fact]
    public void Should_Generate_Caching_Extension_Method()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("WithCaching<T>");
        result.Should().Contain("var cachedResult = await cacheService.GetAsync<T>(cacheKey, cancellationToken);");
        result.Should().Contain("if (cachedResult != null)");
        result.Should().Contain("if (result.IsSuccess)");
        result.Should().Contain("await cacheService.SetAsync(cacheKey, result.Value, expiration, cancellationToken);");
    }

    [Fact]
    public void Should_Handle_Different_Compression_Types()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("\"br\" => new BrotliStream(outputStream, _options.BrotliLevel)");
        result.Should().Contain("\"gzip\" => new GZipStream(outputStream, _options.GzipLevel)");
        result.Should().Contain("\"deflate\" => new DeflateStream(outputStream, _options.DeflateLevel)");
    }

    [Fact]
    public void Should_Include_Thread_Safety_Mechanisms()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;

        // Act
        var result = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, _testCompilation);

        // Assert
        result.Should().Contain("ConcurrentDictionary");
        result.Should().Contain("SemaphoreSlim");
        result.Should().Contain("Interlocked.Increment");
        result.Should().Contain("Interlocked.Decrement");
        result.Should().Contain("lock (_lock)");
    }
}