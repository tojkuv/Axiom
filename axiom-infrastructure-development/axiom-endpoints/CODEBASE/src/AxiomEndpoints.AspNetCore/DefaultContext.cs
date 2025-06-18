using System.Buffers;
using System.Diagnostics.CodeAnalysis;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using Microsoft.AspNetCore.Http;

namespace AxiomEndpoints.AspNetCore;

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Class is instantiated by dependency injection")]
internal sealed class DefaultContext : IContext
{
    private readonly HttpContext _httpContext;

    public DefaultContext(IHttpContextAccessor accessor, TimeProvider timeProvider)
    {
        _httpContext = accessor.HttpContext!;
        TimeProvider = timeProvider;
        MemoryPool = MemoryPool<byte>.Shared;
    }

    public HttpContext HttpContext => _httpContext;
    public IServiceProvider Services => _httpContext.RequestServices;
    public CancellationToken CancellationToken => _httpContext.RequestAborted;
    public TimeProvider TimeProvider { get; }
    public MemoryPool<byte> MemoryPool { get; }

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        if (_httpContext.Request.RouteValues.TryGetValue(key, out var value) &&
            value is string stringValue &&
            T.TryParse(stringValue, null, out var result))
        {
            return result;
        }
        return default;
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values) &&
            values.Count > 0 &&
            !string.IsNullOrEmpty(values[0]) &&
            T.TryParse(values[0], null, out var result))
        {
            return result;
        }
        return null;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values) &&
            values.Count > 0 &&
            !string.IsNullOrEmpty(values[0]) &&
            T.TryParse(values[0], null, out var result))
        {
            return result;
        }
        return null;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values))
        {
            foreach (var value in values)
            {
                if (!string.IsNullOrEmpty(value) && T.TryParse(value, null, out var result))
                {
                    yield return result;
                }
            }
        }
    }

    public bool HasQueryParameter(string key)
    {
        return _httpContext.Request.Query.ContainsKey(key);
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        var url = RouteUrlGenerator.GenerateUrl(route);
        return new Uri(url, UriKind.RelativeOrAbsolute);
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParameters);
        return new Uri(url, UriKind.RelativeOrAbsolute);
    }

    public void SetLocation<TRoute>(TRoute route)
        where TRoute : IRoute<TRoute>
    {
        var uri = GenerateUrl(route);
        _httpContext.Response.Headers.Location = uri.ToString();
    }
}