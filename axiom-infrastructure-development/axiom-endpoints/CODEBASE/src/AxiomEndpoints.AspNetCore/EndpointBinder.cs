using System.Globalization;
using System.Net.Http;
using System.Text.Json;
using Microsoft.AspNetCore.Http;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Handles binding of requests from HTTP context to endpoint parameter types
/// </summary>
public static class EndpointBinder
{
    /// <summary>
    /// Binds request data to the specified type based on HTTP method
    /// </summary>
    public static async ValueTask<object?> BindRequestAsync(HttpContext httpContext, Type requestType)
    {
        ArgumentNullException.ThrowIfNull(httpContext);
        ArgumentNullException.ThrowIfNull(requestType);

        // Handle binding based on HTTP method
        if (httpContext.Request.Method == HttpMethod.Get.Method || 
            httpContext.Request.Method == HttpMethod.Delete.Method)
        {
            // Bind from route and query parameters
            return BindFromRoute(httpContext, requestType);
        }
        else
        {
            // Bind from request body
            return await BindFromBodyAsync(httpContext, requestType);
        }
    }

    /// <summary>
    /// Binds request data from route values and query parameters
    /// </summary>
    public static object? BindFromRoute(HttpContext context, Type requestType)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(requestType);

        // Handle simple types first
        if (requestType.IsPrimitive || requestType == typeof(string) || requestType == typeof(Guid))
        {
            return BindSimpleType(context, requestType);
        }

        // Handle complex types using constructor binding
        return BindComplexType(context, requestType);
    }

    /// <summary>
    /// Binds request data from JSON body
    /// </summary>
    public static async ValueTask<object?> BindFromBodyAsync(HttpContext context, Type requestType)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(requestType);

        if (context.Request.ContentLength == 0)
        {
            return GetDefaultValue(requestType);
        }

        try
        {
            return await context.Request.ReadFromJsonAsync(requestType, context.RequestAborted);
        }
        catch (JsonException)
        {
            // Return default value for invalid JSON
            return GetDefaultValue(requestType);
        }
    }

    /// <summary>
    /// Binds route parameters to a specific parameter by name
    /// </summary>
    public static T? BindRouteParameter<T>(HttpContext context, string parameterName) where T : IParsable<T>
    {
        if (context.Request.RouteValues.TryGetValue(parameterName, out var value) &&
            value is string stringValue &&
            T.TryParse(stringValue, null, out var result))
        {
            return result;
        }
        return default;
    }

    /// <summary>
    /// Binds query parameters to a specific parameter by name
    /// </summary>
    public static T? BindQueryParameter<T>(HttpContext context, string parameterName) where T : IParsable<T>
    {
        if (context.Request.Query.TryGetValue(parameterName, out var values) &&
            values.Count > 0 &&
            !string.IsNullOrEmpty(values[0]) &&
            T.TryParse(values[0], null, out var result))
        {
            return result;
        }
        return default;
    }

    /// <summary>
    /// Binds multiple query parameters with the same name
    /// </summary>
    public static IEnumerable<T> BindQueryParameters<T>(HttpContext context, string parameterName) where T : IParsable<T>
    {
        if (context.Request.Query.TryGetValue(parameterName, out var values))
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

    private static object? BindSimpleType(HttpContext context, Type requestType)
    {
        // For simple types, try to get from route values first, then query parameters
        var routeValue = context.Request.RouteValues.Values.FirstOrDefault();
        if (routeValue != null)
        {
            return ConvertValue(routeValue, requestType);
        }

        var queryParam = context.Request.Query.FirstOrDefault();
        if (queryParam.Value.Count > 0)
        {
            return ConvertValue(queryParam.Value[0], requestType);
        }

        return GetDefaultValue(requestType);
    }

    private static object? BindComplexType(HttpContext context, Type requestType)
    {
        // Try to bind using constructor parameters
        var constructor = requestType.GetConstructors().FirstOrDefault();
        if (constructor != null)
        {
            var parameters = constructor.GetParameters();
            var values = new object?[parameters.Length];

            for (int i = 0; i < parameters.Length; i++)
            {
                var param = parameters[i];
                var paramName = param.Name!;

                // Try route values first (case-insensitive)
                var routeKey = context.Request.RouteValues.Keys.FirstOrDefault(k => 
                    string.Equals(k, paramName, StringComparison.OrdinalIgnoreCase));
                if (routeKey != null && context.Request.RouteValues.TryGetValue(routeKey, out var routeValue))
                {
                    values[i] = ConvertValue(routeValue, param.ParameterType);
                }
                // Then try query parameters (case-insensitive)
                else if (context.Request.Query.TryGetValue(paramName, out var queryValues) && queryValues.Count > 0)
                {
                    values[i] = ConvertValue(queryValues[0], param.ParameterType);
                }
                // Use default value for optional parameters
                else if (param.HasDefaultValue)
                {
                    values[i] = param.DefaultValue;
                }
                else
                {
                    values[i] = GetDefaultValue(param.ParameterType);
                }
            }

            return Activator.CreateInstance(requestType, values);
        }

        // Fallback to default constructor
        return Activator.CreateInstance(requestType);
    }

    private static object? ConvertValue(object? value, Type targetType)
    {
        if (value == null)
        {
            return GetDefaultValue(targetType);
        }

        if (targetType.IsAssignableFrom(value.GetType()))
        {
            return value;
        }

        try
        {
            // Handle Guid types specifically since Convert.ChangeType doesn't support them
            if (targetType == typeof(Guid) && value is string stringValue)
            {
                return Guid.Parse(stringValue);
            }
            
            // Handle nullable Guid types
            if (targetType == typeof(Guid?) && value is string nullableStringValue)
            {
                return Guid.Parse(nullableStringValue);
            }

            // Handle other nullable types
            if (targetType.IsGenericType && targetType.GetGenericTypeDefinition() == typeof(Nullable<>))
            {
                var underlyingType = Nullable.GetUnderlyingType(targetType)!;
                
                // Handle nullable Guid specifically
                if (underlyingType == typeof(Guid) && value is string nullableGuidString)
                {
                    return Guid.Parse(nullableGuidString);
                }
                
                var convertedValue = Convert.ChangeType(value, underlyingType, CultureInfo.InvariantCulture);
                return convertedValue;
            }

            return Convert.ChangeType(value, targetType, CultureInfo.InvariantCulture);
        }
        catch
        {
            return GetDefaultValue(targetType);
        }
    }

    private static object? GetDefaultValue(Type type)
    {
        return type.IsValueType ? Activator.CreateInstance(type) : null;
    }
}