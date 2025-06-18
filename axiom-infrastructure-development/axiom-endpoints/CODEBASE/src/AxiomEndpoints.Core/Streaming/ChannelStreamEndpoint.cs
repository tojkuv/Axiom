using System.Runtime.CompilerServices;
using System.Threading.Channels;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// Base class for channel-based streaming with backpressure
/// </summary>
public abstract record ChannelStreamEndpoint<TRequest, TResponse> : IServerStreamAxiom<TRequest, TResponse>
{
    protected virtual ChannelOptions GetChannelOptions() => new UnboundedChannelOptions
    {
        SingleReader = true,
        SingleWriter = false,
        AllowSynchronousContinuations = false
    };

    public async IAsyncEnumerable<TResponse> StreamAsync(
        TRequest request,
        IContext context)
    {
        var cancellationToken = context.CancellationToken;
        var channel = Channel.CreateUnbounded<TResponse>();

        // Start producing in background with proper error handling
        var producerTask = Task.Run(async () =>
        {
            try
            {
                await ProduceAsync(request, channel.Writer, context, cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // Log error and complete channel with error
                channel.Writer.TryComplete(ex);
                return;
            }

            channel.Writer.TryComplete();
        }, cancellationToken);

        // Consume with automatic disposal and error propagation
        await foreach (var item in channel.Reader.ReadAllAsync(cancellationToken))
        {
            yield return item;
        }

        // Ensure producer completes
        await producerTask;
    }

    protected abstract Task ProduceAsync(
        TRequest request,
        ChannelWriter<TResponse> writer,
        IContext context,
        CancellationToken cancellationToken);
}

/// <summary>
/// Bounded channel streaming for flow control
/// </summary>
public abstract record BoundedStreamEndpoint<TRequest, TResponse> : ChannelStreamEndpoint<TRequest, TResponse>
{
    protected virtual int Capacity => 100;
    protected virtual BoundedChannelFullMode FullMode => BoundedChannelFullMode.Wait;

    protected override ChannelOptions GetChannelOptions() => new BoundedChannelOptions(Capacity)
    {
        FullMode = FullMode,
        SingleReader = true,
        SingleWriter = false,
        AllowSynchronousContinuations = false
    };
}