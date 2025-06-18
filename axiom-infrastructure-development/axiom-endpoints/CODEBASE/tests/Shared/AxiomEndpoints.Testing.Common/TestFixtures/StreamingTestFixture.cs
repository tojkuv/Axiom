using System.Runtime.CompilerServices;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Testing.Common.MockServices;

namespace AxiomEndpoints.Testing.Common.TestFixtures;

public class StreamingTestFixture : IDisposable
{
    private bool _disposed;

    public IContext Context { get; } = new MockContext();

    public virtual void Dispose()
    {
        if (!_disposed)
        {
            _disposed = true;
        }
    }

    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed && disposing)
        {
            // Cleanup resources
        }
    }

    public static async IAsyncEnumerable<T> ToAsyncEnumerable<T>(
        IEnumerable<T> source,
        TimeSpan? delay = null,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        foreach (var item in source)
        {
            if (delay.HasValue)
            {
                await Task.Delay(delay.Value, cancellationToken);
            }

            yield return item;
        }
    }

    public static async Task<List<T>> CollectAsync<T>(
        IAsyncEnumerable<T> source,
        int maxItems = 100,
        TimeSpan? timeout = null,
        CancellationToken cancellationToken = default)
    {
        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);

        if (timeout.HasValue)
        {
            cts.CancelAfter(timeout.Value);
        }

        var results = new List<T>();

        await foreach (var item in source.WithCancellation(cts.Token))
        {
            results.Add(item);

            if (results.Count >= maxItems)
            {
                break;
            }
        }

        return results;
    }
}

public abstract class StreamingTestFixture<TEndpoint> : StreamingTestFixture
{
    public abstract TEndpoint CreateEndpoint();

    protected async Task<List<TResponse>> TestServerStreamAsync<TRequest, TResponse>(
        IServerStreamAxiom<TRequest, TResponse> endpoint,
        TRequest request,
        int expectedCount)
    {
        var results = await endpoint
            .StreamAsync(request, Context)
            .Take(expectedCount)
            .ToListAsync(CancellationToken.None);

        return results;
    }

    protected async Task<Result<TResponse>> TestClientStreamAsync<TRequest, TResponse>(
        IClientStreamAxiom<TRequest, TResponse> endpoint,
        IEnumerable<TRequest> requests)
    {
        var result = await endpoint.HandleAsync(
            ToAsyncEnumerable(requests),
            Context);

        return result;
    }

    protected async Task<List<TResponse>> TestBidirectionalStreamAsync<TRequest, TResponse>(
        IBidirectionalStreamAxiom<TRequest, TResponse> endpoint,
        IEnumerable<TRequest> requests,
        int expectedResponseCount)
    {
        var responses = await endpoint
            .StreamAsync(ToAsyncEnumerable(requests), Context)
            .Take(expectedResponseCount)
            .ToListAsync(CancellationToken.None);

        return responses;
    }
}