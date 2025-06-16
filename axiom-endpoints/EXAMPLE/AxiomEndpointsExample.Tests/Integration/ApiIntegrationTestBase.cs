using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using AxiomEndpointsExample.Api;
using AxiomEndpointsExample.Tests.Builders;
using AxiomEndpointsExample.Tests.Infrastructure;
using System.Text.Json;

namespace AxiomEndpointsExample.Tests.Integration;

/// <summary>
/// Base class for API integration tests using WebApplicationFactory
/// </summary>
[TestClass]
public abstract class ApiIntegrationTestBase : TestBase
{
    protected WebApplicationFactory<Program> Factory { get; private set; } = null!;
    protected HttpClient Client { get; private set; } = null!;
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

        Factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.UseEnvironment("Testing");
                builder.ConfigureServices(services =>
                {
                    // Remove the existing DbContext registration
                    var descriptor = services.SingleOrDefault(
                        d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
                    if (descriptor != null)
                    {
                        services.Remove(descriptor);
                    }

                    // Add in-memory database for testing
                    services.AddDbContext<AppDbContext>(options =>
                    {
                        options.UseInMemoryDatabase($"IntegrationTest_{Guid.NewGuid()}");
                        options.EnableSensitiveDataLogging();
                    });

                    // Add test data builder
                    services.AddSingleton<TestDataBuilder>();

                    // Configure logging for tests
                    services.AddLogging(builder => 
                        builder.AddConsole().SetMinimumLevel(LogLevel.Warning));
                });
            });

        Client = Factory.CreateClient();
        
        using var scope = Factory.Services.CreateScope();
        DbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        DataBuilder = scope.ServiceProvider.GetRequiredService<TestDataBuilder>();

        // Ensure database is created and seeded
        await DbContext.Database.EnsureCreatedAsync();
        await SeedTestDataAsync();
    }

    protected override async Task AdditionalCleanupAsync()
    {
        Client?.Dispose();
        
        if (DbContext != null)
        {
            await DbContext.Database.EnsureDeletedAsync();
            await DbContext.DisposeAsync();
        }
        
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
        using var scope = Factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    /// <summary>
    /// Saves entity to database and returns it with updated values
    /// </summary>
    protected async Task<T> SaveEntityAsync<T>(T entity) where T : class
    {
        using var dbContext = GetFreshDbContext();
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
        using var dbContext = GetFreshDbContext();
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