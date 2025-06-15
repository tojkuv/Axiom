using AxiomEndpoints.AspNetCore;
using PackageGenerationExample.Endpoints;
using PackageGenerationExample.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { 
        Title = "Library Management API", 
        Version = "v1",
        Description = "A sample library management system built with Axiom Endpoints - demonstrating gRPC package generation"
    });
});

// Add Axiom Endpoints
builder.Services.AddAxiomEndpoints();

// Add CORS for development
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Library Management API v1");
        c.RoutePrefix = "";  // Serve Swagger UI at the root
    });
}

app.UseCors();
app.UseHttpsRedirection();

// Use Axiom Endpoints
app.UseAxiomEndpoints();

// Simple health check endpoint
app.MapGet("/health", () => new { Status = "Healthy", Timestamp = DateTime.UtcNow, Service = "Library Management API" });

// API info endpoint with comprehensive information
app.MapGet("/api/info", () => new
{
    Service = "Library Management API",
    Description = "A sample library management system built with Axiom Endpoints",
    Version = "1.0.0",
    Features = new[]
    {
        "Book management (CRUD operations)",
        "Book search with filters and pagination",
        "Genre management",
        "gRPC package generation support",
        "Type-safe validation",
        "Comprehensive event system"
    },
    PackageGeneration = new
    {
        Description = "This API supports generating gRPC client packages for multiple languages",
        SupportedLanguages = new[] { "Swift", "Kotlin", "C#" },
        GenerationCommand = "Run ./generate-packages.sh to generate client packages",
        Types = new
        {
            Requests = new[] { "CreateBookRequest", "GetBookRequest", "SearchBooksRequest", "UpdateBookRequest", "DeleteBookRequest" },
            Responses = new[] { "BookResponse", "BookListResponse", "DeleteBookResponse", "GenresResponse" },
            Events = new[] { "BookAddedEvent", "BookUpdatedEvent", "BookBorrowedEvent", "BookReturnedEvent" },
            Enums = new[] { "BookGenre", "BookCondition", "NotificationMethod" }
        }
    },
    ExampleTypes = new
    {
        BookGenres = Enum.GetNames<BookGenre>(),
        SampleBook = new BookResponse
        {
            Id = 1,
            Title = "The Great Gatsby",
            Author = "F. Scott Fitzgerald",
            Genre = BookGenre.Fiction,
            Pages = 180,
            Price = 12.99m,
            AvailableCopies = 3,
            TotalCopies = 5,
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            UpdatedAt = DateTime.UtcNow.AddDays(-1),
            IsActive = true,
            Tags = new List<string> { "classic", "american-literature" },
            Metadata = new Dictionary<string, string> { { "source", "example" } }
        }
    }
});

// Sample endpoint demonstrating the types that would be used for gRPC generation
app.MapPost("/api/books", (CreateBookRequest request) =>
{
    var response = new BookResponse
    {
        Id = Random.Shared.Next(1, 10000),
        Title = request.Title,
        Author = request.Author,
        Genre = request.Genre,
        Pages = request.Pages,
        Price = request.Price,
        AvailableCopies = request.TotalCopies,
        TotalCopies = request.TotalCopies,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        IsActive = true,
        Tags = request.Tags,
        Metadata = request.Metadata,
        Specification = request.Specification
    };
    return Results.Created($"/api/books/{response.Id}", response);
});

app.MapGet("/api/books/{id:int}", (int id) =>
{
    if (id <= 0)
        return Results.NotFound($"Book with ID {id} not found.");
        
    var book = new BookResponse
    {
        Id = id,
        Title = "Sample Book",
        Author = "Sample Author",
        Genre = BookGenre.Fiction,
        AvailableCopies = 5,
        TotalCopies = 10,
        CreatedAt = DateTime.UtcNow.AddDays(-30),
        UpdatedAt = DateTime.UtcNow.AddDays(-1),
        IsActive = true
    };
    return Results.Ok(book);
});

app.MapGet("/api/genres", () =>
{
    var genres = Enum.GetValues<BookGenre>()
        .Select(g => new GenreInfo
        {
            Id = (int)g,
            Name = g.ToString(),
            Description = GetGenreDescription(g)
        })
        .ToList();

    return Results.Ok(new GenresResponse { Genres = genres });
});

app.Run();

// Helper method for genre descriptions
static string GetGenreDescription(BookGenre genre)
{
    return genre switch
    {
        BookGenre.Fiction => "Literary works that are imaginative and not based on real events",
        BookGenre.NonFiction => "Works based on real facts, people, and events",
        BookGenre.Mystery => "Stories involving crime, detection, or puzzles to be solved",
        BookGenre.Romance => "Stories focused on romantic relationships",
        BookGenre.ScienceFiction => "Speculative fiction dealing with futuristic concepts",
        BookGenre.Fantasy => "Fiction involving magical or supernatural elements",
        BookGenre.Biography => "Accounts of someone's life written by someone else",
        BookGenre.History => "Books about past events and historical periods",
        BookGenre.Science => "Books about scientific subjects and research",
        BookGenre.Technology => "Books about technological developments and innovations",
        BookGenre.SelfHelp => "Books designed to help readers improve their lives",
        BookGenre.Travel => "Books about traveling to different places",
        BookGenre.Cooking => "Books containing recipes and cooking instructions",
        BookGenre.Art => "Books about artistic works and techniques",
        BookGenre.Religion => "Books about religious beliefs and practices",
        BookGenre.Philosophy => "Books exploring fundamental questions about existence",
        BookGenre.Poetry => "Collections of poems and poetic works",
        BookGenre.Drama => "Plays and dramatic works for performance",
        BookGenre.Children => "Books specifically written for children",
        BookGenre.YoungAdult => "Books targeted at teenage readers",
        _ => "Other types of books"
    };
}

// Make the Program class accessible for testing and package generation
public partial class Program { }