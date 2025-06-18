using AxiomEndpoints.AspNetCore;
using AxiomEndpoints.Core;
using AxiomEndpointsExample.Api;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add Entity Framework - conditionally based on environment
if (builder.Environment.IsEnvironment("Testing"))
{
    // Use InMemory database for tests
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}"));
}
else
{
    // Use PostgreSQL for non-test environments
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql("Host=localhost;Database=axiom_example;Username=postgres;Password=postgres"));
}

// Add AxiomEndpoints with automatic discovery
builder.Services.AddAxiomEndpoints();

// Add CORS for client access
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.UseHttpsRedirection();
app.UseCors();

// Debug middleware to log all requests with detailed routing info
app.Use(async (context, next) =>
{
    Console.WriteLine($"[REQUEST] {context.Request.Method} {context.Request.Path}");
    Console.WriteLine($"[REQUEST] Query: {context.Request.QueryString}");
    Console.WriteLine($"[REQUEST] Route Values: {string.Join(", ", context.Request.RouteValues.Select(kv => $"{kv.Key}={kv.Value}"))}");
    
    await next();
    
    Console.WriteLine($"[RESPONSE] {context.Response.StatusCode}");
    Console.WriteLine($"[RESPONSE] Endpoint: {context.GetEndpoint()?.DisplayName ?? "No endpoint matched"}");
});

// Use AxiomEndpoints automatic endpoint discovery
app.UseAxiomEndpoints();


await app.RunAsync();

// Make Program class accessible for testing
public partial class Program { }