using System.Net.Http;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Routing;
using AxiomEndpoints.AspNetCore.Streaming;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Handles mapping of streaming endpoints (server-sent events, WebSockets, etc.)
/// </summary>
public static class StreamingMapper
{
    /// <summary>
    /// Maps a server streaming endpoint (one request, multiple responses via SSE)
    /// </summary>
    public static void MapServerStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        var template = GetRouteTemplate(endpointType, requestType);
        app.MapGet(template, CreateServerStreamHandler(endpointType, requestType, responseType));
    }

    /// <summary>
    /// Maps a client streaming endpoint (multiple requests, one response)
    /// </summary>
    public static void MapClientStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        var template = GetRouteTemplate(endpointType, requestType);
        app.MapPost(template, CreateClientStreamHandler(endpointType, requestType, responseType));
    }

    /// <summary>
    /// Maps a bidirectional streaming endpoint (multiple requests and responses via WebSockets)
    /// </summary>
    public static void MapBidirectionalStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        var template = GetRouteTemplate(endpointType, requestType);
        app.MapGet(template, CreateBidirectionalStreamHandler(endpointType, requestType, responseType));
    }

    private static string GetRouteTemplate(Type endpointType, Type requestType)
    {
        // For streaming endpoints, try to extract route template from request type
        // If request type implements IRoute, use its template
        var routeInterface = requestType.GetInterfaces()
            .FirstOrDefault(i => i.IsGenericType && 
                               i.GetGenericTypeDefinition().IsAssignableFrom(typeof(IRoute<>).GetGenericTypeDefinition()));

        if (routeInterface != null)
        {
            return RouteTemplateGenerator.Generate(requestType);
        }

        // Otherwise, use endpoint type name as route
#pragma warning disable CA1308 // URLs conventionally use lowercase routes
        return $"/{endpointType.Name.ToLowerInvariant()}";
#pragma warning restore CA1308
    }

    private static Delegate CreateServerStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Bind request from route/query parameters
            var request = EndpointBinder.BindFromRoute(httpContext, requestType);

            // Check Accept header for SSE vs JSON
            if (httpContext.Request.Headers.Accept.Contains("text/event-stream"))
            {
                // Use the new SSE handler
                var handleSseMethod = typeof(ServerSentEventsHandler)
                    .GetMethod("HandleSseAsync")!
                    .MakeGenericMethod(requestType, responseType);
                
                await (Task)handleSseMethod.Invoke(null, [httpContext, endpoint, request, context])!;
            }
            else
            {
                // Return first N items as JSON array for compatibility
                var streamMethod = endpointType.GetMethod("StreamAsync")!;
                var streamResult = streamMethod.Invoke(endpoint, [request, context]);
                
                if (streamResult is IAsyncEnumerable<object> asyncEnumerable)
                {
                    var items = await asyncEnumerable
                        .Take(100)
                        .ToListAsync(httpContext.RequestAborted);
                    
                    httpContext.Response.ContentType = "application/json";
                    await httpContext.Response.WriteAsJsonAsync(items, httpContext.RequestAborted);
                }
            }
        };
    }

    private static Delegate CreateClientStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Read streaming request from body
            var requestStream = ReadRequestStream(httpContext, requestType);

            // Invoke client streaming method
            var handleMethod = endpointType.GetMethod("HandleAsync")!;
            var resultTask = (ValueTask<object>)handleMethod.Invoke(endpoint, [requestStream, context])!;
            var result = await resultTask.ConfigureAwait(false);

            return ProcessStreamingResult(result);
        };
    }

    private static Delegate CreateBidirectionalStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        return async (HttpContext httpContext) =>
        {
            var endpoint = httpContext.RequestServices.GetRequiredService(endpointType);
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Use the new WebSocket handler
            var handleWebSocketMethod = typeof(WebSocketHandler)
                .GetMethod("HandleWebSocketAsync")!
                .MakeGenericMethod(requestType, responseType);
            
            await (Task)handleWebSocketMethod.Invoke(null, [httpContext, endpoint, context])!;
        };
    }

    private static async IAsyncEnumerable<object> ReadRequestStream(HttpContext httpContext, Type requestType)
    {
        using var reader = new StreamReader(httpContext.Request.Body);
        string? line;
        
        while ((line = await reader.ReadLineAsync().ConfigureAwait(false)) != null)
        {
            if (!string.IsNullOrWhiteSpace(line))
            {
                var item = JsonSerializer.Deserialize(line, requestType);
                if (item != null)
                    yield return item;
            }
        }
    }

    private static async IAsyncEnumerable<object> ReadWebSocketStream(
        System.Net.WebSockets.WebSocket webSocket,
        Type requestType,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var buffer = new byte[4096];
        
        while (!cancellationToken.IsCancellationRequested && 
               webSocket.State == System.Net.WebSockets.WebSocketState.Open)
        {
            var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellationToken).ConfigureAwait(false);
            
            if (result.MessageType == System.Net.WebSockets.WebSocketMessageType.Text)
            {
                var json = Encoding.UTF8.GetString(buffer, 0, result.Count);
                var item = JsonSerializer.Deserialize(json, requestType);
                if (item != null)
                    yield return item;
            }
            else if (result.MessageType == System.Net.WebSockets.WebSocketMessageType.Close)
            {
                break;
            }
        }
    }

    private static IResult ProcessStreamingResult(object result)
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