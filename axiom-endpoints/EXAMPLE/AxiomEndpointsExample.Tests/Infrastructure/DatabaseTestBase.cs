using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpointsExample.Api;
using AxiomEndpointsExample.Tests.Builders;

namespace AxiomEndpointsExample.Tests.Infrastructure;

/// <summary>
/// Base class for tests that require database access
/// </summary>
[TestClass]
public abstract class DatabaseTestBase : TestBase
{
    protected AppDbContext DbContext { get; private set; } = null!;
    protected TestDataBuilder DataBuilder { get; private set; } = null!;

    protected override void ConfigureServices(IServiceCollection services)
    {
        base.ConfigureServices(services);

        // Configure in-memory database for testing
        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}");
            options.EnableSensitiveDataLogging();
            options.EnableDetailedErrors();
        });

        // Add test data builder
        services.AddSingleton<TestDataBuilder>();
    }

    protected override async Task AdditionalSetupAsync()
    {
        await base.AdditionalSetupAsync();
        
        DbContext = ServiceProvider.GetRequiredService<AppDbContext>();
        DataBuilder = ServiceProvider.GetRequiredService<TestDataBuilder>();
        
        // Ensure database is created and seeded
        await DbContext.Database.EnsureCreatedAsync();
        await SeedTestDataAsync();
    }

    protected override async Task AdditionalCleanupAsync()
    {
        await DbContext.Database.EnsureDeletedAsync();
        await DbContext.DisposeAsync();
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
    /// Clears all data from the database
    /// </summary>
    protected async Task ClearDatabaseAsync()
    {
        DbContext.Users.RemoveRange(DbContext.Users);
        DbContext.Posts.RemoveRange(DbContext.Posts);
        DbContext.Comments.RemoveRange(DbContext.Comments);
        await DbContext.SaveChangesAsync();
    }

    /// <summary>
    /// Saves entity to database and returns it with updated values
    /// </summary>
    protected async Task<T> SaveEntityAsync<T>(T entity) where T : class
    {
        DbContext.Set<T>().Add(entity);
        await DbContext.SaveChangesAsync();
        
        // Detach to simulate fresh load
        DbContext.Entry(entity).State = EntityState.Detached;
        return entity;
    }

    /// <summary>
    /// Counts entities in database
    /// </summary>
    protected async Task<int> CountEntitiesAsync<T>() where T : class
    {
        return await DbContext.Set<T>().CountAsync();
    }

    /// <summary>
    /// Finds entity by predicate
    /// </summary>
    protected async Task<T?> FindEntityAsync<T>(Func<T, bool> predicate) where T : class
    {
        return DbContext.Set<T>().FirstOrDefault(predicate);
    }

    /// <summary>
    /// Asserts that entity exists in database
    /// </summary>
    protected async Task AssertEntityExistsAsync<T>(Func<T, bool> predicate) where T : class
    {
        var entity = await FindEntityAsync(predicate);
        Assert.IsNotNull(entity, $"Expected entity of type {typeof(T).Name} was not found in database");
    }

    /// <summary>
    /// Asserts that entity does not exist in database
    /// </summary>
    protected async Task AssertEntityDoesNotExistAsync<T>(Func<T, bool> predicate) where T : class
    {
        var entity = await FindEntityAsync(predicate);
        Assert.IsNull(entity, $"Unexpected entity of type {typeof(T).Name} was found in database");
    }
}