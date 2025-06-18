using System.Linq;
using System.Net.Http;
using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Routing;

namespace AxiomEndpoints.AspNetCore;

public static class EndpointMapper
{
    public static WebApplication UseAxiomEndpoints(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);
        
        // Enable WebSocket middleware for bidirectional streaming
        app.UseWebSockets();
        
        // Use generated mapping - placeholder until source generator is working
        // Generated.EndpointRegistration.MapEndpoints(app);
        
        // Fallback: Map endpoints not covered by generator
        var options = app.Services.GetRequiredService<AxiomOptions>();
        var endpointTypes = options.AssembliesToScan
            .SelectMany(a => a.GetTypes())
            .Where(ServiceCollectionExtensions.IsEndpointType)
            .OrderByDescending(t => GetRouteSpecificity(t)); // Register more specific routes first

        foreach (var endpointType in endpointTypes)
        {
            MapEndpoint(app, endpointType);
        }

        return app;
    }

    private static void MapEndpoint(WebApplication app, Type endpointType)
    {
        var typeInfo = EndpointTypeAnalyzer.Analyze(endpointType);

        switch (typeInfo.Kind)
        {
            case EndpointKind.ServerStream:
                StreamingMapper.MapServerStreamEndpoint(app, endpointType, typeInfo.ServerStreamInterface!);
                break;
            case EndpointKind.ClientStream:
                StreamingMapper.MapClientStreamEndpoint(app, endpointType, typeInfo.ClientStreamInterface!);
                break;
            case EndpointKind.BidirectionalStream:
                StreamingMapper.MapBidirectionalStreamEndpoint(app, endpointType, typeInfo.BidirectionalStreamInterface!);
                break;
            case EndpointKind.StandardAxiom:
                MapAxiomEndpoint(app, endpointType, typeInfo.AxiomInterface!);
                break;
            case EndpointKind.RouteAxiom:
                MapRouteAxiomEndpoint(app, endpointType, typeInfo.RouteAxiomInterface!);
                break;
            case EndpointKind.Unknown:
            default:
                // Skip unknown endpoint types
                break;
        }
    }

    private static void MapAxiomEndpoint(WebApplication app, Type endpointType, Type axiomInterface)
    {
        var routeType = axiomInterface.GetGenericArguments()[0];
        var requestType = axiomInterface.GetGenericArguments()[1];
        var responseType = axiomInterface.GetGenericArguments()[2];

        var method = GetHttpMethod(endpointType);
        var template = RouteTemplateGenerator.Generate(routeType);

        // Map the endpoint
        var routeBuilder = method switch
        {
            var m when m == HttpMethod.Get => app.MapGet(template, CreateHandler(endpointType, requestType, responseType)),
            var m when m == HttpMethod.Post => app.MapPost(template, CreateHandler(endpointType, requestType, responseType)),
            var m when m == HttpMethod.Put => app.MapPut(template, CreateHandler(endpointType, requestType, responseType)),
            var m when m == HttpMethod.Delete => app.MapDelete(template, CreateHandler(endpointType, requestType, responseType)),
            _ => throw new NotSupportedException($"HTTP method {method} is not supported")
        };
    }

    private static void MapRouteAxiomEndpoint(WebApplication app, Type endpointType, Type routeAxiomInterface)
    {
        var routeType = routeAxiomInterface.GetGenericArguments()[0];
        var responseType = routeAxiomInterface.GetGenericArguments()[1];

        var method = GetHttpMethod(endpointType);
        var template = RouteTemplateGenerator.Generate(routeType);
        
        // Debug logging
        Console.WriteLine($"[MAPPING] Endpoint: {endpointType.Name}, Route: {routeType.Name}, Method: {method}, Template: {template}");


        // Create a more direct handler that doesn't rely on complex route binding
        var handler = CreateDirectRouteHandler(endpointType, routeType, responseType);

        // Map the endpoint with explicit route template
        var routeBuilder = method switch
        {
            var m when m == HttpMethod.Get => app.MapGet(template, handler),
            var m when m == HttpMethod.Post => app.MapPost(template, handler),
            var m when m == HttpMethod.Put => app.MapPut(template, handler),
            var m when m == HttpMethod.Delete => app.MapDelete(template, handler),
            _ => throw new NotSupportedException($"HTTP method {method} is not supported")
        };
        
        // Debug route registration
        Console.WriteLine($"[ROUTE] Successfully registered {method} {template} -> {endpointType.Name}");

        // Add endpoint metadata for debugging
        routeBuilder.WithMetadata(new { EndpointType = endpointType.Name, RouteType = routeType.Name, Template = template });
    }



    private static HttpMethod GetHttpMethod(Type endpointType)
    {
        return (HttpMethod?)endpointType
            .GetProperty("Method", BindingFlags.Public | BindingFlags.Static)?
            .GetValue(null) ?? HttpMethod.Get;
    }

    private static Delegate CreateHandler(Type endpointType, Type requestType, Type responseType)
    {
        // This is a simplified version - real implementation would use source generation
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Handle request binding using EndpointBinder
            var request = await EndpointBinder.BindRequestAsync(httpContext, requestType);

            // Invoke endpoint
            var handleMethod = endpointType.GetMethod("HandleAsync")!;
            var resultTask = (ValueTask<object>)handleMethod.Invoke(endpoint, [request, context])!;
            var result = await resultTask.ConfigureAwait(false);

            return ProcessResult(result);
        };
    }

    private static Delegate CreateDirectRouteHandler(Type endpointType, Type routeType, Type responseType)
    {
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Debug logging
            Console.WriteLine($"[HANDLER] Request: {httpContext.Request.Method} {httpContext.Request.Path}");
            Console.WriteLine($"[HANDLER] Route Values: {string.Join(", ", httpContext.Request.RouteValues.Select(kv => $"{kv.Key}={kv.Value}"))}");

            // Create the specific route instance with proper parameter binding
            var route = EndpointBinder.BindFromRoute(httpContext, routeType);

            // Debug the bound route
            Console.WriteLine($"[HANDLER] Bound route: {route?.GetType().Name}, Route: {route}");

            // Fallback to parameterless constructor if binding fails
            if (route == null)
            {
                route = Activator.CreateInstance(routeType)!;
                Console.WriteLine($"[HANDLER] Used fallback route: {route}");
            }

            // Invoke endpoint
            var handleMethod = endpointType.GetMethod("HandleAsync")!;
            var resultTask = handleMethod.Invoke(endpoint, [route, context])!;
            
            // Handle the generic ValueTask properly using reflection and async/await
            var valueTaskType = resultTask.GetType();
            if (valueTaskType.IsGenericType && valueTaskType.GetGenericTypeDefinition() == typeof(ValueTask<>))
            {
                // Convert ValueTask<T> to Task<T> for easier awaiting
                var asTaskMethod = valueTaskType.GetMethod("AsTask")!;
                var task = (Task)asTaskMethod.Invoke(resultTask, null)!;
                await task.ConfigureAwait(false);
                
                // Get the result from the completed task
                var resultProperty = task.GetType().GetProperty("Result")!;
                var result = resultProperty.GetValue(task)!;
                
                return ProcessResult(result);
            }
            
            // Fallback for non-ValueTask types
            return ProcessResult(resultTask);
        };
    }
    
    private static Delegate CreateRouteHandler(Type endpointType, Type routeType, Type responseType)
    {
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Bind route from route values
            var route = EndpointBinder.BindFromRoute(httpContext, routeType);

            // Invoke endpoint
            var handleMethod = endpointType.GetMethod("HandleAsync")!;
            var resultTask = handleMethod.Invoke(endpoint, [route, context])!;
            
            // Handle the generic ValueTask properly using reflection and async/await
            var valueTaskType = resultTask.GetType();
            if (valueTaskType.IsGenericType && valueTaskType.GetGenericTypeDefinition() == typeof(ValueTask<>))
            {
                // Convert ValueTask<T> to Task<T> for easier awaiting
                var asTaskMethod = valueTaskType.GetMethod("AsTask")!;
                var task = (Task)asTaskMethod.Invoke(resultTask, null)!;
                await task.ConfigureAwait(false);
                
                // Get the result from the completed task
                var resultProperty = task.GetType().GetProperty("Result")!;
                var result = resultProperty.GetValue(task)!;
                
                return ProcessResult(result);
            }
            
            // Fallback for non-ValueTask types
            return ProcessResult(resultTask);
        };
    }

    private static IResult ProcessResult(object result)
    {
        // Handle response using reflection
        var resultProperty = result.GetType().GetProperty("IsSuccess")!;
        if ((bool)resultProperty.GetValue(result)!)
        {
            var valueProperty = result.GetType().GetProperty("Value")!;
            var value = valueProperty.GetValue(result);
            return Results.Ok(value);
        }
        else
        {
            var errorProperty = result.GetType().GetProperty("Error")!;
            var error = errorProperty.GetValue(result);
            
            // Check error type to return appropriate HTTP status code
            if (error != null)
            {
                var typeProperty = error.GetType().GetProperty("Type");
                if (typeProperty?.GetValue(error) is ErrorType errorType)
                {
                    return errorType switch
                    {
                        ErrorType.NotFound => Results.NotFound(error),
                        ErrorType.Unauthorized => Results.Unauthorized(),
                        ErrorType.Forbidden => Results.Forbid(),
                        ErrorType.Conflict => Results.Conflict(error),
                        ErrorType.TooManyRequests => Results.StatusCode(429),
                        ErrorType.Timeout => Results.StatusCode(408),
                        ErrorType.Unavailable => Results.StatusCode(503),
                        ErrorType.NotImplemented => Results.StatusCode(501),
                        _ => Results.BadRequest(error)
                    };
                }
            }
            
            return Results.BadRequest(error);
        }
    }

    private static int GetRouteSpecificity(Type endpointType)
    {
        var typeInfo = EndpointTypeAnalyzer.Analyze(endpointType);
        
        if (typeInfo.Kind == EndpointKind.RouteAxiom)
        {
            var routeType = typeInfo.RouteAxiomInterface!.GetGenericArguments()[0];
            var template = RouteTemplateGenerator.Generate(routeType);
            
            // Count the number of literal segments (non-parameter segments)
            // More literal segments = more specific route
            var segments = template.Split('/', StringSplitOptions.RemoveEmptyEntries);
            return segments.Count(s => !s.StartsWith("{"));
        }
        
        return 0; // Default specificity for non-route endpoints
    }

}

