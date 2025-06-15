using AxiomEndpoints.Core;
using PackageGenerationExample.Models;
using System.ComponentModel.DataAnnotations;

namespace PackageGenerationExample.Endpoints;

/// <summary>
/// Request to create a new book
/// </summary>
public class CreateBookRequest
{
    /// <summary>
    /// Title of the book
    /// </summary>
    [System.ComponentModel.DataAnnotations.Required]
    [StringLength(200, MinimumLength = 1)]
    public required string Title { get; set; }

    /// <summary>
    /// ISBN number
    /// </summary>
    [StringLength(17, MinimumLength = 10)]
    public string? ISBN { get; set; }

    /// <summary>
    /// Author of the book
    /// </summary>
    [System.ComponentModel.DataAnnotations.Required]
    [StringLength(100, MinimumLength = 1)]
    public required string Author { get; set; }

    /// <summary>
    /// Publication year
    /// </summary>
    [Range(1000, 2030)]
    public int? PublicationYear { get; set; }

    /// <summary>
    /// Genre/category of the book
    /// </summary>
    public BookGenre Genre { get; set; }

    /// <summary>
    /// Number of pages
    /// </summary>
    [Range(1, 10000)]
    public int? Pages { get; set; }

    /// <summary>
    /// Book description/summary
    /// </summary>
    [StringLength(1000)]
    public string? Description { get; set; }

    /// <summary>
    /// Price of the book
    /// </summary>
    [Range(0.01, 9999.99)]
    public decimal? Price { get; set; }

    /// <summary>
    /// Total copies to add to the library
    /// </summary>
    [Range(1, 1000)]
    public int TotalCopies { get; set; } = 1;

    /// <summary>
    /// Additional metadata for the book
    /// </summary>
    public Dictionary<string, string> Metadata { get; set; } = new();

    /// <summary>
    /// Tags associated with the book
    /// </summary>
    public List<string> Tags { get; set; } = new();

    /// <summary>
    /// Physical specifications of the book
    /// </summary>
    public BookSpecification? Specification { get; set; }
}

/// <summary>
/// Response containing book information
/// </summary>
public class BookResponse
{
    /// <summary>
    /// Unique identifier for the book
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Title of the book
    /// </summary>
    public required string Title { get; set; }

    /// <summary>
    /// ISBN number
    /// </summary>
    public string? ISBN { get; set; }

    /// <summary>
    /// Author of the book
    /// </summary>
    public required string Author { get; set; }

    /// <summary>
    /// Publication year
    /// </summary>
    public int? PublicationYear { get; set; }

    /// <summary>
    /// Genre/category of the book
    /// </summary>
    public BookGenre Genre { get; set; }

    /// <summary>
    /// Number of pages
    /// </summary>
    public int? Pages { get; set; }

    /// <summary>
    /// Book description/summary
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Price of the book
    /// </summary>
    public decimal? Price { get; set; }

    /// <summary>
    /// Available copies in the library
    /// </summary>
    public int AvailableCopies { get; set; }

    /// <summary>
    /// Total copies owned by the library
    /// </summary>
    public int TotalCopies { get; set; }

    /// <summary>
    /// When the book was added to the library
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// When the book record was last updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }

    /// <summary>
    /// Whether the book is currently active in the system
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Additional metadata for the book
    /// </summary>
    public Dictionary<string, string> Metadata { get; set; } = new();

    /// <summary>
    /// Tags associated with the book
    /// </summary>
    public List<string> Tags { get; set; } = new();

    /// <summary>
    /// Physical specifications of the book
    /// </summary>
    public BookSpecification? Specification { get; set; }
}

/// <summary>
/// Request to get a specific book
/// </summary>
public class GetBookRequest
{
    /// <summary>
    /// Book ID to retrieve
    /// </summary>
    public int Id { get; set; }
}

/// <summary>
/// Request to search for books
/// </summary>
public class SearchBooksRequest
{
    /// <summary>
    /// Search query for title, author, or description
    /// </summary>
    [StringLength(200)]
    public string? Query { get; set; }

    /// <summary>
    /// Filter by author
    /// </summary>
    [StringLength(100)]
    public string? Author { get; set; }

    /// <summary>
    /// Filter by genre
    /// </summary>
    public BookGenre? Genre { get; set; }

    /// <summary>
    /// Minimum publication year
    /// </summary>
    [Range(1000, 2030)]
    public int? MinYear { get; set; }

    /// <summary>
    /// Maximum publication year
    /// </summary>
    [Range(1000, 2030)]
    public int? MaxYear { get; set; }

    /// <summary>
    /// Minimum price
    /// </summary>
    [Range(0, 9999.99)]
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// Maximum price
    /// </summary>
    [Range(0, 9999.99)]
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// Filter by availability
    /// </summary>
    public bool? IsAvailable { get; set; }

    /// <summary>
    /// Filter by active status
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Tags to filter by
    /// </summary>
    public List<string> Tags { get; set; } = new();

    /// <summary>
    /// Sort field
    /// </summary>
    [StringLength(50)]
    public string SortBy { get; set; } = "Title";

    /// <summary>
    /// Sort order (asc/desc)
    /// </summary>
    [StringLength(10)]
    public string SortOrder { get; set; } = "asc";

    /// <summary>
    /// Page number (1-based)
    /// </summary>
    [Range(1, int.MaxValue)]
    public int Page { get; set; } = 1;

    /// <summary>
    /// Number of results per page
    /// </summary>
    [Range(1, 100)]
    public int PageSize { get; set; } = 20;
}

/// <summary>
/// Response containing a list of books
/// </summary>
public class BookListResponse
{
    /// <summary>
    /// List of books
    /// </summary>
    public List<BookResponse> Books { get; set; } = new();

    /// <summary>
    /// Total number of books matching the criteria
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// Current page number
    /// </summary>
    public int Page { get; set; }

    /// <summary>
    /// Number of results per page
    /// </summary>
    public int PageSize { get; set; }

    /// <summary>
    /// Total number of pages
    /// </summary>
    public int TotalPages { get; set; }

    /// <summary>
    /// Whether there is a next page
    /// </summary>
    public bool HasNextPage { get; set; }

    /// <summary>
    /// Whether there is a previous page
    /// </summary>
    public bool HasPreviousPage { get; set; }
}

/// <summary>
/// Request to update a book
/// </summary>
public class UpdateBookRequest
{
    /// <summary>
    /// Book ID to update
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Title of the book
    /// </summary>
    [StringLength(200, MinimumLength = 1)]
    public string? Title { get; set; }

    /// <summary>
    /// ISBN number
    /// </summary>
    [StringLength(17, MinimumLength = 10)]
    public string? ISBN { get; set; }

    /// <summary>
    /// Author of the book
    /// </summary>
    [StringLength(100, MinimumLength = 1)]
    public string? Author { get; set; }

    /// <summary>
    /// Publication year
    /// </summary>
    [Range(1000, 2030)]
    public int? PublicationYear { get; set; }

    /// <summary>
    /// Genre/category of the book
    /// </summary>
    public BookGenre? Genre { get; set; }

    /// <summary>
    /// Number of pages
    /// </summary>
    [Range(1, 10000)]
    public int? Pages { get; set; }

    /// <summary>
    /// Book description/summary
    /// </summary>
    [StringLength(1000)]
    public string? Description { get; set; }

    /// <summary>
    /// Price of the book
    /// </summary>
    [Range(0.01, 9999.99)]
    public decimal? Price { get; set; }

    /// <summary>
    /// Available copies in the library
    /// </summary>
    [Range(0, 1000)]
    public int? AvailableCopies { get; set; }

    /// <summary>
    /// Total copies owned by the library
    /// </summary>
    [Range(0, 1000)]
    public int? TotalCopies { get; set; }

    /// <summary>
    /// Whether the book is currently active in the system
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// Additional metadata for the book
    /// </summary>
    public Dictionary<string, string> Metadata { get; set; } = new();

    /// <summary>
    /// Tags associated with the book
    /// </summary>
    public List<string> Tags { get; set; } = new();

    /// <summary>
    /// Physical specifications of the book
    /// </summary>
    public BookSpecification? Specification { get; set; }
}

/// <summary>
/// Request to delete a book
/// </summary>
public class DeleteBookRequest
{
    /// <summary>
    /// Book ID to delete
    /// </summary>
    public int Id { get; set; }
}

/// <summary>
/// Response for delete operation
/// </summary>
public class DeleteBookResponse
{
    /// <summary>
    /// Success message
    /// </summary>
    public required string Message { get; set; }

    /// <summary>
    /// Whether the operation was successful
    /// </summary>
    public bool Success { get; set; }
}

/// <summary>
/// Request to get available genres
/// </summary>
public class GetGenresRequest
{
}

/// <summary>
/// Genre information
/// </summary>
public class GenreInfo
{
    /// <summary>
    /// Genre enum value
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Genre name
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Genre description
    /// </summary>
    public string? Description { get; set; }
}

/// <summary>
/// Response containing available genres
/// </summary>
public class GenresResponse
{
    /// <summary>
    /// List of available genres
    /// </summary>
    public List<GenreInfo> Genres { get; set; } = new();
}

// Axiom Endpoint Implementations

/// <summary>
/// Create a new book in the library
/// </summary>
public class CreateBook : IAxiom<CreateBookRequest, BookResponse>
{
    public async ValueTask<Result<BookResponse>> HandleAsync(CreateBookRequest request, IContext context)
    {
        // Simulate book creation logic
        var book = new BookResponse
        {
            Id = Random.Shared.Next(1, 10000),
            Title = request.Title,
            ISBN = request.ISBN,
            Author = request.Author,
            PublicationYear = request.PublicationYear,
            Genre = request.Genre,
            Pages = request.Pages,
            Description = request.Description,
            Price = request.Price,
            AvailableCopies = request.TotalCopies,
            TotalCopies = request.TotalCopies,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            IsActive = true,
            Metadata = request.Metadata,
            Tags = request.Tags,
            Specification = request.Specification
        };

        return ResultFactory.Success(book);
    }
}

/// <summary>
/// Retrieve a specific book by ID
/// </summary>
public class GetBook : IAxiom<GetBookRequest, BookResponse>
{
    public async ValueTask<Result<BookResponse>> HandleAsync(GetBookRequest request, IContext context)
    {
        // Simulate book retrieval logic
        if (request.Id <= 0)
        {
            return ResultFactory.NotFound<BookResponse>($"Book with ID {request.Id} not found.");
        }

        var book = new BookResponse
        {
            Id = request.Id,
            Title = "Sample Book",
            Author = "Sample Author",
            Genre = BookGenre.Fiction,
            AvailableCopies = 5,
            TotalCopies = 10,
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            UpdatedAt = DateTime.UtcNow.AddDays(-1),
            IsActive = true
        };

        return ResultFactory.Success(book);
    }
}

/// <summary>
/// Search for books with filtering and pagination
/// </summary>
public class SearchBooks : IAxiom<SearchBooksRequest, BookListResponse>
{
    public async ValueTask<Result<BookListResponse>> HandleAsync(SearchBooksRequest request, IContext context)
    {
        // Simulate book search logic
        var totalCount = 100;
        var totalPages = (int)Math.Ceiling((double)totalCount / request.PageSize);

        var books = Enumerable.Range(1, Math.Min(request.PageSize, 20))
            .Select(i => new BookResponse
            {
                Id = i + ((request.Page - 1) * request.PageSize),
                Title = $"Book {i}",
                Author = $"Author {i}",
                Genre = (BookGenre)(i % 5 + 1),
                AvailableCopies = Random.Shared.Next(0, 10),
                TotalCopies = Random.Shared.Next(5, 15),
                CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 365)),
                UpdatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 30)),
                IsActive = true
            })
            .ToList();

        var response = new BookListResponse
        {
            Books = books,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = totalPages,
            HasNextPage = request.Page < totalPages,
            HasPreviousPage = request.Page > 1
        };

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Update an existing book
/// </summary>
public class UpdateBook : IAxiom<UpdateBookRequest, BookResponse>
{
    public async ValueTask<Result<BookResponse>> HandleAsync(UpdateBookRequest request, IContext context)
    {
        // Simulate book update logic
        if (request.Id <= 0)
        {
            return ResultFactory.NotFound<BookResponse>($"Book with ID {request.Id} not found.");
        }

        var book = new BookResponse
        {
            Id = request.Id,
            Title = request.Title ?? "Updated Book",
            Author = request.Author ?? "Updated Author",
            ISBN = request.ISBN,
            PublicationYear = request.PublicationYear,
            Genre = request.Genre ?? BookGenre.Fiction,
            Pages = request.Pages,
            Description = request.Description,
            Price = request.Price,
            AvailableCopies = request.AvailableCopies ?? 5,
            TotalCopies = request.TotalCopies ?? 10,
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            UpdatedAt = DateTime.UtcNow,
            IsActive = request.IsActive ?? true,
            Metadata = request.Metadata,
            Tags = request.Tags,
            Specification = request.Specification
        };

        return ResultFactory.Success(book);
    }
}

/// <summary>
/// Delete a book from the library
/// </summary>
public class DeleteBook : IAxiom<DeleteBookRequest, DeleteBookResponse>
{
    public async ValueTask<Result<DeleteBookResponse>> HandleAsync(DeleteBookRequest request, IContext context)
    {
        // Simulate book deletion logic
        if (request.Id <= 0)
        {
            return ResultFactory.NotFound<DeleteBookResponse>($"Book with ID {request.Id} not found.");
        }

        var response = new DeleteBookResponse
        {
            Message = $"Book with ID {request.Id} has been successfully deleted.",
            Success = true
        };

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Get available book genres
/// </summary>
public class GetGenres : IAxiom<GetGenresRequest, GenresResponse>
{
    public async ValueTask<Result<GenresResponse>> HandleAsync(GetGenresRequest request, IContext context)
    {
        // Return all available genres
        var genres = Enum.GetValues<BookGenre>()
            .Select(g => new GenreInfo
            {
                Id = (int)g,
                Name = g.ToString(),
                Description = GetGenreDescription(g)
            })
            .ToList();

        var response = new GenresResponse
        {
            Genres = genres
        };

        return ResultFactory.Success(response);
    }

    private static string GetGenreDescription(BookGenre genre)
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
}