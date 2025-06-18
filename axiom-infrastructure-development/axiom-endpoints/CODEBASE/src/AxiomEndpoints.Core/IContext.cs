using Microsoft.AspNetCore.Http;
using System.Buffers;

namespace AxiomEndpoints.Core;

/// <summary>
/// Request context with .NET 9 features
/// </summary>
public interface IContext
{
    HttpContext HttpContext { get; }
    IServiceProvider Services { get; }
    CancellationToken CancellationToken { get; }
    TimeProvider TimeProvider { get; }
    MemoryPool<byte> MemoryPool { get; }

    // Type-safe route value access
    T? GetRouteValue<T>(string key) where T : IParsable<T>;

    // Type-safe query parameter access
    T? GetQueryValue<T>(string key) where T : struct, IParsable<T>;
    
    // Type-safe query parameter access for reference types
    T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>;
    
    // Get all query values for a key (for repeated query parameters)
    IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>;
    
    // Check if query parameter exists
    bool HasQueryParameter(string key);

    // URL generation from routes
    Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>;
    Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>;

    // Set response location header
    void SetLocation<TRoute>(TRoute route)
        where TRoute : IRoute<TRoute>;
}

/// <summary>
/// Factory interface for creating context instances
/// </summary>
public interface IContextFactory
{
    /// <summary>
    /// Creates a context instance
    /// </summary>
    IContext CreateContext();
}