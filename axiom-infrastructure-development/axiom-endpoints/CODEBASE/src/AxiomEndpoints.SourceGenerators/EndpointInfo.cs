using System.Collections.Immutable;

namespace AxiomEndpoints.SourceGenerators;

internal sealed class EndpointInfo
{
    public string TypeName { get; set; } = string.Empty;
    public string Namespace { get; set; } = string.Empty;
    public string RouteType { get; set; } = string.Empty;
    public string RequestType { get; set; } = string.Empty;
    public string ResponseType { get; set; } = string.Empty;
    public string HttpMethod { get; set; } = string.Empty;
    public bool RequiresAuthorization { get; set; }
    public ImmutableArray<string> Scopes { get; set; } = ImmutableArray<string>.Empty;
    public EndpointKind Kind { get; set; }
}

internal enum EndpointKind
{
    Unary,
    ServerStream,
    ClientStream,
    BidirectionalStream
}