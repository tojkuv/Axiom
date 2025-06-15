using System.ComponentModel.DataAnnotations;

namespace PackageGenerationExample.Models;

/// <summary>
/// Represents a book in the library system
/// </summary>
public class Book
{
    /// <summary>
    /// Unique identifier for the book
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Title of the book
    /// </summary>
    [Required]
    [StringLength(200, MinimumLength = 1)]
    public required string Title { get; set; }

    /// <summary>
    /// ISBN number
    /// </summary>
    [StringLength(17, MinimumLength = 10)]
    [RegularExpression(@"^(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]$")]
    public string? ISBN { get; set; }

    /// <summary>
    /// Author of the book
    /// </summary>
    [Required]
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
    /// Available copies in the library
    /// </summary>
    [Range(0, 1000)]
    public int AvailableCopies { get; set; }

    /// <summary>
    /// Total copies owned by the library
    /// </summary>
    [Range(0, 1000)]
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
    public bool IsActive { get; set; } = true;

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
/// Book genre enumeration
/// </summary>
public enum BookGenre
{
    Fiction = 1,
    NonFiction = 2,
    Mystery = 3,
    Romance = 4,
    ScienceFiction = 5,
    Fantasy = 6,
    Biography = 7,
    History = 8,
    Science = 9,
    Technology = 10,
    SelfHelp = 11,
    Travel = 12,
    Cooking = 13,
    Art = 14,
    Religion = 15,
    Philosophy = 16,
    Poetry = 17,
    Drama = 18,
    Children = 19,
    YoungAdult = 20,
    Other = 99
}

/// <summary>
/// Physical specifications of a book
/// </summary>
public class BookSpecification
{
    /// <summary>
    /// Height in centimeters
    /// </summary>
    [Range(1, 100)]
    public double? Height { get; set; }

    /// <summary>
    /// Width in centimeters
    /// </summary>
    [Range(1, 100)]
    public double? Width { get; set; }

    /// <summary>
    /// Thickness in centimeters
    /// </summary>
    [Range(0.1, 20)]
    public double? Thickness { get; set; }

    /// <summary>
    /// Weight in grams
    /// </summary>
    [Range(1, 5000)]
    public double? Weight { get; set; }

    /// <summary>
    /// Cover type (hardcover, paperback, etc.)
    /// </summary>
    [StringLength(50)]
    public string? CoverType { get; set; }

    /// <summary>
    /// Language of the book
    /// </summary>
    [StringLength(50)]
    public string? Language { get; set; }

    /// <summary>
    /// Publisher name
    /// </summary>
    [StringLength(100)]
    public string? Publisher { get; set; }

    /// <summary>
    /// Edition information
    /// </summary>
    [StringLength(50)]
    public string? Edition { get; set; }
}