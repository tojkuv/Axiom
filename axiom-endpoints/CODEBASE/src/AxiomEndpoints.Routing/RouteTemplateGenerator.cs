using AxiomEndpoints.Core;

namespace AxiomEndpoints.Routing;

public static partial class RouteTemplateGenerator
{
    // This will be implemented by source generator
    public static string Generate<TRoute>() where TRoute : IRoute<TRoute>
    {
        // Temporary fallback implementation until source generator is fully working
        return "/" + typeof(TRoute).Name.ToLowerInvariant();
    }

    public static string Generate(Type routeType)
    {
        // Temporary fallback implementation until source generator is fully working
        return "/" + routeType.Name.ToLowerInvariant();
    }
}