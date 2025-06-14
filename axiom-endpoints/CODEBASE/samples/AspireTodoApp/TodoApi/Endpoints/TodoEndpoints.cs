using AxiomEndpoints.Core;
using Microsoft.EntityFrameworkCore;
using TodoApi.Data;
using TodoApi.Models;

namespace TodoApi.Endpoints;

// Get all todos
public record GetTodos(TodoDbContext db) : IAxiom<GetTodosRequest, List<TodoResponse>>
{
    public async ValueTask<Result<List<TodoResponse>>> HandleAsync(
        GetTodosRequest request,
        IContext context)
    {
        var query = db.Todos.AsQueryable();

        // Apply filters
        if (!string.IsNullOrEmpty(request.Category))
        {
            query = query.Where(t => t.Category == request.Category);
        }

        if (request.IsCompleted.HasValue)
        {
            query = query.Where(t => t.IsCompleted == request.IsCompleted.Value);
        }

        if (request.Priority.HasValue)
        {
            query = query.Where(t => t.Priority == request.Priority.Value);
        }

        // Apply sorting
        query = request.SortBy?.ToLowerInvariant() switch
        {
            "title" => request.SortOrder == "desc" ? query.OrderByDescending(t => t.Title) : query.OrderBy(t => t.Title),
            "created" => request.SortOrder == "desc" ? query.OrderByDescending(t => t.CreatedAt) : query.OrderBy(t => t.CreatedAt),
            "priority" => request.SortOrder == "desc" ? query.OrderByDescending(t => t.Priority) : query.OrderBy(t => t.Priority),
            _ => query.OrderByDescending(t => t.CreatedAt)
        };

        // Apply pagination
        var skip = (request.Page - 1) * request.PageSize;
        query = query.Skip(skip).Take(request.PageSize);

        var todos = await query.ToListAsync(context.CancellationToken);

        var response = todos.Select(t => new TodoResponse
        {
            Id = t.Id,
            Title = t.Title,
            Description = t.Description,
            IsCompleted = t.IsCompleted,
            CreatedAt = t.CreatedAt,
            CompletedAt = t.CompletedAt,
            Priority = t.Priority,
            Category = t.Category
        }).ToList();

        return Result<List<TodoResponse>>.Success(response);
    }
}

public record GetTodosRequest
{
    public string? Category { get; init; }
    public bool? IsCompleted { get; init; }
    public Priority? Priority { get; init; }
    public string? SortBy { get; init; }
    public string SortOrder { get; init; } = "asc";
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 10;
}

// Get todo by ID
public record GetTodoById(TodoDbContext db) : IAxiom<GetTodoByIdRequest, TodoResponse>
{
    public async ValueTask<Result<TodoResponse>> HandleAsync(
        GetTodoByIdRequest request,
        IContext context)
    {
        var todo = await db.Todos.FindAsync([request.Id], context.CancellationToken);

        if (todo == null)
        {
            return Result<TodoResponse>.NotFound($"Todo with ID {request.Id} not found");
        }

        var response = new TodoResponse
        {
            Id = todo.Id,
            Title = todo.Title,
            Description = todo.Description,
            IsCompleted = todo.IsCompleted,
            CreatedAt = todo.CreatedAt,
            CompletedAt = todo.CompletedAt,
            Priority = todo.Priority,
            Category = todo.Category
        };

        return Result<TodoResponse>.Success(response);
    }
}

public record GetTodoByIdRequest
{
    public required int Id { get; init; }
}

// Create todo
public record CreateTodo(TodoDbContext db) : IAxiom<CreateTodoRequest, TodoResponse>
{
    public async ValueTask<Result<TodoResponse>> HandleAsync(
        CreateTodoRequest request,
        IContext context)
    {
        var todo = new Todo
        {
            Title = request.Title,
            Description = request.Description,
            Priority = request.Priority,
            Category = request.Category,
            CreatedAt = DateTime.UtcNow
        };

        db.Todos.Add(todo);
        await db.SaveChangesAsync(context.CancellationToken);

        var response = new TodoResponse
        {
            Id = todo.Id,
            Title = todo.Title,
            Description = todo.Description,
            IsCompleted = todo.IsCompleted,
            CreatedAt = todo.CreatedAt,
            CompletedAt = todo.CompletedAt,
            Priority = todo.Priority,
            Category = todo.Category
        };

        // Set location header
        context.SetLocation(new GetTodoByIdRequest { Id = todo.Id });

        return Result<TodoResponse>.Success(response);
    }
}

// Update todo
public record UpdateTodo(TodoDbContext db) : IAxiom<UpdateTodoRequest, TodoResponse>
{
    public async ValueTask<Result<TodoResponse>> HandleAsync(
        UpdateTodoRequest request,
        IContext context)
    {
        var todo = await db.Todos.FindAsync([request.Id], context.CancellationToken);

        if (todo == null)
        {
            return Result<TodoResponse>.NotFound($"Todo with ID {request.Id} not found");
        }

        // Update fields if provided
        if (request.Title != null)
            todo.Title = request.Title;
        
        if (request.Description != null)
            todo.Description = request.Description;
        
        if (request.Priority.HasValue)
            todo.Priority = request.Priority.Value;
        
        if (request.Category != null)
            todo.Category = request.Category;
        
        if (request.IsCompleted.HasValue)
        {
            todo.IsCompleted = request.IsCompleted.Value;
            todo.CompletedAt = request.IsCompleted.Value ? DateTime.UtcNow : null;
        }

        await db.SaveChangesAsync(context.CancellationToken);

        var response = new TodoResponse
        {
            Id = todo.Id,
            Title = todo.Title,
            Description = todo.Description,
            IsCompleted = todo.IsCompleted,
            CreatedAt = todo.CreatedAt,
            CompletedAt = todo.CompletedAt,
            Priority = todo.Priority,
            Category = todo.Category
        };

        return Result<TodoResponse>.Success(response);
    }
}

public record UpdateTodoRequest
{
    public required int Id { get; init; }
    public string? Title { get; init; }
    public string? Description { get; init; }
    public bool? IsCompleted { get; init; }
    public Priority? Priority { get; init; }
    public string? Category { get; init; }
}

// Delete todo
public record DeleteTodo(TodoDbContext db) : IAxiom<DeleteTodoRequest, DeleteTodoResponse>
{
    public async ValueTask<Result<DeleteTodoResponse>> HandleAsync(
        DeleteTodoRequest request,
        IContext context)
    {
        var todo = await db.Todos.FindAsync([request.Id], context.CancellationToken);

        if (todo == null)
        {
            return Result<DeleteTodoResponse>.NotFound($"Todo with ID {request.Id} not found");
        }

        db.Todos.Remove(todo);
        await db.SaveChangesAsync(context.CancellationToken);

        return Result<DeleteTodoResponse>.Success(new DeleteTodoResponse
        {
            Message = "Todo deleted successfully"
        });
    }
}

public record DeleteTodoRequest
{
    public required int Id { get; init; }
}

public record DeleteTodoResponse
{
    public required string Message { get; init; }
}