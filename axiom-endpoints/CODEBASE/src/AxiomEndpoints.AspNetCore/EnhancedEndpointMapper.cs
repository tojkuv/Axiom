using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Middleware;
using AxiomEndpoints.Routing;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;
using System.Text.Json;

namespace AxiomEndpoints.AspNetCore;

public static class EnhancedEndpointMapper
{
    public static WebApplication UseAxiomEndpointsWithMiddleware(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);
        
        // Enable WebSocket middleware for bidirectional streaming
        app.UseWebSockets();
        
        // Use generated mapping - the source generator will create MiddlewarePipelines class
        // This is now the primary way to map endpoints with middleware
        var options = app.Services.GetRequiredService<AxiomOptions>();
        var endpointTypes = options.AssembliesToScan
            .SelectMany(a => a.GetTypes())
            .Where(ServiceCollectionExtensions.IsEndpointType);

        foreach (var endpointType in endpointTypes)
        {
            MapEndpointWithMiddleware(app, endpointType);
        }

        return app;
    }

    public static void MapEndpointWithMiddleware(
        WebApplication app,
        Type endpointType)
    {
        var metadata = ExtractEndpointMetadata(endpointType);
        var handler = CreateEnhancedHandler(endpointType, metadata);

        var builder = metadata.Method.Method switch
        {
            "GET" => app.MapGet(metadata.Template, handler),
            "POST" => app.MapPost(metadata.Template, handler),
            "PUT" => app.MapPut(metadata.Template, handler),
            "DELETE" => app.MapDelete(metadata.Template, handler),
            _ => throw new NotSupportedException($"HTTP method {metadata.Method} is not supported")
        };

        // Configure based on attributes
        ConfigureEndpoint(builder, metadata);
    }

    private static EndpointMetadata ExtractEndpointMetadata(Type endpointType)
    {
        var template = GetRouteTemplate(endpointType);
        var method = GetHttpMethod(endpointType);
        var requiresAuth = HasAttribute<AuthorizeAttribute>(endpointType);
        var allowAnonymous = HasAttribute<AllowAnonymousAttribute>(endpointType);
        var authPolicy = GetAttributeProperty<AuthorizeAttribute, string>(endpointType, "Policy");
        var rateLimitPolicy = GetAttributeProperty<RateLimitAttribute, string>(endpointType, "Policy");
        var corsPolicy = GetAttributeProperty<CorsAttribute, string>(endpointType, "PolicyName");
        var cacheDuration = GetAttributeProperty<CacheAttribute, int>(endpointType, "DurationSeconds");
        var cacheVaryByQuery = GetAttributeProperty<CacheAttribute, string>(endpointType, "VaryByQuery");
        var cacheVaryByHeader = GetAttributeProperty<CacheAttribute, string>(endpointType, "VaryByHeader");

        return new EndpointMetadata
        {
            EndpointType = endpointType,
            Template = template,
            Method = method,
            RequiresAuthorization = requiresAuth,
            AuthorizationPolicy = authPolicy,
            AllowAnonymous = allowAnonymous,
            RateLimitPolicy = !string.IsNullOrEmpty(rateLimitPolicy) 
                ? new RateLimitPolicyInfo { PolicyName = rateLimitPolicy } 
                : null,
            CorsPolicy = corsPolicy,
            CacheDuration = cacheDuration,
            CacheVaryByQuery = cacheVaryByQuery,
            CacheVaryByHeader = cacheVaryByHeader
        };
    }

    private static Delegate CreateEnhancedHandler(Type endpointType, EndpointMetadata metadata)
    {
        var interfaces = endpointType.GetInterfaces();
        
        // Try to find the Axiom interface to determine request/response types
        var axiomInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            (i.GetGenericTypeDefinition() == typeof(IAxiom<,>) ||
             i.GetGenericTypeDefinition() == typeof(IAxiom<,,>) ||
             i.GetGenericTypeDefinition() == typeof(IRouteAxiom<,>)));

        if (axiomInterface == null)
        {
            throw new InvalidOperationException($"Endpoint {endpointType.Name} does not implement a recognized Axiom interface");
        }

        var genericArgs = axiomInterface.GetGenericArguments();
        
        Type requestType;
        Type responseType;

        if (axiomInterface.GetGenericTypeDefinition() == typeof(IAxiom<,>))
        {
            requestType = genericArgs[0];
            responseType = genericArgs[1];
        }
        else if (axiomInterface.GetGenericTypeDefinition() == typeof(IAxiom<,,>))
        {
            requestType = genericArgs[1]; // Skip route type
            responseType = genericArgs[2];
        }
        else // IRouteAxiom<,>
        {
            requestType = genericArgs[0]; // Route type is the request
            responseType = genericArgs[1];
        }

        // This would be source-generated for optimal performance
        return async (HttpContext httpContext) =>
        {
            var services = httpContext.RequestServices;
            var endpoint = services.GetRequiredService(endpointType);
            var context = services.GetRequiredService<IContext>();
            
            // Get middleware pipeline factory
            var pipelineFactory = services.GetService<MiddlewarePipelineFactory>();
            
            if (pipelineFactory != null)
            {
                // Use reflection to call the generic method
                var getOrCreateMethod = typeof(MiddlewarePipelineFactory)
                    .GetMethod("GetOrCreate", new[] { typeof(Type) })!
                    .MakeGenericMethod(requestType, responseType);
                
                var pipeline = getOrCreateMethod.Invoke(pipelineFactory, new object[] { endpointType });

                // Bind request
                var request = await BindRequestAsync(httpContext, requestType, metadata);

                // Execute through pipeline using reflection
                var executeMethod = pipeline!.GetType()
                    .GetMethod("ExecuteAsync")!;

                // Create the handler function
                Func<object, IContext, ValueTask<object>> handler = async (req, ctx) =>
                {
                    var handleMethod = endpointType.GetMethod("HandleAsync")!;
                    var task = handleMethod.Invoke(endpoint, new[] { req, ctx });
                    
                    // Handle ValueTask<Result<T>> return type
                    if (task is ValueTask<object> valueTask)
                    {
                        return await valueTask;
                    }
                    else if (task != null)
                    {
                        // Use reflection to await the task
                        var awaiter = task.GetType().GetMethod("GetAwaiter")!.Invoke(task, null);
                        var isCompleted = (bool)awaiter!.GetType().GetProperty("IsCompleted")!.GetValue(awaiter)!;
                        
                        if (!isCompleted)
                        {
                            var getResultMethod = awaiter.GetType().GetMethod("GetResult")!;
                            await Task.Delay(0); // Allow task to complete
                        }
                        
                        var getResult = awaiter.GetType().GetMethod("GetResult")!;
                        return getResult.Invoke(awaiter, null)!;
                    }
                    
                    throw new InvalidOperationException("Invalid endpoint method signature");
                };

                var result = await (ValueTask<object>)executeMethod.Invoke(pipeline, new object[] { request!, context, handler })!;
                return GenerateResponse(result, httpContext);
            }
            else
            {
                // Fallback to direct endpoint execution
                var request = await BindRequestAsync(httpContext, requestType, metadata);
                var handleMethod = endpointType.GetMethod("HandleAsync")!;
                var task = handleMethod.Invoke(endpoint, new[] { request, context });
                var result = await (ValueTask<object>)task!;
                return GenerateResponse(result, httpContext);
            }
        };
    }

    private static async ValueTask<object?> BindRequestAsync(HttpContext httpContext, Type requestType, EndpointMetadata metadata)
    {
        if (metadata.Method == HttpMethod.Get || metadata.Method == HttpMethod.Delete)
        {
            // Bind from route and query parameters
            return BindFromRoute(httpContext, requestType);
        }
        else
        {
            // Bind from request body
            return await httpContext.Request.ReadFromJsonAsync(requestType);
        }
    }

    private static object? BindFromRoute(HttpContext context, Type requestType)
    {
        // Simple implementation - real version would use source generation
        if (requestType.GetConstructors().FirstOrDefault() is { } constructor)
        {
            var parameters = constructor.GetParameters();
            var values = new object?[parameters.Length];

            for (int i = 0; i < parameters.Length; i++)
            {
                var param = parameters[i];
                if (context.Request.RouteValues.TryGetValue(param.Name!, out var value))
                {
                    values[i] = Convert.ChangeType(value, param.ParameterType, System.Globalization.CultureInfo.InvariantCulture);
                }
                else if (context.Request.Query.TryGetValue(param.Name!, out var queryValues) && queryValues.Count > 0)
                {
                    values[i] = Convert.ChangeType(queryValues[0], param.ParameterType, System.Globalization.CultureInfo.InvariantCulture);
                }
            }

            return Activator.CreateInstance(requestType, values);
        }

        return Activator.CreateInstance(requestType);
    }

    private static IResult GenerateResponse(object result, HttpContext httpContext)
    {
        // Handle Result<T> response
        var resultType = result.GetType();
        var isSuccessProperty = resultType.GetProperty("IsSuccess");
        
        if (isSuccessProperty != null && isSuccessProperty.GetValue(result) is bool isSuccess)
        {
            if (isSuccess)
            {
                var valueProperty = resultType.GetProperty("Value");
                var value = valueProperty?.GetValue(result);
                return Results.Ok(value);
            }
            else
            {
                var errorProperty = resultType.GetProperty("Error");
                var error = errorProperty?.GetValue(result);
                
                if (error != null)
                {
                    var errorType = error.GetType();
                    var typeProperty = errorType.GetProperty("Type");
                    var messageProperty = errorType.GetProperty("Message");
                    
                    var type = typeProperty?.GetValue(error);
                    var message = messageProperty?.GetValue(error)?.ToString();
                    
                    return type?.ToString() switch
                    {
                        "NotFound" => Results.NotFound(error),
                        "Unauthorized" => Results.Unauthorized(),
                        "Forbidden" => Results.Forbid(),
                        "Validation" => Results.BadRequest(error),
                        "TooManyRequests" => Results.StatusCode(429),
                        _ => Results.Problem(message ?? "An error occurred")
                    };
                }
                
                return Results.BadRequest(result);
            }
        }

        // Fallback for non-Result types
        return Results.Ok(result);
    }

    private static void ConfigureEndpoint(RouteHandlerBuilder builder, EndpointMetadata metadata)
    {
        // Apply authentication/authorization
        if (metadata.RequiresAuthorization)
        {
            if (!string.IsNullOrEmpty(metadata.AuthorizationPolicy))
            {
                builder.RequireAuthorization(metadata.AuthorizationPolicy);
            }
            else
            {
                builder.RequireAuthorization();
            }
        }
        else if (metadata.AllowAnonymous)
        {
            builder.AllowAnonymous();
        }

        // Apply CORS
        if (!string.IsNullOrEmpty(metadata.CorsPolicy))
        {
            builder.RequireCors(metadata.CorsPolicy);
        }

        // Configure caching
        if (metadata.CacheDuration > 0)
        {
            builder.CacheOutput(policy =>
            {
                policy.Expire(TimeSpan.FromSeconds(metadata.CacheDuration));
                
                // Note: VaryByQuery API may differ in .NET 9
                // if (!string.IsNullOrEmpty(metadata.CacheVaryByQuery))
                // {
                //     foreach (var query in metadata.CacheVaryByQuery.Split(','))
                //     {
                //         policy.SetVaryByQuery(query.Trim());
                //     }
                // }
                
                // Note: VaryByHeader API may differ in .NET 9
                // if (!string.IsNullOrEmpty(metadata.CacheVaryByHeader))
                // {
                //     foreach (var header in metadata.CacheVaryByHeader.Split(','))
                //     {
                //         policy.SetVaryByHeader(header.Trim());
                //     }
                // }
            });
        }

        // Add OpenAPI metadata
        builder.WithOpenApi(operation =>
        {
            operation.Summary = metadata.Summary;
            operation.Description = metadata.Description;
            return operation;
        });
    }

    private static string GetRouteTemplate(Type endpointType)
    {
        // Try to get template from route type
        var interfaces = endpointType.GetInterfaces();
        
        var axiomInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            (i.GetGenericTypeDefinition() == typeof(IAxiom<,,>) ||
             i.GetGenericTypeDefinition() == typeof(IRouteAxiom<,>)));

        if (axiomInterface != null)
        {
            var routeType = axiomInterface.GetGenericArguments()[0];
            return RouteTemplateGenerator.Generate(routeType);
        }

        // Fallback to endpoint name
        return $"/{endpointType.Name.ToLowerInvariant()}";
    }

    private static HttpMethod GetHttpMethod(Type endpointType)
    {
        return (HttpMethod?)endpointType
            .GetProperty("Method", BindingFlags.Public | BindingFlags.Static)?
            .GetValue(null) ?? HttpMethod.Get;
    }

    private static bool HasAttribute<T>(Type type) where T : Attribute
    {
        return type.GetCustomAttribute<T>() != null;
    }

    private static TValue? GetAttributeProperty<TAttribute, TValue>(Type type, string propertyName)
        where TAttribute : Attribute
    {
        var attribute = type.GetCustomAttribute<TAttribute>();
        if (attribute == null) return default;

        var property = typeof(TAttribute).GetProperty(propertyName);
        return property != null ? (TValue?)property.GetValue(attribute) : default;
    }
}