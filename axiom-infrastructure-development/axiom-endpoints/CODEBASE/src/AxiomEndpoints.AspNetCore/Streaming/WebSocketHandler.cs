using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Channels;
using Microsoft.AspNetCore.Http;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.AspNetCore.Streaming;

public class WebSocketHandler
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public static async Task HandleWebSocketAsync<TRequest, TResponse>(
        HttpContext httpContext,
        IBidirectionalStreamAxiom<TRequest, TResponse> endpoint,
        IContext context)
    {
        if (!httpContext.WebSockets.IsWebSocketRequest)
        {
            httpContext.Response.StatusCode = StatusCodes.Status400BadRequest;
            return;
        }

        using var webSocket = await httpContext.WebSockets.AcceptWebSocketAsync();

        // Create channels for bidirectional communication
        var receiveChannel = Channel.CreateUnbounded<TRequest>();
        var sendChannel = Channel.CreateUnbounded<TResponse>();

        // Start receive task
        var receiveTask = ReceiveAsync(webSocket, receiveChannel.Writer, httpContext.RequestAborted);

        // Start send task
        var sendTask = SendAsync(webSocket, sendChannel.Reader, httpContext.RequestAborted);

        // Process messages through endpoint
        var processingTask = ProcessAsync(
            endpoint,
            receiveChannel.Reader,
            sendChannel.Writer,
            context,
            httpContext.RequestAborted);

        // Wait for any task to complete
        await Task.WhenAny(receiveTask, sendTask, processingTask);

        // Cancel all tasks
        receiveChannel.Writer.TryComplete();
        sendChannel.Writer.TryComplete();

        // Close WebSocket
        if (webSocket.State == WebSocketState.Open)
        {
            await webSocket.CloseAsync(
                WebSocketCloseStatus.NormalClosure,
                "Closing",
                CancellationToken.None);
        }
    }

    private static async Task ReceiveAsync<TRequest>(
        WebSocket webSocket,
        ChannelWriter<TRequest> writer,
        CancellationToken cancellationToken)
    {
        var buffer = new ArraySegment<byte>(new byte[4096]);

        try
        {
            while (webSocket.State == WebSocketState.Open && !cancellationToken.IsCancellationRequested)
            {
                using var ms = new MemoryStream();
                WebSocketReceiveResult result;

                do
                {
                    result = await webSocket.ReceiveAsync(buffer, cancellationToken);

                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        return;
                    }

                    ms.Write(buffer.Array!, buffer.Offset, result.Count);
                } while (!result.EndOfMessage);

                if (result.MessageType == WebSocketMessageType.Text)
                {
                    var json = Encoding.UTF8.GetString(ms.ToArray());
                    var message = JsonSerializer.Deserialize<TRequest>(json, JsonOptions);

                    if (message != null)
                    {
                        await writer.WriteAsync(message, cancellationToken);
                    }
                }
            }
        }
        finally
        {
            writer.TryComplete();
        }
    }

    private static async Task SendAsync<TResponse>(
        WebSocket webSocket,
        ChannelReader<TResponse> reader,
        CancellationToken cancellationToken)
    {
        await foreach (var message in reader.ReadAllAsync(cancellationToken))
        {
            var json = JsonSerializer.Serialize(message, JsonOptions);
            var bytes = Encoding.UTF8.GetBytes(json);

            await webSocket.SendAsync(
                new ArraySegment<byte>(bytes),
                WebSocketMessageType.Text,
                endOfMessage: true,
                cancellationToken);
        }
    }

    private static async Task ProcessAsync<TRequest, TResponse>(
        IBidirectionalStreamAxiom<TRequest, TResponse> endpoint,
        ChannelReader<TRequest> input,
        ChannelWriter<TResponse> output,
        IContext context,
        CancellationToken cancellationToken)
    {
        try
        {
            var responses = endpoint.StreamAsync(
                input.ReadAllAsync(cancellationToken),
                context);

            await foreach (var response in responses.WithCancellation(cancellationToken))
            {
                await output.WriteAsync(response, cancellationToken);
            }
        }
        finally
        {
            output.TryComplete();
        }
    }
}