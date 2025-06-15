using ProtoGenSample.Models;

namespace ProtoGenSample.Events;

/// <summary>
/// Base class for all product-related events
/// </summary>
public abstract record ProductEvent
{
    public required int ProductId { get; init; }
    public required DateTime Timestamp { get; init; }
    public required string UserId { get; init; }
    public string? CorrelationId { get; init; }
}

/// <summary>
/// Event raised when a product is created
/// </summary>
public record ProductCreatedEvent : ProductEvent
{
    public required ProductResponse Product { get; init; }
    public required string CreatedBy { get; init; }
}

/// <summary>
/// Event raised when a product is updated
/// </summary>
public record ProductUpdatedEvent : ProductEvent
{
    public required ProductResponse Product { get; init; }
    public required ProductResponse PreviousProduct { get; init; }
    public required string UpdatedBy { get; init; }
    public required List<string> ChangedFields { get; init; }
}

/// <summary>
/// Event raised when a product is deleted
/// </summary>
public record ProductDeletedEvent : ProductEvent
{
    public required string DeletedBy { get; init; }
    public required string Reason { get; init; }
}

/// <summary>
/// Event raised when a product's price changes
/// </summary>
public record ProductPriceChangedEvent : ProductEvent
{
    public required decimal OldPrice { get; init; }
    public required decimal NewPrice { get; init; }
    public required decimal ChangePercentage { get; init; }
    public required string ChangedBy { get; init; }
    public string? Reason { get; init; }
}

/// <summary>
/// Event raised when a product goes out of stock
/// </summary>
public record ProductOutOfStockEvent : ProductEvent
{
    public required int LastKnownQuantity { get; init; }
    public required DateTime LastSaleDate { get; init; }
}

/// <summary>
/// Event raised when a product is restocked
/// </summary>
public record ProductRestockedEvent : ProductEvent
{
    public required int NewQuantity { get; init; }
    public required int AddedQuantity { get; init; }
    public required string RestockedBy { get; init; }
    public string? BatchNumber { get; init; }
}

/// <summary>
/// Event raised when a product is viewed
/// </summary>
public record ProductViewedEvent : ProductEvent
{
    public required string ViewerType { get; init; } // "customer", "admin", "system"
    public string? SessionId { get; init; }
    public string? UserAgent { get; init; }
    public string? IpAddress { get; init; }
    public string? Referrer { get; init; }
}

/// <summary>
/// Event raised when a product is added to a cart
/// </summary>
public record ProductAddedToCartEvent : ProductEvent
{
    public required string CartId { get; init; }
    public required int Quantity { get; init; }
    public required decimal UnitPrice { get; init; }
    public required decimal TotalPrice { get; init; }
}

/// <summary>
/// Event raised when a product is removed from a cart
/// </summary>
public record ProductRemovedFromCartEvent : ProductEvent
{
    public required string CartId { get; init; }
    public required int RemovedQuantity { get; init; }
    public required string RemovalReason { get; init; }
}

/// <summary>
/// Event raised when a product is purchased
/// </summary>
public record ProductPurchasedEvent : ProductEvent
{
    public required string OrderId { get; init; }
    public required int Quantity { get; init; }
    public required decimal UnitPrice { get; init; }
    public required decimal TotalPrice { get; init; }
    public required decimal TaxAmount { get; init; }
    public required decimal DiscountAmount { get; init; }
    public required PaymentInfo Payment { get; init; }
    public required ShippingInfo Shipping { get; init; }
}

/// <summary>
/// Payment information for purchase events
/// </summary>
public record PaymentInfo
{
    public required string PaymentMethod { get; init; }
    public required string TransactionId { get; init; }
    public required decimal Amount { get; init; }
    public required string Currency { get; init; }
    public required DateTime ProcessedAt { get; init; }
    public PaymentStatus Status { get; init; }
}

/// <summary>
/// Shipping information for purchase events
/// </summary>
public record ShippingInfo
{
    public required string Method { get; init; }
    public required decimal Cost { get; init; }
    public required Address Address { get; init; }
    public DateTime? EstimatedDelivery { get; init; }
    public string? TrackingNumber { get; init; }
}

/// <summary>
/// Address information
/// </summary>
public record Address
{
    public required string Line1 { get; init; }
    public string? Line2 { get; init; }
    public required string City { get; init; }
    public required string State { get; init; }
    public required string PostalCode { get; init; }
    public required string Country { get; init; }
}

/// <summary>
/// Payment status enumeration
/// </summary>
public enum PaymentStatus
{
    Pending = 1,
    Completed = 2,
    Failed = 3,
    Cancelled = 4,
    Refunded = 5
}

/// <summary>
/// Command to create a product
/// </summary>
public record CreateProductCommand
{
    public required string CommandId { get; init; }
    public required DateTime Timestamp { get; init; }
    public required string UserId { get; init; }
    public required CreateProductRequest Request { get; init; }
    public string? CorrelationId { get; init; }
    public Dictionary<string, string> Metadata { get; init; } = new();
}

/// <summary>
/// Command to update a product
/// </summary>
public record UpdateProductCommand
{
    public required string CommandId { get; init; }
    public required DateTime Timestamp { get; init; }
    public required string UserId { get; init; }
    public required UpdateProductRequest Request { get; init; }
    public string? CorrelationId { get; init; }
    public Dictionary<string, string> Metadata { get; init; } = new();
}

/// <summary>
/// Command to delete a product
/// </summary>
public record DeleteProductCommand
{
    public required string CommandId { get; init; }
    public required DateTime Timestamp { get; init; }
    public required string UserId { get; init; }
    public required DeleteProductRequest Request { get; init; }
    public required string Reason { get; init; }
    public string? CorrelationId { get; init; }
    public Dictionary<string, string> Metadata { get; init; } = new();
}