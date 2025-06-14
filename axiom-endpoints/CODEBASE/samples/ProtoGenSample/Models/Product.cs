using System.ComponentModel.DataAnnotations;

namespace ProtoGenSample.Models;

/// <summary>
/// Product domain model
/// </summary>
public class Product
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100, MinimumLength = 3)]
    public required string Name { get; set; }
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    [Range(0.01, 999999.99)]
    public decimal Price { get; set; }
    
    public ProductCategory Category { get; set; } = ProductCategory.Other;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? UpdatedAt { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public List<string> Tags { get; set; } = new();
    
    public Dictionary<string, string> Metadata { get; set; } = new();
    
    public ProductSpec? Specification { get; set; }
}

/// <summary>
/// Product category enumeration
/// </summary>
public enum ProductCategory
{
    Electronics = 1,
    Clothing = 2,
    Books = 3,
    Sports = 4,
    Home = 5,
    Other = 6
}

/// <summary>
/// Product specification details
/// </summary>
public class ProductSpec
{
    [Range(0, 100)]
    public double? Weight { get; set; }
    
    public ProductDimensions? Dimensions { get; set; }
    
    public string? Color { get; set; }
    
    public string? Material { get; set; }
    
    public string? Brand { get; set; }
    
    public string? Model { get; set; }
}

/// <summary>
/// Product dimensions
/// </summary>
public class ProductDimensions
{
    [Range(0.1, 1000)]
    public double Length { get; set; }
    
    [Range(0.1, 1000)]
    public double Width { get; set; }
    
    [Range(0.1, 1000)]
    public double Height { get; set; }
    
    public string Unit { get; set; } = "cm";
}

/// <summary>
/// Request to create a new product
/// </summary>
public record CreateProductRequest
{
    [Required]
    [StringLength(100, MinimumLength = 3)]
    public required string Name { get; init; }
    
    [StringLength(500)]
    public string? Description { get; init; }
    
    [Range(0.01, 999999.99)]
    public decimal Price { get; init; }
    
    public ProductCategory Category { get; init; } = ProductCategory.Other;
    
    public List<string> Tags { get; init; } = new();
    
    public Dictionary<string, string> Metadata { get; init; } = new();
    
    public ProductSpec? Specification { get; init; }
}

/// <summary>
/// Request to update an existing product
/// </summary>
public record UpdateProductRequest
{
    public required int Id { get; init; }
    
    [StringLength(100, MinimumLength = 3)]
    public string? Name { get; init; }
    
    [StringLength(500)]
    public string? Description { get; init; }
    
    [Range(0.01, 999999.99)]
    public decimal? Price { get; init; }
    
    public ProductCategory? Category { get; init; }
    
    public bool? IsActive { get; init; }
    
    public List<string>? Tags { get; init; }
    
    public Dictionary<string, string>? Metadata { get; init; }
    
    public ProductSpec? Specification { get; init; }
}

/// <summary>
/// Response containing product information
/// </summary>
public record ProductResponse
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public string? Description { get; init; }
    public required decimal Price { get; init; }
    public required ProductCategory Category { get; init; }
    public required DateTime CreatedAt { get; init; }
    public DateTime? UpdatedAt { get; init; }
    public required bool IsActive { get; init; }
    public required List<string> Tags { get; init; }
    public required Dictionary<string, string> Metadata { get; init; }
    public ProductSpec? Specification { get; init; }
}

/// <summary>
/// Request to search for products
/// </summary>
public record SearchProductsRequest
{
    public string? Query { get; init; }
    public ProductCategory? Category { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }
    public bool? IsActive { get; init; }
    public List<string>? Tags { get; init; }
    public string? SortBy { get; init; }
    public string SortOrder { get; init; } = "asc";
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}

/// <summary>
/// Paginated list of products
/// </summary>
public record ProductListResponse
{
    public required List<ProductResponse> Products { get; init; }
    public required int TotalCount { get; init; }
    public required int Page { get; init; }
    public required int PageSize { get; init; }
    public required int TotalPages { get; init; }
    public bool HasNextPage => Page < TotalPages;
    public bool HasPreviousPage => Page > 1;
}

/// <summary>
/// Request to get a product by ID
/// </summary>
public record GetProductRequest
{
    public required int Id { get; init; }
}

/// <summary>
/// Request to delete a product
/// </summary>
public record DeleteProductRequest
{
    public required int Id { get; init; }
}

/// <summary>
/// Response for delete operations
/// </summary>
public record DeleteProductResponse
{
    public required string Message { get; init; }
    public required bool Success { get; init; }
}