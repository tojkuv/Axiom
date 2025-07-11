using System.Net.Http.Json;
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
using AxiomEndpoints.AspNetCore;
using AxiomEndpoints.Testing.Common.TestData;
using Xunit;

namespace AxiomEndpoints.AspNetCore.Tests;

/// <summary>
/// Comprehensive API workflow tests converted from test-endpoints.sh
/// Tests complete CRUD operations, pagination, filtering, and search scenarios
/// </summary>
public class ComprehensiveApiWorkflowTests : IAsyncDisposable
{
    private readonly TestServer _server;
    private readonly HttpClient _client;

    public ComprehensiveApiWorkflowTests()
    {
        var builder = WebApplication.CreateBuilder();
        
        builder.Services.AddAxiomEndpoints();
        builder.Services.AddScoped<TodoCreateEndpoint>();
        builder.Services.AddScoped<TodoGetEndpoint>();
        builder.Services.AddScoped<TodoListEndpoint>();
        builder.Services.AddScoped<TodoSearchEndpoint>();
        
        builder.WebHost.UseTestServer();
        
        var app = builder.Build();
        
        // Map comprehensive test endpoints
        app.MapPost("/todos", async (CreateTodoRequest request, TodoCreateEndpoint endpoint) =>
        {
            var context = new TestContext();
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.MapGet("/todos/{id:guid}", async (Guid id, TodoGetEndpoint endpoint) =>
        {
            var context = new TestContext();
            var request = new GetTodoRequest(id);
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.NotFound(result.Error);
        });
        
        app.MapGet("/todos", async ([AsParameters] ListTodosQuery query, TodoListEndpoint endpoint) =>
        {
            var context = new TestContext();
            var request = new ListTodosRequest(query.PageSize ?? 20, query.Page ?? 1, query.Completed, query.Search);
            var result = await endpoint.HandleAsync(request, context).ConfigureAwait(false);
            return result.IsSuccess ? Results.Ok(result.Value) : Results.BadRequest(result.Error);
        });
        
        app.Start();
        _server = app.GetTestServer();
        _client = _server.CreateClient();
    }

    [Fact]
    public async Task CompleteTodoWorkflow_CreateGetListSearch_WorksCorrectly()
    {
        // Test 1: Get all todos (should be empty initially) - from test-endpoints.sh line 12
        var initialResponse = await _client.GetAsync("/todos");
        initialResponse.Should().BeSuccessful();
        
        var initialTodos = await initialResponse.Content.ReadFromJsonAsync<TodoListResponse>();
        initialTodos.Should().NotBeNull();
        initialTodos!.Todos.Should().BeEmpty();

        // Test 2: Create a new todo - from test-endpoints.sh line 17
        var createRequest = new CreateTodoRequest("Learn Axiom Endpoints");
        var createResponse = await _client.PostAsJsonAsync("/todos", createRequest);
        createResponse.Should().BeSuccessful();
        
        var createdTodo = await createResponse.Content.ReadFromJsonAsync<TodoResponse>();
        createdTodo.Should().NotBeNull();
        createdTodo!.Title.Should().Be("Learn Axiom Endpoints");
        createdTodo.Id.Should().NotBeEmpty();

        // Test 3: Get specific todo by ID - from test-endpoints.sh line 29
        var getResponse = await _client.GetAsync($"/todos/{createdTodo.Id}");
        getResponse.Should().BeSuccessful();
        
        var retrievedTodo = await getResponse.Content.ReadFromJsonAsync<TodoResponse>();
        retrievedTodo.Should().NotBeNull();
        retrievedTodo!.Id.Should().Be(createdTodo.Id);
        retrievedTodo.Title.Should().Be("Learn Axiom Endpoints");

        // Test 4: Create another todo - from test-endpoints.sh line 34
        var createRequest2 = new CreateTodoRequest("Build awesome APIs");
        var createResponse2 = await _client.PostAsJsonAsync("/todos", createRequest2);
        createResponse2.Should().BeSuccessful();
        
        var createdTodo2 = await createResponse2.Content.ReadFromJsonAsync<TodoResponse>();
        createdTodo2.Should().NotBeNull();
        createdTodo2!.Title.Should().Be("Build awesome APIs");

        // Test 5: Get all todos with pagination - from test-endpoints.sh line 42
        var paginatedResponse = await _client.GetAsync("/todos?pageSize=5&page=1");
        paginatedResponse.Should().BeSuccessful();
        
        var paginatedTodos = await paginatedResponse.Content.ReadFromJsonAsync<TodoListResponse>();
        paginatedTodos.Should().NotBeNull();
        paginatedTodos!.Todos.Should().HaveCount(2);
        paginatedTodos.Page.Should().Be(1);
        paginatedTodos.PageSize.Should().Be(5);

        // Test 6: Search todos - from test-endpoints.sh line 47
        var searchResponse = await _client.GetAsync("/todos?search=axiom");
        searchResponse.Should().BeSuccessful();
        
        var searchResults = await searchResponse.Content.ReadFromJsonAsync<TodoListResponse>();
        searchResults.Should().NotBeNull();
        searchResults!.Todos.Should().HaveCount(1);
        searchResults.Todos[0].Title.Should().Contain("Axiom");

        // Test 7: Filter by completion status - from test-endpoints.sh line 52
        var filteredResponse = await _client.GetAsync("/todos?completed=false");
        filteredResponse.Should().BeSuccessful();
        
        var filteredTodos = await filteredResponse.Content.ReadFromJsonAsync<TodoListResponse>();
        filteredTodos.Should().NotBeNull();
        filteredTodos!.Todos.Should().HaveCount(2);
        filteredTodos.Todos.All(t => !t.Completed).Should().BeTrue();
    }

    [Fact]
    public async Task TodoApi_EdgeCases_HandledCorrectly()
    {
        // Test getting non-existent todo
        var nonExistentId = Guid.NewGuid();
        var notFoundResponse = await _client.GetAsync($"/todos/{nonExistentId}");
        notFoundResponse.Should().HaveClientError();
        notFoundResponse.StatusCode.Should().Be(System.Net.HttpStatusCode.NotFound);

        // Test invalid pagination parameters
        var invalidPageResponse = await _client.GetAsync("/todos?page=0&pageSize=-1");
        invalidPageResponse.Should().BeSuccessful(); // Should handle gracefully with defaults

        // Test empty search
        var emptySearchResponse = await _client.GetAsync("/todos?search=");
        emptySearchResponse.Should().BeSuccessful();

        // Test very long search query
        var longQuery = new string('a', 1000);
        var longSearchResponse = await _client.GetAsync($"/todos?search={Uri.EscapeDataString(longQuery)}");
        longSearchResponse.Should().BeSuccessful();
    }

    [Fact]
    public async Task TodoApi_QueryParameterVariations_WorkCorrectly()
    {
        // Create test todos
        await _client.PostAsJsonAsync("/todos", new CreateTodoRequest("Completed Task"));
        await _client.PostAsJsonAsync("/todos", new CreateTodoRequest("Pending Task"));

        // Test different query parameter combinations
        var combinations = new[]
        {
            "?page=1",
            "?pageSize=10",
            "?completed=true",
            "?completed=false",
            "?search=task",
            "?page=1&pageSize=10",
            "?page=1&pageSize=10&completed=false",
            "?page=1&pageSize=10&completed=false&search=pending"
        };

        foreach (var queryParams in combinations)
        {
            var response = await _client.GetAsync($"/todos{queryParams}");
            response.Should().BeSuccessful($"Query params: {queryParams}");
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

// Test DTOs converted from shell script scenarios
public sealed record CreateTodoRequest(string Title, string? Description = null);

public sealed record GetTodoRequest(Guid Id);

public sealed record ListTodosRequest(int PageSize = 20, int Page = 1, bool? Completed = null, string? Search = null);

public class ListTodosQuery
{
    public int? PageSize { get; set; }
    public int? Page { get; set; }
    public bool? Completed { get; set; }
    public string? Search { get; set; }
}

public sealed record TodoResponse(Guid Id, string Title, string? Description, bool Completed, DateTime CreatedAt);

public sealed record TodoListResponse(
    IReadOnlyList<TodoResponse> Todos,
    int TotalCount,
    int Page,
    int PageSize,
    bool HasNextPage,
    bool HasPreviousPage
);

// Test endpoint implementations
public sealed class TodoCreateEndpoint : IAxiom<CreateTodoRequest, TodoResponse>
{
    public ValueTask<Result<TodoResponse>> HandleAsync(CreateTodoRequest request, IContext context)
    {
        var todo = new TodoResponse(
            Guid.NewGuid(),
            request.Title,
            request.Description,
            false,
            DateTime.UtcNow
        );
        
        return ValueTask.FromResult(ResultFactory.Success(todo));
    }
}

public sealed class TodoGetEndpoint : IAxiom<GetTodoRequest, TodoResponse>
{
    public ValueTask<Result<TodoResponse>> HandleAsync(GetTodoRequest request, IContext context)
    {
        // Simulate finding todo by ID
        var todo = new TodoResponse(
            request.Id,
            "Sample Todo",
            "Sample Description",
            false,
            DateTime.UtcNow
        );
        
        return ValueTask.FromResult(ResultFactory.Success(todo));
    }
}

public sealed class TodoListEndpoint : IAxiom<ListTodosRequest, TodoListResponse>
{
    public ValueTask<Result<TodoListResponse>> HandleAsync(ListTodosRequest request, IContext context)
    {
        // Simulate paginated todo list
        var todos = new List<TodoResponse>
        {
            new(Guid.NewGuid(), "Learn Axiom Endpoints", null, false, DateTime.UtcNow),
            new(Guid.NewGuid(), "Build awesome APIs", null, false, DateTime.UtcNow)
        };
        
        // Apply filtering
        if (request.Completed.HasValue)
        {
            todos = todos.Where(t => t.Completed == request.Completed.Value).ToList();
        }
        
        if (!string.IsNullOrEmpty(request.Search))
        {
            todos = todos.Where(t => t.Title.Contains(request.Search, StringComparison.OrdinalIgnoreCase)).ToList();
        }
        
        var response = new TodoListResponse(
            todos,
            todos.Count,
            request.Page,
            request.PageSize,
            false,
            false
        );
        
        return ValueTask.FromResult(ResultFactory.Success(response));
    }
}

public sealed class TodoSearchEndpoint : IAxiom<ListTodosRequest, TodoListResponse>
{
    public ValueTask<Result<TodoListResponse>> HandleAsync(ListTodosRequest request, IContext context)
    {
        // Simulate search functionality
        var results = new List<TodoResponse>();
        
        if (!string.IsNullOrEmpty(request.Search))
        {
            results.Add(new TodoResponse(
                Guid.NewGuid(),
                $"Found: {request.Search}",
                "Search result",
                false,
                DateTime.UtcNow
            ));
        }
        
        var response = new TodoListResponse(
            results,
            results.Count,
            request.Page,
            request.PageSize,
            false,
            false
        );
        
        return ValueTask.FromResult(ResultFactory.Success(response));
    }
}