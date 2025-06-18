using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using AxiomEndpointsExample.Api;
using AxiomEndpointsExample.Tests.Builders;
using AxiomEndpointsExample.Tests.Infrastructure;
using System.Text.Json;
using AutoFixture;

namespace AxiomEndpointsExample.Tests.Integration;

/// <summary>
/// Base class for API integration tests using WebApplicationFactory
/// </summary>
[TestClass]
public abstract class ApiIntegrationTestBase : TestBase
{
    protected WebApplicationFactory<Program> Factory { get; private set; } = null!;
    protected HttpClient Client { get; private set; } = null!;
    protected IServiceScope TestScope { get; private set; } = null!;
    protected AppDbContext DbContext { get; private set; } = null!;
    protected TestDataBuilder DataBuilder { get; private set; } = null!;

    protected static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true
    };

    protected override async Task AdditionalSetupAsync()
    {
        await base.AdditionalSetupAsync();

        // Get the shared database provider
        var sharedServiceProvider = SharedDatabaseProvider.GetSharedServiceProvider();
        var sharedDbOptions = SharedDatabaseProvider.GetSharedDbContextOptions();
        
        Factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Testing");
                builder.ConfigureServices(services =>
                {
                    // Remove ALL existing DbContext-related registrations
                    var descriptorsToRemove = services.Where(d => 
                        d.ServiceType == typeof(DbContextOptions<AppDbContext>) ||
                        d.ServiceType == typeof(AppDbContext) ||
                        d.ServiceType == typeof(DbContextOptions) ||
                        d.ImplementationType == typeof(AppDbContext))
                        .ToList();
                    
                    foreach (var descriptor in descriptorsToRemove)
                    {
                        services.Remove(descriptor);
                    }
                    
                    // Use the shared DbContext options singleton
                    services.AddSingleton(sharedDbOptions);
                    services.AddScoped<AppDbContext>(provider => 
                        new AppDbContext(provider.GetRequiredService<DbContextOptions<AppDbContext>>()));
                    
                    // Add test data builder with IFixture dependency
                    services.AddSingleton<IFixture>(provider =>
                    {
                        var fixture = new Fixture();
                        fixture.Behaviors.OfType<ThrowingRecursionBehavior>().ToList()
                            .ForEach(b => fixture.Behaviors.Remove(b));
                        fixture.Behaviors.Add(new OmitOnRecursionBehavior());
                        return fixture;
                    });
                    services.AddSingleton<TestDataBuilder>();

                    // Configure logging for tests
                    services.AddLogging(builder => 
                        builder.AddConsole().SetMinimumLevel(LogLevel.Warning));
                });
            });

        // Create the test DbContext using the shared options
        DbContext = new AppDbContext(sharedDbOptions);
        
        // Create test data builder
        var fixture = new Fixture();
        fixture.Behaviors.OfType<ThrowingRecursionBehavior>().ToList()
            .ForEach(b => fixture.Behaviors.Remove(b));
        fixture.Behaviors.Add(new OmitOnRecursionBehavior());
        DataBuilder = new TestDataBuilder(fixture);

        // Ensure database is created and seeded BEFORE creating the HTTP client
        await DbContext.Database.EnsureCreatedAsync();
        await SeedTestDataAsync();

        // Verify data was seeded
        var userCount = await DbContext.Users.CountAsync();
        Console.WriteLine($"[TEST] Seeded {userCount} users in test database");

        // Check if the specific test user exists
        var specificTestUserId = new Guid("A1B2C3D4-E5F6-789A-BCDE-F0123456789A");
        var specificUser = await DbContext.Users.FirstOrDefaultAsync(u => u.Id == specificTestUserId);
        Console.WriteLine($"[TEST] Specific test user exists: {specificUser != null}, Email: {specificUser?.Email}");

        // Now create the HTTP client - the web app should use the same database
        Client = Factory.CreateClient();
        
        // Verify web app can see the data by checking database from web app's perspective
        using var webAppScope = Factory.Services.CreateScope();
        var webAppDbContext = webAppScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var webAppUserCount = await webAppDbContext.Users.CountAsync();
        Console.WriteLine($"[WEB] Web app sees {webAppUserCount} users in database");
        
        // Check if web app can see the specific test user
        var webAppSpecificUser = await webAppDbContext.Users.FirstOrDefaultAsync(u => u.Id == specificTestUserId);
        Console.WriteLine($"[WEB] Web app sees specific test user: {webAppSpecificUser != null}, Email: {webAppSpecificUser?.Email}");
        
        // Create test scope for cleanup purposes 
        TestScope = Factory.Services.CreateScope();
    }

    protected override async Task AdditionalCleanupAsync()
    {
        Client?.Dispose();
        
        if (DbContext != null)
        {
            try
            {
                await DbContext.Database.EnsureDeletedAsync();
                await DbContext.DisposeAsync();
            }
            catch (ObjectDisposedException)
            {
                // Database context is already disposed
            }
        }
        
        TestScope?.Dispose();
        Factory?.Dispose();
        await base.AdditionalCleanupAsync();
    }

    /// <summary>
    /// Seeds the database with test data
    /// </summary>
    protected virtual async Task SeedTestDataAsync()
    {
        // Override in derived classes to add specific test data
        await Task.CompletedTask;
    }

    /// <summary>
    /// Makes a GET request and deserializes the response
    /// </summary>
    protected async Task<T?> GetAsync<T>(string requestUri)
    {
        var response = await Client.GetAsync(requestUri);
        response.EnsureSuccessStatusCode();
        
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(json, JsonOptions);
    }

    /// <summary>
    /// Makes a POST request with JSON content
    /// </summary>
    protected async Task<HttpResponseMessage> PostAsJsonAsync<T>(string requestUri, T content)
    {
        var json = JsonSerializer.Serialize(content, JsonOptions);
        var httpContent = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
        return await Client.PostAsync(requestUri, httpContent);
    }

    /// <summary>
    /// Makes a PUT request with JSON content
    /// </summary>
    protected async Task<HttpResponseMessage> PutAsJsonAsync<T>(string requestUri, T content)
    {
        var json = JsonSerializer.Serialize(content, JsonOptions);
        var httpContent = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
        return await Client.PutAsync(requestUri, httpContent);
    }

    /// <summary>
    /// Asserts that the response has the expected status code
    /// </summary>
    protected static void AssertStatusCode(HttpResponseMessage response, System.Net.HttpStatusCode expectedStatusCode)
    {
        Assert.AreEqual(expectedStatusCode, response.StatusCode, 
            $"Expected status code {expectedStatusCode} but got {response.StatusCode}. Response: {response.Content.ReadAsStringAsync().Result}");
    }

    /// <summary>
    /// Asserts that the response contains the expected content type
    /// </summary>
    protected static void AssertContentType(HttpResponseMessage response, string expectedContentType)
    {
        Assert.IsNotNull(response.Content.Headers.ContentType);
        Assert.AreEqual(expectedContentType, response.Content.Headers.ContentType.MediaType);
    }

    /// <summary>
    /// Gets a fresh DbContext for database operations during tests
    /// </summary>
    protected AppDbContext GetFreshDbContext()
    {
        var scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    /// <summary>
    /// Saves entity to database and returns it with updated values
    /// </summary>
    protected async Task<T> SaveEntityAsync<T>(T entity) where T : class
    {
        // Use a fresh DbContext from the same factory that the web app uses
        using var scope = Factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        
        dbContext.Set<T>().Add(entity);
        await dbContext.SaveChangesAsync();
        
        // Detach to simulate fresh load
        dbContext.Entry(entity).State = EntityState.Detached;
        return entity;
    }

    /// <summary>
    /// Clears all data from the database
    /// </summary>
    protected async Task ClearDatabaseAsync()
    {
        using var scope = Factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        
        dbContext.Users.RemoveRange(dbContext.Users);
        dbContext.Posts.RemoveRange(dbContext.Posts);
        dbContext.Comments.RemoveRange(dbContext.Comments);
        await dbContext.SaveChangesAsync();
    }

    /// <summary>
    /// Waits for the application to be ready
    /// </summary>
    protected async Task WaitForApplicationReadyAsync(TimeSpan? timeout = null)
    {
        timeout ??= TimeSpan.FromSeconds(30);
        var cts = new CancellationTokenSource(timeout.Value);
        
        while (!cts.Token.IsCancellationRequested)
        {
            try
            {
                var response = await Client.GetAsync("/health");
                if (response.IsSuccessStatusCode)
                {
                    return;
                }
            }
            catch
            {
                // Continue waiting
            }
            
            await Task.Delay(100, cts.Token);
        }
        
        throw new TimeoutException($"Application was not ready within {timeout}");
    }
}