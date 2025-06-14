using Microsoft.EntityFrameworkCore;
using TodoApi.Models;

namespace TodoApi.Data;

public class TodoDbContext : DbContext
{
    public TodoDbContext(DbContextOptions<TodoDbContext> options) : base(options)
    {
    }

    public DbSet<Todo> Todos => Set<Todo>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Todo>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Category).HasMaxLength(50);
            entity.Property(e => e.Priority).HasConversion<int>();
            
            // Add indexes
            entity.HasIndex(e => e.IsCompleted);
            entity.HasIndex(e => e.Category);
            entity.HasIndex(e => e.Priority);
            entity.HasIndex(e => e.CreatedAt);
        });

        base.OnModelCreating(modelBuilder);
    }
}