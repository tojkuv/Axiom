using Grpc.Core;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpoints.Core;
using System.Security.Claims;
using System.Buffers;
using System.Linq;

namespace AxiomEndpoints.Grpc;

/// <summary>
/// Adapter that converts gRPC ServerCallContext to Axiom IContext
/// </summary>
public class GrpcContextAdapter : IContext
{
    private readonly ServerCallContext _grpcContext;
    private readonly HttpContext? _httpContext;

    public HttpContext HttpContext => _httpContext ?? throw new InvalidOperationException("HttpContext not available in pure gRPC context");
    public IServiceProvider Services { get; }
    public CancellationToken CancellationToken => _grpcContext.CancellationToken;
    public TimeProvider TimeProvider { get; }

    public GrpcContextAdapter(ServerCallContext grpcContext, IServiceProvider services)
    {
        _grpcContext = grpcContext;
        Services = services;
        TimeProvider = services.GetService<TimeProvider>() ?? TimeProvider.System;
        
        // Try to get HttpContext if available (for gRPC over HTTP/2)
        _httpContext = grpcContext.GetHttpContext();
    }

    /// <summary>
    /// Gets gRPC-specific context information
    /// </summary>
    public IGrpcContext AsGrpcContext() => new GrpcContextImpl(_grpcContext, this);

    /// <summary>
    /// Gets the gRPC request headers
    /// </summary>
    public Metadata RequestHeaders => _grpcContext.RequestHeaders;

    /// <summary>
    /// Gets the gRPC response headers
    /// </summary>
    public Metadata ResponseHeaders => new Metadata(); // gRPC response headers are handled differently

    /// <summary>
    /// Gets the gRPC response trailers
    /// </summary>
    public Metadata ResponseTrailers => _grpcContext.ResponseTrailers;

    /// <summary>
    /// Gets the gRPC peer information
    /// </summary>
    public string Peer => _grpcContext.Peer;

    /// <summary>
    /// Gets the gRPC method name
    /// </summary>
    public string Method => _grpcContext.Method;

    /// <summary>
    /// Gets the gRPC host
    /// </summary>
    public string Host => _grpcContext.Host;

    /// <summary>
    /// Gets the user identity from gRPC context or HTTP context
    /// </summary>
    public ClaimsPrincipal? User
    {
        get
        {
            // Try HTTP context first
            if (_httpContext?.User != null)
            {
                return _httpContext.User;
            }

            // Fall back to gRPC metadata for authentication
            return ExtractUserFromMetadata();
        }
    }

    private ClaimsPrincipal? ExtractUserFromMetadata()
    {
        // Extract user information from gRPC metadata
        // This is a simplified implementation - real scenarios would handle JWT tokens, etc.
        
        var authHeader = _grpcContext.RequestHeaders.FirstOrDefault(h => 
            h.Key.Equals("authorization", StringComparison.OrdinalIgnoreCase));

        if (authHeader != null && !string.IsNullOrEmpty(authHeader.Value))
        {
            // Parse authorization header and create claims principal
            // This is a placeholder - real implementation would validate tokens
            var claims = new List<Claim>
            {
                new(ClaimTypes.Name, "grpc-user"),
                new(ClaimTypes.AuthenticationMethod, "grpc")
            };

            var identity = new ClaimsIdentity(claims, "grpc");
            return new ClaimsPrincipal(identity);
        }

        return null;
    }

    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        throw new NotSupportedException("Route values not available in gRPC context");
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        return null;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        return null;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        return Enumerable.Empty<T>();
    }

    public bool HasQueryParameter(string key)
    {
        return false;
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("Location header not available in gRPC context");
    }
}

/// <summary>
/// gRPC-specific context interface
/// </summary>
public interface IGrpcContext : IContext
{
    /// <summary>
    /// The underlying gRPC server call context
    /// </summary>
    ServerCallContext ServerCallContext { get; }

    /// <summary>
    /// gRPC request headers
    /// </summary>
    Metadata RequestHeaders { get; }

    /// <summary>
    /// gRPC response headers
    /// </summary>
    Metadata ResponseHeaders { get; }

    /// <summary>
    /// gRPC response trailers
    /// </summary>
    Metadata ResponseTrailers { get; }

    /// <summary>
    /// Sets the gRPC status for the response
    /// </summary>
    void SetStatus(Status status);

    /// <summary>
    /// Sets a trailer value
    /// </summary>
    void SetTrailer(string key, string value);

    /// <summary>
    /// Gets the gRPC peer information
    /// </summary>
    string Peer { get; }

    /// <summary>
    /// Gets the gRPC method name
    /// </summary>
    string Method { get; }

    /// <summary>
    /// Gets the gRPC host
    /// </summary>
    string Host { get; }
}

/// <summary>
/// Implementation of gRPC-specific context
/// </summary>
internal class GrpcContextImpl : IGrpcContext
{
    private readonly ServerCallContext _grpcContext;
    private readonly IContext _baseContext;

    public ServerCallContext ServerCallContext => _grpcContext;
    public Metadata RequestHeaders => _grpcContext.RequestHeaders;
    public Metadata ResponseHeaders => new Metadata(); // gRPC response headers are handled differently
    public Metadata ResponseTrailers => _grpcContext.ResponseTrailers;
    public string Peer => _grpcContext.Peer;
    public string Method => _grpcContext.Method;
    public string Host => _grpcContext.Host;

    // Delegate to base context
    public HttpContext HttpContext => _baseContext.HttpContext;
    public IServiceProvider Services => _baseContext.Services;
    public CancellationToken CancellationToken => _baseContext.CancellationToken;
    public TimeProvider TimeProvider => _baseContext.TimeProvider;

    public GrpcContextImpl(ServerCallContext grpcContext, IContext baseContext)
    {
        _grpcContext = grpcContext;
        _baseContext = baseContext;
    }

    public void SetStatus(Status status)
    {
        _grpcContext.Status = status;
    }

    public void SetTrailer(string key, string value)
    {
        _grpcContext.ResponseTrailers.Add(key, value);
    }

    // Delegate remaining IContext members to base context
    public MemoryPool<byte> MemoryPool => _baseContext.MemoryPool;
    public T? GetRouteValue<T>(string key) where T : IParsable<T> => _baseContext.GetRouteValue<T>(key);
    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T> => _baseContext.GetQueryValue<T>(key);
    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T> => _baseContext.GetQueryValueRef<T>(key);
    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T> => _baseContext.GetQueryValues<T>(key);
    public bool HasQueryParameter(string key) => _baseContext.HasQueryParameter(key);
    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute> => _baseContext.GenerateUrl(route);
    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute> => _baseContext.GenerateUrlWithQuery(route, queryParameters);
    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute> => _baseContext.SetLocation(route);
}

/// <summary>
/// Enhanced context factory that can create both HTTP and gRPC contexts
/// </summary>
public class EnhancedContextFactory : IContextFactory
{
    private readonly IServiceProvider _services;
    private readonly IHttpContextAccessor? _httpContextAccessor;

    public EnhancedContextFactory(IServiceProvider services, IHttpContextAccessor? httpContextAccessor = null)
    {
        _services = services;
        _httpContextAccessor = httpContextAccessor;
    }

    public IContext CreateContext()
    {
        var httpContext = _httpContextAccessor?.HttpContext;
        if (httpContext != null)
        {
            return new HttpContextAdapter(httpContext, _services);
        }

        // Fallback to simple context
        return new SimpleContext(_services);
    }

    public IContext CreateGrpcContext(ServerCallContext grpcContext)
    {
        return new GrpcContextAdapter(grpcContext, _services);
    }
}

/// <summary>
/// HTTP context adapter for Axiom
/// </summary>
public class HttpContextAdapter : IContext
{
    public HttpContext HttpContext { get; }
    public IServiceProvider Services { get; }
    public CancellationToken CancellationToken => HttpContext.RequestAborted;
    public TimeProvider TimeProvider { get; }

    public HttpContextAdapter(HttpContext httpContext, IServiceProvider services)
    {
        HttpContext = httpContext;
        Services = services;
        TimeProvider = services.GetService<TimeProvider>() ?? TimeProvider.System;
    }

    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        throw new NotImplementedException("Route value access not implemented for HttpContextAdapter");
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        throw new NotImplementedException("Query value access not implemented for HttpContextAdapter");
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        throw new NotImplementedException("Query value access not implemented for HttpContextAdapter");
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        throw new NotImplementedException("Query values access not implemented for HttpContextAdapter");
    }

    public bool HasQueryParameter(string key)
    {
        throw new NotImplementedException("Query parameter check not implemented for HttpContextAdapter");
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("URL generation not implemented for HttpContextAdapter");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("URL generation not implemented for HttpContextAdapter");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("Location header setting not implemented for HttpContextAdapter");
    }
}

/// <summary>
/// Simple context for scenarios where HTTP context is not available
/// </summary>
public class SimpleContext : IContext
{
    public HttpContext HttpContext => throw new InvalidOperationException("HttpContext not available");
    public IServiceProvider Services { get; }
    public CancellationToken CancellationToken { get; set; } = CancellationToken.None;
    public TimeProvider TimeProvider { get; }
    public MemoryPool<byte> MemoryPool { get; }

    public SimpleContext(IServiceProvider services)
    {
        Services = services;
        TimeProvider = services.GetService<TimeProvider>() ?? TimeProvider.System;
        MemoryPool = MemoryPool<byte>.Shared;
    }

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        throw new NotSupportedException("Route values not available in gRPC context");
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        return null;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        return null;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        return Enumerable.Empty<T>();
    }

    public bool HasQueryParameter(string key)
    {
        return false;
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("URL generation not available in gRPC context");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotSupportedException("Location header not available in gRPC context");
    }
}