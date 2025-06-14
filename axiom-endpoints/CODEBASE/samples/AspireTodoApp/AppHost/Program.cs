using AxiomEndpoints.Aspire;

var builder = DistributedApplication.CreateBuilder(args);

// Add infrastructure
var postgres = builder.AddPostgres("postgres")
    .WithDataVolume()
    .WithPgAdmin();

var redis = builder.AddRedis("redis")
    .WithDataVolume()
    .WithRedisCommander();

// Add database for Todo API
var todoDb = postgres.AddDatabase("todoDb");

// Add Axiom Todo API service
var todoApi = builder.AddProject<Projects.TodoApi>("todo-api")
    .WithReference(todoDb)
    .WithReference(redis)
    .WithEnvironment("EventBus__Transport", "Redis")
    .WithExternalHttpEndpoints();

// Add Notification Service
var notificationService = builder.AddProject<Projects.NotificationService>("notification-service")
    .WithReference(redis)
    .WithEnvironment("EventBus__Transport", "Redis");

// Build and run
var app = builder.Build();
await app.RunAsync();