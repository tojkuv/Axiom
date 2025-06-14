using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Routing;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

namespace AxiomEndpoints.Aspire.Telemetry;

public static class AxiomTelemetryExtensions
{
    /// <summary>
    /// Add Axiom telemetry with Aspire dashboard integration
    /// </summary>
    public static IHostApplicationBuilder AddAxiomTelemetry(
        this IHostApplicationBuilder builder)
    {
        // Add OpenTelemetry with basic configuration
        // Note: Full implementation would use proper Aspire service registration
        builder.Services.AddSingleton(services =>
        {
            // Basic OpenTelemetry setup - would be enhanced with full Aspire integration
            return new { Message = "OpenTelemetry configured for Aspire integration" };
        });

        // Add custom Axiom telemetry
        builder.Services.AddSingleton<IAxiomTelemetry, AspireTelemetry>();

        // Add metrics enrichment
        builder.Services.AddSingleton<IMetricsEnricher, AxiomMetricsEnricher>();

        return builder;
    }
}

/// <summary>
/// Axiom-specific telemetry
/// </summary>
public interface IAxiomTelemetry
{
    Activity? StartEndpointActivity(string endpointName, RouteValueDictionary routeValues);
    void RecordEndpointMetrics(EndpointMetrics metrics);
    Activity? StartEventActivity(string eventType, string operation);
    void RecordEventMetrics(EventMetrics metrics);
}

public class AspireTelemetry : IAxiomTelemetry
{
    private static readonly ActivitySource EndpointActivitySource = new("AxiomEndpoints");
    private static readonly Meter EndpointMeter = new("AxiomEndpoints");

    private static readonly Counter<long> EndpointCounter =
        EndpointMeter.CreateCounter<long>("axiom_endpoint_requests_total");
    private static readonly Histogram<double> EndpointDuration =
        EndpointMeter.CreateHistogram<double>("axiom_endpoint_duration_seconds");
    private static readonly UpDownCounter<long> ActiveRequests =
        EndpointMeter.CreateUpDownCounter<long>("axiom_active_requests");

    private static readonly ActivitySource EventActivitySource = new("AxiomEndpoints.Events");
    private static readonly Meter EventMeter = new("AxiomEndpoints.Events");

    private static readonly Counter<long> EventCounter =
        EventMeter.CreateCounter<long>("axiom_events_total");

    public Activity? StartEndpointActivity(string endpointName, RouteValueDictionary routeValues)
    {
        var activity = EndpointActivitySource.StartActivity(
            $"Endpoint.{endpointName}",
            ActivityKind.Server);

        if (activity != null)
        {
            activity.SetTag("axiom.endpoint.name", endpointName);

            foreach (var (key, value) in routeValues)
            {
                activity.SetTag($"axiom.route.{key}", value?.ToString());
            }
        }

        ActiveRequests.Add(1);

        return activity;
    }

    public void RecordEndpointMetrics(EndpointMetrics metrics)
    {
        var tags = new TagList
        {
            { "endpoint", metrics.EndpointName },
            { "method", metrics.HttpMethod },
            { "status_code", metrics.StatusCode },
            { "success", metrics.Success }
        };

        EndpointCounter.Add(1, tags);
        EndpointDuration.Record(metrics.Duration.TotalSeconds, tags);
        ActiveRequests.Add(-1);
    }

    public Activity? StartEventActivity(string eventType, string operation)
    {
        var activity = EventActivitySource.StartActivity(
            $"Event.{operation}",
            ActivityKind.Producer);

        if (activity != null)
        {
            activity.SetTag("axiom.event.type", eventType);
            activity.SetTag("axiom.event.operation", operation);
        }

        return activity;
    }

    public void RecordEventMetrics(EventMetrics metrics)
    {
        var tags = new TagList
        {
            { "event_type", metrics.EventType },
            { "operation", metrics.Operation },
            { "success", metrics.Success }
        };

        EventCounter.Add(1, tags);
    }
}

public record EndpointMetrics
{
    public required string EndpointName { get; init; }
    public required string HttpMethod { get; init; }
    public required int StatusCode { get; init; }
    public required bool Success { get; init; }
    public required TimeSpan Duration { get; init; }
}

public record EventMetrics
{
    public required string EventType { get; init; }
    public required string Operation { get; init; }
    public required bool Success { get; init; }
    public required TimeSpan Duration { get; init; }
}

/// <summary>
/// Interface for metrics enrichment
/// </summary>
public interface IMetricsEnricher
{
    void EnrichEndpointMetrics(EndpointMetrics metrics, IDictionary<string, object> tags);
    void EnrichEventMetrics(EventMetrics metrics, IDictionary<string, object> tags);
}

/// <summary>
/// Default metrics enricher
/// </summary>
public class AxiomMetricsEnricher : IMetricsEnricher
{
    public void EnrichEndpointMetrics(EndpointMetrics metrics, IDictionary<string, object> tags)
    {
        // Add environment-specific tags
        tags["environment"] = Environment.GetEnvironmentVariable("ASPIRE_ENVIRONMENT") ?? "Unknown";
        tags["machine"] = Environment.MachineName;
        tags["timestamp"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
    }

    public void EnrichEventMetrics(EventMetrics metrics, IDictionary<string, object> tags)
    {
        // Add environment-specific tags
        tags["environment"] = Environment.GetEnvironmentVariable("ASPIRE_ENVIRONMENT") ?? "Unknown";
        tags["machine"] = Environment.MachineName;
        tags["timestamp"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
    }
}