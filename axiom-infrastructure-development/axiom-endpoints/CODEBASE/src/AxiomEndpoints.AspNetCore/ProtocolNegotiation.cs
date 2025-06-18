using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;
using System.Diagnostics.CodeAnalysis;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Supported protocols for Axiom endpoints
/// </summary>
public enum Protocol
{
    /// <summary>
    /// HTTP/1.1 or HTTP/2 without gRPC
    /// </summary>
    Http,
    
    /// <summary>
    /// gRPC over HTTP/2
    /// </summary>
    Grpc,
    
    /// <summary>
    /// gRPC-Web for browser clients
    /// </summary>
    GrpcWeb,
    
    /// <summary>
    /// Buf Connect protocol
    /// </summary>
    Connect,
    
    /// <summary>
    /// WebSocket for real-time streaming
    /// </summary>
    WebSocket
}

/// <summary>
/// Interface for protocol negotiation
/// </summary>
public interface IProtocolNegotiator
{
    /// <summary>
    /// Negotiates the protocol to use based on the HTTP request
    /// </summary>
    Protocol NegotiateProtocol(HttpContext context);
    
    /// <summary>
    /// Checks if a specific protocol is supported for this request
    /// </summary>
    bool SupportsProtocol(Protocol protocol, HttpContext context);
    
    /// <summary>
    /// Gets the content type for a given protocol
    /// </summary>
    string GetContentType(Protocol protocol);
}

/// <summary>
/// Default implementation of protocol negotiation
/// </summary>
public class DefaultProtocolNegotiator : IProtocolNegotiator
{
    private static readonly string[] GrpcContentTypes = 
    [
        "application/grpc",
        "application/grpc+proto",
        "application/grpc+json"
    ];
    
    private static readonly string[] GrpcWebContentTypes = 
    [
        "application/grpc-web",
        "application/grpc-web+proto", 
        "application/grpc-web+json"
    ];

    public Protocol NegotiateProtocol(HttpContext context)
    {
        var request = context.Request;
        
        // Check for WebSocket upgrade
        if (IsWebSocketRequest(request))
        {
            return Protocol.WebSocket;
        }
        
        // Check Content-Type header
        var contentType = request.ContentType;
        if (!string.IsNullOrEmpty(contentType))
        {
            if (IsGrpcContentType(contentType))
            {
                return Protocol.Grpc;
            }
            
            if (IsGrpcWebContentType(contentType))
            {
                return Protocol.GrpcWeb;
            }
            
            if (contentType.Contains("application/connect"))
            {
                return Protocol.Connect;
            }
        }
        
        // Check for gRPC-specific headers
        if (HasGrpcHeaders(request))
        {
            return Protocol.Grpc;
        }
        
        // Check Accept header for content negotiation
        var accept = request.Headers.Accept.ToString();
        if (!string.IsNullOrEmpty(accept))
        {
            if (IsGrpcContentType(accept))
            {
                return Protocol.Grpc;
            }
            
            if (IsGrpcWebContentType(accept))
            {
                return Protocol.GrpcWeb;
            }
        }
        
        // Check User-Agent for gRPC clients
        var userAgent = request.Headers.UserAgent.ToString();
        if (userAgent.Contains("grpc", StringComparison.OrdinalIgnoreCase))
        {
            return Protocol.Grpc;
        }
        
        // Default to HTTP
        return Protocol.Http;
    }

    public bool SupportsProtocol(Protocol protocol, HttpContext context)
    {
        return protocol switch
        {
            Protocol.Grpc => context.Request.Protocol == "HTTP/2" || 
                           context.Request.Protocol == "HTTP/3",
            Protocol.GrpcWeb => true, // Works over HTTP/1.1
            Protocol.Connect => true, // Works over any HTTP version
            Protocol.Http => true,
            Protocol.WebSocket => context.WebSockets.IsWebSocketRequest ||
                                 context.Request.Headers.ContainsKey("Sec-WebSocket-Key"),
            _ => false
        };
    }

    public string GetContentType(Protocol protocol)
    {
        return protocol switch
        {
            Protocol.Grpc => "application/grpc+proto",
            Protocol.GrpcWeb => "application/grpc-web+proto",
            Protocol.Connect => "application/connect+proto",
            Protocol.Http => "application/json",
            Protocol.WebSocket => "application/json", // For initial handshake
            _ => "application/json"
        };
    }

    private static bool IsWebSocketRequest(HttpRequest request)
    {
        return request.Headers.ContainsKey("Sec-WebSocket-Key") ||
               request.Headers.Connection.Contains("Upgrade") &&
               request.Headers.Upgrade.Contains("websocket");
    }

    private static bool IsGrpcContentType(string contentType)
    {
        return GrpcContentTypes.Any(grpcType => 
            contentType.Contains(grpcType, StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsGrpcWebContentType(string contentType)
    {
        return GrpcWebContentTypes.Any(grpcWebType => 
            contentType.Contains(grpcWebType, StringComparison.OrdinalIgnoreCase));
    }

    private static bool HasGrpcHeaders(HttpRequest request)
    {
        return request.Headers.ContainsKey("grpc-timeout") ||
               request.Headers.ContainsKey("grpc-encoding") ||
               request.Headers.ContainsKey("grpc-message-type") ||
               request.Headers.ContainsKey("grpc-status");
    }
}

/// <summary>
/// Middleware for protocol detection and routing
/// </summary>
public class ProtocolRoutingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IProtocolNegotiator _negotiator;

    public ProtocolRoutingMiddleware(RequestDelegate next, IProtocolNegotiator negotiator)
    {
        _next = next;
        _negotiator = negotiator;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var protocol = _negotiator.NegotiateProtocol(context);
        
        // Store protocol information in HttpContext
        context.Items["Protocol"] = protocol;
        context.Items["ProtocolNegotiator"] = _negotiator;
        
        // Add protocol-specific features or headers
        switch (protocol)
        {
            case Protocol.Grpc:
            case Protocol.GrpcWeb:
                AddGrpcFeatures(context);
                break;
            case Protocol.WebSocket:
                AddWebSocketFeatures(context);
                break;
        }
        
        await _next(context);
    }

    private static void AddGrpcFeatures(HttpContext context)
    {
        // Add gRPC-specific context features
        context.Features.Set<IProtocolFeature>(new GrpcProtocolFeature());
        
        // Ensure proper headers for gRPC
        if (!context.Response.Headers.ContainsKey("grpc-status"))
        {
            context.Response.OnStarting(() =>
            {
                if (!context.Response.Headers.ContainsKey("grpc-status"))
                {
                    context.Response.Headers.Add("grpc-status", "0");
                }
                return Task.CompletedTask;
            });
        }
    }

    private static void AddWebSocketFeatures(HttpContext context)
    {
        // Add WebSocket-specific context features
        context.Features.Set<IProtocolFeature>(new WebSocketProtocolFeature());
    }
}

/// <summary>
/// Feature interface for protocol-specific capabilities
/// </summary>
public interface IProtocolFeature
{
    Protocol Protocol { get; }
    bool SupportsStreaming { get; }
    bool SupportsBidirectional { get; }
}

/// <summary>
/// gRPC protocol feature implementation
/// </summary>
public class GrpcProtocolFeature : IProtocolFeature
{
    public Protocol Protocol => Protocol.Grpc;
    public bool SupportsStreaming => true;
    public bool SupportsBidirectional => true;
}

/// <summary>
/// WebSocket protocol feature implementation
/// </summary>
public class WebSocketProtocolFeature : IProtocolFeature
{
    public Protocol Protocol => Protocol.WebSocket;
    public bool SupportsStreaming => true;
    public bool SupportsBidirectional => true;
}

/// <summary>
/// HTTP protocol feature implementation
/// </summary>
public class HttpProtocolFeature : IProtocolFeature
{
    public Protocol Protocol => Protocol.Http;
    public bool SupportsStreaming => true; // Server-Sent Events
    public bool SupportsBidirectional => false;
}

/// <summary>
/// Extension methods for protocol negotiation
/// </summary>
public static class ProtocolExtensions
{
    /// <summary>
    /// Gets the negotiated protocol from HttpContext
    /// </summary>
    public static Protocol GetProtocol(this HttpContext context)
    {
        return context.Items.TryGetValue("Protocol", out var protocol) && protocol is Protocol p
            ? p 
            : Protocol.Http;
    }
    
    /// <summary>
    /// Gets the protocol negotiator from HttpContext
    /// </summary>
    public static IProtocolNegotiator? GetProtocolNegotiator(this HttpContext context)
    {
        return context.Items.TryGetValue("ProtocolNegotiator", out var negotiator) 
            ? negotiator as IProtocolNegotiator
            : null;
    }
    
    /// <summary>
    /// Checks if the request uses gRPC (any variant)
    /// </summary>
    public static bool IsGrpc(this HttpContext context)
    {
        var protocol = context.GetProtocol();
        return protocol is Protocol.Grpc or Protocol.GrpcWeb;
    }
    
    /// <summary>
    /// Checks if the request supports streaming
    /// </summary>
    public static bool SupportsStreaming(this HttpContext context)
    {
        var feature = context.Features.Get<IProtocolFeature>();
        return feature?.SupportsStreaming ?? false;
    }
    
    /// <summary>
    /// Checks if the request supports bidirectional streaming
    /// </summary>
    public static bool SupportsBidirectional(this HttpContext context)
    {
        var feature = context.Features.Get<IProtocolFeature>();
        return feature?.SupportsBidirectional ?? false;
    }
}

/// <summary>
/// Metadata for protocol support on endpoints
/// </summary>
public class ProtocolSupportMetadata
{
    public required IReadOnlySet<Protocol> SupportedProtocols { get; init; }
    public Protocol PreferredProtocol { get; init; } = Protocol.Http;
}

/// <summary>
/// Metadata for gRPC-HTTP transcoding
/// </summary>
public class GrpcHttpMetadata
{
    public required string ServiceName { get; init; }
    public required string MethodName { get; init; }
    public required string Pattern { get; init; }
}