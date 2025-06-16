using Aspire.Hosting;

var builder = DistributedApplication.CreateBuilder(args);

// Infrastructure services
var postgres = builder.AddPostgreSQL("postgres")
                     .WithPgAdmin()
                     .AddDatabase("axiomexample");

var redis = builder.AddRedis("redis")
                  .WithRedisCommander();

// Notification service (gRPC)
var notifications = builder.AddProject("notifications", "../AxiomEndpointsExample.Notifications")
                          .WithReference(redis)
                          .WithHttpsEndpoint(7002);

// API service with AxiomEndpoints
var api = builder.AddProject("api", "../AxiomEndpointsExample.Api")
                .WithReference(postgres)
                .WithReference(redis)
                .WithReference(notifications)
                .WithHttpsEndpoint(7001);

// Demo client
builder.AddProject("client", "../AxiomEndpointsExample.Client")
       .WithReference(api)
       .WithReference(notifications);

await builder.Build().RunAsync();