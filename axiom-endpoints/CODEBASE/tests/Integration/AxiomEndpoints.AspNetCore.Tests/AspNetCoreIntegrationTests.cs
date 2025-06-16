using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using AxiomEndpoints.Core;
using AxiomEndpoints.AspNetCore;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;
using System.Text.Json;
using System.Text;
using Microsoft.AspNetCore.Http;
using System.Buffers;
using Microsoft.AspNetCore.Builder;

namespace AxiomEndpoints.AspNetCore.Tests;

public class AspNetCoreIntegrationTests : IAsyncDisposable
{
    private readonly TestServer _server;
    private readonly HttpClient _client;

    public AspNetCoreIntegrationTests()
    {
        var builder = WebApplication.CreateBuilder();
        
        builder.Services.AddAxiomEndpoints();
        builder.Services.AddScoped<SimpleEndpoint>();
        builder.Services.AddScoped<ErrorEndpoint>();
        builder.Services.AddScoped<UserByIdEndpoint>();
        builder.Services.AddScoped<SearchEndpoint>();
        
        builder.WebHost.UseTestServer();
        
        var app = builder.Build();
        
        // Manual endpoint mapping for integration tests
        app.MapPost("/test/simple", async (TestRequest request, SimpleEndpoint endpoint) =>
        {
            var context = new TestContext();
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.MapPost("/test/error", async (TestRequest request, ErrorEndpoint endpoint) =>
        {
            var context = new TestContext();
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.MapGet("/users/{userId:guid}", async (Guid userId, UserByIdEndpoint endpoint) =>
        {
            var context = new TestContext();
            var request = new UserByIdRequest(userId);
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.MapGet("/search", async (string query, int page, int limit, SearchEndpoint endpoint) =>
        {
            var context = new TestContext();
            var request = new SearchRequest(query, page, limit);
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.Start();
        _server = app.GetTestServer();
        _client = _server.CreateClient();
    }

    [Fact]
    public async Task SimpleEndpoint_Should_Process_Request_Successfully()
    {
        // Arrange
        var request = new TestRequest("Hello World");
        var jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };
        var json = JsonSerializer.Serialize(request, jsonOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Act
        var response = await _client.PostAsync("/test/simple", content);

        // Assert
        response.Should().BeSuccessful();
        var responseContent = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<TestResponse>(responseContent, jsonOptions);
        result!.Message.Should().Be("Processed: Hello World");
    }

    [Fact]
    public async Task ErrorEndpoint_Should_Return_Error_Response()
    {
        // Arrange
        var request = new TestRequest("Test Error");
        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Act
        var response = await _client.PostAsync("/test/error", content);

        // Assert
        response.Should().HaveClientError();
        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("Test error");
    }

    [Fact]
    public async Task RouteParameters_Should_Be_Bound_Correctly()
    {
        // Arrange
        var userId = Guid.NewGuid();

        // Act
        var response = await _client.GetAsync($"/users/{userId}");

        // Assert
        response.Should().BeSuccessful();
        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain(userId.ToString());
    }

    [Fact]
    public async Task QueryParameters_Should_Be_Parsed_Correctly()
    {
        // Arrange
        var query = "test search";
        var page = 2;
        var limit = 50;

        // Act
        var response = await _client.GetAsync($"/search?query={Uri.EscapeDataString(query)}&page={page}&limit={limit}");

        // Assert
        response.Should().BeSuccessful();
        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain(query);
        responseContent.Should().Contain(page.ToString());
        responseContent.Should().Contain(limit.ToString());
    }

    [Fact]
    public async Task InvalidRoute_Should_Return_NotFound()
    {
        // Act
        var response = await _client.GetAsync("/non-existent-route");

        // Assert
        response.Should().HaveClientError();
        response.StatusCode.Should().Be(System.Net.HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task InvalidMethodOnValidRoute_Should_Return_MethodNotAllowed()
    {
        // Act
        var response = await _client.DeleteAsync("/test/simple");

        // Assert
        response.Should().HaveClientError();
        response.StatusCode.Should().Be(System.Net.HttpStatusCode.MethodNotAllowed);
    }

    [Fact]
    public async Task ConstraintValidation_Should_Reject_Invalid_Parameters()
    {
        // Act - Invalid GUID
        var response = await _client.GetAsync("/users/not-a-guid");

        // Assert - Route constraints return 404 when no route matches
        response.Should().HaveClientError();
        response.StatusCode.Should().Be(System.Net.HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task ContentNegotiation_Should_Work_With_Different_Accept_Headers()
    {
        // Arrange
        var request = new TestRequest("Content Test");
        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        _client.DefaultRequestHeaders.Clear();
        _client.DefaultRequestHeaders.Add("Accept", "application/json");

        // Act
        var response = await _client.PostAsync("/test/simple", content);

        // Assert
        response.Should().BeSuccessful();
        response.Content.Headers.ContentType?.MediaType.Should().Be("application/json");
    }

    public async ValueTask DisposeAsync()
    {
        _client.Dispose();
        _server.Dispose();
        GC.SuppressFinalize(this);
        await ValueTask.CompletedTask.ConfigureAwait(false);
    }
}

// Test endpoint implementations
public sealed record UserByIdRequest(Guid UserId);
public sealed record SearchRequest(string Query, int Page, int Limit);

public sealed class UserByIdEndpoint : IAxiom<UserByIdRequest, TestResponse>
{
    public ValueTask<Result<TestResponse>> HandleAsync(UserByIdRequest request, IContext context)
    {
        return ValueTask.FromResult(ResultFactory.Success(new TestResponse($"User: {request.UserId}")));
    }
}

public sealed class SearchEndpoint : IAxiom<SearchRequest, TestResponse>
{
    public ValueTask<Result<TestResponse>> HandleAsync(SearchRequest request, IContext context)
    {
        return ValueTask.FromResult(ResultFactory.Success(new TestResponse($"Search: {request.Query}, Page: {request.Page}, Limit: {request.Limit}")));
    }
}

public sealed class TestContext : IContext
{
    public CancellationToken CancellationToken { get; } = CancellationToken.None;
    public HttpContext HttpContext { get; } = new DefaultHttpContext();
    public IServiceProvider Services => HttpContext.RequestServices;
    public TimeProvider TimeProvider => TimeProvider.System;
    public MemoryPool<byte> MemoryPool => MemoryPool<byte>.Shared;

    public T? GetRouteValue<T>(string key) where T : IParsable<T>
    {
        return default(T);
    }

    public T? GetQueryValue<T>(string key) where T : struct, IParsable<T>
    {
        return default(T);
    }

    public T? GetQueryValueRef<T>(string key) where T : class, IParsable<T>
    {
        return default(T);
    }

    public IEnumerable<T> GetQueryValues<T>(string key) where T : IParsable<T>
    {
        return Enumerable.Empty<T>();
    }

    public bool HasQueryParameter(string key)
    {
        return false;
    }

    public Uri GenerateUrl<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        return new Uri("http://localhost/");
    }

    public Uri GenerateUrlWithQuery<TRoute>(TRoute route, object? queryParameters = null) where TRoute : IRoute<TRoute>
    {
        return new Uri("http://localhost/");
    }

    public void SetLocation<TRoute>(TRoute route) where TRoute : IRoute<TRoute>
    {
        // No-op for tests
    }
}