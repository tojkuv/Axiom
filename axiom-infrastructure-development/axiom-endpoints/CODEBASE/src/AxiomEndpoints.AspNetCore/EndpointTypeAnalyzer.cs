using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.AspNetCore;

/// <summary>
/// Analyzes endpoint types to determine their interface implementations
/// </summary>
public static class EndpointTypeAnalyzer
{
    /// <summary>
    /// Analyzes an endpoint type and returns information about its interfaces
    /// </summary>
    public static EndpointTypeInfo Analyze(Type endpointType)
    {
        ArgumentNullException.ThrowIfNull(endpointType);

        var interfaces = endpointType.GetInterfaces();
        
        return new EndpointTypeInfo
        {
            EndpointType = endpointType,
            ServerStreamInterface = FindInterface(interfaces, typeof(IServerStreamAxiom<,>)),
            ClientStreamInterface = FindInterface(interfaces, typeof(IClientStreamAxiom<,>)),
            BidirectionalStreamInterface = FindInterface(interfaces, typeof(IBidirectionalStreamAxiom<,>)),
            AxiomInterface = FindInterface(interfaces, typeof(IAxiom<,,>)),
            RouteAxiomInterface = FindInterface(interfaces, typeof(IRouteAxiom<,>))
        };
    }

    private static Type? FindInterface(Type[] interfaces, Type genericTypeDefinition)
    {
        return interfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.GetGenericTypeDefinition() == genericTypeDefinition);
    }
}

/// <summary>
/// Information about an endpoint type's interface implementations
/// </summary>
public record EndpointTypeInfo
{
    public required Type EndpointType { get; init; }
    public Type? ServerStreamInterface { get; init; }
    public Type? ClientStreamInterface { get; init; }
    public Type? BidirectionalStreamInterface { get; init; }
    public Type? AxiomInterface { get; init; }
    public Type? RouteAxiomInterface { get; init; }

    public bool IsStreamingEndpoint => 
        ServerStreamInterface != null || 
        ClientStreamInterface != null || 
        BidirectionalStreamInterface != null;

    public bool IsStandardEndpoint => 
        AxiomInterface != null || 
        RouteAxiomInterface != null;

    public EndpointKind Kind
    {
        get
        {
            if (ServerStreamInterface != null) return EndpointKind.ServerStream;
            if (ClientStreamInterface != null) return EndpointKind.ClientStream;
            if (BidirectionalStreamInterface != null) return EndpointKind.BidirectionalStream;
            if (AxiomInterface != null) return EndpointKind.StandardAxiom;
            if (RouteAxiomInterface != null) return EndpointKind.RouteAxiom;
            return EndpointKind.Unknown;
        }
    }
}

/// <summary>
/// Types of endpoints supported by the framework
/// </summary>
public enum EndpointKind
{
    Unknown,
    StandardAxiom,
    RouteAxiom,
    ServerStream,
    ClientStream,
    BidirectionalStream
}