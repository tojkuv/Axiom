using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

namespace AxiomEndpointsExample.Notifications.Services;

public class RedisNotificationTracker : INotificationTracker
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<RedisNotificationTracker> _logger;

    public RedisNotificationTracker(IDistributedCache cache, ILogger<RedisNotificationTracker> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    public async Task TrackNotificationAsync(string notificationId, string userId, NotificationType type, string title, string message)
    {
        var statusInfo = new NotificationStatusInfo
        {
            NotificationId = notificationId,
            UserId = userId,
            Status = NotificationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            Title = title,
            Message = message,
            Type = type
        };

        var json = JsonSerializer.Serialize(statusInfo);
        var key = GetCacheKey(notificationId);
        
        await _cache.SetStringAsync(key, json, new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromDays(7) // Keep notification history for 7 days
        });

        _logger.LogDebug("Tracked notification {NotificationId} for user {UserId}", notificationId, userId);
    }

    public async Task UpdateStatusAsync(string notificationId, NotificationStatus status)
    {
        var key = GetCacheKey(notificationId);
        var existingJson = await _cache.GetStringAsync(key);
        
        if (existingJson == null)
        {
            _logger.LogWarning("Attempted to update status for non-existent notification {NotificationId}", notificationId);
            return;
        }

        var statusInfo = JsonSerializer.Deserialize<NotificationStatusInfo>(existingJson);
        if (statusInfo == null)
        {
            _logger.LogError("Failed to deserialize notification status for {NotificationId}", notificationId);
            return;
        }

        statusInfo.Status = status;
        
        switch (status)
        {
            case NotificationStatus.Sent:
                statusInfo.SentAt = DateTime.UtcNow;
                break;
            case NotificationStatus.Delivered:
                statusInfo.DeliveredAt = DateTime.UtcNow;
                break;
        }

        var updatedJson = JsonSerializer.Serialize(statusInfo);
        await _cache.SetStringAsync(key, updatedJson, new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromDays(7)
        });

        _logger.LogDebug("Updated notification {NotificationId} status to {Status}", notificationId, status);
    }

    public async Task<NotificationStatusInfo?> GetStatusAsync(string notificationId)
    {
        var key = GetCacheKey(notificationId);
        var json = await _cache.GetStringAsync(key);
        
        if (json == null)
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<NotificationStatusInfo>(json);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize notification status for {NotificationId}", notificationId);
            return null;
        }
    }

    private static string GetCacheKey(string notificationId) => $"notification:status:{notificationId}";
}