using AxiomEndpoints.Core;

namespace AxiomEndpoints.Routing;

/// <summary>
/// Provides route matching capabilities for type-safe routes
/// </summary>
public static class RouteMatcher
{
    /// <summary>
    /// Matches a path against a route type and extracts parameters
    /// </summary>
    public static bool TryMatch<TRoute>(string path, out Dictionary<string, object> parameters)
        where TRoute : IRoute<TRoute>
    {
        ArgumentNullException.ThrowIfNull(path);
        
        parameters = new Dictionary<string, object>();
        
        var template = RouteTemplateGenerator.Generate<TRoute>();
        return TryMatchInternal(path, template, parameters);
    }

    /// <summary>
    /// Matches a path against a route type and extracts parameters
    /// </summary>
    public static bool TryMatch(Type routeType, string path, out Dictionary<string, object> parameters)
    {
        ArgumentNullException.ThrowIfNull(path);
        
        parameters = new Dictionary<string, object>();
        
        var template = RouteTemplateGenerator.Generate(routeType);
        return TryMatchInternal(path, template, parameters);
    }

    private static bool TryMatchInternal(string path, string template, Dictionary<string, object> parameters)
    {
        // Simple implementation - will be enhanced later
        var pathSegments = path.Trim('/').Split('/', StringSplitOptions.RemoveEmptyEntries);
        var templateSegments = template.Trim('/').Split('/', StringSplitOptions.RemoveEmptyEntries);

        if (pathSegments.Length != templateSegments.Length)
            return false;

        for (int i = 0; i < pathSegments.Length; i++)
        {
            var pathSegment = pathSegments[i];
            var templateSegment = templateSegments[i];

            if (templateSegment.StartsWith('{') && templateSegment.EndsWith('}'))
            {
                // Parameter segment
                var paramName = templateSegment[1..^1]; // Remove { and }
                parameters[paramName] = pathSegment;
            }
            else if (!string.Equals(pathSegment, templateSegment, StringComparison.OrdinalIgnoreCase))
            {
                // Literal segment mismatch
                return false;
            }
        }

        return true;
    }
}