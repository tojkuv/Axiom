using System.Buffers;
using Microsoft.AspNetCore.Http;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Testing.Common.MockServices;

public class MockContext : IContext
{
    private readonly CancellationToken _cancellationToken;
    private readonly Dictionary<string, object> _routeValues = new();
    private readonly Dictionary<string, string[]> _queryValues = new();

    public MockContext(CancellationToken cancellationToken = default)
    {
        _cancellationToken = cancellationToken;
        HttpContext = new MockHttpContext();
        Services = new MockServiceProvider();
    }

    public HttpContext HttpContext { get; set; }
    public IServiceProvider Services { get; set; }
    public CancellationToken CancellationToken => _cancellationToken;
    public TimeProvider TimeProvider => TimeProvider.System;
    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public MockContext SetRouteValue<T>(string key, T value) where T : IParsable<T>
    {
        _routeValues[key] = value!;
        return this;
    }

    public MockContext SetQueryValue<T>(string key, T value) where T : IParsable<T>
    {
        _queryValues[key] = [value?.ToString() ?? string.Empty];
        return this;
    }

    public MockContext SetQueryValues<T>(string key, IEnumerable<T> values) where T : IParsable<T>
    {
        _queryValues[key] = values.Select(v => v?.ToString() ?? string.Empty).ToArray();
        return this;
    }

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        if (!_routeValues.TryGetValue(key, out var value))
            return default;

        if (value is T directValue)
            return directValue;

        var stringValue = value.ToString();
        if (string.IsNullOrEmpty(stringValue))
            return default;

        return T.TryParse(stringValue, null, out var result) ? result : default;
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        if (!_queryValues.TryGetValue(key, out var values) || values.Length == 0)
            return default;

        return T.TryParse(values[0], null, out var result) ? result : default;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        if (!_queryValues.TryGetValue(key, out var values) || values.Length == 0)
            return default;

        return T.TryParse(values[0], null, out var result) ? result : default;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        if (!_queryValues.TryGetValue(key, out var values))
            yield break;

        foreach (var value in values)
        {
            if (T.TryParse(value, null, out var result))
                yield return result;
        }
    }

    public bool HasQueryParameter(string key) => _queryValues.ContainsKey(key);

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        return new Uri($"/test/{typeof(TRoute).Name}", UriKind.Relative);
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        var url = $"/test/{typeof(TRoute).Name}";
        if (queryParameters != null)
        {
            url += "?mock=true";
        }
        return new Uri(url, UriKind.Relative);
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        // Mock implementation - could set a property if needed for testing
    }
}