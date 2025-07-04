using System.Buffers;
using System.Runtime.CompilerServices;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.AspNetCore;
using AxiomEndpoints.Testing.Common.TestData;
using Xunit;

namespace AxiomEndpoints.AspNetCore.Tests;

/// <summary>
/// Streaming integration tests converted from test-streaming.sh
/// Tests Server-Sent Events, real-time data streaming, and streaming endpoint scenarios
/// </summary>
public class StreamingIntegrationTests : IAsyncDisposable
{
    private readonly TestServer _server;
    private readonly HttpClient _client;

    public StreamingIntegrationTests()
    {
        var builder = WebApplication.CreateBuilder();
        
        builder.Services.AddAxiomEndpoints();
        builder.Services.AddScoped<StreamTodosEndpoint>();
        builder.Services.AddScoped<TodoNotificationStreamEndpoint>();
        builder.Services.AddScoped<RealTimeUpdateStreamEndpoint>();
        
        builder.WebHost.UseTestServer();
        
        var app = builder.Build();
        
        // Map streaming endpoints
        app.MapGet("/streamtodosrequest", ([AsParameters] StreamTodosQuery query, StreamTodosEndpoint endpoint) =>
        {
            var context = new TestStreamingContext();
            var request = new StreamTodosRequest(query.MaxUpdates ?? 5, query.IntervalSeconds ?? 2);
            
            return Results.Stream(async stream =>
            {
                using var writer = new StreamWriter(stream);
                
                await foreach (var todo in endpoint.StreamAsync(request, context).ConfigureAwait(false))
                {
                    var json = JsonSerializer.Serialize(todo);
                    var data = $"data: {json}\n\n";
                    await writer.WriteAsync(data).ConfigureAwait(false);
                    await writer.FlushAsync().ConfigureAwait(false);
                }
            }, "text/event-stream");
        });
        
        app.MapGet("/notifications/stream", ([AsParameters] NotificationStreamQuery query, TodoNotificationStreamEndpoint endpoint) =>
        {
            var context = new TestStreamingContext();
            var request = new NotificationStreamRequest(query.UserId ?? Guid.NewGuid(), query.MaxEvents ?? 10);
            
            return Results.Stream(async stream =>
            {
                using var writer = new StreamWriter(stream);
                
                await foreach (var notification in endpoint.StreamAsync(request, context).ConfigureAwait(false))
                {
                    var json = JsonSerializer.Serialize(notification);
                    var data = $"data: {json}\n\n";
                    await writer.WriteAsync(data).ConfigureAwait(false);
                    await writer.FlushAsync().ConfigureAwait(false);
                }
            }, "text/event-stream");
        });
        
        app.MapGet("/realtime/updates", ([AsParameters] RealTimeQuery query, RealTimeUpdateStreamEndpoint endpoint) =>
        {
            var context = new TestStreamingContext();
            var request = new RealTimeUpdateRequest(query.Channel ?? "default", query.Duration ?? 10);
            
            return Results.Stream(async stream =>
            {
                using var writer = new StreamWriter(stream);
                
                await foreach (var update in endpoint.StreamAsync(request, context).ConfigureAwait(false))
                {
                    var json = JsonSerializer.Serialize(update);
                    var data = $"data: {json}\n\n";
                    await writer.WriteAsync(data).ConfigureAwait(false);
                    await writer.FlushAsync().ConfigureAwait(false);
                }
            }, "text/event-stream");
        });
        
        app.Start();
        _server = app.GetTestServer();
        _client = _server.CreateClient();
    }

    [Fact]
    public async Task StreamTodos_ServerSentEvents_StreamsCorrectly()
    {
        // Test scenario from test-streaming.sh line 12-13
        using var response = await _client.GetAsync("/streamtodosrequest?maxupdates=3&intervalseconds=1");
        
        response.Should().BeSuccessful();
        response.Content.Headers.ContentType?.MediaType.Should().Be("text/event-stream");
        response.Headers.CacheControl?.NoCache.Should().BeTrue();
        
        var stream = await response.Content.ReadAsStreamAsync();
        var reader = new StreamReader(stream);
        
        var events = new List<string>();
        var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        
        try
        {
            while (!timeoutCts.Token.IsCancellationRequested && events.Count < 3)
            {
                var line = await reader.ReadLineAsync();
                if (line != null && line.StartsWith("data: "))
                {
                    events.Add(line);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Expected timeout behavior
        }
        
        events.Should().HaveCountGreaterThan(0);
        events.Should().HaveCountLessOrEqualTo(3);
        
        // Verify event format
        foreach (var eventData in events)
        {
            eventData.Should().StartWith("data: ");
            var jsonData = eventData.Substring(6); // Remove "data: " prefix
            var action = () => JsonSerializer.Deserialize<TodoStreamEvent>(jsonData);
            action.Should().NotThrow();
        }
    }

    [Fact]
    public async Task NotificationStream_MultipleEvents_StreamsCorrectly()
    {
        // Test scenario similar to test-streaming.sh for notifications
        var userId = Guid.NewGuid();
        using var response = await _client.GetAsync($"/notifications/stream?userId={userId}&maxEvents=5");
        
        response.Should().BeSuccessful();
        response.Content.Headers.ContentType?.MediaType.Should().Be("text/event-stream");
        
        var stream = await response.Content.ReadAsStreamAsync();
        var reader = new StreamReader(stream);
        
        var notifications = new List<NotificationEvent>();
        var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        
        try
        {
            while (!timeoutCts.Token.IsCancellationRequested && notifications.Count < 5)
            {
                var line = await reader.ReadLineAsync();
                if (line != null && line.StartsWith("data: "))
                {
                    var jsonData = line.Substring(6);
                    var notification = JsonSerializer.Deserialize<NotificationEvent>(jsonData);
                    if (notification != null)
                    {
                        notifications.Add(notification);
                    }
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Expected timeout
        }
        
        notifications.Should().HaveCountGreaterThan(0);
        notifications.All(n => n.UserId == userId).Should().BeTrue();
        notifications.All(n => !string.IsNullOrEmpty(n.Type)).Should().BeTrue();
    }

    [Fact]
    public async Task RealTimeUpdates_ContinuousStream_WorksCorrectly()
    {
        // Test continuous real-time updates
        using var response = await _client.GetAsync("/realtime/updates?channel=test&duration=5");
        
        response.Should().BeSuccessful();
        response.Content.Headers.ContentType?.MediaType.Should().Be("text/event-stream");
        
        var stream = await response.Content.ReadAsStreamAsync();
        var reader = new StreamReader(stream);
        
        var updates = new List<RealTimeUpdate>();
        var startTime = DateTime.UtcNow;
        var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(8));
        
        try
        {
            while (!timeoutCts.Token.IsCancellationRequested)
            {
                var line = await reader.ReadLineAsync();
                if (line != null && line.StartsWith("data: "))
                {
                    var jsonData = line.Substring(6);
                    var update = JsonSerializer.Deserialize<RealTimeUpdate>(jsonData);
                    if (update != null)
                    {
                        updates.Add(update);
                    }
                }
                
                // Break if we've been streaming for the expected duration
                if (DateTime.UtcNow - startTime > TimeSpan.FromSeconds(6))
                {
                    break;
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Expected timeout
        }
        
        updates.Should().HaveCountGreaterThan(0);
        updates.All(u => u.Channel == "test").Should().BeTrue();
        updates.All(u => u.Timestamp > startTime).Should().BeTrue();
    }

    [Fact]
    public async Task StreamingEndpoint_InvalidParameters_HandlesGracefully()
    {
        // Test edge cases and error handling
        var testCases = new[]
        {
            "/streamtodosrequest?maxupdates=0",
            "/streamtodosrequest?intervalseconds=0",
            "/streamtodosrequest?maxupdates=-1",
            "/notifications/stream", // Missing userId
            "/realtime/updates?duration=-1"
        };

        foreach (var testCase in testCases)
        {
            using var response = await _client.GetAsync(testCase);
            
            // Should either succeed with sensible defaults or return appropriate error
            if (response.IsSuccessStatusCode)
            {
                response.Content.Headers.ContentType?.MediaType.Should().Be("text/event-stream");
            }
            else
            {
                response.Should().HaveClientError();
            }
        }
    }

    [Fact]
    public async Task StreamingEndpoint_ConnectionInterruption_HandlesCorrectly()
    {
        // Test streaming behavior when connection is interrupted
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
        
        try
        {
            using var response = await _client.GetAsync("/streamtodosrequest?maxupdates=10&intervalseconds=1", cts.Token);
            var stream = await response.Content.ReadAsStreamAsync();
            var reader = new StreamReader(stream);
            
            // Read a few events then cancel
            var eventsRead = 0;
            while (eventsRead < 5 && !cts.Token.IsCancellationRequested)
            {
                var line = await reader.ReadLineAsync();
                if (line != null && line.StartsWith("data: "))
                {
                    eventsRead++;
                }
            }
            
            eventsRead.Should().BeGreaterThan(0);
        }
        catch (OperationCanceledException)
        {
            // Expected when cancellation token fires
        }
    }

    public async ValueTask DisposeAsync()
    {
        _client.Dispose();
        _server.Dispose();
        GC.SuppressFinalize(this);
        await ValueTask.CompletedTask.ConfigureAwait(false);
    }
}

// Streaming query models
public class StreamTodosQuery
{
    public int? MaxUpdates { get; set; }
    public int? IntervalSeconds { get; set; }
}

public class NotificationStreamQuery
{
    public Guid? UserId { get; set; }
    public int? MaxEvents { get; set; }
}

public class RealTimeQuery
{
    public string? Channel { get; set; }
    public int? Duration { get; set; }
}

// Streaming request/response models
public sealed record StreamTodosRequest(int MaxUpdates = 5, int IntervalSeconds = 2);
public sealed record NotificationStreamRequest(Guid UserId, int MaxEvents = 10);
public sealed record RealTimeUpdateRequest(string Channel = "default", int Duration = 10);

public sealed record TodoStreamEvent(
    Guid Id,
    string Title,
    string Action,
    DateTime Timestamp
);

public sealed record NotificationEvent(
    Guid UserId,
    string Type,
    string Message,
    DateTime Timestamp,
    object? Data = null
);

public sealed record RealTimeUpdate(
    string Channel,
    string Type,
    DateTime Timestamp,
    object? Payload = null
);

// Streaming endpoint implementations
public sealed class StreamTodosEndpoint : IServerStreamAxiom<StreamTodosRequest, TodoStreamEvent>
{
    public async IAsyncEnumerable<TodoStreamEvent> StreamAsync(
        StreamTodosRequest request, 
        IContext context)
    {
        var count = 0;
        var cancellationToken = context.CancellationToken;
        
        while (count < request.MaxUpdates && !cancellationToken.IsCancellationRequested)
        {
            yield return new TodoStreamEvent(
                Guid.NewGuid(),
                $"Streaming Todo {count + 1}",
                "created",
                DateTime.UtcNow
            );
            
            count++;
            
            if (count < request.MaxUpdates)
            {
                await Task.Delay(TimeSpan.FromSeconds(request.IntervalSeconds), cancellationToken).ConfigureAwait(false);
            }
        }
    }
}

public sealed class TodoNotificationStreamEndpoint : IServerStreamAxiom<NotificationStreamRequest, NotificationEvent>
{
    public async IAsyncEnumerable<NotificationEvent> StreamAsync(
        NotificationStreamRequest request, 
        IContext context)
    {
        var eventTypes = new[] { "todo_created", "todo_updated", "todo_completed", "reminder" };
#pragma warning disable CA5394 // Do not use insecure randomness
        var random = new Random();
#pragma warning restore CA5394
        var count = 0;
        var cancellationToken = context.CancellationToken;
        
        while (count < request.MaxEvents && !cancellationToken.IsCancellationRequested)
        {
            yield return new NotificationEvent(
                request.UserId,
#pragma warning disable CA5394 // Do not use insecure randomness
                eventTypes[random.Next(eventTypes.Length)],
#pragma warning restore CA5394
                $"Notification {count + 1} for user {request.UserId}",
                DateTime.UtcNow,
                new { sequenceNumber = count + 1 }
            );
            
            count++;
            
            if (count < request.MaxEvents)
            {
                await Task.Delay(TimeSpan.FromSeconds(1), cancellationToken).ConfigureAwait(false);
            }
        }
    }
}

public sealed class RealTimeUpdateStreamEndpoint : IServerStreamAxiom<RealTimeUpdateRequest, RealTimeUpdate>
{
    public async IAsyncEnumerable<RealTimeUpdate> StreamAsync(
        RealTimeUpdateRequest request, 
        IContext context)
    {
        var startTime = DateTime.UtcNow;
        var endTime = startTime.AddSeconds(request.Duration);
        var updateTypes = new[] { "status_change", "data_update", "user_action", "system_event" };
#pragma warning disable CA5394 // Do not use insecure randomness
        var random = new Random();
#pragma warning restore CA5394
        var cancellationToken = context.CancellationToken;
        
        while (DateTime.UtcNow < endTime && !cancellationToken.IsCancellationRequested)
        {
            yield return new RealTimeUpdate(
                request.Channel,
#pragma warning disable CA5394 // Do not use insecure randomness
                updateTypes[random.Next(updateTypes.Length)],
#pragma warning restore CA5394
                DateTime.UtcNow,
                new { 
                    channel = request.Channel,
                    elapsedSeconds = (DateTime.UtcNow - startTime).TotalSeconds,
#pragma warning disable CA5394 // Do not use insecure randomness
                    randomValue = random.Next(1000)
#pragma warning restore CA5394
                }
            );
            
            await Task.Delay(TimeSpan.FromMilliseconds(500), cancellationToken).ConfigureAwait(false);
        }
    }
}

// Test streaming context
public sealed class TestStreamingContext : IContext
{
    public CancellationToken CancellationToken { get; } = CancellationToken.None;
    public HttpContext HttpContext { get; } = new DefaultHttpContext();
    public IServiceProvider Services => HttpContext.RequestServices;
    public TimeProvider TimeProvider => TimeProvider.System;
    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T> => default(T);
    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T> => default(T);
    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T> => default(T);
    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T> => Enumerable.Empty<T>();
    public bool HasQueryParameter(string key) => false;
    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute> => new Uri("http://localhost/");
    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute> => new Uri("http://localhost/");
    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute> { }
}