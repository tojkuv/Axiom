using System;
using System.Collections.Generic;
using System.Linq;

namespace AxiomEndpoints.SourceGenerators;

internal static class RouteTemplateBuilder
{
    public static string BuildTemplate(RouteInfo route)
    {
        var segments = new List<string>();
        var current = route;

        // Build route from nested types
        while (current is not null)
        {
            var segment = current.TypeName.ToLowerInvariant();

            // Handle "ById" -> ""
            if (segment == "byid" && current.Parameters.Any(p => p.Name.Equals("id", StringComparison.OrdinalIgnoreCase)))
            {
                segment = "";
            }

            // Add parameters
            foreach (var param in current.Parameters)
            {
                var paramSegment = $"{{{param.Name.ToLowerInvariant()}";

                // Add type constraint
                if (param.Type != "string")
                {
                    paramSegment += $":{GetRouteConstraint(param.Type)}";
                }

                // Add custom constraint
                if (param.Constraint is not null)
                {
                    paramSegment += $":{param.Constraint}";
                }

                // Optional parameter
                if (param.IsOptional)
                {
                    paramSegment += "?";
                }

                paramSegment += "}";
                segment = string.IsNullOrEmpty(segment) ? paramSegment : $"{segment}/{paramSegment}";
            }

            if (!string.IsNullOrEmpty(segment))
            {
                segments.Insert(0, segment);
            }

            // Move to parent - for now, we'll handle this in the main generator
            current = null;
        }

        return "/" + string.Join("/", segments);
    }

    private static string GetRouteConstraint(string type) => type switch
    {
        "System.Guid" => "guid",
        "System.Int32" => "int",
        "System.Int64" => "long",
        "System.Boolean" => "bool",
        "System.DateTime" => "datetime",
        "System.Decimal" => "decimal",
        "System.Double" => "double",
        "System.Single" => "float",
        _ => "string"
    };
}