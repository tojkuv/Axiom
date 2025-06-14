using System.Runtime.CompilerServices;
using System.Threading.Channels;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// High-performance streaming extensions
/// </summary>
public static class StreamingOptimizations
{
    /// <summary>
    /// Batches items for more efficient transmission
    /// </summary>
    public static async IAsyncEnumerable<IReadOnlyList<T>> BatchAsync<T>(
        this IAsyncEnumerable<T> source,
        int batchSize,
        TimeSpan maxWait,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var timer = new PeriodicTimer(maxWait);
        var batch = new List<T>(batchSize);
        var timerTask = timer.WaitForNextTickAsync(cancellationToken).AsTask();

        await using var enumerator = source.GetAsyncEnumerator(cancellationToken);

        while (true)
        {
            var moveNextTask = enumerator.MoveNextAsync().AsTask();
            var completedTask = await Task.WhenAny(moveNextTask, timerTask);

            if (completedTask == moveNextTask)
            {
                if (!await moveNextTask)
                {
                    // Source completed
                    if (batch.Count > 0)
                    {
                        yield return batch.ToArray();
                    }
                    break;
                }

                batch.Add(enumerator.Current);

                if (batch.Count >= batchSize)
                {
                    yield return batch.ToArray();
                    batch.Clear();
                    timerTask = timer.WaitForNextTickAsync(cancellationToken).AsTask();
                }
            }
            else
            {
                // Timer expired
                if (batch.Count > 0)
                {
                    yield return batch.ToArray();
                    batch.Clear();
                }
                timerTask = timer.WaitForNextTickAsync(cancellationToken).AsTask();
            }
        }
    }

    /// <summary>
    /// Applies backpressure based on consumer speed
    /// </summary>
    public static async IAsyncEnumerable<T> WithBackpressureAsync<T>(
        this IAsyncEnumerable<T> source,
        int bufferSize = 10,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var channel = Channel.CreateBounded<T>(new BoundedChannelOptions(bufferSize)
        {
            FullMode = BoundedChannelFullMode.Wait,
            SingleReader = true,
            SingleWriter = true
        });

        // Producer
        _ = Task.Run(async () =>
        {
            try
            {
                await foreach (var item in source.WithCancellation(cancellationToken))
                {
                    await channel.Writer.WriteAsync(item, cancellationToken);
                }
            }
            finally
            {
                channel.Writer.TryComplete();
            }
        }, cancellationToken);

        // Consumer
        await foreach (var item in channel.Reader.ReadAllAsync(cancellationToken))
        {
            yield return item;
        }
    }
}