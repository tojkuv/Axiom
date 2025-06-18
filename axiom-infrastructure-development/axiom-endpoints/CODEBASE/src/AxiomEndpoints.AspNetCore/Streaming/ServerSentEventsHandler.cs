using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Features;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

namespace AxiomEndpoints.AspNetCore.Streaming;

public class ServerSentEventsHandler
{
    public static async Task HandleSseAsync<TRequest, TResponse>(
        HttpContext httpContext,
        IServerStreamAxiom<TRequest, TResponse> endpoint,
        TRequest request,
        IContext context)
    {
        // Set SSE headers
        httpContext.Response.Headers.ContentType = "text/event-stream";
        httpContext.Response.Headers.CacheControl = "no-cache";
        httpContext.Response.Headers.Connection = "keep-alive";

        // Disable buffering for real-time updates
        var bufferingFeature = httpContext.Features.Get<IHttpResponseBodyFeature>();
        if (bufferingFeature != null)
        {
            bufferingFeature.DisableBuffering();
        }

        await httpContext.Response.Body.FlushAsync();

        var writer = httpContext.Response.BodyWriter;
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
        };

        try
        {
            await foreach (var item in endpoint.StreamAsync(request, context)
                .WithCancellation(httpContext.RequestAborted))
            {
                // Format as SSE
                var eventData = FormatSseEvent(item, jsonOptions);
                await writer.WriteAsync(eventData, httpContext.RequestAborted);
                await writer.FlushAsync();

                // Small delay to prevent overwhelming clients
                await Task.Delay(10, httpContext.RequestAborted);
            }

            // Send completion event
            await writer.WriteAsync("event: complete\ndata: {}\n\n"u8.ToArray().AsMemory());
            await writer.FlushAsync();
        }
        catch (OperationCanceledException)
        {
            // Client disconnected - normal behavior
        }
        catch (Exception ex)
        {
            // Send error event
            var errorEvent = $"event: error\ndata: {{\"message\":\"{JsonEncodedText.Encode(ex.Message)}\"}}\n\n";
            await writer.WriteAsync(Encoding.UTF8.GetBytes(errorEvent));
            await writer.FlushAsync();
            throw;
        }
    }

    private static ReadOnlyMemory<byte> FormatSseEvent<T>(T data, JsonSerializerOptions options)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream))
        {
            writer.WriteStartObject();
            writer.WriteString("event", "message");
            writer.WritePropertyName("data");
            JsonSerializer.Serialize(writer, data, options);
            writer.WriteNumber("timestamp", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());
            writer.WriteEndObject();
        }

        var json = Encoding.UTF8.GetString(stream.ToArray());
        var sseFormat = $"event: message\ndata: {json}\n\n";
        return Encoding.UTF8.GetBytes(sseFormat);
    }
}