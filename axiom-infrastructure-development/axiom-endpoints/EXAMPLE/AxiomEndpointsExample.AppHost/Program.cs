using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

// Infrastructure services - using in-memory alternatives for testing
var redis = builder.AddRedis("redis");

// Notification service (gRPC)
var notifications = builder.AddProject("notifications", "../AxiomEndpointsExample.Notifications")
                          .WithReference(redis);

// API service with AxiomEndpoints - using in-memory database for testing
var api = builder.AddProject("api", "../AxiomEndpointsExample.Api")
                .WithReference(redis)
                .WithReference(notifications);

// Demo client
builder.AddProject("client", "../AxiomEndpointsExample.Client")
       .WithReference(api)
       .WithReference(notifications);

await builder.Build().RunAsync();