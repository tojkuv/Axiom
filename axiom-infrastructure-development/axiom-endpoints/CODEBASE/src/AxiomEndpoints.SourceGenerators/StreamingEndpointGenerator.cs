using System.Text;

namespace AxiomEndpoints.SourceGenerators;

internal static class StreamingEndpointGenerator
{
    public static void GenerateStreamingEndpointMapping(
        StringBuilder sb,
        StreamingEndpointInfo endpoint)
    {
        switch (endpoint.Mode)
        {
            case StreamingMode.ServerStream:
                GenerateServerStreamMapping(sb, endpoint);
                break;

            case StreamingMode.ClientStream:
                GenerateClientStreamMapping(sb, endpoint);
                break;

            case StreamingMode.Bidirectional:
                GenerateBidirectionalMapping(sb, endpoint);
                break;
        }
    }

    private static void GenerateServerStreamMapping(StringBuilder sb, StreamingEndpointInfo endpoint)
    {
        var template = endpoint.RouteType != null
            ? $"RouteTemplates.GetTemplate<{endpoint.RouteType}>()"
            : "\"/stream\"";

        sb.AppendLine($@"
        // Server streaming endpoint: {endpoint.TypeName}
        app.MapGet({template}, async (HttpContext httpContext) =>
        {{
            var endpoint = httpContext.RequestServices.GetRequiredService<{endpoint.Namespace}.{endpoint.TypeName}>();
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Bind request from route/query
            var request = BindRequest<{endpoint.RequestType}>(httpContext);

            // Check Accept header for SSE
            if (httpContext.Request.Headers.Accept.Contains(""text/event-stream""))
            {{
                await ServerSentEventsHandler.HandleSseAsync(httpContext, endpoint, request, context);
            }}
            else
            {{
                // Return first N items as JSON array
                var items = await endpoint.StreamAsync(request, context)
                    .Take(100)
                    .ToListAsync(httpContext.RequestAborted);

                return Results.Ok(items);
            }}
        }})
        .WithName(""{endpoint.TypeName}"")
        .WithTags(""Streaming"");");
    }

    private static void GenerateClientStreamMapping(StringBuilder sb, StreamingEndpointInfo endpoint)
    {
        var template = endpoint.RouteType != null
            ? $"RouteTemplates.GetTemplate<{endpoint.RouteType}>()"
            : "\"/stream\"";

        sb.AppendLine($@"
        // Client streaming endpoint: {endpoint.TypeName}
        app.MapPost({template}, async (HttpContext httpContext) =>
        {{
            var endpoint = httpContext.RequestServices.GetRequiredService<{endpoint.Namespace}.{endpoint.TypeName}>();
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            // Read streaming request from body
            var requestStream = ReadRequestStream<{endpoint.RequestType}>(httpContext);

            // Invoke client streaming method
            var result = await endpoint.HandleAsync(requestStream, context);

            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        }})
        .WithName(""{endpoint.TypeName}"")
        .WithTags(""Streaming"");");
    }

    private static void GenerateBidirectionalMapping(StringBuilder sb, StreamingEndpointInfo endpoint)
    {
        var template = endpoint.RouteType != null
            ? $"RouteTemplates.GetTemplate<{endpoint.RouteType}>()"
            : "\"/ws\"";

        sb.AppendLine($@"
        // Bidirectional streaming endpoint: {endpoint.TypeName}
        app.MapGet({template}, async (HttpContext httpContext) =>
        {{
            var endpoint = httpContext.RequestServices.GetRequiredService<{endpoint.Namespace}.{endpoint.TypeName}>();
            var context = httpContext.RequestServices.GetRequiredService<IContext>();

            await WebSocketHandler.HandleWebSocketAsync(httpContext, endpoint, context);
        }})
        .WithName(""{endpoint.TypeName}"")
        .WithTags(""WebSocket"");");
    }
}