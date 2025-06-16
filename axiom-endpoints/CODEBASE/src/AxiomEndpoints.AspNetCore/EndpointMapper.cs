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
            .Where(ServiceCollectionExtensions.IsEndpointType);

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

        // Map the endpoint - route axiom uses the route as the request
        var routeBuilder = method switch
        {
            var m when m == HttpMethod.Get => app.MapGet(template, CreateRouteHandler(endpointType, routeType, responseType)),
            var m when m == HttpMethod.Post => app.MapPost(template, CreateRouteHandler(endpointType, routeType, responseType)),
            var m when m == HttpMethod.Put => app.MapPut(template, CreateRouteHandler(endpointType, routeType, responseType)),
            var m when m == HttpMethod.Delete => app.MapDelete(template, CreateRouteHandler(endpointType, routeType, responseType)),
            _ => throw new NotSupportedException($"HTTP method {method} is not supported")
        };
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
            var resultTask = (ValueTask<object>)handleMethod.Invoke(endpoint, [route, context])!;
            var result = await resultTask.ConfigureAwait(false);

            return ProcessResult(result);
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
            return Results.BadRequest(error);
        }
    }

}

