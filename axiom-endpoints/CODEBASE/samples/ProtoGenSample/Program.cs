var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

// Health check endpoint
app.MapGet("/health", () => new { Status = "Healthy", Timestamp = DateTime.UtcNow });

// API info endpoint
app.MapGet("/api/info", () => new 
{ 
    Name = "ProtoGenSample API",
    Version = "1.0.0",
    Description = "Sample API for testing Axiom Endpoints proto generation"
});

app.Run();