using AxiomEndpointsExample.Notifications;
using Grpc.Net.Client;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Text.Json;

var builder = Host.CreateApplicationBuilder(args);

// Configure services
builder.Services.AddHttpClient("api", client =>
{
    client.BaseAddress = new Uri("https://localhost:7001"); // API service URL
});

builder.Services.AddSingleton(provider =>
{
    var channel = GrpcChannel.ForAddress("https://localhost:7002"); // Notifications service URL
    return new NotificationService.NotificationServiceClient(channel);
});

builder.Services.AddHostedService<ClientDemoService>();

var app = builder.Build();

await app.RunAsync();

public class ClientDemoService : BackgroundService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly NotificationService.NotificationServiceClient _notificationClient;
    private readonly ILogger<ClientDemoService> _logger;

    public ClientDemoService(
        IHttpClientFactory httpClientFactory,
        NotificationService.NotificationServiceClient notificationClient,
        ILogger<ClientDemoService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _notificationClient = notificationClient;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            _logger.LogInformation("Starting AxiomEndpoints Example Client Demo");

            // Test API endpoints
            await TestApiEndpoints(stoppingToken);
            
            // Test notification service
            await TestNotificationService(stoppingToken);
            
            // Stream notifications (this will run until cancelled)
            await StreamNotifications(stoppingToken);
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Client demo stopped");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in client demo");
        }
    }

    private async Task TestApiEndpoints(CancellationToken cancellationToken)
    {
        _logger.LogInformation("=== Testing API Endpoints ===");
        
        var httpClient = _httpClientFactory.CreateClient("api");

        try
        {
            // Test health endpoint
            _logger.LogInformation("Testing health endpoint...");
            var healthResponse = await httpClient.GetStringAsync("/health", cancellationToken);
            _logger.LogInformation("Health response: {Response}", healthResponse);

            // Test users endpoint
            _logger.LogInformation("Testing users endpoint...");
            var usersResponse = await httpClient.GetStringAsync("/v1/users", cancellationToken);
            _logger.LogInformation("Users response: {Response}", usersResponse);

            // Test user search
            _logger.LogInformation("Testing user search...");
            var searchResponse = await httpClient.GetStringAsync("/v1/users/search?search=test&limit=5", cancellationToken);
            _logger.LogInformation("Search response: {Response}", searchResponse);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning("API endpoints not available: {Message}", ex.Message);
            _logger.LogInformation("Make sure the API service is running on https://localhost:7001");
        }
    }

    private async Task TestNotificationService(CancellationToken cancellationToken)
    {
        _logger.LogInformation("=== Testing Notification Service ===");

        try
        {
            // Send a test notification
            _logger.LogInformation("Sending test notification...");
            var sendRequest = new SendNotificationRequest
            {
                UserId = "demo-user-123",
                Title = "Welcome to AxiomEndpoints!",
                Message = "This is a test notification from the demo client.",
                Type = NotificationType.Info
            };
            sendRequest.Metadata.Add("source", "demo-client");

            var sendResponse = await _notificationClient.SendNotificationAsync(sendRequest, cancellationToken: cancellationToken);
            
            if (sendResponse.Success)
            {
                _logger.LogInformation("Notification sent successfully! ID: {NotificationId}", sendResponse.NotificationId);

                // Check notification status
                await Task.Delay(1000, cancellationToken); // Wait a bit for processing

                var statusRequest = new GetNotificationStatusRequest
                {
                    NotificationId = sendResponse.NotificationId
                };

                var statusResponse = await _notificationClient.GetNotificationStatusAsync(statusRequest, cancellationToken: cancellationToken);
                _logger.LogInformation("Notification status: {Status}, Sent: {SentAt}, Delivered: {DeliveredAt}",
                    statusResponse.Status,
                    statusResponse.SentAt > 0 ? new DateTime(statusResponse.SentAt) : "Not sent",
                    statusResponse.DeliveredAt > 0 ? new DateTime(statusResponse.DeliveredAt) : "Not delivered");
            }
            else
            {
                _logger.LogError("Failed to send notification: {Error}", sendResponse.ErrorMessage);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Notification service not available: {Message}", ex.Message);
            _logger.LogInformation("Make sure the Notifications service is running on https://localhost:7002");
        }
    }

    private async Task StreamNotifications(CancellationToken cancellationToken)
    {
        _logger.LogInformation("=== Starting Notification Stream ===");
        _logger.LogInformation("Streaming real-time notifications... (Press Ctrl+C to stop)");

        try
        {
            var streamRequest = new StreamNotificationsRequest
            {
                UserId = "demo-user-123"
            };

            using var call = _notificationClient.StreamNotifications(streamRequest, cancellationToken: cancellationToken);

            while (await call.ResponseStream.MoveNext(cancellationToken))
            {
                var notification = call.ResponseStream.Current;
                _logger.LogInformation(
                    "[{Timestamp}] {Type} Notification: {Title} - {Message} (ID: {NotificationId})",
                    new DateTime(notification.Timestamp).ToString("HH:mm:ss"),
                    notification.Type,
                    notification.Title,
                    notification.Message,
                    notification.NotificationId[..8] + "...");
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogInformation("Notification streaming stopped");
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Error in notification streaming: {Message}", ex.Message);
            _logger.LogInformation("Make sure the Notifications service is running and accessible");
        }
    }
}