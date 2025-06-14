using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Security.Claims;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// OpenTelemetry metrics and tracing
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ObservableAttribute : EndpointFilterAttribute, IEndpointResultFilter
{
    public static readonly Meter Meter = new("AxiomEndpoints", "1.0");
    public static readonly ActivitySource ActivitySource = new("AxiomEndpoints");
    private static readonly Counter<long> RequestCounter = Meter.CreateCounter<long>("axiom_requests_total");
    private static readonly Histogram<double> RequestDuration = Meter.CreateHistogram<double>("axiom_request_duration_seconds");
    private static readonly Counter<long> ErrorCounter = Meter.CreateCounter<long>("axiom_errors_total");

    private readonly Stopwatch _stopwatch = new();

    public override int Order => 200; // Run last

    public override ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        _stopwatch.Restart();

        // Start activity for distributed tracing
        var activity = ActivitySource.StartActivity($"Endpoint.{context.EndpointType.Name}");

        if (activity != null)
        {
            activity.SetTag("endpoint.type", context.EndpointType.FullName);
            activity.SetTag("http.method", context.Context.HttpContext.Request.Method);
            activity.SetTag("http.route", context.Metadata.Template);
            activity.SetTag("user.id", context.Context.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

            // Store activity in context for later
            var updatedProperties = new Dictionary<string, object>(context.Properties);
            updatedProperties["Activity"] = activity;
        }

        return ValueTask.FromResult(Result<Unit>.CreateSuccess(Unit.Value));
    }

    public ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        _stopwatch.Stop();

        var tags = new TagList
        {
            { "endpoint", context.EndpointType.Name },
            { "method", context.Context.HttpContext.Request.Method },
            { "status", result.IsSuccess ? "success" : "failure" },
            { "status_code", context.Context.HttpContext.Response.StatusCode.ToString() }
        };

        // Record metrics
        RequestCounter.Add(1, tags);
        RequestDuration.Record(_stopwatch.Elapsed.TotalSeconds, tags);

        if (result.IsFailure)
        {
            var errorTags = new TagList
            {
                { "endpoint", context.EndpointType.Name },
                { "error_type", result.Error.Type.ToString() },
                { "error_code", result.Error.Code }
            };
            ErrorCounter.Add(1, errorTags);
        }

        // Update activity
        if (context.Properties.TryGetValue("Activity", out var activityObj) &&
            activityObj is Activity activity)
        {
            activity.SetTag("http.status_code", context.Context.HttpContext.Response.StatusCode);
            activity.SetTag("endpoint.duration_ms", _stopwatch.ElapsedMilliseconds);

            if (result.IsFailure)
            {
                activity.SetStatus(ActivityStatusCode.Error, result.Error.Message);
                activity.SetTag("error.type", result.Error.Type.ToString());
                activity.SetTag("error.code", result.Error.Code);
            }
            else
            {
                activity.SetStatus(ActivityStatusCode.Ok);
            }

            activity.Dispose();
        }

        return ValueTask.FromResult(result);
    }
}

/// <summary>
/// Custom metric attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class MetricAttribute : EndpointResultFilterAttribute
{
    private readonly string _metricName;
    private readonly MetricType _type;
    private readonly string? _description;

    public MetricAttribute(string metricName, MetricType type = MetricType.Counter, string? description = null)
    {
        _metricName = metricName;
        _type = type;
        _description = description;
    }

    public override ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (result.IsSuccess && _type == MetricType.Counter)
        {
            var counter = ObservableAttribute.Meter.CreateCounter<long>(_metricName, description: _description);
            counter.Add(1, new TagList { { "endpoint", context.EndpointType.Name } });
        }

        return ValueTask.FromResult(result);
    }
}

/// <summary>
/// Custom tracing attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class TracingAttribute : EndpointFilterAttribute, IEndpointResultFilter
{
    public string? OperationName { get; set; }
    public bool IncludeRequest { get; set; } = false;
    public bool IncludeResponse { get; set; } = false;

    public override ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var operationName = OperationName ?? $"{context.EndpointType.Name}";
        var activity = ObservableAttribute.ActivitySource.StartActivity(operationName);

        if (activity != null)
        {
            activity.SetTag("component", "AxiomEndpoints");
            activity.SetTag("endpoint.name", context.EndpointType.Name);
            
            if (IncludeRequest)
            {
                activity.SetTag("request.data", System.Text.Json.JsonSerializer.Serialize(context.Request));
            }

            var updatedProperties = new Dictionary<string, object>(context.Properties);
            updatedProperties["TracingActivity"] = activity;
        }

        return ValueTask.FromResult(Result<Unit>.CreateSuccess(Unit.Value));
    }

    public ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        if (context.Properties.TryGetValue("TracingActivity", out var activityObj) &&
            activityObj is Activity activity)
        {
            if (IncludeResponse && result.IsSuccess)
            {
                activity.SetTag("response.data", System.Text.Json.JsonSerializer.Serialize(result.Value));
            }

            if (result.IsFailure)
            {
                activity.SetStatus(ActivityStatusCode.Error, result.Error.Message);
                activity.SetTag("error.message", result.Error.Message);
                activity.SetTag("error.code", result.Error.Code);
            }

            activity.Dispose();
        }

        return ValueTask.FromResult(result);
    }
}

/// <summary>
/// Performance monitoring attribute
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class PerformanceMonitorAttribute : EndpointFilterAttribute, IEndpointResultFilter
{
    private static readonly Histogram<double> PerformanceHistogram = 
        ObservableAttribute.Meter.CreateHistogram<double>("axiom_performance_duration_seconds");

    public double SlowThresholdSeconds { get; set; } = 1.0;

    private readonly Stopwatch _stopwatch = new();

    public override ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        _stopwatch.Restart();
        return ValueTask.FromResult(Result<Unit>.CreateSuccess(Unit.Value));
    }

    public ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        _stopwatch.Stop();
        var duration = _stopwatch.Elapsed.TotalSeconds;

        var tags = new TagList
        {
            { "endpoint", context.EndpointType.Name },
            { "slow", duration > SlowThresholdSeconds ? "true" : "false" }
        };

        PerformanceHistogram.Record(duration, tags);

        // Log slow requests
        if (duration > SlowThresholdSeconds)
        {
            var logger = context.Context.HttpContext.RequestServices
                .GetService(typeof(ILogger<PerformanceMonitorAttribute>)) as ILogger<PerformanceMonitorAttribute>;
            
            logger?.LogWarning(
                "Slow request detected: {Endpoint} took {Duration}ms",
                context.EndpointType.Name,
                _stopwatch.ElapsedMilliseconds);
        }

        return ValueTask.FromResult(result);
    }
}

public enum MetricType
{
    Counter,
    Histogram,
    Gauge
}

/// <summary>
/// Health check attribute for endpoints
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class HealthCheckAttribute : EndpointResultFilterAttribute
{
    private static readonly Counter<long> HealthCounter = 
        ObservableAttribute.Meter.CreateCounter<long>("axiom_health_checks_total");

    public override ValueTask<Result<TResponse>> OnExecutedAsync<TResponse>(
        Result<TResponse> result,
        EndpointFilterContext context)
    {
        var tags = new TagList
        {
            { "endpoint", context.EndpointType.Name },
            { "healthy", result.IsSuccess ? "true" : "false" }
        };

        HealthCounter.Add(1, tags);

        return ValueTask.FromResult(result);
    }
}