using System.Buffers;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Linq;
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
        // Get route and method from endpoint type
        var interfaces = endpointType.GetInterfaces();
        
        // Try streaming interfaces first
        var serverStreamInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == typeof(IServerStreamAxiom<,>));

        var clientStreamInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == typeof(IClientStreamAxiom<,>));

        var bidirectionalStreamInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == typeof(IBidirectionalStreamAxiom<,>));

        // Try IAxiom<TRoute, TRequest, TResponse> 
        var axiomInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == typeof(IAxiom<,,>));

        // Try IRouteAxiom<TRoute, TResponse> 
        var routeAxiomInterface = interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == typeof(IRouteAxiom<,>));

        if (serverStreamInterface != null)
        {
            MapServerStreamEndpoint(app, endpointType, serverStreamInterface);
        }
        else if (clientStreamInterface != null)
        {
            MapClientStreamEndpoint(app, endpointType, clientStreamInterface);
        }
        else if (bidirectionalStreamInterface != null)
        {
            MapBidirectionalStreamEndpoint(app, endpointType, bidirectionalStreamInterface);
        }
        else if (axiomInterface != null)
        {
            MapAxiomEndpoint(app, endpointType, axiomInterface);
        }
        else if (routeAxiomInterface != null)
        {
            MapRouteAxiomEndpoint(app, endpointType, routeAxiomInterface);
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

    private static void MapServerStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        // Server streaming typically uses GET with route parameters and query parameters
        // Map to a route that returns Server-Sent Events
        var template = GetRouteTemplate(endpointType, requestType);
        
        app.MapGet(template, CreateServerStreamHandler(endpointType, requestType, responseType));
    }

    private static void MapClientStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        // Client streaming typically uses POST with streaming request body
        var template = GetRouteTemplate(endpointType, requestType);
        
        app.MapPost(template, CreateClientStreamHandler(endpointType, requestType, responseType));
    }

    private static void MapBidirectionalStreamEndpoint(WebApplication app, Type endpointType, Type streamInterface)
    {
        var requestType = streamInterface.GetGenericArguments()[0];
        var responseType = streamInterface.GetGenericArguments()[1];

        // Bidirectional streaming typically requires WebSockets
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
            var request = BindFromRoute(httpContext, requestType);

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

            return ProcessResult(result);
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

            // Handle request binding
            object? request;
            if (httpContext.Request.Method == HttpMethod.Get.Method || httpContext.Request.Method == HttpMethod.Delete.Method)
            {
                // Bind from route
                request = BindFromRoute(httpContext, requestType);
            }
            else
            {
                // Bind from body
                request = await httpContext.Request.ReadFromJsonAsync(requestType).ConfigureAwait(false);
            }

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
            var route = BindFromRoute(httpContext, routeType);

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
                    values[i] = Convert.ChangeType(value, param.ParameterType, CultureInfo.InvariantCulture);
                }
            }

            return Activator.CreateInstance(requestType, values);
        }

        return Activator.CreateInstance(requestType);
    }
}

[SuppressMessage("Performance", "CA1812:Avoid uninstantiated internal classes", Justification = "Class is instantiated by dependency injection")]
internal sealed class DefaultContext : IContext
{
    private readonly HttpContext _httpContext;

    public DefaultContext(IHttpContextAccessor accessor, TimeProvider timeProvider)
    {
        _httpContext = accessor.HttpContext!;
        TimeProvider = timeProvider;
        MemoryPool = MemoryPool<byte>.Shared;
    }

    public HttpContext HttpContext => _httpContext;
    public IServiceProvider Services => _httpContext.RequestServices;
    public CancellationToken CancellationToken => _httpContext.RequestAborted;
    public TimeProvider TimeProvider { get; }
    public MemoryPool<byte> MemoryPool { get; }

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        if (_httpContext.Request.RouteValues.TryGetValue(key, out var value) &&
            value is string stringValue &&
            T.TryParse(stringValue, null, out var result))
        {
            return result;
        }
        return default;
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values) &&
            values.Count > 0 &&
            !string.IsNullOrEmpty(values[0]) &&
            T.TryParse(values[0], null, out var result))
        {
            return result;
        }
        return null;
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values) &&
            values.Count > 0 &&
            !string.IsNullOrEmpty(values[0]) &&
            T.TryParse(values[0], null, out var result))
        {
            return result;
        }
        return null;
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        if (_httpContext.Request.Query.TryGetValue(key, out var values))
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

    public bool HasQueryParameter(string key)
    {
        return _httpContext.Request.Query.ContainsKey(key);
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        var url = RouteUrlGenerator.GenerateUrl(route);
        return new Uri(url, UriKind.RelativeOrAbsolute);
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParameters);
        return new Uri(url, UriKind.RelativeOrAbsolute);
    }

    public void SetLocation<TRoute>(TRoute route)
        where TRoute : IRoute<TRoute>
    {
        // Generate URL from route instance
        var uri = GenerateUrl(route);
        _httpContext.Response.Headers.Location = uri.ToString();
    }
}