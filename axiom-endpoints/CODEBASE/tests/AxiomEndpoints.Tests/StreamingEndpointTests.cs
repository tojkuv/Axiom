using System.Buffers;
using Microsoft.AspNetCore.Http;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Tests;

public class StreamingEndpointTests
{
    [Fact]
    public void ServerStreamEndpoint_ImplementsCorrectInterface()
    {
        // Arrange
        var endpoint = new TestServerStreamEndpoint();

        // Act & Assert
        Assert.IsAssignableFrom<IServerStreamAxiom<TestRequest, TestResponse>>(endpoint);
    }

    [Fact]
    public void ClientStreamEndpoint_ImplementsCorrectInterface()
    {
        // Arrange
        var endpoint = new TestClientStreamEndpoint();

        // Act & Assert
        Assert.IsAssignableFrom<IClientStreamAxiom<TestRequest, TestResponse>>(endpoint);
    }

    [Fact]
    public void BidirectionalStreamEndpoint_ImplementsCorrectInterface()
    {
        // Arrange
        var endpoint = new TestBidirectionalStreamEndpoint();

        // Act & Assert
        Assert.IsAssignableFrom<IBidirectionalStreamAxiom<TestRequest, TestResponse>>(endpoint);
    }

    [Fact]
    public async Task ServerStreamEndpoint_StreamsResponses()
    {
        // Arrange
        var endpoint = new TestServerStreamEndpoint();
        var request = new TestRequest("test");
        var context = new TestContext();

        // Act
        var responses = new List<TestResponse>();
        await foreach (var response in endpoint.StreamAsync(request, context))
        {
            responses.Add(response);
        }

        // Assert
        Assert.Equal(3, responses.Count);
        Assert.Equal("Response 0", responses[0].Message);
        Assert.Equal("Response 1", responses[1].Message);
        Assert.Equal("Response 2", responses[2].Message);
    }

    [Fact]
    public async Task ClientStreamEndpoint_ProcessesMultipleRequests()
    {
        // Arrange
        var endpoint = new TestClientStreamEndpoint();
        var requests = new List<TestRequest>
        {
            new("Request 1"),
            new("Request 2"),
            new("Request 3")
        };
        var context = new TestContext();

        // Act
        var result = await endpoint.HandleAsync(ToAsyncEnumerable(requests), context);

        // Assert
        Assert.True(result.IsSuccess);
        Assert.Equal("Processed 3 requests", result.Value.Message);
    }

    [Fact]
    public async Task BidirectionalStreamEndpoint_ProcessesRequestsAndStreamsResponses()
    {
        // Arrange
        var endpoint = new TestBidirectionalStreamEndpoint();
        var requests = new List<TestRequest>
        {
            new("Request 1"),
            new("Request 2"),
            new("Request 3")
        };
        var context = new TestContext();

        // Act
        var responses = new List<TestResponse>();
        await foreach (var response in endpoint.StreamAsync(ToAsyncEnumerable(requests), context))
        {
            responses.Add(response);
        }

        // Assert
        Assert.Equal(3, responses.Count);
        Assert.Equal("Echo: Request 1", responses[0].Message);
        Assert.Equal("Echo: Request 2", responses[1].Message);
        Assert.Equal("Echo: Request 3", responses[2].Message);
    }

    [Fact]
    public async Task StreamingWithCancellation_StopsGracefully()
    {
        // Arrange
        var endpoint = new TestServerStreamEndpoint();
        var request = new TestRequest("test");
        using var cts = new CancellationTokenSource();
        var context = new TestContext(cts.Token);

        // Act
        var responses = new List<TestResponse>();
        try
        {
            await foreach (var response in endpoint.StreamAsync(request, context)
                .WithCancellation(cts.Token))
            {
                responses.Add(response);
                
                // Cancel after first response
                if (responses.Count == 1)
                {
                    cts.Cancel();
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Expected when cancellation occurs
        }

        // Assert
        Assert.Single(responses);
    }

    private static async IAsyncEnumerable<T> ToAsyncEnumerable<T>(IEnumerable<T> items)
    {
        foreach (var item in items)
        {
            yield return item;
            await Task.Delay(1).ConfigureAwait(false); // Small delay to ensure async behavior
        }
    }
}

// Test streaming endpoints
internal sealed class TestServerStreamEndpoint : IServerStreamAxiom<TestRequest, TestResponse>
{
    public async IAsyncEnumerable<TestResponse> StreamAsync(TestRequest request, IContext context)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(context);
        
        for (int i = 0; i < 3; i++)
        {
            // Check for cancellation before yielding each item
            context.CancellationToken.ThrowIfCancellationRequested();
            
            yield return new TestResponse($"Response {i}");
            
            // Only delay if not the last item to avoid unnecessary waiting
            if (i < 2)
            {
                await Task.Delay(100, context.CancellationToken).ConfigureAwait(false);
            }
        }
    }
}

internal sealed class TestClientStreamEndpoint : IClientStreamAxiom<TestRequest, TestResponse>
{
    public async ValueTask<Result<TestResponse>> HandleAsync(IAsyncEnumerable<TestRequest> requests, IContext context)
    {
        ArgumentNullException.ThrowIfNull(requests);
        ArgumentNullException.ThrowIfNull(context);
        
        var count = 0;
        await foreach (var request in requests.WithCancellation(default).ConfigureAwait(false))
        {
            count++;
        }
        
        return ResultFactory.Success(new TestResponse($"Processed {count} requests"));
    }
}

internal sealed class TestBidirectionalStreamEndpoint : IBidirectionalStreamAxiom<TestRequest, TestResponse>
{
    public async IAsyncEnumerable<TestResponse> StreamAsync(IAsyncEnumerable<TestRequest> requests, IContext context)
    {
        await foreach (var request in requests.WithCancellation(default).ConfigureAwait(false))
        {
            yield return new TestResponse($"Echo: {request.Message}");
        }
    }
}

internal sealed record TestRequest(string Message);
internal sealed record TestResponse(string Message);

public sealed class TestContext : IContext
{
    private readonly CancellationToken _cancellationToken;

    public TestContext(CancellationToken cancellationToken = default)
    {
        _cancellationToken = cancellationToken;
    }

    public HttpContext HttpContext => null!;
    public IServiceProvider Services => null!;
    public CancellationToken CancellationToken => _cancellationToken;
    public TimeProvider TimeProvider => TimeProvider.System;
    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T> => default;
    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T> => default;
    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T> => default;
    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T> => [];
    public bool HasQueryParameter(string key) => false;
    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute> => new Uri("/test", UriKind.Relative);
    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute> => new Uri("/test", UriKind.Relative);
    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute> { }
}