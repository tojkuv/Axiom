using AxiomEndpoints.Aspire.Configuration;
using AxiomEndpoints.Aspire.HealthChecks;
using AxiomEndpoints.Aspire.Telemetry;

var builder = WebApplication.CreateBuilder(args);

// Add Aspire integration
builder.AddServiceDefaults();
builder.AddAxiomAspireConfiguration();
builder.AddAxiomTelemetry();

// Add Redis for event bus
builder.AddRedisClient("redis");

// Add Axiom endpoints
builder.Services.AddAxiomEndpoints();

// Add health checks
builder.Services.AddAxiomHealthChecks();

var app = builder.Build();

// Configure pipeline
app.MapDefaultEndpoints(); // Aspire defaults

// Use Axiom endpoints
app.UseAxiomEndpoints();

// Map health checks
app.MapAxiomHealthChecks();

await app.RunAsync();