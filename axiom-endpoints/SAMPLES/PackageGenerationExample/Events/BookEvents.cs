using PackageGenerationExample.Models;
using PackageGenerationExample.Endpoints;

namespace PackageGenerationExample.Events;

/// <summary>
/// Base interface for all library events
/// </summary>
public interface ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    string EventId { get; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    DateTime Timestamp { get; }

    /// <summary>
    /// User who triggered the event
    /// </summary>
    string? UserId { get; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    string? CorrelationId { get; }
}

/// <summary>
/// Event fired when a new book is added to the library
/// </summary>
public class BookAddedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// User who added the book
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was added
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// Complete book information
    /// </summary>
    public required BookResponse Book { get; set; }

    /// <summary>
    /// Number of copies added
    /// </summary>
    public int CopiesAdded { get; set; }

    /// <summary>
    /// Library branch where the book was added
    /// </summary>
    public string? BranchId { get; set; }

    /// <summary>
    /// Additional metadata about the addition
    /// </summary>
    public Dictionary<string, string> Metadata { get; set; } = new();
}

/// <summary>
/// Event fired when a book is updated
/// </summary>
public class BookUpdatedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// User who updated the book
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was updated
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// Book information after the update
    /// </summary>
    public required BookResponse Book { get; set; }

    /// <summary>
    /// Previous book information before the update
    /// </summary>
    public BookResponse? PreviousBook { get; set; }

    /// <summary>
    /// List of fields that were changed
    /// </summary>
    public List<string> ChangedFields { get; set; } = new();

    /// <summary>
    /// Reason for the update
    /// </summary>
    public string? UpdateReason { get; set; }
}

/// <summary>
/// Event fired when a book is removed from the library
/// </summary>
public class BookRemovedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// User who removed the book
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was removed
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// Book information at the time of removal
    /// </summary>
    public required BookResponse Book { get; set; }

    /// <summary>
    /// Reason for removal
    /// </summary>
    public required string RemovalReason { get; set; }

    /// <summary>
    /// Whether the book was physically removed or just deactivated
    /// </summary>
    public bool PhysicalRemoval { get; set; }

    /// <summary>
    /// Number of copies that were removed
    /// </summary>
    public int CopiesRemoved { get; set; }
}

/// <summary>
/// Event fired when a book is borrowed by a patron
/// </summary>
public class BookBorrowedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// Library staff who processed the borrowing
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was borrowed
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// ID of the patron who borrowed the book
    /// </summary>
    public required string PatronId { get; set; }

    /// <summary>
    /// Name of the patron
    /// </summary>
    public string? PatronName { get; set; }

    /// <summary>
    /// Due date for the book return
    /// </summary>
    public DateTime DueDate { get; set; }

    /// <summary>
    /// Number of copies borrowed
    /// </summary>
    public int CopiesBorrowed { get; set; }

    /// <summary>
    /// Library branch where the book was borrowed
    /// </summary>
    public string? BranchId { get; set; }

    /// <summary>
    /// Lending period in days
    /// </summary>
    public int LendingPeriodDays { get; set; }

    /// <summary>
    /// Special borrowing conditions
    /// </summary>
    public string? SpecialConditions { get; set; }
}

/// <summary>
/// Event fired when a book is returned by a patron
/// </summary>
public class BookReturnedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// Library staff who processed the return
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was returned
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// ID of the patron who returned the book
    /// </summary>
    public required string PatronId { get; set; }

    /// <summary>
    /// When the book was originally borrowed
    /// </summary>
    public DateTime BorrowedDate { get; set; }

    /// <summary>
    /// When the book was due
    /// </summary>
    public DateTime DueDate { get; set; }

    /// <summary>
    /// Whether the book was returned late
    /// </summary>
    public bool IsLate { get; set; }

    /// <summary>
    /// Number of days late (if applicable)
    /// </summary>
    public int DaysLate { get; set; }

    /// <summary>
    /// Fine amount for late return
    /// </summary>
    public decimal FineAmount { get; set; }

    /// <summary>
    /// Condition of the book upon return
    /// </summary>
    public BookCondition BookCondition { get; set; }

    /// <summary>
    /// Any notes about the book's condition
    /// </summary>
    public string? ConditionNotes { get; set; }

    /// <summary>
    /// Library branch where the book was returned
    /// </summary>
    public string? BranchId { get; set; }
}

/// <summary>
/// Event fired when a book is reserved by a patron
/// </summary>
public class BookReservedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// User who processed the reservation (could be patron or staff)
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book that was reserved
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// ID of the patron who reserved the book
    /// </summary>
    public required string PatronId { get; set; }

    /// <summary>
    /// Position in the reservation queue
    /// </summary>
    public int QueuePosition { get; set; }

    /// <summary>
    /// Estimated availability date
    /// </summary>
    public DateTime? EstimatedAvailableDate { get; set; }

    /// <summary>
    /// Reservation expiry date
    /// </summary>
    public DateTime ExpiryDate { get; set; }

    /// <summary>
    /// Preferred pickup branch
    /// </summary>
    public string? PreferredBranchId { get; set; }

    /// <summary>
    /// How the patron wants to be notified
    /// </summary>
    public NotificationMethod NotificationMethod { get; set; }
}

/// <summary>
/// Event fired when book inventory is updated
/// </summary>
public class BookInventoryUpdatedEvent : ILibraryEvent
{
    /// <summary>
    /// Event ID
    /// </summary>
    public required string EventId { get; set; }

    /// <summary>
    /// When the event occurred
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// User who updated the inventory
    /// </summary>
    public string? UserId { get; set; }

    /// <summary>
    /// Correlation ID for tracking related events
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// ID of the book whose inventory was updated
    /// </summary>
    public int BookId { get; set; }

    /// <summary>
    /// Previous total copies
    /// </summary>
    public int PreviousTotalCopies { get; set; }

    /// <summary>
    /// New total copies
    /// </summary>
    public int NewTotalCopies { get; set; }

    /// <summary>
    /// Previous available copies
    /// </summary>
    public int PreviousAvailableCopies { get; set; }

    /// <summary>
    /// New available copies
    /// </summary>
    public int NewAvailableCopies { get; set; }

    /// <summary>
    /// Reason for inventory update
    /// </summary>
    public required string UpdateReason { get; set; }

    /// <summary>
    /// Type of inventory change
    /// </summary>
    public InventoryChangeType ChangeType { get; set; }

    /// <summary>
    /// Branch where the inventory change occurred
    /// </summary>
    public string? BranchId { get; set; }
}

/// <summary>
/// Condition of a book upon return
/// </summary>
public enum BookCondition
{
    Excellent = 1,
    Good = 2,
    Fair = 3,
    Poor = 4,
    Damaged = 5,
    Lost = 6
}

/// <summary>
/// Methods for notifying patrons
/// </summary>
public enum NotificationMethod
{
    Email = 1,
    SMS = 2,
    Phone = 3,
    Mail = 4,
    AppNotification = 5
}

/// <summary>
/// Types of inventory changes
/// </summary>
public enum InventoryChangeType
{
    Purchase = 1,
    Donation = 2,
    Transfer = 3,
    Damaged = 4,
    Lost = 5,
    Theft = 6,
    Disposal = 7,
    Correction = 8
}