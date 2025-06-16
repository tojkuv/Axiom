namespace AxiomEndpointsExample.Notifications.Services;

public interface INotificationTracker
{
    Task TrackNotificationAsync(string notificationId, string userId, NotificationType type, string title, string message);
    Task UpdateStatusAsync(string notificationId, NotificationStatus status);
    Task<NotificationStatusInfo?> GetStatusAsync(string notificationId);
}

public class NotificationStatusInfo
{
    public string NotificationId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public NotificationStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public NotificationType Type { get; set; }
}