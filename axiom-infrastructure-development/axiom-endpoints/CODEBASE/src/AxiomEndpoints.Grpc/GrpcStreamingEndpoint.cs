using System.Runtime.CompilerServices;
using Grpc.Core;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.Grpc;

/// <summary>
/// Base class for gRPC streaming endpoints
/// </summary>
public abstract class GrpcStreamingEndpoint<TService> where TService : class
{
    protected ILogger<TService> Logger { get; }
    protected IContextFactory ContextFactory { get; }

    protected GrpcStreamingEndpoint(ILogger<TService> logger, IContextFactory contextFactory)
    {
        Logger = logger;
        ContextFactory = contextFactory;
    }

    protected virtual IContext CreateContext(ServerCallContext grpcContext)
    {
        // Convert gRPC context to Axiom context
        // This is a simplified implementation - a real one would properly map headers, cancellation, etc.
        return ContextFactory.CreateContext();
    }
}

/// <summary>
/// gRPC server streaming endpoint
/// </summary>
public abstract class GrpcServerStreamEndpoint<TService, TRequest, TResponse>
    : GrpcStreamingEndpoint<TService>
    where TService : class
{
    protected GrpcServerStreamEndpoint(ILogger<TService> logger, IContextFactory contextFactory)
        : base(logger, contextFactory)
    {
    }

    public async Task StreamAsync(
        TRequest request,
        IServerStreamWriter<TResponse> responseStream,
        ServerCallContext context)
    {
        var endpoint = GetEndpoint();
        var axiomContext = CreateContext(context);

        await foreach (var item in endpoint.StreamAsync(request, axiomContext)
            .WithCancellation(context.CancellationToken))
        {
            await responseStream.WriteAsync(item);
        }
    }

    protected abstract IServerStreamAxiom<TRequest, TResponse> GetEndpoint();
}

/// <summary>
/// gRPC client streaming endpoint
/// </summary>
public abstract class GrpcClientStreamEndpoint<TService, TRequest, TResponse>
    : GrpcStreamingEndpoint<TService>
    where TService : class
{
    protected GrpcClientStreamEndpoint(ILogger<TService> logger, IContextFactory contextFactory)
        : base(logger, contextFactory)
    {
    }

    public async Task<TResponse> HandleAsync(
        IAsyncStreamReader<TRequest> requestStream,
        ServerCallContext context)
    {
        var endpoint = GetEndpoint();
        var axiomContext = CreateContext(context);

        // Convert gRPC stream to IAsyncEnumerable
        var requests = ReadRequestStream(requestStream, context.CancellationToken);
        var result = await endpoint.HandleAsync(requests, axiomContext);

        if (result.IsSuccess)
        {
            return result.Value;
        }
        else
        {
            throw new RpcException(new Status(StatusCode.Internal, result.Error.Message));
        }
    }

    private static async IAsyncEnumerable<TRequest> ReadRequestStream(
        IAsyncStreamReader<TRequest> reader,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        await foreach (var request in reader.ReadAllAsync(cancellationToken))
        {
            yield return request;
        }
    }

    protected abstract IClientStreamAxiom<TRequest, TResponse> GetEndpoint();
}

/// <summary>
/// gRPC bidirectional streaming endpoint
/// </summary>
public abstract class GrpcBidirectionalStreamEndpoint<TService, TRequest, TResponse>
    : GrpcStreamingEndpoint<TService>
    where TService : class
{
    protected GrpcBidirectionalStreamEndpoint(ILogger<TService> logger, IContextFactory contextFactory)
        : base(logger, contextFactory)
    {
    }

    public async Task StreamAsync(
        IAsyncStreamReader<TRequest> requestStream,
        IServerStreamWriter<TResponse> responseStream,
        ServerCallContext context)
    {
        var endpoint = GetEndpoint();
        var axiomContext = CreateContext(context);

        // Convert gRPC request stream to IAsyncEnumerable
        var requests = ReadRequestStream(requestStream, context.CancellationToken);
        
        // Get response stream from endpoint
        var responses = endpoint.StreamAsync(requests, axiomContext);

        // Write responses to gRPC stream
        await foreach (var response in responses.WithCancellation(context.CancellationToken))
        {
            await responseStream.WriteAsync(response);
        }
    }

    private static async IAsyncEnumerable<TRequest> ReadRequestStream(
        IAsyncStreamReader<TRequest> reader,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        await foreach (var request in reader.ReadAllAsync(cancellationToken))
        {
            yield return request;
        }
    }

    protected abstract IBidirectionalStreamAxiom<TRequest, TResponse> GetEndpoint();
}

/// <summary>
/// Factory interface for creating Axiom contexts from gRPC contexts
/// </summary>
public interface IContextFactory
{
    IContext CreateContext();
}