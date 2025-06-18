using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace AxiomEndpointsExample.Api;

// Database models
public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Bio { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    public UserStatus Status { get; set; } = UserStatus.Active;
    
    // Navigation properties
    public List<Post> Posts { get; set; } = new();
}

public class Post
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    public string Content { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Slug { get; set; } = string.Empty;
    
    public Guid AuthorId { get; set; }
    public User Author { get; set; } = null!;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    public PostStatus Status { get; set; } = PostStatus.Draft;
    
    // Navigation properties
    public List<Comment> Comments { get; set; } = new();
}

public class Comment
{
    public int Id { get; set; }
    
    [Required]
    public string Content { get; set; } = string.Empty;
    
    public Guid AuthorId { get; set; }
    public User Author { get; set; } = null!;
    
    public int PostId { get; set; }
    public Post Post { get; set; } = null!;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class Organization
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Slug { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public List<Project> Projects { get; set; } = new();
}

public class Project
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Slug { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public Guid OrganizationId { get; set; }
    public Organization Organization { get; set; } = null!;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

// DTOs for API responses
public record ApiResponse<T>
{
    public required T Data { get; init; }
    public bool Success { get; init; } = true;
    public string? Message { get; init; }
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
}

public record PagedResponse<T> : ApiResponse<IEnumerable<T>>
{
    public int Page { get; init; } = 1;
    public int Limit { get; init; } = 20;
    public int TotalCount { get; init; }
    public int TotalPages { get; init; }
    public bool HasNextPage { get; init; }
    public bool HasPreviousPage { get; init; }
}

public record UserDto
{
    public Guid Id { get; init; }
    public required string Email { get; init; }
    public required string Name { get; init; }
    public string? Bio { get; init; }
    public DateTime CreatedAt { get; init; }
    public UserStatus Status { get; init; }
    public int PostsCount { get; init; }
}

public record PostDto
{
    public int Id { get; init; }
    public required string Title { get; init; }
    public required string Content { get; init; }
    public required string Slug { get; init; }
    public UserDto Author { get; init; } = null!;
    public DateTime CreatedAt { get; init; }
    public DateTime UpdatedAt { get; init; }
    public PostStatus Status { get; init; }
    public int CommentsCount { get; init; }
}

public record CommentDto
{
    public int Id { get; init; }
    public required string Content { get; init; }
    public UserDto Author { get; init; } = null!;
    public DateTime CreatedAt { get; init; }
}

public record ProjectDto
{
    public Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Slug { get; init; }
    public string? Description { get; init; }
    public OrganizationDto Organization { get; init; } = null!;
    public DateTime CreatedAt { get; init; }
}

public record OrganizationDto
{
    public Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Slug { get; init; }
    public string? Description { get; init; }
    public DateTime CreatedAt { get; init; }
    public int ProjectsCount { get; init; }
}

// Query parameter classes
public class UserSearchQuery
{
    public string? Search { get; set; }
    public UserStatus? Status { get; set; }
    public int Page { get; set; } = 1;
    public int Limit { get; set; } = 20;
    public UserSortBy Sort { get; set; } = UserSortBy.CreatedAt;
    public SortOrder Order { get; set; } = SortOrder.Desc;
}

// Enums
public enum UserStatus
{
    Active,
    Inactive,
    Suspended,
    Pending
}

public enum PostStatus
{
    Draft,
    Published,
    Archived
}

public enum UserSortBy
{
    CreatedAt,
    Name,
    Email,
    PostsCount
}

public enum SortOrder
{
    Asc,
    Desc
}

// Database context
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Post> Posts { get; set; }
    public DbSet<Comment> Comments { get; set; }
    public DbSet<Organization> Organizations { get; set; }
    public DbSet<Project> Projects { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Bio).HasMaxLength(500);
        });

        // Post configuration
        modelBuilder.Entity<Post>(entity =>
        {
            entity.HasIndex(e => e.Slug).IsUnique();
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Slug).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Content).IsRequired();
            
            entity.HasOne(e => e.Author)
                  .WithMany(e => e.Posts)
                  .HasForeignKey(e => e.AuthorId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Comment configuration
        modelBuilder.Entity<Comment>(entity =>
        {
            entity.Property(e => e.Content).IsRequired();
            
            entity.HasOne(e => e.Author)
                  .WithMany()
                  .HasForeignKey(e => e.AuthorId)
                  .OnDelete(DeleteBehavior.Restrict);
                  
            entity.HasOne(e => e.Post)
                  .WithMany(e => e.Comments)
                  .HasForeignKey(e => e.PostId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Organization configuration
        modelBuilder.Entity<Organization>(entity =>
        {
            entity.HasIndex(e => e.Slug).IsUnique();
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Slug).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Description).HasMaxLength(500);
        });

        // Project configuration
        modelBuilder.Entity<Project>(entity =>
        {
            entity.HasIndex(e => new { e.OrganizationId, e.Slug }).IsUnique();
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Slug).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Description).HasMaxLength(500);
            
            entity.HasOne(e => e.Organization)
                  .WithMany(e => e.Projects)
                  .HasForeignKey(e => e.OrganizationId)
                  .OnDelete(DeleteBehavior.Cascade);
        });
    }
}