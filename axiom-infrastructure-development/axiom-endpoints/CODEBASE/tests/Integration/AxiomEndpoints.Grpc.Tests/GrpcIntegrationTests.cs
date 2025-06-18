using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Grpc.Net.Client;
using Grpc.Core;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Testing.Common.Helpers;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Grpc.Tests;

public class GrpcIntegrationTests : IAsyncDisposable
{
    private readonly TestServer _server;
    private readonly GrpcChannel _channel;
    private readonly TestService.TestServiceClient _client;

    public GrpcIntegrationTests()
    {
        var hostBuilder = new HostBuilder()
            .ConfigureWebHost(webHost =>
            {
                webHost
                    .UseTestServer()
                    .ConfigureServices(services =>
                    {
                        services.AddGrpc();
                        services.AddScoped<TestGrpcService>();
                    })
                    .Configure(app =>
                    {
                        app.UseRouting();
                        app.UseEndpoints(endpoints =>
                        {
                            endpoints.MapGrpcService<TestGrpcService>();
                        });
                    });
            });

        var host = hostBuilder.Start();
        _server = host.GetTestServer();

        var httpClient = _server.CreateClient();
        _channel = GrpcChannel.ForAddress(_server.BaseAddress, new GrpcChannelOptions
        {
            HttpClient = httpClient
        });

        _client = new TestService.TestServiceClient(_channel);
    }

    [Fact]
    public async Task ProcessRequest_Should_Handle_Simple_Request()
    {
        // Arrange
        var request = new TestRequest
        {
            Message = "Hello gRPC",
            Id = 42
        };

        // Act
        var response = await _client.ProcessRequestAsync(request);

        // Assert
        response.Should().NotBeNull();
        response.Message.Should().Be("Processed: Hello gRPC");
        response.Count.Should().Be(1);
        response.Success.Should().BeTrue();
    }

    [Fact]
    public async Task StreamResponses_Should_Stream_Multiple_Responses()
    {
        // Arrange
        var request = new TestRequest
        {
            Message = "Stream Test",
            Id = 123
        };

        // Act
        var responses = new List<TestResponse>();
        using var call = _client.StreamResponses(request);

        await foreach (var response in call.ResponseStream.ReadAllAsync())
        {
            responses.Add(response);
            if (responses.Count >= 3) break; // Prevent infinite streaming
        }

        // Assert
        responses.Should().HaveCount(3);
        responses[0].Message.Should().Be("Response 0");
        responses[1].Message.Should().Be("Response 1");
        responses[2].Message.Should().Be("Response 2");
    }

    [Fact]
    public async Task StreamRequests_Should_Process_Multiple_Requests()
    {
        // Arrange
        var requests = new[]
        {
            new TestRequest { Message = "Request 1", Id = 1 },
            new TestRequest { Message = "Request 2", Id = 2 },
            new TestRequest { Message = "Request 3", Id = 3 }
        };

        // Act
        using var call = _client.StreamRequests();

        foreach (var request in requests)
        {
            await call.RequestStream.WriteAsync(request);
        }
        await call.RequestStream.CompleteAsync();

        var response = await call;

        // Assert
        response.Should().NotBeNull();
        response.Message.Should().Be("Processed 3 requests");
        response.Count.Should().Be(3);
        response.Success.Should().BeTrue();
    }

    [Fact]
    public async Task BidirectionalStream_Should_Echo_Requests()
    {
        // Arrange
        var requests = new[]
        {
            new TestRequest { Message = "Echo 1", Id = 1 },
            new TestRequest { Message = "Echo 2", Id = 2 }
        };

        // Act
        using var call = _client.BidirectionalStream();
        var responses = new List<TestResponse>();

        // Start reading responses
        var readTask = Task.Run(async () =>
        {
            await foreach (var response in call.ResponseStream.ReadAllAsync())
            {
                responses.Add(response);
                if (responses.Count >= requests.Length) break;
            }
        });

        // Send requests
        foreach (var request in requests)
        {
            await call.RequestStream.WriteAsync(request);
        }
        await call.RequestStream.CompleteAsync();

        await readTask;

        // Assert
        responses.Should().HaveCount(2);
        responses[0].Message.Should().Be("Echo: Echo 1");
        responses[1].Message.Should().Be("Echo: Echo 2");
    }

    [Fact]
    public async Task Cancellation_Should_Stop_Streaming()
    {
        // Arrange
        var request = new TestRequest
        {
            Message = "Cancellation Test",
            Id = 999
        };

        using var cts = new CancellationTokenSource();

        // Act
        var responses = new List<TestResponse>();
        using var call = _client.StreamResponses(request, cancellationToken: cts.Token);

        try
        {
            await foreach (var response in call.ResponseStream.ReadAllAsync(cts.Token))
            {
                responses.Add(response);
                
                // Cancel after first response
                if (responses.Count == 1)
                {
                    cts.Cancel();
                }
            }
        }
        catch (Exception ex) when (ex is OperationCanceledException or RpcException)
        {
            // Expected when cancellation occurs
        }

        // Assert
        responses.Should().HaveCount(1);
    }

    public async ValueTask DisposeAsync()
    {
        _channel?.Dispose();
        await _server.Host.StopAsync();
        _server.Dispose();
    }
}

// Test gRPC service implementation
public class TestGrpcService : TestService.TestServiceBase
{
    public override Task<TestResponse> ProcessRequest(TestRequest request, ServerCallContext context)
    {
        var response = new TestResponse
        {
            Message = $"Processed: {request.Message}",
            Count = 1,
            Success = true
        };

        return Task.FromResult(response);
    }

    public override async Task StreamResponses(TestRequest request, IServerStreamWriter<TestResponse> responseStream, ServerCallContext context)
    {
        for (int i = 0; i < 3; i++)
        {
            if (context.CancellationToken.IsCancellationRequested)
                break;

            var response = new TestResponse
            {
                Message = $"Response {i}",
                Count = i + 1,
                Success = true
            };

            await responseStream.WriteAsync(response);
            await Task.Delay(100, context.CancellationToken);
        }
    }

    public override async Task<TestResponse> StreamRequests(IAsyncStreamReader<TestRequest> requestStream, ServerCallContext context)
    {
        var count = 0;
        await foreach (var request in requestStream.ReadAllAsync())
        {
            count++;
        }

        return new TestResponse
        {
            Message = $"Processed {count} requests",
            Count = count,
            Success = true
        };
    }

    public override async Task BidirectionalStream(IAsyncStreamReader<TestRequest> requestStream, IServerStreamWriter<TestResponse> responseStream, ServerCallContext context)
    {
        await foreach (var request in requestStream.ReadAllAsync())
        {
            var response = new TestResponse
            {
                Message = $"Echo: {request.Message}",
                Count = request.Id,
                Success = true
            };

            await responseStream.WriteAsync(response);
        }
    }
}