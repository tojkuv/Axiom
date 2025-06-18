using System.Diagnostics;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Primitives;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Audit logging attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AuditAttribute : EndpointFilterAttribute, IEndpointResultFilter
{
    public bool IncludeRequest { get; set; } = true;
    public bool IncludeResponse { get; set; } = false;
    public string[]? SensitiveProperties { get; set; }

    private readonly Stopwatch _stopwatch = new();

    public override int Order => 100; // Run late, but before observability

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        _stopwatch.Restart();

        var logger = context.Context.HttpContext.RequestServices
            .GetRequiredService<IAuditLogger>();

        var entry = new AuditEntry
        {
            Id = Guid.NewGuid(),
            Timestamp = context.Context.TimeProvider.GetUtcNow(),
            User = context.Context.HttpContext.User.Identity?.Name,
            Action = context.EndpointType.Name,
            IpAddress = context.Context.HttpContext.Connection.RemoteIpAddress?.ToString(),
            UserAgent = context.Context.HttpContext.Request.Headers.TryGetValue("User-Agent", out StringValues userAgent) ? userAgent.ToString() : null,
            Protocol = context.Context.HttpContext.Request.Protocol,
            Method = context.Context.HttpContext.Request.Method,
            Path = context.Context.HttpContext.Request.Path,
            Request = IncludeRequest ? SanitizeData(context.Request) : null
        };

        // Store entry in context for later update
        var updatedProperties = new Dictionary<string, object>(context.Properties);
        updatedProperties["AuditEntry"] = entry;

        await logger.LogAsync(entry, context.Context.CancellationToken);

        return Result<Unit>.CreateSuccess(Unit.Value);
    }

    public async ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        _stopwatch.Stop();

        if (context.Properties.TryGetValue("AuditEntry", out var entryObj) &&
            entryObj is AuditEntry entry)
        {
            entry.Duration = _stopwatch.Elapsed;
            entry.Success = result.IsSuccess;
            entry.StatusCode = context.Context.HttpContext.Response.StatusCode;
            entry.Response = IncludeResponse && result.IsSuccess
                ? SanitizeData(result.Value)
                : null;
            entry.Error = result.IsFailure ? result.Error.Message : null;

            var logger = context.Context.HttpContext.RequestServices
                .GetRequiredService<IAuditLogger>();

            await logger.UpdateAsync(entry, context.Context.CancellationToken);
        }

        return result;
    }

    private object? SanitizeData(object? data)
    {
        if (data == null || SensitiveProperties == null || SensitiveProperties.Length == 0)
            return data;

        try
        {
            // Clone and remove sensitive properties
            var json = JsonSerializer.Serialize(data);
            var doc = JsonDocument.Parse(json);

            using var stream = new MemoryStream();
            using var writer = new Utf8JsonWriter(stream);

            WriteSanitized(doc.RootElement, writer);
            writer.Flush();

            return JsonSerializer.Deserialize<object>(stream.ToArray());
        }
        catch
        {
            // If sanitization fails, return null for safety
            return null;
        }
    }

    private void WriteSanitized(JsonElement element, Utf8JsonWriter writer)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Object:
                writer.WriteStartObject();
                foreach (var property in element.EnumerateObject())
                {
                    if (SensitiveProperties!.Contains(property.Name, StringComparer.OrdinalIgnoreCase))
                    {
                        writer.WriteString(property.Name, "[REDACTED]");
                    }
                    else
                    {
                        writer.WritePropertyName(property.Name);
                        WriteSanitized(property.Value, writer);
                    }
                }
                writer.WriteEndObject();
                break;

            case JsonValueKind.Array:
                writer.WriteStartArray();
                foreach (var item in element.EnumerateArray())
                {
                    WriteSanitized(item, writer);
                }
                writer.WriteEndArray();
                break;

            default:
                element.WriteTo(writer);
                break;
        }
    }
}

/// <summary>
/// Custom audit action attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AuditActionAttribute : EndpointResultFilterAttribute
{
    public string Action { get; }
    public string? Description { get; set; }

    public AuditActionAttribute(string action)
    {
        Action = action;
    }

    public override async ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess)
        {
            var logger = context.Context.HttpContext.RequestServices
                .GetRequiredService<IAuditLogger>();

            var entry = new AuditEntry
            {
                Id = Guid.NewGuid(),
                Timestamp = context.Context.TimeProvider.GetUtcNow(),
                User = context.Context.HttpContext.User.Identity?.Name,
                Action = Action,
                Description = Description,
                IpAddress = context.Context.HttpContext.Connection.RemoteIpAddress?.ToString(),
                Success = true
            };

            await logger.LogAsync(entry, context.Context.CancellationToken);
        }

        return result;
    }
}

public interface IAuditLogger
{
    ValueTask LogAsync(AuditEntry entry, CancellationToken cancellationToken = default);
    ValueTask UpdateAsync(AuditEntry entry, CancellationToken cancellationToken = default);
}

public record AuditEntry
{
    public Guid Id { get; init; }
    public DateTimeOffset Timestamp { get; init; }
    public string? User { get; init; }
    public string Action { get; init; } = "";
    public string? Description { get; init; }
    public string? IpAddress { get; init; }
    public string? UserAgent { get; init; }
    public string Protocol { get; init; } = "";
    public string Method { get; init; } = "";
    public string Path { get; init; } = "";
    public object? Request { get; set; }
    public object? Response { get; set; }
    public TimeSpan Duration { get; set; }
    public bool Success { get; set; }
    public int StatusCode { get; set; }
    public string? Error { get; set; }
}

/// <summary>
/// Default audit logger that logs to ILogger
/// </summary>
public class DefaultAuditLogger : IAuditLogger
{
    private readonly ILogger<DefaultAuditLogger> _logger;

    public DefaultAuditLogger(ILogger<DefaultAuditLogger> logger)
    {
        _logger = logger;
    }

    public ValueTask LogAsync(AuditEntry entry, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Audit: {Action} by {User} from {IpAddress} at {Timestamp}",
            entry.Action,
            entry.User ?? "Anonymous",
            entry.IpAddress,
            entry.Timestamp);

        return ValueTask.CompletedTask;
    }

    public ValueTask UpdateAsync(AuditEntry entry, CancellationToken cancellationToken = default)
    {
        if (entry.Success)
        {
            _logger.LogInformation(
                "Audit Complete: {Action} by {User} - {StatusCode} in {Duration}ms",
                entry.Action,
                entry.User ?? "Anonymous",
                entry.StatusCode,
                entry.Duration.TotalMilliseconds);
        }
        else
        {
            _logger.LogWarning(
                "Audit Failed: {Action} by {User} - {StatusCode} in {Duration}ms - {Error}",
                entry.Action,
                entry.User ?? "Anonymous",
                entry.StatusCode,
                entry.Duration.TotalMilliseconds,
                entry.Error);
        }

        return ValueTask.CompletedTask;
    }
}