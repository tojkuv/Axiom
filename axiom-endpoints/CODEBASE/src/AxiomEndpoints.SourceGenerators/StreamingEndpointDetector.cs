using System.Linq;
using Microsoft.CodeAnalysis;

namespace AxiomEndpoints.SourceGenerators;

internal static class StreamingEndpointDetector
{
    public static StreamingEndpointInfo? GetStreamingInfo(GeneratorSyntaxContext context)
    {
        var symbol = context.SemanticModel.GetDeclaredSymbol(context.Node);
        if (symbol is not INamedTypeSymbol typeSymbol)
            return null;

        var streamingInterface = typeSymbol.AllInterfaces.FirstOrDefault(i =>
            i.Name.StartsWith("IServerStreamAxiom") ||
            i.Name.StartsWith("IClientStreamAxiom") ||
            i.Name.StartsWith("IBidirectionalStreamAxiom"));

        if (streamingInterface == null)
            return null;

        var mode = streamingInterface.Name switch
        {
            var name when name.StartsWith("IServerStreamAxiom") => StreamingMode.ServerStream,
            var name when name.StartsWith("IClientStreamAxiom") => StreamingMode.ClientStream,
            var name when name.StartsWith("IBidirectionalStreamAxiom") => StreamingMode.Bidirectional,
            _ => StreamingMode.Unary
        };

        var requestType = streamingInterface.TypeArguments.Length > 0 
            ? streamingInterface.TypeArguments[0].ToDisplayString() 
            : "";
        var responseType = streamingInterface.TypeArguments.Length > 1 
            ? streamingInterface.TypeArguments[1].ToDisplayString() 
            : "";

        return new StreamingEndpointInfo
        {
            TypeName = typeSymbol.Name,
            Namespace = typeSymbol.ContainingNamespace.ToDisplayString(),
            Mode = mode,
            RequestType = requestType,
            ResponseType = responseType,
            RouteType = GetRouteType(typeSymbol)
        };
    }

    private static string? GetRouteType(INamedTypeSymbol typeSymbol)
    {
        // Check if any of the streaming interfaces have a route type as first generic argument
        var routeInterface = typeSymbol.AllInterfaces.FirstOrDefault(i =>
            i.IsGenericType &&
            i.TypeArguments.Length >= 3 &&
            i.Name.Contains("StreamAxiom"));

        if (routeInterface != null && routeInterface.TypeArguments.Length >= 3)
        {
            var potentialRouteType = routeInterface.TypeArguments[0];
            // Check if it implements IRoute<T>
            if (potentialRouteType is INamedTypeSymbol routeTypeSymbol &&
                routeTypeSymbol.AllInterfaces.Any(i => i.Name == "IRoute"))
            {
                return potentialRouteType.ToDisplayString();
            }
        }

        return null;
    }
}

internal class StreamingEndpointInfo
{
    public string TypeName { get; set; } = string.Empty;
    public string Namespace { get; set; } = string.Empty;
    public StreamingMode Mode { get; set; }
    public string RequestType { get; set; } = string.Empty;
    public string ResponseType { get; set; } = string.Empty;
    public string? RouteType { get; set; }
}

internal enum StreamingMode
{
    Unary,
    ServerStream,
    ClientStream,
    Bidirectional
}