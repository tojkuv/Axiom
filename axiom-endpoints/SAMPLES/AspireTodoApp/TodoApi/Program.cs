using AxiomEndpoints.Aspire.Configuration;
using AxiomEndpoints.Aspire.HealthChecks;
using AxiomEndpoints.Aspire.Telemetry;
using Microsoft.EntityFrameworkCore;
using TodoApi.Data;
using TodoApi.Endpoints;

var builder = WebApplication.CreateBuilder(args);

// Add Aspire integration
builder.AddServiceDefaults();
builder.AddAxiomAspireConfiguration();
builder.AddAxiomTelemetry();

// Add database
builder.AddNpgsqlDbContext<TodoDbContext>("todoDb");

// Add Redis for caching
builder.AddRedisClient("redis");

// Add Axiom endpoints
builder.Services.AddAxiomEndpoints();

// Add health checks
builder.Services.AddAxiomHealthChecks();

// Add API documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure pipeline
app.MapDefaultEndpoints(); // Aspire defaults

// Configure Swagger for development
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Use Axiom endpoints
app.UseAxiomEndpoints();

// Map health checks
app.MapAxiomHealthChecks();

// Ensure database is created
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<TodoDbContext>();
    await context.Database.EnsureCreatedAsync();
}

await app.RunAsync();