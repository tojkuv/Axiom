using AxiomEndpointsExample.Notifications.Services;

var builder = WebApplication.CreateBuilder(args);

// Add gRPC services
builder.Services.AddGrpc();

// Add Redis for notification tracking
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
});

// Register our notification service
builder.Services.AddSingleton<INotificationTracker, RedisNotificationTracker>();

var app = builder.Build();

// Configure gRPC endpoints
app.MapGrpcService<NotificationServiceImpl>();

// Add health check
app.MapGet("/", () => "Notification Service is running. gRPC endpoints available at /NotificationService");

await app.RunAsync();