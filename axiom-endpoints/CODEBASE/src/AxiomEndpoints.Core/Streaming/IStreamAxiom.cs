using System.Buffers;
using System.Net.Http;
using System.Threading.Channels;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// Server streaming endpoint - one request, multiple responses
/// </summary>
public interface IServerStreamAxiom<TRequest, TResponse>
{
    IAsyncEnumerable<TResponse> StreamAsync(
        TRequest request,
        IContext context);
}

/// <summary>
/// Server streaming with route
/// </summary>
public interface IServerStreamAxiom<TRoute, TRequest, TResponse> : IServerStreamAxiom<TRequest, TResponse>
    where TRoute : IRoute<TRoute>
{
    static virtual HttpMethod Method => HttpMethod.Get;
}

/// <summary>
/// Client streaming endpoint - multiple requests, one response
/// </summary>
public interface IClientStreamAxiom<TRequest, TResponse>
{
    ValueTask<Result<TResponse>> HandleAsync(
        IAsyncEnumerable<TRequest> requests,
        IContext context);
}

/// <summary>
/// Bidirectional streaming endpoint
/// </summary>
public interface IBidirectionalStreamAxiom<TRequest, TResponse>
{
    IAsyncEnumerable<TResponse> StreamAsync(
        IAsyncEnumerable<TRequest> requests,
        IContext context);
}

/// <summary>
/// Unified streaming interface with mode detection
/// </summary>
public interface IStreamAxiom<TRoute, TRequest, TResponse>
    where TRoute : IRoute<TRoute>
{
    StreamingMode Mode { get; }

    ValueTask<IStreamingHandler<TRequest, TResponse>> CreateHandlerAsync(IContext context);
}

public enum StreamingMode
{
    Unary,
    ServerStream,
    ClientStream,
    Bidirectional
}

/// <summary>
/// Protocol-agnostic streaming handler
/// </summary>
public interface IStreamingHandler<TRequest, TResponse>
{
    StreamingMode Mode { get; }

    ValueTask<Result<TResponse>> HandleUnaryAsync(TRequest request, CancellationToken ct);

    IAsyncEnumerable<TResponse> HandleServerStreamAsync(TRequest request, CancellationToken ct);

    ValueTask<Result<TResponse>> HandleClientStreamAsync(IAsyncEnumerable<TRequest> requests, CancellationToken ct);

    IAsyncEnumerable<TResponse> HandleBidirectionalAsync(IAsyncEnumerable<TRequest> requests, CancellationToken ct);
}