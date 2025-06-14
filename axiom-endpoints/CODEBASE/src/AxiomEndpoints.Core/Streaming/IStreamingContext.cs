using System.Buffers;
using System.Threading.Channels;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// Extended context for streaming scenarios
/// </summary>
public interface IStreamingContext : IContext
{
    /// <summary>
    /// Gets the current protocol (HTTP, WebSocket, gRPC)
    /// </summary>
    StreamingProtocol Protocol { get; }

    /// <summary>
    /// Gets a channel writer for server-initiated messages
    /// </summary>
    ChannelWriter<T> GetChannelWriter<T>(string channelName);

    /// <summary>
    /// Gets stream metadata (for gRPC headers/trailers)
    /// </summary>
    IStreamMetadata Metadata { get; }

    /// <summary>
    /// Checks if client supports streaming
    /// </summary>
    bool SupportsStreaming { get; }

    /// <summary>
    /// Gets memory pool for efficient buffer management
    /// </summary>
    new MemoryPool<byte> MemoryPool { get; }
}

public enum StreamingProtocol
{
    Http,
    ServerSentEvents,
    WebSocket,
    Grpc
}

public interface IStreamMetadata
{
    void SetHeader(string key, string value);
    void SetTrailer(string key, string value);
    IReadOnlyDictionary<string, string> Headers { get; }
    IReadOnlyDictionary<string, string> Trailers { get; }
}