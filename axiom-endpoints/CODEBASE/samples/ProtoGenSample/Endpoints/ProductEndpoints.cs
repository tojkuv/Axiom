using AxiomEndpoints.Core;
using ProtoGenSample.Models;

namespace ProtoGenSample.Endpoints;

/// <summary>
/// Endpoint to create a new product
/// </summary>
public record CreateProduct : IAxiom<CreateProductRequest, ProductResponse>
{
    public async ValueTask<Result<ProductResponse>> HandleAsync(
        CreateProductRequest request,
        IContext context)
    {
        // Simulate product creation
        var product = new Product
        {
            Id = Random.Shared.Next(1, 10000),
            Name = request.Name,
            Description = request.Description,
            Price = request.Price,
            Category = request.Category,
            Tags = request.Tags,
            Metadata = request.Metadata,
            Specification = request.Specification,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        var response = new ProductResponse
        {
            Id = product.Id,
            Name = product.Name,
            Description = product.Description,
            Price = product.Price,
            Category = product.Category,
            CreatedAt = product.CreatedAt,
            UpdatedAt = product.UpdatedAt,
            IsActive = product.IsActive,
            Tags = product.Tags,
            Metadata = product.Metadata,
            Specification = product.Specification
        };

        // Set location header for created resource
        // context.SetLocation(new GetProductRequest { Id = product.Id });

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Endpoint to get a product by ID
/// </summary>
public record GetProduct : IAxiom<GetProductRequest, ProductResponse>
{
    public async ValueTask<Result<ProductResponse>> HandleAsync(
        GetProductRequest request,
        IContext context)
    {
        // Simulate database lookup
        if (request.Id <= 0)
        {
            return ResultFactory.Failure<ProductResponse>(AxiomError.Validation("Product ID must be positive"));
        }

        // Simulate product not found
        if (request.Id == 999)
        {
            return ResultFactory.NotFound<ProductResponse>($"Product with ID {request.Id} not found");
        }

        // Simulate found product
        var response = new ProductResponse
        {
            Id = request.Id,
            Name = "Sample Product",
            Description = "This is a sample product for testing",
            Price = 99.99m,
            Category = ProductCategory.Electronics,
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            UpdatedAt = DateTime.UtcNow.AddDays(-5),
            IsActive = true,
            Tags = new List<string> { "sample", "test", "electronics" },
            Metadata = new Dictionary<string, string>
            {
                ["color"] = "blue",
                ["warranty"] = "1 year"
            },
            Specification = new ProductSpec
            {
                Weight = 1.5,
                Dimensions = new ProductDimensions
                {
                    Length = 20,
                    Width = 15,
                    Height = 8,
                    Unit = "cm"
                },
                Color = "Blue",
                Material = "Plastic",
                Brand = "SampleBrand",
                Model = "SB-123"
            }
        };

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Endpoint to search for products
/// </summary>
public record SearchProducts : IAxiom<SearchProductsRequest, ProductListResponse>
{
    public async ValueTask<Result<ProductListResponse>> HandleAsync(
        SearchProductsRequest request,
        IContext context)
    {
        // Simulate search logic
        var products = GenerateSimulatedProducts(request);
        
        var totalCount = 100; // Simulated total
        var totalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize);

        var response = new ProductListResponse
        {
            Products = products,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = totalPages
        };

        return ResultFactory.Success(response);
    }

    private List<ProductResponse> GenerateSimulatedProducts(SearchProductsRequest request)
    {
        var products = new List<ProductResponse>();
        
        for (int i = 1; i <= Math.Min(request.PageSize, 10); i++)
        {
            var id = (request.Page - 1) * request.PageSize + i;
            products.Add(new ProductResponse
            {
                Id = id,
                Name = $"Product {id}",
                Description = $"Description for product {id}",
                Price = 10.99m * i,
                Category = (ProductCategory)(i % 6 + 1),
                CreatedAt = DateTime.UtcNow.AddDays(-i),
                UpdatedAt = DateTime.UtcNow.AddDays(-i / 2.0),
                IsActive = i % 10 != 0, // 90% active
                Tags = new List<string> { $"tag{i}", "generated" },
                Metadata = new Dictionary<string, string>
                {
                    ["generated"] = "true",
                    ["index"] = i.ToString()
                },
                Specification = new ProductSpec
                {
                    Weight = i * 0.5,
                    Color = i % 2 == 0 ? "Blue" : "Red",
                    Brand = "TestBrand"
                }
            });
        }

        return products;
    }
}

/// <summary>
/// Endpoint to update a product
/// </summary>
public record UpdateProduct : IAxiom<UpdateProductRequest, ProductResponse>
{
    public async ValueTask<Result<ProductResponse>> HandleAsync(
        UpdateProductRequest request,
        IContext context)
    {
        // Simulate validation
        if (request.Id <= 0)
        {
            return ResultFactory.Failure<ProductResponse>(AxiomError.Validation("Product ID must be positive"));
        }

        // Simulate product not found
        if (request.Id == 999)
        {
            return ResultFactory.NotFound<ProductResponse>($"Product with ID {request.Id} not found");
        }

        // Simulate updated product
        var response = new ProductResponse
        {
            Id = request.Id,
            Name = request.Name ?? "Updated Product",
            Description = request.Description ?? "Updated description",
            Price = request.Price ?? 199.99m,
            Category = request.Category ?? ProductCategory.Electronics,
            CreatedAt = DateTime.UtcNow.AddDays(-30),
            UpdatedAt = DateTime.UtcNow,
            IsActive = request.IsActive ?? true,
            Tags = request.Tags ?? new List<string> { "updated" },
            Metadata = request.Metadata ?? new Dictionary<string, string>
            {
                ["updated"] = "true"
            },
            Specification = request.Specification
        };

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Endpoint to delete a product
/// </summary>
public record DeleteProduct : IAxiom<DeleteProductRequest, DeleteProductResponse>
{
    public async ValueTask<Result<DeleteProductResponse>> HandleAsync(
        DeleteProductRequest request,
        IContext context)
    {
        // Simulate validation
        if (request.Id <= 0)
        {
            return ResultFactory.Failure<DeleteProductResponse>(AxiomError.Validation("Product ID must be positive"));
        }

        // Simulate product not found
        if (request.Id == 999)
        {
            return ResultFactory.NotFound<DeleteProductResponse>($"Product with ID {request.Id} not found");
        }

        var response = new DeleteProductResponse
        {
            Message = $"Product {request.Id} deleted successfully",
            Success = true
        };

        return ResultFactory.Success(response);
    }
}

/// <summary>
/// Endpoint to get product categories
/// </summary>
public record GetProductCategories : IAxiom<GetCategoriesRequest, CategoriesResponse>
{
    public async ValueTask<Result<CategoriesResponse>> HandleAsync(
        GetCategoriesRequest request,
        IContext context)
    {
        var categories = Enum.GetValues<ProductCategory>()
            .Select(c => new CategoryInfo
            {
                Id = (int)c,
                Name = c.ToString(),
                Description = GetCategoryDescription(c)
            })
            .ToList();

        var response = new CategoriesResponse
        {
            Categories = categories
        };

        return ResultFactory.Success(response);
    }

    private string GetCategoryDescription(ProductCategory category)
    {
        return category switch
        {
            ProductCategory.Electronics => "Electronic devices and gadgets",
            ProductCategory.Clothing => "Apparel and fashion items",
            ProductCategory.Books => "Books and educational materials",
            ProductCategory.Sports => "Sports equipment and gear",
            ProductCategory.Home => "Home and garden items",
            ProductCategory.Other => "Miscellaneous items",
            _ => ""
        };
    }
}

/// <summary>
/// Request for getting categories (empty)
/// </summary>
public record GetCategoriesRequest;

/// <summary>
/// Response containing product categories
/// </summary>
public record CategoriesResponse
{
    public required List<CategoryInfo> Categories { get; init; }
}

/// <summary>
/// Category information
/// </summary>
public record CategoryInfo
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Description { get; init; }
}