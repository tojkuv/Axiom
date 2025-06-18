using System.Runtime.CompilerServices;
using System.Threading.Channels;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// Extensions for streaming operations
/// </summary>
public static class StreamingExtensions
{
    /// <summary>
    /// Converts an async enumerable to a channel reader for better control
    /// </summary>
    public static ChannelReader<T> ToChannelReader<T>(this IAsyncEnumerable<T> source, int capacity = 100)
    {
        ArgumentNullException.ThrowIfNull(source);
        
        var channel = Channel.CreateBounded<T>(capacity);
        var writer = channel.Writer;

        _ = Task.Run(async () =>
        {
            try
            {
                await foreach (var item in source.ConfigureAwait(false))
                {
                    if (!await writer.WaitToWriteAsync().ConfigureAwait(false))
                        break;
                    
                    writer.TryWrite(item);
                }
            }
            catch (OperationCanceledException)
            {
                // Cancellation is expected, complete without error
                writer.TryComplete();
                return;
            }
            catch (ObjectDisposedException ex)
            {
                // Handle disposal during streaming
                writer.TryComplete(ex);
                return;
            }
            catch (InvalidOperationException ex)
            {
                // Handle specific streaming operation issues
                writer.TryComplete(ex);
                return;
            }
            
            writer.TryComplete();
        });

        return channel.Reader;
    }

    /// <summary>
    /// Converts a channel reader to an async enumerable
    /// </summary>
    public static async IAsyncEnumerable<T> ToAsyncEnumerable<T>(this ChannelReader<T> reader, [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(reader);
        
        await foreach (var item in reader.ReadAllAsync(cancellationToken).ConfigureAwait(false))
        {
            yield return item;
        }
    }
}