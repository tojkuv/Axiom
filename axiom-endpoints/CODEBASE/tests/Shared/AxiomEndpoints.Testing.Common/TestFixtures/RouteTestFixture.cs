using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

namespace AxiomEndpoints.Testing.Common.TestFixtures;

public class RouteTestFixture : IDisposable
{
    private bool _disposed;

    public virtual void Dispose()
    {
        if (!_disposed)
        {
            _disposed = true;
        }
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed && disposing)
        {
            // Cleanup resources
        }
    }
}

public abstract class RouteTestFixture<TRoute> : RouteTestFixture where TRoute : IRoute<TRoute>
{
    public abstract TRoute CreateRoute();

    protected virtual string GenerateTemplate()
    {
        return RouteTemplateGenerator.Generate(typeof(TRoute));
    }

    protected virtual bool TestMatch(string path)
    {
        return RouteMatcher.TryMatch(typeof(TRoute), path, out _);
    }

    protected virtual Dictionary<string, object> TestMatchWithParameters(string path)
    {
        RouteMatcher.TryMatch(typeof(TRoute), path, out var parameters);
        return parameters;
    }

    protected virtual string GenerateUrl(TRoute route)
    {
        return RouteUrlGenerator.GenerateUrl(route);
    }
}