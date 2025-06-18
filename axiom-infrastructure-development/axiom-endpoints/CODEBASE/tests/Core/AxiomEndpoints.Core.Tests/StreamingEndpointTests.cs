using System.Buffers;
using Microsoft.AspNetCore.Http;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Testing.Common.MockServices;
using AxiomEndpoints.Testing.Common.TestData;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Core.Tests;

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
        var context = new MockContext();

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
        var context = new MockContext();

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
        var context = new MockContext();

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
        var context = new MockContext(cts.Token);

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