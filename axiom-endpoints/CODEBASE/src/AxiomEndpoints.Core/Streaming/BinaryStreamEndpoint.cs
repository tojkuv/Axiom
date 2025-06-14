using System;
using System.Buffers;
using System.Runtime.CompilerServices;

namespace AxiomEndpoints.Core.Streaming;

/// <summary>
/// Memory-efficient binary streaming with pooled buffers
/// </summary>
public abstract record BinaryStreamEndpoint<TRequest> : IServerStreamAxiom<TRequest, BinaryChunk>
{
    protected virtual int ChunkSize => 81920; // 80KB default

    public async IAsyncEnumerable<BinaryChunk> StreamAsync(
        TRequest request,
        IContext context)
    {
        var cancellationToken = context.CancellationToken;
        using var rental = context.MemoryPool.Rent(ChunkSize);
        var buffer = rental.Memory;

        await using var stream = await OpenStreamAsync(request, context, cancellationToken);

        long totalBytesRead = 0;
        int bytesRead;

        while ((bytesRead = await stream.ReadAsync(buffer, cancellationToken)) > 0)
        {
            // Convert to byte array for now
            var data = buffer.Slice(0, bytesRead).ToArray();

            yield return new BinaryChunk
            {
                Data = data,
                Offset = totalBytesRead,
                Length = bytesRead,
                IsLast = stream.Position >= stream.Length,
                ContentType = GetContentType(request)
            };

            totalBytesRead += bytesRead;

            // Allow cooperative cancellation between chunks
            cancellationToken.ThrowIfCancellationRequested();
        }
    }

    protected abstract ValueTask<Stream> OpenStreamAsync(
        TRequest request,
        IContext context,
        CancellationToken cancellationToken);

    protected virtual string GetContentType(TRequest request) => "application/octet-stream";
}

public record BinaryChunk
{
    public required byte[] Data { get; init; }
    public required long Offset { get; init; }
    public required int Length { get; init; }
    public required bool IsLast { get; init; }
    public string ContentType { get; init; } = "application/octet-stream";
}