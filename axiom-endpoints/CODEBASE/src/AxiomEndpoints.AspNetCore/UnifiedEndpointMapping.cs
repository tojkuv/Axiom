using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using System.Reflection;
using System.Buffers;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Mapper for unified endpoints that support both HTTP and gRPC
/// </summary>
public static class UnifiedEndpointMapper
{
    /// <summary>
    /// Maps a unified endpoint that supports multiple protocols
    /// </summary>
    public static IEndpointConventionBuilder MapUnifiedEndpoint(
        this IEndpointRouteBuilder endpoints,
        Type endpointType,
        string pattern,
        string httpMethod = "POST")
    {
        var supportedProtocols = GetSupportedProtocols(endpointType);
        
        // Map HTTP endpoint
        var httpEndpoint = MapHttpEndpoint(endpoints, endpointType, pattern, httpMethod);
        
        // Add protocol support metadata
        httpEndpoint.WithMetadata(new ProtocolSupportMetadata
        {
            SupportedProtocols = supportedProtocols,
            PreferredProtocol = DeterminePreferredProtocol(endpointType)
        });
        
        // Add gRPC metadata if supported
        if (IsGrpcEndpoint(endpointType))
        {
            httpEndpoint.WithMetadata(new GrpcHttpMetadata
            {
                ServiceName = GetServiceName(endpointType),
                MethodName = GetMethodName(endpointType),
                Pattern = pattern
            });
        }
        
        return httpEndpoint;
    }

    /// <summary>
    /// Maps multiple unified endpoints from an assembly
    /// </summary>
    public static void MapUnifiedEndpoints(
        this IEndpointRouteBuilder endpoints,
        Assembly assembly)
    {
        var endpointTypes = assembly.GetTypes()
            .Where(IsEndpointType)
            .ToList();

        foreach (var endpointType in endpointTypes)
        {
            var pattern = GeneratePattern(endpointType);
            var httpMethod = GetHttpMethod(endpointType);
            
            endpoints.MapUnifiedEndpoint(endpointType, pattern, httpMethod);
        }
    }

    private static RouteHandlerBuilder MapHttpEndpoint(
        IEndpointRouteBuilder endpoints,
        Type endpointType,
        string pattern,
        string httpMethod)
    {
        return httpMethod.ToUpperInvariant() switch
        {
            "GET" => endpoints.MapGet(pattern, CreateEndpointHandler(endpointType)),
            "POST" => endpoints.MapPost(pattern, CreateEndpointHandler(endpointType)),
            "PUT" => endpoints.MapPut(pattern, CreateEndpointHandler(endpointType)),
            "DELETE" => endpoints.MapDelete(pattern, CreateEndpointHandler(endpointType)),
            "PATCH" => endpoints.MapPatch(pattern, CreateEndpointHandler(endpointType)),
            _ => endpoints.MapPost(pattern, CreateEndpointHandler(endpointType))
        };
    }

    private static Delegate CreateEndpointHandler(Type endpointType)
    {
        // This is a simplified implementation
        // In a full implementation, this would create appropriate handlers based on endpoint types
        
        var interfaces = endpointType.GetInterfaces();
        var axiomInterface = interfaces.FirstOrDefault(i => i.IsGenericType && i.Name.Contains("Axiom"));
        
        if (axiomInterface == null)
        {
            throw new InvalidOperationException($"Type {endpointType.Name} does not implement an Axiom interface");
        }

        var typeArgs = axiomInterface.GetGenericArguments();
        
        if (axiomInterface.Name.StartsWith("IServerStreamAxiom"))
        {
            return CreateServerStreamHandler(endpointType, typeArgs[0], typeArgs[1]);
        }
        else if (axiomInterface.Name.StartsWith("IClientStreamAxiom"))
        {
            return CreateClientStreamHandler(endpointType, typeArgs[0], typeArgs[1]);
        }
        else if (axiomInterface.Name.StartsWith("IBidirectionalStreamAxiom"))
        {
            return CreateBidirectionalStreamHandler(endpointType, typeArgs[0], typeArgs[1]);
        }
        else
        {
            return CreateUnaryHandler(endpointType, typeArgs[0], typeArgs[1]);
        }
    }

    private static Delegate CreateUnaryHandler(Type endpointType, Type requestType, Type responseType)
    {
        var method = typeof(UnifiedEndpointMapper)
            .GetMethod(nameof(HandleUnaryEndpoint), BindingFlags.NonPublic | BindingFlags.Static)!
            .MakeGenericMethod(endpointType, requestType, responseType);

        return method.CreateDelegate(typeof(Func<,,,>).MakeGenericType(
            requestType, 
            typeof(HttpContext), 
            typeof(IServiceProvider), 
            typeof(Task<IResult>)));
    }

    private static Delegate CreateServerStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        var method = typeof(UnifiedEndpointMapper)
            .GetMethod(nameof(HandleServerStreamEndpoint), BindingFlags.NonPublic | BindingFlags.Static)!
            .MakeGenericMethod(endpointType, requestType, responseType);

        return method.CreateDelegate(typeof(Func<,,,>).MakeGenericType(
            requestType,
            typeof(HttpContext),
            typeof(IServiceProvider),
            typeof(Task<IResult>)));
    }

    private static Delegate CreateClientStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        // Client streaming over HTTP is more complex - simplified for now
        return CreateUnaryHandler(endpointType, requestType, responseType);
    }

    private static Delegate CreateBidirectionalStreamHandler(Type endpointType, Type requestType, Type responseType)
    {
        // Bidirectional streaming would typically use WebSockets for HTTP
        return CreateServerStreamHandler(endpointType, requestType, responseType);
    }

    private static async Task<IResult> HandleUnaryEndpoint<TEndpoint, TRequest, TResponse>(
        TRequest request,
        HttpContext context,
        IServiceProvider services)
        where TEndpoint : IAxiom<TRequest, TResponse>
    {
        try
        {
            var endpoint = services.GetRequiredService<TEndpoint>();
            var axiomContext = CreateAxiomContext(context, services);
            
            var result = await endpoint.HandleAsync(request, axiomContext);
            
            return result.Match(
                success: value => Results.Ok(value),
                failure: error => MapErrorToResult(error, context.GetProtocol()));
        }
        catch (Exception ex)
        {
            return Results.Problem(ex.Message);
        }
    }

    private static async Task<IResult> HandleServerStreamEndpoint<TEndpoint, TRequest, TResponse>(
        TRequest request,
        HttpContext context,
        IServiceProvider services)
        where TEndpoint : IServerStreamAxiom<TRequest, TResponse>
    {
        try
        {
            var endpoint = services.GetRequiredService<TEndpoint>();
            var axiomContext = CreateAxiomContext(context, services);
            
            var protocol = context.GetProtocol();
            
            if (protocol == Protocol.WebSocket)
            {
                // Handle WebSocket streaming
                return await HandleWebSocketStream(endpoint, request, context, axiomContext);
            }
            else
            {
                // Handle Server-Sent Events
                return await HandleServerSentEvents(endpoint, request, context, axiomContext);
            }
        }
        catch (Exception ex)
        {
            return Results.Problem(ex.Message);
        }
    }

    private static async Task<IResult> HandleWebSocketStream<TRequest, TResponse>(
        IServerStreamAxiom<TRequest, TResponse> endpoint,
        TRequest request,
        HttpContext context,
        IContext axiomContext)
    {
        if (!context.WebSockets.IsWebSocketRequest)
        {
            return Results.BadRequest("WebSocket connection required");
        }

        var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        
        try
        {
            await foreach (var item in endpoint.StreamAsync(request, axiomContext)
                .WithCancellation(context.RequestAborted))
            {
                var json = System.Text.Json.JsonSerializer.Serialize(item);
                var bytes = System.Text.Encoding.UTF8.GetBytes(json);
                
                await webSocket.SendAsync(
                    new ArraySegment<byte>(bytes),
                    System.Net.WebSockets.WebSocketMessageType.Text,
                    true,
                    context.RequestAborted);
            }
            
            await webSocket.CloseAsync(
                System.Net.WebSockets.WebSocketCloseStatus.NormalClosure,
                "Stream completed",
                context.RequestAborted);
        }
        catch (OperationCanceledException)
        {
            // Client disconnected
        }
        catch (Exception ex)
        {
            await webSocket.CloseAsync(
                System.Net.WebSockets.WebSocketCloseStatus.InternalServerError,
                ex.Message,
                CancellationToken.None);
        }

        return Results.Empty;
    }

    private static async Task<IResult> HandleServerSentEvents<TRequest, TResponse>(
        IServerStreamAxiom<TRequest, TResponse> endpoint,
        TRequest request,
        HttpContext context,
        IContext axiomContext)
    {
        context.Response.Headers.Add("Content-Type", "text/event-stream");
        context.Response.Headers.Add("Cache-Control", "no-cache");
        context.Response.Headers.Add("Connection", "keep-alive");

        try
        {
            await foreach (var item in endpoint.StreamAsync(request, axiomContext)
                .WithCancellation(context.RequestAborted))
            {
                var json = System.Text.Json.JsonSerializer.Serialize(item);
                await context.Response.WriteAsync($"data: {json}\n\n", context.RequestAborted);
                await context.Response.Body.FlushAsync(context.RequestAborted);
            }
        }
        catch (OperationCanceledException)
        {
            // Client disconnected
        }

        return Results.Empty;
    }

    private static IContext CreateAxiomContext(HttpContext httpContext, IServiceProvider services)
    {
        // Simple context creation - in a full implementation this would be more sophisticated
        return new HttpContextAdapter(httpContext, services);
    }

    private static IResult MapErrorToResult(AxiomError error, Protocol protocol)
    {
        return error.Type switch
        {
            ErrorType.NotFound => Results.NotFound(new { error = error.Message }),
            ErrorType.Validation => Results.BadRequest(new { error = error.Message }),
            ErrorType.Unauthorized => Results.Unauthorized(),
            ErrorType.Forbidden => Results.Forbid(),
            ErrorType.Conflict => Results.Conflict(new { error = error.Message }),
            ErrorType.TooManyRequests => Results.StatusCode(429),
            _ => Results.Problem(error.Message)
        };
    }

    private static IReadOnlySet<Protocol> GetSupportedProtocols(Type endpointType)
    {
        var protocols = new HashSet<Protocol> { Protocol.Http };

        if (IsGrpcEndpoint(endpointType))
        {
            protocols.Add(Protocol.Grpc);
            protocols.Add(Protocol.GrpcWeb);
        }

        if (IsStreamingEndpoint(endpointType))
        {
            protocols.Add(Protocol.WebSocket);
        }

        return protocols;
    }

    private static Protocol DeterminePreferredProtocol(Type endpointType)
    {
        if (IsGrpcEndpoint(endpointType))
        {
            return Protocol.Grpc;
        }
        
        if (IsStreamingEndpoint(endpointType))
        {
            return Protocol.WebSocket;
        }
        
        return Protocol.Http;
    }

    private static bool IsEndpointType(Type type)
    {
        return type.GetInterfaces().Any(i =>
            i.IsGenericType &&
            (i.Name == "IAxiom" || i.Name == "IRouteAxiom" ||
             i.Name.Contains("StreamAxiom")));
    }

    private static bool IsGrpcEndpoint(Type endpointType)
    {
        // Check for gRPC-specific attributes or interfaces
        return endpointType.GetCustomAttributes()
            .Any(attr => attr.GetType().Name.Contains("Grpc")) ||
            endpointType.GetInterfaces()
            .Any(i => i.Name.Contains("Grpc"));
    }

    private static bool IsStreamingEndpoint(Type endpointType)
    {
        return endpointType.GetInterfaces().Any(i =>
            i.IsGenericType &&
            i.Name.Contains("StreamAxiom"));
    }

    private static string GeneratePattern(Type endpointType)
    {
        var name = endpointType.Name.Replace("Endpoint", "");
        return $"/api/{name.ToLowerInvariant()}";
    }

    private static string GetHttpMethod(Type endpointType)
    {
        if (IsStreamingEndpoint(endpointType))
        {
            return "GET"; // Streaming endpoints typically use GET for HTTP
        }
        
        var name = endpointType.Name.ToLowerInvariant();
        return name switch
        {
            var n when n.Contains("get") || n.Contains("read") => "GET",
            var n when n.Contains("create") || n.Contains("add") => "POST",
            var n when n.Contains("update") || n.Contains("edit") => "PUT",
            var n when n.Contains("delete") || n.Contains("remove") => "DELETE",
            _ => "POST"
        };
    }

    private static string GetServiceName(Type endpointType)
    {
        var namespaceParts = endpointType.Namespace?.Split('.') ?? [];
        var serviceName = namespaceParts.Length > 1 ? namespaceParts[^1] : "DefaultService";
        
        if (!serviceName.EndsWith("Service", StringComparison.OrdinalIgnoreCase))
        {
            serviceName += "Service";
        }

        return serviceName;
    }

    private static string GetMethodName(Type endpointType)
    {
        return endpointType.Name.Replace("Endpoint", "");
    }
}

/// <summary>
/// Simple adapter to convert HttpContext to IContext
/// </summary>
internal class HttpContextAdapter : IContext
{
    public HttpContext HttpContext { get; }
    public IServiceProvider Services { get; }
    public CancellationToken CancellationToken => HttpContext.RequestAborted;
    public TimeProvider TimeProvider { get; }

    public HttpContextAdapter(HttpContext httpContext, IServiceProvider services)
    {
        HttpContext = httpContext;
        Services = services;
        TimeProvider = Services.GetService<TimeProvider>() ?? TimeProvider.System;
    }

    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        throw new NotImplementedException("Route value access not implemented for HttpContextAdapter");
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        throw new NotImplementedException("Query value access not implemented for HttpContextAdapter");
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        throw new NotImplementedException("Query value access not implemented for HttpContextAdapter");
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        throw new NotImplementedException("Query values access not implemented for HttpContextAdapter");
    }

    public bool HasQueryParameter(string key)
    {
        throw new NotImplementedException("Query parameter check not implemented for HttpContextAdapter");
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("URL generation not implemented for HttpContextAdapter");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("URL generation not implemented for HttpContextAdapter");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        throw new NotImplementedException("Location header setting not implemented for HttpContextAdapter");
    }
}