using System;
using System.Collections.Immutable;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;

namespace AxiomEndpoints.SourceGenerators;

public static class PerformanceOptimizationGenerator
{
    public static string GeneratePerformanceOptimizations(
        ImmutableArray<EndpointInfo> endpoints,
        CompilationInfo compilation)
    {
        var sb = new StringBuilder();

        sb.AppendLine("// <auto-generated/>");
        sb.AppendLine("#nullable enable");
        sb.AppendLine();
        sb.AppendLine("using System;");
        sb.AppendLine("using System.Collections.Concurrent;");
        sb.AppendLine("using System.Collections.Generic;");
        sb.AppendLine("using System.IO;");
        sb.AppendLine("using System.IO.Compression;");
        sb.AppendLine("using System.Text;");
        sb.AppendLine("using System.Threading;");
        sb.AppendLine("using System.Threading.Tasks;");
        sb.AppendLine("using Microsoft.AspNetCore.Builder;");
        sb.AppendLine("using Microsoft.AspNetCore.Http;");
        sb.AppendLine("using Microsoft.AspNetCore.ResponseCompression;");
        sb.AppendLine("using Microsoft.Extensions.Caching.Memory;");
        sb.AppendLine("using Microsoft.Extensions.DependencyInjection;");
        sb.AppendLine("using Microsoft.Extensions.Logging;");
        sb.AppendLine("using Microsoft.Extensions.Options;");
        sb.AppendLine("using AxiomEndpoints.Core;");
        sb.AppendLine();
        sb.AppendLine($"namespace {compilation.RootNamespace}.Generated.Performance;");
        sb.AppendLine();

        // Generate caching infrastructure
        GenerateCachingInfrastructure(sb);

        // Generate compression infrastructure
        GenerateCompressionInfrastructure(sb);

        // Generate object pooling infrastructure
        GenerateObjectPoolingInfrastructure(sb);

        // Generate performance monitoring
        GeneratePerformanceMonitoring(sb, endpoints);

        // Generate configuration and extensions
        GeneratePerformanceExtensions(sb, compilation);

        return sb.ToString();
    }

    private static void GenerateCachingInfrastructure(StringBuilder sb)
    {
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Advanced caching service for Axiom endpoints");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public interface IAxiomCacheService");
        sb.AppendLine("{");
        sb.AppendLine("    Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default);");
        sb.AppendLine("    Task SetAsync<T>(string key, T value, TimeSpan? expiration = null, CancellationToken cancellationToken = default);");
        sb.AppendLine("    Task RemoveAsync(string key, CancellationToken cancellationToken = default);");
        sb.AppendLine("    Task RemoveByPatternAsync(string pattern, CancellationToken cancellationToken = default);");
        sb.AppendLine("    Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default);");
        sb.AppendLine("    Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, TimeSpan? expiration = null, CancellationToken cancellationToken = default);");
        sb.AppendLine("}");
        sb.AppendLine();

        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// High-performance in-memory cache implementation");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomMemoryCacheService : IAxiomCacheService");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly IMemoryCache _memoryCache;");
        sb.AppendLine("    private readonly ILogger<AxiomMemoryCacheService> _logger;");
        sb.AppendLine("    private readonly AxiomCacheOptions _options;");
        sb.AppendLine("    private readonly ConcurrentDictionary<string, SemaphoreSlim> _locks = new();");
        sb.AppendLine();
        sb.AppendLine("    public AxiomMemoryCacheService(");
        sb.AppendLine("        IMemoryCache memoryCache,");
        sb.AppendLine("        ILogger<AxiomMemoryCacheService> logger,");
        sb.AppendLine("        IOptions<AxiomCacheOptions> options)");
        sb.AppendLine("    {");
        sb.AppendLine("        _memoryCache = memoryCache;");
        sb.AppendLine("        _logger = logger;");
        sb.AppendLine("        _options = options.Value;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        await Task.CompletedTask;");
        sb.AppendLine("        if (_memoryCache.TryGetValue(key, out var value) && value is T typedValue)");
        sb.AppendLine("        {");
        sb.AppendLine("            _logger.LogDebug(\"Cache hit for key: {Key}\", key);");
        sb.AppendLine("            return typedValue;");
        sb.AppendLine("        }");
        sb.AppendLine("        _logger.LogDebug(\"Cache miss for key: {Key}\", key);");
        sb.AppendLine("        return default;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task SetAsync<T>(string key, T value, TimeSpan? expiration = null, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        await Task.CompletedTask;");
        sb.AppendLine("        var options = new MemoryCacheEntryOptions");
        sb.AppendLine("        {");
        sb.AppendLine("            AbsoluteExpirationRelativeToNow = expiration ?? _options.DefaultExpiration,");
        sb.AppendLine("            Priority = CacheItemPriority.Normal,");
        sb.AppendLine("            Size = CalculateSize(value)");
        sb.AppendLine("        };");
        sb.AppendLine();
        sb.AppendLine("        _memoryCache.Set(key, value, options);");
        sb.AppendLine("        _logger.LogDebug(\"Cached value for key: {Key}, Expiration: {Expiration}\", key, options.AbsoluteExpirationRelativeToNow);");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task RemoveAsync(string key, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        await Task.CompletedTask;");
        sb.AppendLine("        _memoryCache.Remove(key);");
        sb.AppendLine("        _logger.LogDebug(\"Removed cache entry for key: {Key}\", key);");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task RemoveByPatternAsync(string pattern, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        await Task.CompletedTask;");
        sb.AppendLine("        // Note: IMemoryCache doesn't support pattern removal, this would require custom implementation");
        sb.AppendLine("        _logger.LogWarning(\"Pattern-based cache removal not supported in memory cache: {Pattern}\", pattern);");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        await Task.CompletedTask;");
        sb.AppendLine("        return _memoryCache.TryGetValue(key, out _);");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, TimeSpan? expiration = null, CancellationToken cancellationToken = default)");
        sb.AppendLine("    {");
        sb.AppendLine("        if (_memoryCache.TryGetValue(key, out var existingValue) && existingValue is T cachedValue)");
        sb.AppendLine("        {");
        sb.AppendLine("            return cachedValue;");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        var lockKey = $\"lock:{key}\";");
        sb.AppendLine("        var semaphore = _locks.GetOrAdd(lockKey, _ => new SemaphoreSlim(1, 1));");
        sb.AppendLine();
        sb.AppendLine("        await semaphore.WaitAsync(cancellationToken);");
        sb.AppendLine("        try");
        sb.AppendLine("        {");
        sb.AppendLine("            // Double-check after acquiring lock");
        sb.AppendLine("            if (_memoryCache.TryGetValue(key, out existingValue) && existingValue is T doubleCheckValue)");
        sb.AppendLine("            {");
        sb.AppendLine("                return doubleCheckValue;");
        sb.AppendLine("            }");
        sb.AppendLine();
        sb.AppendLine("            var newValue = await factory();");
        sb.AppendLine("            await SetAsync(key, newValue, expiration, cancellationToken);");
        sb.AppendLine("            return newValue;");
        sb.AppendLine("        }");
        sb.AppendLine("        finally");
        sb.AppendLine("        {");
        sb.AppendLine("            semaphore.Release();");
        sb.AppendLine("        }");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    private static long CalculateSize<T>(T value)");
        sb.AppendLine("    {");
        sb.AppendLine("        return value switch");
        sb.AppendLine("        {");
        sb.AppendLine("            string s => s.Length * sizeof(char),");
        sb.AppendLine("            byte[] bytes => bytes.Length,");
        sb.AppendLine("            _ => 1 // Default size for other types");
        sb.AppendLine("        };");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate cache options
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Configuration options for Axiom caching");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomCacheOptions");
        sb.AppendLine("{");
        sb.AppendLine("    public TimeSpan DefaultExpiration { get; set; } = TimeSpan.FromMinutes(15);");
        sb.AppendLine("    public long SizeLimit { get; set; } = 100_000_000; // 100MB");
        sb.AppendLine("    public bool EnableCompaction { get; set; } = true;");
        sb.AppendLine("    public double CompactionPercentage { get; set; } = 0.25;");
        sb.AppendLine("    public bool EnableMetrics { get; set; } = true;");
        sb.AppendLine("    public string KeyPrefix { get; set; } = \"axiom:\";");
        sb.AppendLine("}");
        sb.AppendLine();
    }

    private static void GenerateCompressionInfrastructure(StringBuilder sb)
    {
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Advanced compression middleware for Axiom endpoints");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomCompressionMiddleware");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly RequestDelegate _next;");
        sb.AppendLine("    private readonly ILogger<AxiomCompressionMiddleware> _logger;");
        sb.AppendLine("    private readonly AxiomCompressionOptions _options;");
        sb.AppendLine();
        sb.AppendLine("    public AxiomCompressionMiddleware(");
        sb.AppendLine("        RequestDelegate next,");
        sb.AppendLine("        ILogger<AxiomCompressionMiddleware> logger,");
        sb.AppendLine("        IOptions<AxiomCompressionOptions> options)");
        sb.AppendLine("    {");
        sb.AppendLine("        _next = next;");
        sb.AppendLine("        _logger = logger;");
        sb.AppendLine("        _options = options.Value;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task InvokeAsync(HttpContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        if (!ShouldCompress(context))");
        sb.AppendLine("        {");
        sb.AppendLine("            await _next(context);");
        sb.AppendLine("            return;");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        var originalBodyStream = context.Response.Body;");
        sb.AppendLine("        var compressionType = GetBestCompressionType(context);");
        sb.AppendLine();
        sb.AppendLine("        using var compressionStream = CreateCompressionStream(originalBodyStream, compressionType);");
        sb.AppendLine("        context.Response.Body = compressionStream;");
        sb.AppendLine("        context.Response.Headers[\"Content-Encoding\"] = compressionType;");
        sb.AppendLine("        context.Response.Headers.Remove(\"Content-Length\");");
        sb.AppendLine();
        sb.AppendLine("        try");
        sb.AppendLine("        {");
        sb.AppendLine("            await _next(context);");
        sb.AppendLine("        }");
        sb.AppendLine("        finally");
        sb.AppendLine("        {");
        sb.AppendLine("            context.Response.Body = originalBodyStream;");
        sb.AppendLine("        }");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    private bool ShouldCompress(HttpContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        if (!_options.EnableCompression) return false;");
        sb.AppendLine("        if (context.Response.Headers.ContainsKey(\"Content-Encoding\")) return false;");
        sb.AppendLine("        if (context.Response.StatusCode < 200 || context.Response.StatusCode >= 300) return false;");
        sb.AppendLine();
        sb.AppendLine("        var contentType = context.Response.ContentType;");
        sb.AppendLine("        if (string.IsNullOrEmpty(contentType)) return false;");
        sb.AppendLine();
        sb.AppendLine("        return _options.CompressibleMimeTypes.Any(mimeType => ");
        sb.AppendLine("            contentType.StartsWith(mimeType, StringComparison.OrdinalIgnoreCase));");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    private string GetBestCompressionType(HttpContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        var acceptEncoding = context.Request.Headers[\"Accept-Encoding\"].ToString();");
        sb.AppendLine();
        sb.AppendLine("        if (acceptEncoding.Contains(\"br\", StringComparison.OrdinalIgnoreCase) && _options.EnableBrotli)");
        sb.AppendLine("            return \"br\";");
        sb.AppendLine("        if (acceptEncoding.Contains(\"gzip\", StringComparison.OrdinalIgnoreCase) && _options.EnableGzip)");
        sb.AppendLine("            return \"gzip\";");
        sb.AppendLine("        if (acceptEncoding.Contains(\"deflate\", StringComparison.OrdinalIgnoreCase) && _options.EnableDeflate)");
        sb.AppendLine("            return \"deflate\";");
        sb.AppendLine();
        sb.AppendLine("        return \"gzip\"; // Default fallback");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    private Stream CreateCompressionStream(Stream outputStream, string compressionType)");
        sb.AppendLine("    {");
        sb.AppendLine("        return compressionType switch");
        sb.AppendLine("        {");
        sb.AppendLine("            \"br\" => new BrotliStream(outputStream, _options.BrotliLevel),");
        sb.AppendLine("            \"gzip\" => new GZipStream(outputStream, _options.GzipLevel),");
        sb.AppendLine("            \"deflate\" => new DeflateStream(outputStream, _options.DeflateLevel),");
        sb.AppendLine("            _ => new GZipStream(outputStream, _options.GzipLevel)");
        sb.AppendLine("        };");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate compression options
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Configuration options for Axiom compression");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomCompressionOptions");
        sb.AppendLine("{");
        sb.AppendLine("    public bool EnableCompression { get; set; } = true;");
        sb.AppendLine("    public bool EnableGzip { get; set; } = true;");
        sb.AppendLine("    public bool EnableBrotli { get; set; } = true;");
        sb.AppendLine("    public bool EnableDeflate { get; set; } = true;");
        sb.AppendLine("    public CompressionLevel GzipLevel { get; set; } = CompressionLevel.Optimal;");
        sb.AppendLine("    public CompressionLevel BrotliLevel { get; set; } = CompressionLevel.Optimal;");
        sb.AppendLine("    public CompressionLevel DeflateLevel { get; set; } = CompressionLevel.Optimal;");
        sb.AppendLine("    public int MinimumSizeToCompress { get; set; } = 1024; // 1KB");
        sb.AppendLine("    public string[] CompressibleMimeTypes { get; set; } = new[]");
        sb.AppendLine("    {");
        sb.AppendLine("        \"application/json\",");
        sb.AppendLine("        \"application/xml\",");
        sb.AppendLine("        \"text/plain\",");
        sb.AppendLine("        \"text/html\",");
        sb.AppendLine("        \"text/css\",");
        sb.AppendLine("        \"text/javascript\",");
        sb.AppendLine("        \"application/javascript\"");
        sb.AppendLine("    };");
        sb.AppendLine("}");
        sb.AppendLine();
    }

    private static void GenerateObjectPoolingInfrastructure(StringBuilder sb)
    {
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// High-performance object pool for frequently allocated objects");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public interface IAxiomObjectPool<T> where T : class");
        sb.AppendLine("{");
        sb.AppendLine("    T Get();");
        sb.AppendLine("    void Return(T item);");
        sb.AppendLine("    int Count { get; }");
        sb.AppendLine("    int CountActive { get; }");
        sb.AppendLine("}");
        sb.AppendLine();

        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Thread-safe object pool implementation");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomObjectPool<T> : IAxiomObjectPool<T> where T : class");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly ConcurrentQueue<T> _objects = new();");
        sb.AppendLine("    private readonly Func<T> _objectFactory;");
        sb.AppendLine("    private readonly Action<T>? _resetAction;");
        sb.AppendLine("    private readonly int _maxSize;");
        sb.AppendLine("    private int _count;");
        sb.AppendLine("    private int _countActive;");
        sb.AppendLine();
        sb.AppendLine("    public AxiomObjectPool(Func<T> objectFactory, Action<T>? resetAction = null, int maxSize = 100)");
        sb.AppendLine("    {");
        sb.AppendLine("        _objectFactory = objectFactory;");
        sb.AppendLine("        _resetAction = resetAction;");
        sb.AppendLine("        _maxSize = maxSize;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public int Count => _count;");
        sb.AppendLine("    public int CountActive => _countActive;");
        sb.AppendLine();
        sb.AppendLine("    public T Get()");
        sb.AppendLine("    {");
        sb.AppendLine("        if (_objects.TryDequeue(out var item))");
        sb.AppendLine("        {");
        sb.AppendLine("            Interlocked.Decrement(ref _count);");
        sb.AppendLine("            Interlocked.Increment(ref _countActive);");
        sb.AppendLine("            return item;");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        Interlocked.Increment(ref _countActive);");
        sb.AppendLine("        return _objectFactory();");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public void Return(T item)");
        sb.AppendLine("    {");
        sb.AppendLine("        if (item == null) return;");
        sb.AppendLine();
        sb.AppendLine("        _resetAction?.Invoke(item);");
        sb.AppendLine();
        sb.AppendLine("        if (_count < _maxSize)");
        sb.AppendLine("        {");
        sb.AppendLine("            _objects.Enqueue(item);");
        sb.AppendLine("            Interlocked.Increment(ref _count);");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        Interlocked.Decrement(ref _countActive);");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate pooled objects for common scenarios
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Pooled StringBuilder for reducing allocations");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public static class AxiomStringBuilderPool");
        sb.AppendLine("{");
        sb.AppendLine("    private static readonly AxiomObjectPool<StringBuilder> Pool = new(");
        sb.AppendLine("        () => new StringBuilder(1024),");
        sb.AppendLine("        sb => sb.Clear(),");
        sb.AppendLine("        50);");
        sb.AppendLine();
        sb.AppendLine("    public static StringBuilder Get() => Pool.Get();");
        sb.AppendLine("    public static void Return(StringBuilder sb) => Pool.Return(sb);");
        sb.AppendLine("    public static string GetStringAndReturn(StringBuilder sb)");
        sb.AppendLine("    {");
        sb.AppendLine("        var result = sb.ToString();");
        sb.AppendLine("        Return(sb);");
        sb.AppendLine("        return result;");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Pooled MemoryStream for reducing allocations");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public static class AxiomMemoryStreamPool");
        sb.AppendLine("{");
        sb.AppendLine("    private static readonly AxiomObjectPool<MemoryStream> Pool = new(");
        sb.AppendLine("        () => new MemoryStream(),");
        sb.AppendLine("        ms => { ms.Position = 0; ms.SetLength(0); },");
        sb.AppendLine("        25);");
        sb.AppendLine();
        sb.AppendLine("    public static MemoryStream Get() => Pool.Get();");
        sb.AppendLine("    public static void Return(MemoryStream ms) => Pool.Return(ms);");
        sb.AppendLine("}");
        sb.AppendLine();
    }

    private static void GeneratePerformanceMonitoring(StringBuilder sb, ImmutableArray<EndpointInfo> endpoints)
    {
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Performance monitoring and metrics collection for Axiom endpoints");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomPerformanceMonitoringMiddleware");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly RequestDelegate _next;");
        sb.AppendLine("    private readonly ILogger<AxiomPerformanceMonitoringMiddleware> _logger;");
        sb.AppendLine("    private readonly AxiomPerformanceOptions _options;");
        sb.AppendLine("    private static readonly ConcurrentDictionary<string, AxiomEndpointMetrics> EndpointMetrics = new();");
        sb.AppendLine();
        sb.AppendLine("    public AxiomPerformanceMonitoringMiddleware(");
        sb.AppendLine("        RequestDelegate next,");
        sb.AppendLine("        ILogger<AxiomPerformanceMonitoringMiddleware> logger,");
        sb.AppendLine("        IOptions<AxiomPerformanceOptions> options)");
        sb.AppendLine("    {");
        sb.AppendLine("        _next = next;");
        sb.AppendLine("        _logger = logger;");
        sb.AppendLine("        _options = options.Value;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public async Task InvokeAsync(HttpContext context)");
        sb.AppendLine("    {");
        sb.AppendLine("        if (!_options.EnablePerformanceMonitoring)");
        sb.AppendLine("        {");
        sb.AppendLine("            await _next(context);");
        sb.AppendLine("            return;");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        var stopwatch = System.Diagnostics.Stopwatch.StartNew();");
        sb.AppendLine("        var endpoint = context.GetEndpoint()?.DisplayName ?? \"Unknown\";");
        sb.AppendLine("        var initialMemory = GC.GetTotalMemory(false);");
        sb.AppendLine();
        sb.AppendLine("        try");
        sb.AppendLine("        {");
        sb.AppendLine("            await _next(context);");
        sb.AppendLine("        }");
        sb.AppendLine("        finally");
        sb.AppendLine("        {");
        sb.AppendLine("            stopwatch.Stop();");
        sb.AppendLine("            var finalMemory = GC.GetTotalMemory(false);");
        sb.AppendLine("            var memoryUsed = finalMemory - initialMemory;");
        sb.AppendLine();
        sb.AppendLine("            RecordMetrics(endpoint, stopwatch.ElapsedMilliseconds, memoryUsed, context.Response.StatusCode);");
        sb.AppendLine();
        sb.AppendLine("            if (stopwatch.ElapsedMilliseconds > _options.SlowRequestThresholdMs)");
        sb.AppendLine("            {");
        sb.AppendLine("                _logger.LogWarning(\"Slow request detected: {Endpoint} took {ElapsedMs}ms\", endpoint, stopwatch.ElapsedMilliseconds);");
        sb.AppendLine("            }");
        sb.AppendLine("        }");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    private static void RecordMetrics(string endpoint, long elapsedMs, long memoryUsed, int statusCode)");
        sb.AppendLine("    {");
        sb.AppendLine("        var metrics = EndpointMetrics.GetOrAdd(endpoint, _ => new AxiomEndpointMetrics());");
        sb.AppendLine("        metrics.RecordRequest(elapsedMs, memoryUsed, statusCode);");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    public static Dictionary<string, AxiomEndpointMetrics> GetAllMetrics()");
        sb.AppendLine("    {");
        sb.AppendLine("        return new Dictionary<string, AxiomEndpointMetrics>(EndpointMetrics);");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate metrics model
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Performance metrics for an endpoint");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomEndpointMetrics");
        sb.AppendLine("{");
        sb.AppendLine("    private readonly object _lock = new();");
        sb.AppendLine("    private long _totalRequests;");
        sb.AppendLine("    private long _totalResponseTimeMs;");
        sb.AppendLine("    private long _totalMemoryUsed;");
        sb.AppendLine("    private long _errorCount;");
        sb.AppendLine("    private long _minResponseTimeMs = long.MaxValue;");
        sb.AppendLine("    private long _maxResponseTimeMs;");
        sb.AppendLine();
        sb.AppendLine("    public long TotalRequests => _totalRequests;");
        sb.AppendLine("    public double AverageResponseTimeMs => _totalRequests > 0 ? (double)_totalResponseTimeMs / _totalRequests : 0;");
        sb.AppendLine("    public long MinResponseTimeMs => _minResponseTimeMs == long.MaxValue ? 0 : _minResponseTimeMs;");
        sb.AppendLine("    public long MaxResponseTimeMs => _maxResponseTimeMs;");
        sb.AppendLine("    public double ErrorRate => _totalRequests > 0 ? (double)_errorCount / _totalRequests : 0;");
        sb.AppendLine("    public long TotalMemoryUsed => _totalMemoryUsed;");
        sb.AppendLine("    public double AverageMemoryPerRequest => _totalRequests > 0 ? (double)_totalMemoryUsed / _totalRequests : 0;");
        sb.AppendLine();
        sb.AppendLine("    public void RecordRequest(long responseTimeMs, long memoryUsed, int statusCode)");
        sb.AppendLine("    {");
        sb.AppendLine("        lock (_lock)");
        sb.AppendLine("        {");
        sb.AppendLine("            _totalRequests++;");
        sb.AppendLine("            _totalResponseTimeMs += responseTimeMs;");
        sb.AppendLine("            _totalMemoryUsed += memoryUsed;");
        sb.AppendLine();
        sb.AppendLine("            if (responseTimeMs < _minResponseTimeMs)");
        sb.AppendLine("                _minResponseTimeMs = responseTimeMs;");
        sb.AppendLine("            if (responseTimeMs > _maxResponseTimeMs)");
        sb.AppendLine("                _maxResponseTimeMs = responseTimeMs;");
        sb.AppendLine();
        sb.AppendLine("            if (statusCode >= 400)");
        sb.AppendLine("                _errorCount++;");
        sb.AppendLine("        }");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate performance options
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Configuration options for Axiom performance monitoring");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomPerformanceOptions");
        sb.AppendLine("{");
        sb.AppendLine("    public bool EnablePerformanceMonitoring { get; set; } = true;");
        sb.AppendLine("    public bool EnableMemoryTracking { get; set; } = true;");
        sb.AppendLine("    public int SlowRequestThresholdMs { get; set; } = 1000;");
        sb.AppendLine("    public bool EnableDetailedLogging { get; set; } = false;");
        sb.AppendLine("    public TimeSpan MetricsRetentionPeriod { get; set; } = TimeSpan.FromHours(24);");
        sb.AppendLine("    public int MaxMetricsEntries { get; set; } = 10000;");
        sb.AppendLine("}");
        sb.AppendLine();
    }

    private static void GeneratePerformanceExtensions(StringBuilder sb, CompilationInfo compilation)
    {
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Extension methods for configuring Axiom performance optimizations");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public static class AxiomPerformanceExtensions");
        sb.AppendLine("{");
        sb.AppendLine("    /// <summary>");
        sb.AppendLine("    /// Add Axiom performance optimization services");
        sb.AppendLine("    /// </summary>");
        sb.AppendLine("    public static IServiceCollection AddAxiomPerformance(");
        sb.AppendLine("        this IServiceCollection services,");
        sb.AppendLine("        Action<AxiomPerformanceConfiguration>? configure = null)");
        sb.AppendLine("    {");
        sb.AppendLine("        var config = new AxiomPerformanceConfiguration();");
        sb.AppendLine("        configure?.Invoke(config);");
        sb.AppendLine();
        sb.AppendLine("        // Configure caching");
        sb.AppendLine("        if (config.EnableCaching)");
        sb.AppendLine("        {");
        sb.AppendLine("            services.Configure<AxiomCacheOptions>(opt =>");
        sb.AppendLine("            {");
        sb.AppendLine("                opt.DefaultExpiration = config.Cache.DefaultExpiration;");
        sb.AppendLine("                opt.SizeLimit = config.Cache.SizeLimit;");
        sb.AppendLine("                opt.EnableCompaction = config.Cache.EnableCompaction;");
        sb.AppendLine("            });");
        sb.AppendLine("            services.AddMemoryCache(opt => opt.SizeLimit = config.Cache.SizeLimit);");
        sb.AppendLine("            services.AddScoped<IAxiomCacheService, AxiomMemoryCacheService>();");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        // Configure compression");
        sb.AppendLine("        if (config.EnableCompression)");
        sb.AppendLine("        {");
        sb.AppendLine("            services.Configure<AxiomCompressionOptions>(opt =>");
        sb.AppendLine("            {");
        sb.AppendLine("                opt.EnableCompression = config.Compression.EnableCompression;");
        sb.AppendLine("                opt.EnableGzip = config.Compression.EnableGzip;");
        sb.AppendLine("                opt.EnableBrotli = config.Compression.EnableBrotli;");
        sb.AppendLine("                opt.GzipLevel = config.Compression.GzipLevel;");
        sb.AppendLine("                opt.BrotliLevel = config.Compression.BrotliLevel;");
        sb.AppendLine("            });");
        sb.AppendLine("            services.AddScoped<AxiomCompressionMiddleware>();");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        // Configure performance monitoring");
        sb.AppendLine("        if (config.EnablePerformanceMonitoring)");
        sb.AppendLine("        {");
        sb.AppendLine("            services.Configure<AxiomPerformanceOptions>(opt =>");
        sb.AppendLine("            {");
        sb.AppendLine("                opt.EnablePerformanceMonitoring = config.Performance.EnablePerformanceMonitoring;");
        sb.AppendLine("                opt.SlowRequestThresholdMs = config.Performance.SlowRequestThresholdMs;");
        sb.AppendLine("                opt.EnableMemoryTracking = config.Performance.EnableMemoryTracking;");
        sb.AppendLine("            });");
        sb.AppendLine("            services.AddScoped<AxiomPerformanceMonitoringMiddleware>();");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        return services;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    /// <summary>");
        sb.AppendLine("    /// Use Axiom performance optimization middleware");
        sb.AppendLine("    /// </summary>");
        sb.AppendLine("    public static IApplicationBuilder UseAxiomPerformance(this IApplicationBuilder app)");
        sb.AppendLine("    {");
        sb.AppendLine("        app.UseMiddleware<AxiomPerformanceMonitoringMiddleware>();");
        sb.AppendLine("        app.UseMiddleware<AxiomCompressionMiddleware>();");
        sb.AppendLine("        return app;");
        sb.AppendLine("    }");
        sb.AppendLine();
        sb.AppendLine("    /// <summary>");
        sb.AppendLine("    /// Configure caching for a specific endpoint");
        sb.AppendLine("    /// </summary>");
        sb.AppendLine("    public static async Task<Result<T>> WithCaching<T>(");
        sb.AppendLine("        this Task<Result<T>> resultTask,");
        sb.AppendLine("        IAxiomCacheService cacheService,");
        sb.AppendLine("        string cacheKey,");
        sb.AppendLine("        TimeSpan? expiration = null,");
        sb.AppendLine("        CancellationToken cancellationToken = default) where T : notnull");
        sb.AppendLine("    {");
        sb.AppendLine("        // Check cache first");
        sb.AppendLine("        var cachedResult = await cacheService.GetAsync<T>(cacheKey, cancellationToken);");
        sb.AppendLine("        if (cachedResult != null)");
        sb.AppendLine("        {");
        sb.AppendLine("            return ResultFactory.Success(cachedResult);");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        // Execute original operation");
        sb.AppendLine("        var result = await resultTask;");
        sb.AppendLine("        if (result.IsSuccess)");
        sb.AppendLine("        {");
        sb.AppendLine("            await cacheService.SetAsync(cacheKey, result.Value, expiration, cancellationToken);");
        sb.AppendLine("        }");
        sb.AppendLine();
        sb.AppendLine("        return result;");
        sb.AppendLine("    }");
        sb.AppendLine("}");
        sb.AppendLine();

        // Generate performance configuration
        sb.AppendLine("/// <summary>");
        sb.AppendLine("/// Comprehensive configuration for Axiom performance optimizations");
        sb.AppendLine("/// </summary>");
        sb.AppendLine("[System.CodeDom.Compiler.GeneratedCode(\"AxiomEndpoints.SourceGenerators\", \"1.0.0\")]");
        sb.AppendLine("public class AxiomPerformanceConfiguration");
        sb.AppendLine("{");
        sb.AppendLine("    public bool EnableCaching { get; set; } = true;");
        sb.AppendLine("    public bool EnableCompression { get; set; } = true;");
        sb.AppendLine("    public bool EnablePerformanceMonitoring { get; set; } = true;");
        sb.AppendLine("    public bool EnableObjectPooling { get; set; } = true;");
        sb.AppendLine();
        sb.AppendLine("    public AxiomCacheOptions Cache { get; set; } = new();");
        sb.AppendLine("    public AxiomCompressionOptions Compression { get; set; } = new();");
        sb.AppendLine("    public AxiomPerformanceOptions Performance { get; set; } = new();");
        sb.AppendLine("}");
        sb.AppendLine();
    }
}