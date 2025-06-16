using AxiomEndpoints.Core;
using System.Reflection;
using System.Text;

namespace AxiomEndpoints.Routing;

public static partial class RouteTemplateGenerator
{
    // This will be implemented by source generator
    public static string Generate<TRoute>() where TRoute : IRoute<TRoute>
    {
        return Generate(typeof(TRoute));
    }

    public static string Generate(Type routeType)
    {
        // Check if this is an optional route
        if (IsOptionalRoute(routeType))
        {
            return GenerateOptionalRouteTemplate(routeType);
        }
        
        var typeParts = new List<(Type type, bool hasParams)>();
        
        // First, collect all types in the hierarchy
        var currentType = routeType;
        
        // Always include the target route type first
        var constructorParams = GetConstructorParameters(currentType);
        typeParts.Add((currentType, constructorParams.Count > 0));
        
        // Then collect parent types in the hierarchy
        while (currentType != null && currentType.DeclaringType != null)
        {
            currentType = currentType.DeclaringType;
            
            // Stop traversal if we hit a test organization class or other non-route containers
            if (IsTestOrganizationClass(currentType))
            {
                break;
            }
            
            var parentParams = GetConstructorParameters(currentType);
            typeParts.Add((currentType, parentParams.Count > 0));
        }
        
        // Reverse to get correct order (root to leaf)
        typeParts.Reverse();
        
        var templateParts = new List<string>();
        var seenParameters = new HashSet<string>();
        
        // Process each type in order, adding segments and parameters
        for (int i = 0; i < typeParts.Count; i++)
        {
            var (type, hasParams) = typeParts[i];
            
            // Determine if we should add a path segment for this type
            bool isRouteType = IsRouteType(type);
            bool isOrganizationalClass = !isRouteType; // Static classes used for organization
            bool isRouteWithoutParams = isRouteType && !hasParams;
            bool isSimpleRouteType = isRouteType && typeParts.Count == 1; // Simple route not in hierarchy
            bool shouldAddPathSegment = isOrganizationalClass || isRouteWithoutParams || isSimpleRouteType;
            
            if (shouldAddPathSegment)
            {
                var segmentName = GetPathSegment(type);
                if (!string.IsNullOrEmpty(segmentName))
                {
                    templateParts.Add(segmentName);
                }
            }
            
            // Add parameters if this type has them
            if (hasParams)
            {
                var typeParams = GetConstructorParameters(type);
                foreach (var param in typeParams)
                {
                    // Only add parameters we haven't seen before (avoid duplicates in hierarchical routes)
                    if (!seenParameters.Contains(param.Name))
                    {
                        seenParameters.Add(param.Name);
                        var paramPart = '{' + param.Name;
                        if (!string.IsNullOrEmpty(param.Constraint))
                        {
                            paramPart += ':' + param.Constraint;
                        }
                        paramPart += '}';
                        templateParts.Add(paramPart);
                    }
                }
            }
        }
        
        // Build template
        if (templateParts.Count > 0)
        {
            return "/" + string.Join("/", templateParts);
        }
        else
        {
            // Fallback for simple types
            return "/" + GetFallbackPath(routeType);
        }
    }

    private static List<RouteParameter> GetConstructorParameters(Type routeType)
    {
        var constructor = GetPrimaryConstructor(routeType);
        if (constructor?.GetParameters().Length > 0)
        {
            return constructor.GetParameters()
                .Select(p => new RouteParameter
                {
                    Name = ToCamelCase(p.Name ?? "param"),
                    Constraint = GetParameterConstraint(p, routeType)
                })
                .ToList();
        }
        
        return new List<RouteParameter>();
    }

    private static string GetPathSegment(Type routeType)
    {
        var typeName = routeType.Name;
        
        // Handle version containers like "V1", "V2"
        if (typeName.Length > 0 && typeName[0] == 'V' && 
            typeName.Length > 1 && char.IsDigit(typeName[1]))
        {
            return typeName.ToLowerInvariant();
        }
        
        // Handle compound route names like "UserById" or "OrderByUserAndId"
        // Extract the main entity name (the part before "By")
        var byIndex = typeName.IndexOf("By", StringComparison.Ordinal);
        if (byIndex > 0)
        {
            var entityName = typeName.Substring(0, byIndex);
            // Convert to lowercase and handle plural forms
            return entityName.ToLowerInvariant();
        }
        
        return typeName.ToLowerInvariant();
    }

    private static string GetFallbackPath(Type routeType)
    {
        var typeName = routeType.Name;
        
        return typeName.ToLowerInvariant();
    }

    private static string? GetParameterConstraint(ParameterInfo parameter, Type routeType)
    {
        // For record types, the constraint attributes are on the properties, not constructor parameters
        var propertyName = parameter.Name;
        if (propertyName != null)
        {
            var property = routeType.GetProperty(propertyName);
            if (property != null)
            {
                // Check property for constraint attributes
                foreach (var attr in property.GetCustomAttributes(false))
                {
                    var attrType = attr.GetType();
                    
                    // Check if this attribute implements the RouteConstraintAttribute<T> pattern
                    if (attrType.IsGenericType && 
                        attrType.GetGenericTypeDefinition() == typeof(RouteConstraintAttribute<>))
                    {
                        // Get the constraint property
                        var constraintProperty = attrType.GetProperty("Constraint");
                        if (constraintProperty?.GetValue(attr) is IRouteConstraint constraint)
                        {
                            return constraint.ConstraintString;
                        }
                    }
                }
            }
        }
        
        return null;
    }

    private static string ToCamelCase(string value)
    {
        if (string.IsNullOrEmpty(value))
            return value;
            
        // Convert first character to lowercase, keep the rest as-is
        return char.ToLowerInvariant(value[0]) + value[1..];
    }

    private record RouteParameter
    {
        public required string Name { get; init; }
        public string? Constraint { get; init; }
    }

    private static bool IsOptionalRoute(Type routeType)
    {
        return routeType.GetInterfaces()
            .Any(i => i.IsGenericType && 
                     i.GetGenericTypeDefinition().Name.Contains("IOptionalRoute"));
    }
    
    private static bool IsRouteType(Type type)
    {
        return type.GetInterfaces()
            .Any(i => i.IsGenericType && 
                     i.GetGenericTypeDefinition().Name.Contains("IRoute"));
    }
    
    private static bool IsTestOrganizationClass(Type type)
    {
        var typeName = type.Name;
        
        // Common test organization class patterns
        return typeName.Contains("Test") || 
               typeName.Contains("Routes") ||
               typeName.EndsWith("Tests") ||
               typeName.StartsWith("Test");
    }
    
    private static string GenerateOptionalRouteTemplate(Type routeType)
    {
        // Get the base path segments from the parent types
        var pathSegments = new List<string>();
        var currentType = routeType.DeclaringType;
        
        while (currentType != null && currentType.DeclaringType != null)
        {
            var segmentName = GetPathSegment(currentType);
            if (!string.IsNullOrEmpty(segmentName))
            {
                pathSegments.Add(segmentName);
            }
            currentType = currentType.DeclaringType;
        }
        
        pathSegments.Reverse();
        
        // For optional routes like Files.ByPath, we need special handling
        var template = new StringBuilder();
        
        if (pathSegments.Count > 0)
        {
            template.Append('/').Append(string.Join("/", pathSegments));
        }
        else
        {
            template.Append('/').Append(GetFallbackPath(routeType));
        }
        
        // For Files.ByPath-like routes, the path parameter should be a catch-all
        var constructor = GetPrimaryConstructor(routeType);
        if (constructor?.GetParameters().Length > 0)
        {
            var firstParam = constructor.GetParameters()[0];
            if (firstParam.Name?.ToLowerInvariant() == "path")
            {
                // Use catch-all parameter for path
                template.Append("/{*").Append(ToCamelCase(firstParam.Name ?? "path")).Append('}');
            }
            else if (firstParam.Name != null)
            {
                // Regular parameter
                template.Append('/').Append('{').Append(ToCamelCase(firstParam.Name)).Append('}');
            }
        }
        
        return template.ToString();
    }

    private static ConstructorInfo? GetPrimaryConstructor(Type type)
    {
        // For records, the primary constructor is typically the one with the most parameters
        // or has the CompilerGenerated attribute
        var constructors = type.GetConstructors(BindingFlags.Public | BindingFlags.Instance);
        
        if (constructors.Length == 0)
            return null;
            
        if (constructors.Length == 1)
            return constructors[0];
        
        // Return the constructor with the most parameters (likely the primary constructor for records)
        return constructors.OrderByDescending(c => c.GetParameters().Length).First();
    }
}