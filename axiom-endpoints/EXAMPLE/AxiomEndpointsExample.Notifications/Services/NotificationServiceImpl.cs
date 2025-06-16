using Grpc.Core;
using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

namespace AxiomEndpointsExample.Notifications.Services;

public class NotificationServiceImpl : NotificationService.NotificationServiceBase
{
    private readonly INotificationTracker _tracker;
    private readonly ILogger<NotificationServiceImpl> _logger;

    public NotificationServiceImpl(INotificationTracker tracker, ILogger<NotificationServiceImpl> logger)
    {
        _tracker = tracker;
        _logger = logger;
    }

    public override async Task<SendNotificationResponse> SendNotification(
        SendNotificationRequest request, 
        ServerCallContext context)
    {
        try
        {
            var notificationId = Guid.NewGuid().ToString();
            
            _logger.LogInformation(
                "Sending notification {NotificationId} to user {UserId}: {Title}", 
                notificationId, request.UserId, request.Title);

            // Track the notification
            await _tracker.TrackNotificationAsync(notificationId, request.UserId, request.Type, request.Title, request.Message);

            // Simulate sending (in real implementation, this would integrate with push notification services)
            await Task.Delay(100); // Simulate network delay

            // Mark as sent
            await _tracker.UpdateStatusAsync(notificationId, NotificationStatus.Sent);

            // Simulate delivery
            await Task.Delay(50);
            await _tracker.UpdateStatusAsync(notificationId, NotificationStatus.Delivered);

            return new SendNotificationResponse
            {
                NotificationId = notificationId,
                Success = true
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to user {UserId}", request.UserId);
            return new SendNotificationResponse
            {
                Success = false,
                ErrorMessage = ex.Message
            };
        }
    }

    public override async Task<GetNotificationStatusResponse> GetNotificationStatus(
        GetNotificationStatusRequest request, 
        ServerCallContext context)
    {
        try
        {
            var status = await _tracker.GetStatusAsync(request.NotificationId);
            
            if (status == null)
            {
                throw new RpcException(new Status(StatusCode.NotFound, "Notification not found"));
            }

            return new GetNotificationStatusResponse
            {
                NotificationId = request.NotificationId,
                Status = status.Status,
                SentAt = status.SentAt?.Ticks ?? 0,
                DeliveredAt = status.DeliveredAt?.Ticks ?? 0
            };
        }
        catch (Exception ex) when (!(ex is RpcException))
        {
            _logger.LogError(ex, "Failed to get notification status for {NotificationId}", request.NotificationId);
            throw new RpcException(new Status(StatusCode.Internal, "Internal server error"));
        }
    }

    public override async Task StreamNotifications(
        StreamNotificationsRequest request, 
        IServerStreamWriter<NotificationEvent> responseStream, 
        ServerCallContext context)
    {
        _logger.LogInformation("Starting notification stream for user {UserId}", request.UserId);

        try
        {
            // In a real implementation, this would connect to a message queue or event stream
            // For demo purposes, we'll send periodic test notifications
            var random = new Random();
            var counter = 0;

            while (!context.CancellationToken.IsCancellationRequested)
            {
                counter++;
                var notificationEvent = new NotificationEvent
                {
                    NotificationId = Guid.NewGuid().ToString(),
                    UserId = request.UserId,
                    Title = $"Live Notification #{counter}",
                    Message = $"This is a real-time notification sent at {DateTime.UtcNow:HH:mm:ss}",
                    Type = (NotificationType)(counter % 4),
                    Timestamp = DateTime.UtcNow.Ticks
                };

                notificationEvent.Metadata.Add("counter", counter.ToString());
                notificationEvent.Metadata.Add("demo", "true");

                await responseStream.WriteAsync(notificationEvent);
                
                // Wait 3-8 seconds between notifications
                await Task.Delay(TimeSpan.FromSeconds(3 + random.Next(6)), context.CancellationToken);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Notification stream cancelled for user {UserId}", request.UserId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in notification stream for user {UserId}", request.UserId);
            throw;
        }
    }
}