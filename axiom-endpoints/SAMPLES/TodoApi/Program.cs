using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Middleware;
using AxiomEndpoints.AspNetCore;

namespace TodoApi;

public static class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add services to the container
        builder.Services.AddAxiomEndpoints();

        // Add middleware services
        builder.Services.AddDistributedMemoryCache();
        builder.Services.AddSingleton<IRateLimiterService, DefaultRateLimiterService>();
        builder.Services.AddSingleton<IFeatureManager, DefaultFeatureManager>();

        // Add application services
        builder.Services.AddSingleton<ITodoService, TodoService>();

        var app = builder.Build();

        // Configure the HTTP request pipeline
        if (app.Environment.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseRouting();
        
        // Manually map endpoints since source generator is disabled
        app.MapGet("/todos/{id:int}", async (int id, ITodoService todoService) =>
        {
            var todo = await todoService.GetByIdAsync(id);
            return todo != null ? Results.Ok(new TodoResponse(todo.Id, todo.Title, todo.IsCompleted)) : Results.NotFound();
        });

        app.MapPost("/todos", async (CreateTodoRequest request, ITodoService todoService) =>
        {
            var todo = await todoService.CreateAsync(request.Title);
            return Results.Created($"/todos/{todo.Id}", new TodoResponse(todo.Id, todo.Title, todo.IsCompleted));
        });

        app.Run();
    }
}

// Simple todo models
public record Todo(int Id, string Title, bool IsCompleted);
public record CreateTodoRequest(string Title);
public record GetTodoRequest(int Id);
public record TodoResponse(int Id, string Title, bool IsCompleted);

// Simple service interface and implementation
public interface ITodoService
{
    Task<Todo?> GetByIdAsync(int id);
    Task<Todo> CreateAsync(string title);
}

public class TodoService : ITodoService
{
    private readonly List<Todo> _todos = new();
    private int _nextId = 1;

    public Task<Todo?> GetByIdAsync(int id)
    {
        var todo = _todos.FirstOrDefault(t => t.Id == id);
        return Task.FromResult(todo);
    }

    public Task<Todo> CreateAsync(string title)
    {
        var todo = new Todo(_nextId++, title, false);
        _todos.Add(todo);
        return Task.FromResult(todo);
    }
}