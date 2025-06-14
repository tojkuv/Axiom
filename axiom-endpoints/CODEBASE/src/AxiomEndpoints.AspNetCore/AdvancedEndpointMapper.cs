using System.Collections.Frozen;
using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Middleware;
using AxiomEndpoints.Routing;

namespace AxiomEndpoints.AspNetCore;

public static class AdvancedEndpointMapper
{
    public static void MapAdvancedEndpoint(
        WebApplication app,
        Type endpointType,
        EndpointMetadata metadata)
    {
        var builder = metadata.Method.Method switch
        {
            "GET" => app.MapGet(metadata.Template, CreateAdvancedHandler(endpointType, metadata)),
            "POST" => app.MapPost(metadata.Template, CreateAdvancedHandler(endpointType, metadata)),
            "PUT" => app.MapPut(metadata.Template, CreateAdvancedHandler(endpointType, metadata)),
            "DELETE" => app.MapDelete(metadata.Template, CreateAdvancedHandler(endpointType, metadata)),
            "PATCH" => app.MapPatch(metadata.Template, CreateAdvancedHandler(endpointType, metadata)),
            _ => throw new NotSupportedException($"HTTP method {metadata.Method} is not supported")
        };

        // Add constraints
        foreach (var (param, constraint) in metadata.Constraints)
        {
            // builder.WithRouteConstraint(param, constraint.ConstraintString); // Method not available in this ASP.NET version
        }

        // Add metadata
        builder.WithMetadata(metadata);

        // Add version metadata
        if (metadata.Version != null)
        {
            // builder.WithApiVersionSet(CreateVersionSet(metadata.Version)); // Method not available in this ASP.NET version
        }

        // Add authentication
        if (metadata.RequiresAuthentication)
        {
            if (metadata.RequiredRoles.Any())
            {
                builder.RequireAuthorization(policy => policy.RequireRole(metadata.RequiredRoles));
            }
            else if (metadata.RequiredPolicies.Any())
            {
                builder.RequireAuthorization(metadata.RequiredPolicies.ToArray());
            }
            else
            {
                builder.RequireAuthorization();
            }
        }

        // Add rate limiting
        if (metadata.RateLimitPolicy != null)
        {
            builder.RequireRateLimiting(CreateRateLimitPolicy(metadata.RateLimitPolicy));
        }

        // Add caching
        if (metadata.CachePolicy != null)
        {
            ConfigureCaching(builder, metadata.CachePolicy);
        }

        // Configure OpenAPI - commented out due to compatibility issues
        // builder.WithOpenApi(operation =>
        // {
        //     if (metadata.Documentation != null)
        //     {
        //         operation.OperationId = $"{endpointType.Name}";
        //         operation.Summary = metadata.Documentation.Summary;
        //         operation.Description = metadata.Documentation.Description;
        //         operation.Tags = metadata.Documentation.Tags.Select(tag => new OpenApiTag { Name = tag }).ToList();
        //         operation.Deprecated = metadata.Documentation.Deprecated;
        //
        //         // Add parameter descriptions
        //         foreach (var param in operation.Parameters)
        //         {
        //             if (metadata.Documentation.ParameterDescriptions.TryGetValue(param.Name, out var description))
        //             {
        //                 param.Description = description;
        //             }
        //         }
        //
        //         // Add response descriptions
        //         foreach (var (code, desc) in metadata.Documentation.ResponseDescriptions)
        //         {
        //             if (operation.Responses.TryGetValue(code.ToString(), out var response))
        //             {
        //                 response.Description = desc;
        //             }
        //         }
        //     }
        //
        //     return operation;
        // });
    }

    private static Delegate CreateAdvancedHandler(Type endpointType, EndpointMetadata metadata)
    {
        return async (HttpContext context) =>
        {
            var endpoint = context.RequestServices.GetRequiredService(endpointType);
            var axiomContext = context.RequestServices.GetRequiredService<IContext>();

            // Validate route constraints
            var routeValidationResult = ValidateRouteConstraints(context.Request.RouteValues, metadata.Constraints);
            if (!routeValidationResult.IsValid)
            {
                return Results.BadRequest(new
                {
                    error = routeValidationResult.ErrorMessage,
                    parameter = routeValidationResult.ParameterName
                });
            }

            // Bind route parameters
            var routeValues = new Dictionary<string, object>();
            foreach (var (key, value) in context.Request.RouteValues)
            {
                routeValues[key] = value!;
            }

            // Bind query parameters
            if (metadata.HasQueryParameters)
            {
                var queryResult = BindQueryParameters(context.Request.Query, metadata.QueryMetadata!);
                if (!queryResult.IsSuccess)
                {
                    return Results.BadRequest(queryResult.Errors);
                }

                // Merge query parameters into route values
                foreach (var (key, value) in queryResult.Values)
                {
                    routeValues[key] = value;
                }
            }

            // Handle request body binding
            object? requestBody = null;
            if (metadata.Method.Method != "GET" && metadata.Method.Method != "DELETE")
            {
                requestBody = await BindRequestBody(context, metadata.RequestType);
            }

            // Create request object
            var request = CreateRequest(endpointType, routeValues, requestBody, metadata);

            // Execute endpoint
            var handleMethod = endpointType.GetMethod("HandleAsync")!;
            dynamic task = handleMethod.Invoke(endpoint, [request, axiomContext])!;
            var result = await task;

            // Handle response
            return HandleResult(result, context, metadata);
        };
    }

    private static AxiomEndpoints.Core.Middleware.ConstraintValidationResult ValidateRouteConstraints(
        RouteValueDictionary routeValues, 
        FrozenDictionary<string, AxiomEndpoints.Core.IRouteConstraint> constraints)
    {
        foreach (var (paramName, constraint) in constraints)
        {
            if (routeValues.TryGetValue(paramName, out var value))
            {
                if (!constraint.IsValid(value?.ToString()))
                {
                    return AxiomEndpoints.Core.Middleware.ConstraintValidationResult.Failure(constraint.ErrorMessage, paramName);
                }
            }
        }

        return AxiomEndpoints.Core.Middleware.ConstraintValidationResult.Success();
    }

    private static async Task<object?> BindRequestBody(HttpContext context, Type? requestType)
    {
        if (requestType == null) return null;

        try
        {
            return await context.Request.ReadFromJsonAsync(requestType);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Failed to bind request body to type {requestType.Name}", ex);
        }
    }

    private static QueryBindingResult BindQueryParameters(IQueryCollection query, AxiomEndpoints.Core.QueryParameterMetadata metadata)
    {
        var values = new Dictionary<string, object>();
        var errors = new List<string>();

        foreach (var (name, info) in metadata.Parameters)
        {
            if (query.TryGetValue(name, out var queryValues))
            {
                try
                {
                    var value = ConvertQueryValue(queryValues, info.Type);
                    
                    // Validate constraint
                    if (info.Constraint != null && !info.Constraint.IsValid(value?.ToString()))
                    {
                        errors.Add($"Parameter '{name}': {info.Constraint.ErrorMessage}");
                        continue;
                    }

                    values[name] = value!;
                }
                catch (Exception ex)
                {
                    errors.Add($"Parameter '{name}': {ex.Message}");
                }
            }
            else if (info.IsRequired)
            {
                errors.Add($"Required parameter '{name}' is missing");
            }
            else if (info.DefaultValue != null)
            {
                values[name] = info.DefaultValue;
            }
        }

        return new QueryBindingResult(errors.Count == 0, values, errors);
    }

    private static object? ConvertQueryValue(Microsoft.Extensions.Primitives.StringValues values, Type targetType)
    {
        if (values.Count == 0) return null;

        // Handle collections
        if (targetType.IsAssignableFrom(typeof(IEnumerable<string>)))
        {
            return values.ToArray();
        }

        if (targetType.IsGenericType && targetType.GetGenericTypeDefinition() == typeof(IReadOnlyList<>))
        {
            var elementType = targetType.GetGenericArguments()[0];
            var list = values.Select(v => Convert.ChangeType(v, elementType)).ToList();
            return list;
        }

        // Handle single values
        var stringValue = values.First();
        if (string.IsNullOrEmpty(stringValue)) return null;

        // Handle common types
        return targetType switch
        {
            Type t when t == typeof(string) => stringValue,
            Type t when t == typeof(int) => int.Parse(stringValue),
            Type t when t == typeof(long) => long.Parse(stringValue),
            Type t when t == typeof(decimal) => decimal.Parse(stringValue),
            Type t when t == typeof(double) => double.Parse(stringValue),
            Type t when t == typeof(float) => float.Parse(stringValue),
            Type t when t == typeof(bool) => bool.Parse(stringValue),
            Type t when t == typeof(Guid) => Guid.Parse(stringValue),
            Type t when t == typeof(DateTime) => DateTime.Parse(stringValue),
            Type t when t == typeof(DateTimeOffset) => DateTimeOffset.Parse(stringValue),
            Type t when t.IsEnum => Enum.Parse(targetType, stringValue, true),
            _ => Convert.ChangeType(stringValue, targetType)
        };
    }

    private static object CreateRequest(Type endpointType, Dictionary<string, object> values, object? body, AxiomEndpoints.Core.Middleware.EndpointMetadata metadata)
    {
        // This is a simplified version - real implementation would use source generation
        if (metadata.RequestType == null) return new object();

        var constructor = metadata.RequestType.GetConstructors().FirstOrDefault();
        if (constructor == null) return Activator.CreateInstance(metadata.RequestType)!;

        var parameters = constructor.GetParameters();
        var args = new object?[parameters.Length];

        for (int i = 0; i < parameters.Length; i++)
        {
            var param = parameters[i];
            if (values.TryGetValue(param.Name!, out var value))
            {
                args[i] = Convert.ChangeType(value, param.ParameterType);
            }
            else if (body != null && param.ParameterType.IsAssignableFrom(body.GetType()))
            {
                args[i] = body;
            }
        }

        return Activator.CreateInstance(metadata.RequestType, args)!;
    }

    private static IResult HandleResult(object result, HttpContext context, AxiomEndpoints.Core.Middleware.EndpointMetadata metadata)
    {
        // Handle response caching
        if (metadata.CachePolicy != null)
        {
            context.Response.Headers.CacheControl = $"max-age={metadata.CachePolicy.Duration.TotalSeconds}";
            
            if (metadata.CachePolicy.VaryByUser)
            {
                context.Response.Headers.Vary = "Authorization";
            }

            if (!string.IsNullOrEmpty(metadata.CachePolicy.VaryByHeader))
            {
                context.Response.Headers.Vary = metadata.CachePolicy.VaryByHeader;
            }
        }

        // Handle Result<T> types
        var resultType = result.GetType();
        if (resultType.IsGenericType && resultType.GetGenericTypeDefinition() == typeof(Result<>))
        {
            var isSuccessProperty = resultType.GetProperty("IsSuccess")!;
            var isSuccess = (bool)isSuccessProperty.GetValue(result)!;

            if (isSuccess)
            {
                var valueProperty = resultType.GetProperty("Value")!;
                var value = valueProperty.GetValue(result);
                return Results.Ok(value);
            }
            else
            {
                var errorProperty = resultType.GetProperty("Error")!;
                var error = errorProperty.GetValue(result);
                return Results.BadRequest(error);
            }
        }

        // Handle direct values
        return Results.Ok(result);
    }

    private static object CreateVersionSet(AxiomEndpoints.Core.ApiVersion version)
    {
        // This would create an actual API version set in a real implementation
        return new { Version = version.ToString() };
    }

    private static string CreateRateLimitPolicy(RateLimitPolicyInfo rateLimitPolicy)
    {
        // This would create an actual rate limit policy in a real implementation
        return rateLimitPolicy.PolicyName;
    }

    private static void ConfigureCaching(RouteHandlerBuilder builder, CachePolicyInfo cachePolicy)
    {
        builder.CacheOutput(policy =>
        {
            policy.Expire(cachePolicy.Duration);
            
            // Note: VaryByUser, VaryByHeader, VaryByQuery methods may not be available in all ASP.NET versions
            // These would need to be implemented based on the specific output caching API
        });
    }
}





internal record QueryBindingResult(
    bool IsSuccess,
    Dictionary<string, object> Values,
    List<string> Errors
);

// Extension to add advanced routing
public static class AdvancedEndpointMapperExtensions
{
    public static WebApplication UseAdvancedAxiomEndpoints(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);
        
        // Enable WebSocket middleware for bidirectional streaming
        app.UseWebSockets();
        
        // Use the enhanced generated mapping - placeholder until source generator is working
        // Generated.AdvancedEndpointRegistration.MapEndpoints(app);
        
        // Fallback implementation when source generator isn't available
        app.MapGet("/health", () => "Healthy");
        
        return app;
    }
}