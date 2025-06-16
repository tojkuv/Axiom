using System.Collections.Concurrent;
using System.Diagnostics.CodeAnalysis;
using System.Reflection;
using System.Text;
using AxiomEndpoints.Core;

namespace AxiomEndpoints.Routing;

/// <summary>
/// Type-safe URL builder for routes
/// </summary>
public static class UrlBuilder
{
    private static readonly ConcurrentDictionary<Type, Func<object, string>> _generatorCache = new();

    /// <summary>
    /// Builds a URL from a route instance
    /// </summary>
    [SuppressMessage("Design", "CA1055:URI-like return values should not be strings", Justification = "Internal utility for URL string generation; conversion to Uri happens at API boundary")]
    public static string BuildUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        var template = RouteTemplateGenerator.Generate<TRoute>();
        var url = new StringBuilder();

        var segments = template.Split('/', StringSplitOptions.RemoveEmptyEntries);

        foreach (var segment in segments)
        {
            if (url.Length > 0) url.Append('/');

            if (segment.StartsWith('{') && segment.EndsWith('}'))
            {
                var paramName = segment[1..^1];
                bool isCatchAll = paramName.StartsWith('*');
                
                if (isCatchAll)
                {
                    paramName = paramName[1..]; // Remove the '*'
                }
                
                var colonIndex = paramName.IndexOf(':');
                if (colonIndex > 0)
                {
                    paramName = paramName[..colonIndex];
                }

                var value = GetParameterValue(route, paramName);
                if (isCatchAll)
                {
                    // For catch-all parameters, encode everything except forward slashes
                    var stringValue = value?.ToString() ?? "";
                    if (!string.IsNullOrEmpty(stringValue))
                    {
                        // Split by forward slashes, encode each segment, then rejoin with slashes
                        var pathSegments = stringValue.Split('/');
                        var encodedSegments = pathSegments.Select(Uri.EscapeDataString);
                        url.Append(string.Join("/", encodedSegments));
                    }
                }
                else
                {
                    url.Append(Uri.EscapeDataString(value?.ToString() ?? ""));
                }
            }
            else
            {
                url.Append(segment);
            }
        }

        // Handle optional parameters for IOptionalRoute
        var optionalRouteType = typeof(TRoute).GetInterfaces()
            .FirstOrDefault(i => i.IsGenericType && i.GetGenericTypeDefinition().Name.Contains("IOptionalRoute"));
        
        if (optionalRouteType != null)
        {
            // Get optional parameters configuration
            var getOptionalParametersMethod = typeof(TRoute).GetMethod("GetOptionalParameters", BindingFlags.Public | BindingFlags.Static);
            if (getOptionalParametersMethod != null)
            {
                var optionalParams = getOptionalParametersMethod.Invoke(null, null);
                if (optionalParams != null)
                {
                    var optionalSegmentsProperty = optionalParams.GetType().GetProperty("OptionalSegments");
                    var defaultValuesProperty = optionalParams.GetType().GetProperty("DefaultValues");
                    
                    if (optionalSegmentsProperty != null && defaultValuesProperty != null)
                    {
                        var optionalSegments = optionalSegmentsProperty.GetValue(optionalParams) as System.Collections.IEnumerable;
                        var defaultValues = defaultValuesProperty.GetValue(optionalParams) as System.Collections.IDictionary;
                        
                        if (optionalSegments != null && defaultValues != null)
                        {
                            // Check for optional parameters and add them if they differ from defaults
                            foreach (var segment in optionalSegments)
                            {
                                var segmentName = segment?.ToString();
                                if (!string.IsNullOrEmpty(segmentName))
                                {
                                    var property = typeof(TRoute).GetProperty(segmentName, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
                                    if (property != null)
                                    {
                                        var value = property.GetValue(route);
                                        var defaultValue = defaultValues.Contains(segmentName) ? defaultValues[segmentName] : null;
                                        
                                        if (value != null && !Equals(value, defaultValue))
                                        {
                                            url.Append('/').Append(Uri.EscapeDataString(value.ToString()!));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Handle query parameters if the route supports them
        var queryRouteType = typeof(TRoute).GetInterfaces()
            .FirstOrDefault(i => i.IsGenericType && i.GetGenericTypeDefinition().Name.Contains("IRouteWithQuery"));
        
        if (queryRouteType != null)
        {
            var queryProperty = typeof(TRoute).GetProperty("Query");
            if (queryProperty != null)
            {
                var queryValue = queryProperty.GetValue(route);
                if (queryValue != null)
                {
                    var queryString = BuildQueryString(queryValue);
                    if (!string.IsNullOrEmpty(queryString))
                    {
                        url.Append('?').Append(queryString);
                    }
                }
            }
        }

        return "/" + url.ToString();
    }

    /// <summary>
    /// Builds a URL with additional query parameters
    /// </summary>
    [SuppressMessage("Design", "CA1055:URI-like return values should not be strings", Justification = "Internal utility for URL string generation; conversion to Uri happens at API boundary")]
    public static string BuildUrl<TRoute, TQuery>(TRoute route, TQuery query)
        where TRoute : IRoute<TRoute>
        where TQuery : IQueryParameters
    {
        var baseUrl = BuildUrl(route);
        var queryString = BuildQueryString(query);

        return string.IsNullOrEmpty(queryString)
            ? baseUrl
            : $"{baseUrl}?{queryString}";
    }

    private static string? GetParameterValue<TRoute>(TRoute route, string paramName)
    {
        var property = typeof(TRoute).GetProperty(paramName,
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);

        return property?.GetValue(route)?.ToString();
    }

    private static string BuildQueryString(IQueryParameters? parameters)
    {
        if (parameters == null) return "";

        var metadata = parameters.GetType()
            .GetMethod(nameof(IQueryParameters.GetMetadata), BindingFlags.Public | BindingFlags.Static)!
            .Invoke(null, null) as QueryParameterMetadata;

        if (metadata == null) return "";

        var queryParts = new List<string>();

        foreach (var (name, info) in metadata.Parameters)
        {
            // Try to find property by parameter name first, then by all properties
            var property = parameters.GetType().GetProperty(info.Name, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
            if (property == null)
            {
                // If not found by parameter name, look for property with QueryParam attribute that matches
                property = parameters.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance)
                    .FirstOrDefault(p => 
                    {
                        var attr = p.GetCustomAttribute<QueryParamAttribute>();
                        var paramName = attr?.Name ?? p.Name.ToLowerInvariant();
                        return paramName == name;
                    });
            }
            if (property == null) continue;

            var value = property.GetValue(parameters);

            if (Equals(value, info.DefaultValue)) continue;

            if (value is IEnumerable<string> collection)
            {
                foreach (var item in collection)
                {
                    queryParts.Add($"{Uri.EscapeDataString(name)}={Uri.EscapeDataString(item)}");
                }
            }
            else if (value != null)
            {
                var stringValue = value switch
                {
                    DateTime dt => dt.ToString("O"),
                    DateTimeOffset dto => dto.ToString("O"),
                    bool b => b.ToString().ToLowerInvariant(),
                    Enum e => e.ToString().ToLowerInvariant(),
                    _ => value.ToString()
                };

                if (!string.IsNullOrEmpty(stringValue))
                {
                    queryParts.Add($"{Uri.EscapeDataString(name)}={Uri.EscapeDataString(stringValue)}");
                }
            }
        }

        return string.Join("&", queryParts);
    }

    private static string BuildQueryString(object? parameters)
    {
        if (parameters == null) return "";

        if (parameters is IQueryParameters queryParams)
        {
            return BuildQueryString(queryParams);
        }

        // Fallback for generic objects - use reflection to get properties
        var queryParts = new List<string>();
        var properties = parameters.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);

        foreach (var property in properties)
        {
            var value = property.GetValue(parameters);
            if (value == null) continue;

            var name = property.Name.ToLowerInvariant();
            
            if (value is IEnumerable<string> collection)
            {
                foreach (var item in collection)
                {
                    queryParts.Add($"{Uri.EscapeDataString(name)}={Uri.EscapeDataString(item)}");
                }
            }
            else
            {
                var stringValue = value switch
                {
                    DateTime dt => dt.ToString("O"),
                    DateTimeOffset dto => dto.ToString("O"),
                    bool b => b.ToString().ToLowerInvariant(),
                    Enum e => e.ToString().ToLowerInvariant(),
                    _ => value.ToString()
                };

                if (!string.IsNullOrEmpty(stringValue))
                {
                    queryParts.Add($"{Uri.EscapeDataString(name)}={Uri.EscapeDataString(stringValue)}");
                }
            }
        }

        return string.Join("&", queryParts);
    }
}

/// <summary>
/// Extension methods for URL building
/// </summary>
public static class UrlBuilderExtensions
{
    public static string ToUrl<TRoute>(this TRoute route) where TRoute : IRoute<TRoute>
        => UrlBuilder.BuildUrl(route);

    public static string ToUrl<TRoute, TQuery>(this TRoute route, TQuery query)
        where TRoute : IRoute<TRoute>
        where TQuery : IQueryParameters
        => UrlBuilder.BuildUrl(route, query);

    public static Uri ToUri<TRoute>(this TRoute route, string? baseUrl = null)
        where TRoute : IRoute<TRoute>
    {
        var path = route.ToUrl();
        return string.IsNullOrEmpty(baseUrl)
            ? new Uri(path, UriKind.Relative)
            : new Uri(new Uri(baseUrl), path);
    }
}

/// <summary>
/// Legacy compatibility - generates URLs from route instances
/// </summary>
public static class RouteUrlGenerator
{
    private static readonly ConcurrentDictionary<Type, Func<object, string>> _generatorCache = new();

    /// <summary>
    /// Generate URL from a route instance
    /// </summary>
    [SuppressMessage("Design", "CA1055:URI-like return values should not be strings", Justification = "Internal utility for URL string generation; conversion to Uri happens at API boundary")]
    public static string GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        return UrlBuilder.BuildUrl(route);
    }

    /// <summary>
    /// Generate URL from a route instance (non-generic)
    /// </summary>
    [SuppressMessage("Design", "CA1055:URI-like return values should not be strings", Justification = "Internal utility for URL string generation; conversion to Uri happens at API boundary")]
    public static string GenerateUrl(object route)
    {
        ArgumentNullException.ThrowIfNull(route);
        
        var routeType = route.GetType();
        var generator = _generatorCache.GetOrAdd(routeType, CreateGenerator);
        return generator(route);
    }

    private static Func<object, string> CreateGenerator(Type routeType)
    {
        return (object routeInstance) =>
        {
            var template = RouteTemplateGenerator.Generate(routeType);
            
            if (!template.Contains('{', StringComparison.Ordinal))
            {
                return template;
            }

            var url = new StringBuilder(template);
            
            var properties = routeType.GetProperties(BindingFlags.Public | BindingFlags.Instance);
            foreach (var property in properties)
            {
#pragma warning disable CA1308 // URLs conventionally use lowercase parameters
                var paramName = property.Name.ToLowerInvariant();
#pragma warning restore CA1308
                var paramPlaceholder = $"{{{paramName}}}";
                
                if (template.Contains(paramPlaceholder, StringComparison.Ordinal))
                {
                    var value = property.GetValue(routeInstance);
                    var stringValue = value?.ToString() ?? "";
                    url.Replace(paramPlaceholder, Uri.EscapeDataString(stringValue));
                }
            }

            var constructors = routeType.GetConstructors();
            var primaryConstructor = constructors.FirstOrDefault(c => c.GetParameters().Length > 0);
            
            if (primaryConstructor != null)
            {
                var parameters = primaryConstructor.GetParameters();
                foreach (var parameter in parameters)
                {
#pragma warning disable CA1308 // URLs conventionally use lowercase parameters
                    var paramName = parameter.Name!.ToLowerInvariant();
#pragma warning restore CA1308
                    var paramPlaceholder = $"{{{paramName}}}";
                    
                    if (template.Contains(paramPlaceholder, StringComparison.Ordinal))
                    {
                        var property = properties.FirstOrDefault(p => 
                            string.Equals(p.Name, parameter.Name, StringComparison.OrdinalIgnoreCase));
                        
                        if (property != null)
                        {
                            var value = property.GetValue(routeInstance);
                            var stringValue = value?.ToString() ?? "";
                            url.Replace(paramPlaceholder, Uri.EscapeDataString(stringValue));
                        }
                    }
                }
            }

            return url.ToString();
        };
    }

    /// <summary>
    /// Generate URL with query parameters
    /// </summary>
    [SuppressMessage("Design", "CA1055:URI-like return values should not be strings", Justification = "Internal utility for URL string generation; conversion to Uri happens at API boundary")]
    public static string GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) 
        where TRoute : IRoute<TRoute>
    {
        var baseUrl = GenerateUrl(route);
        
        if (queryParameters == null)
        {
            return baseUrl;
        }

        var queryString = BuildLegacyQueryString(queryParameters);
        return string.IsNullOrEmpty(queryString) ? baseUrl : $"{baseUrl}?{queryString}";
    }

    private static string BuildLegacyQueryString(object queryParameters)
    {
        var properties = queryParameters.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
        var queryParts = new List<string>();

        foreach (var property in properties)
        {
            var value = property.GetValue(queryParameters);
            if (value != null)
            {
#pragma warning disable CA1308 // URLs conventionally use lowercase parameters
                var key = property.Name.ToLowerInvariant();
#pragma warning restore CA1308
                
                if (value is System.Collections.IEnumerable enumerable and not string)
                {
                    foreach (var item in enumerable)
                    {
                        if (item != null)
                        {
                            queryParts.Add($"{Uri.EscapeDataString(key)}={Uri.EscapeDataString(item.ToString()!)}");
                        }
                    }
                }
                else
                {
                    queryParts.Add($"{Uri.EscapeDataString(key)}={Uri.EscapeDataString(value.ToString()!)}");
                }
            }
        }

        return string.Join("&", queryParts);
    }
}