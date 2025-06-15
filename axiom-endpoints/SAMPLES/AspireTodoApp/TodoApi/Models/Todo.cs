namespace TodoApi.Models;

public class Todo
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public Priority Priority { get; set; } = Priority.Medium;
    public string? Category { get; set; }
}

public enum Priority
{
    Low = 1,
    Medium = 2,
    High = 3,
    Critical = 4
}

// Request/Response DTOs
public record CreateTodoRequest
{
    public required string Title { get; init; }
    public string? Description { get; init; }
    public Priority Priority { get; init; } = Priority.Medium;
    public string? Category { get; init; }
}

public record UpdateTodoRequest
{
    public string? Title { get; init; }
    public string? Description { get; init; }
    public bool? IsCompleted { get; init; }
    public Priority? Priority { get; init; }
    public string? Category { get; init; }
}

public record TodoResponse
{
    public required int Id { get; init; }
    public required string Title { get; init; }
    public string? Description { get; init; }
    public required bool IsCompleted { get; init; }
    public required DateTime CreatedAt { get; init; }
    public DateTime? CompletedAt { get; init; }
    public required Priority Priority { get; init; }
    public string? Category { get; init; }
}