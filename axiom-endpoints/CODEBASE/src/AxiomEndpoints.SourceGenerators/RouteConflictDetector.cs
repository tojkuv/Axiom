using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis;

namespace AxiomEndpoints.SourceGenerators;

internal static class RouteConflictDetector
{
    public static ImmutableArray<Diagnostic> DetectConflicts(
        ImmutableArray<AdvancedRouteInfo> routes,
        SourceProductionContext context)
    {
        var diagnostics = ImmutableArray.CreateBuilder<Diagnostic>();
        var routesByTemplate = new Dictionary<string, List<AdvancedRouteInfo>>();

        // Group routes by their normalized template
        foreach (var route in routes)
        {
            var normalized = NormalizeTemplate(route.Template);

            if (!routesByTemplate.TryGetValue(normalized, out var list))
            {
                list = new List<AdvancedRouteInfo>();
                routesByTemplate[normalized] = list;
            }

            list.Add(route);
        }

        // Check for conflicts
        foreach (var kvp in routesByTemplate)
        {
            var template = kvp.Key;
            var conflictingRoutes = kvp.Value;
            if (conflictingRoutes.Count > 1)
            {
                // Check if they differ by HTTP method or version
                var conflicts = conflictingRoutes
                    .GroupBy(r => (r.HttpMethod, GetVersionString(r.Version)))
                    .Where(g => g.Count() > 1)
                    .ToList();

                foreach (var conflict in conflicts)
                {
                    var diagnostic = Diagnostic.Create(
                        RouteConflictDescriptor,
                        Location.None,
                        template,
                        string.Join(", ", conflict.Select(r => r.TypeName)));

                    diagnostics.Add(diagnostic);
                }
            }
        }

        // Check for ambiguous routes (parameter vs literal conflict)
        DetectAmbiguousRoutes(diagnostics, routes);

        // Check for invalid constraints
        DetectInvalidConstraints(diagnostics, routes);

        // Check for circular hierarchies
        DetectCircularHierarchies(diagnostics, routes);

        return diagnostics.ToImmutable();
    }

    private static void DetectAmbiguousRoutes(ImmutableArray<Diagnostic>.Builder diagnostics, ImmutableArray<AdvancedRouteInfo> routes)
    {
        var groupedRoutes = routes.GroupBy(r => r.HttpMethod);

        foreach (var methodGroup in groupedRoutes)
        {
            var templates = methodGroup.Select(r => r.Template).ToList();

            for (int i = 0; i < templates.Count; i++)
            {
                for (int j = i + 1; j < templates.Count; j++)
                {
                    if (AreAmbiguous(templates[i], templates[j]))
                    {
                        var diagnostic = Diagnostic.Create(
                            AmbiguousRouteDescriptor,
                            Location.None,
                            templates[i],
                            templates[j]);

                        diagnostics.Add(diagnostic);
                    }
                }
            }
        }
    }

    private static void DetectInvalidConstraints(ImmutableArray<Diagnostic>.Builder diagnostics, ImmutableArray<AdvancedRouteInfo> routes)
    {
        foreach (var route in routes)
        {
            foreach (var constraint in route.Constraints)
            {
                // Check if parameter exists in route
                var hasParameter = route.Parameters.Any(p => 
                    string.Equals(p.Name, constraint.ParameterName, StringComparison.OrdinalIgnoreCase));

                if (!hasParameter)
                {
                    var diagnostic = Diagnostic.Create(
                        InvalidConstraintDescriptor,
                        Location.None,
                        constraint.ParameterName,
                        route.TypeName);

                    diagnostics.Add(diagnostic);
                }

                // Validate constraint type
                if (!IsValidConstraintType(constraint.Type))
                {
                    var diagnostic = Diagnostic.Create(
                        UnknownConstraintDescriptor,
                        Location.None,
                        constraint.Type,
                        constraint.ParameterName);

                    diagnostics.Add(diagnostic);
                }
            }
        }
    }

    private static void DetectCircularHierarchies(ImmutableArray<Diagnostic>.Builder diagnostics, ImmutableArray<AdvancedRouteInfo> routes)
    {
        var hierarchicalRoutes = routes.Where(r => r.IsHierarchical).ToArray();

        foreach (var route in hierarchicalRoutes)
        {
            var visited = new HashSet<string>();
            var path = new List<string>();

            if (HasCircularReference(route, routes, visited, path))
            {
                var diagnostic = Diagnostic.Create(
                    CircularHierarchyDescriptor,
                    Location.None,
                    route.TypeName,
                    string.Join(" -> ", path));

                diagnostics.Add(diagnostic);
            }
        }
    }

    private static bool HasCircularReference(
        AdvancedRouteInfo route, 
        ImmutableArray<AdvancedRouteInfo> allRoutes,
        HashSet<string> visited,
        List<string> path)
    {
        if (visited.Contains(route.TypeName))
        {
            path.Add(route.TypeName);
            return true;
        }

        visited.Add(route.TypeName);
        path.Add(route.TypeName);

        if (route.ParentRouteType != null)
        {
            var parent = allRoutes.FirstOrDefault(r => r.FullTypeName == route.ParentRouteType);
            if (parent != null && HasCircularReference(parent, allRoutes, visited, path))
            {
                return true;
            }
        }

        visited.Remove(route.TypeName);
        path.RemoveAt(path.Count - 1);
        return false;
    }

    private static string NormalizeTemplate(string template)
    {
        // Replace parameter names with placeholders, but keep constraints
        return Regex.Replace(template, @"\{([^:}]+)([^}]*)\}", "{param$2}");
    }

    private static bool AreAmbiguous(string template1, string template2)
    {
        var segments1 = template1.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
        var segments2 = template2.Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);

        if (segments1.Length != segments2.Length)
            return false;

        for (int i = 0; i < segments1.Length; i++)
        {
            var seg1 = segments1[i];
            var seg2 = segments2[i];

            // Both are parameters - ambiguous
            if (IsParameter(seg1) && IsParameter(seg2))
            {
                // Check if constraints make them unambiguous
                var constraint1 = ExtractConstraint(seg1);
                var constraint2 = ExtractConstraint(seg2);

                if (constraint1 != constraint2)
                    return false; // Different constraints resolve ambiguity
            }
            // One parameter, one literal with same name as parameter - ambiguous
            else if ((IsParameter(seg1) && seg2 == ExtractParameterName(seg1)) ||
                     (IsParameter(seg2) && seg1 == ExtractParameterName(seg2)))
            {
                return true;
            }
            // Both literals but different - not ambiguous
            else if (!IsParameter(seg1) && !IsParameter(seg2) && seg1 != seg2)
            {
                return false;
            }
        }

        return true; // If we got here, routes are ambiguous
    }

    private static bool IsParameter(string segment)
    {
        return segment.StartsWith("{") && segment.EndsWith("}");
    }

    private static string ExtractParameterName(string parameterSegment)
    {
        var content = parameterSegment.Substring(1, parameterSegment.Length - 2); // Remove { }
        var colonIndex = content.IndexOf(':');
        return colonIndex > 0 ? content.Substring(0, colonIndex) : content;
    }

    private static string? ExtractConstraint(string parameterSegment)
    {
        var content = parameterSegment.Substring(1, parameterSegment.Length - 2); // Remove { }
        var colonIndex = content.IndexOf(':');
        return colonIndex > 0 ? content.Substring(colonIndex + 1) : null;
    }

    private static string GetVersionString(ApiVersionInfo? version)
    {
        return version?.ToString() ?? "none";
    }

    private static bool IsValidConstraintType(string constraintType)
    {
        var validTypes = new[] { "Range", "Regex", "Length", "Enum", "AllowedValues", "Required", "Alpha", "Alphanumeric" };
        return validTypes.Contains(constraintType);
    }

    private static readonly DiagnosticDescriptor RouteConflictDescriptor = new(
        id: "AX001",
        title: "Route conflict detected",
        messageFormat: "Multiple endpoints match the route template '{0}': {1}",
        category: "Routing",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);

    private static readonly DiagnosticDescriptor AmbiguousRouteDescriptor = new(
        id: "AX002",
        title: "Ambiguous route detected",
        messageFormat: "Routes '{0}' and '{1}' are ambiguous and may cause conflicts",
        category: "Routing",
        DiagnosticSeverity.Warning,
        isEnabledByDefault: true);

    private static readonly DiagnosticDescriptor InvalidConstraintDescriptor = new(
        id: "AX003",
        title: "Invalid route constraint",
        messageFormat: "Parameter '{0}' does not exist in route '{1}'",
        category: "Routing",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);

    private static readonly DiagnosticDescriptor UnknownConstraintDescriptor = new(
        id: "AX004",
        title: "Unknown constraint type",
        messageFormat: "Unknown constraint type '{0}' for parameter '{1}'",
        category: "Routing",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);

    private static readonly DiagnosticDescriptor CircularHierarchyDescriptor = new(
        id: "AX005",
        title: "Circular hierarchy detected",
        messageFormat: "Route '{0}' has a circular hierarchy: {1}",
        category: "Routing",
        DiagnosticSeverity.Error,
        isEnabledByDefault: true);
}