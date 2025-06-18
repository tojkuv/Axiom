using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using AxiomEndpointsExample.Api;

namespace AxiomEndpointsExample.Tests.Infrastructure;

/// <summary>
/// Provides a shared database instance for both tests and web application
/// </summary>
public static class SharedDatabaseProvider
{
    private static IServiceProvider? _sharedServiceProvider;
    private static readonly object _lock = new object();
    private static string? _databaseName;

    public static IServiceProvider GetSharedServiceProvider()
    {
        if (_sharedServiceProvider == null)
        {
            lock (_lock)
            {
                if (_sharedServiceProvider == null)
                {
                    _databaseName = $"SharedTestDb_{Guid.NewGuid()}";
                    
                    var services = new ServiceCollection();
                    services.AddDbContext<AppDbContext>(options =>
                    {
                        options.UseInMemoryDatabase(_databaseName);
                        options.EnableSensitiveDataLogging();
                        options.EnableDetailedErrors();
                    });
                    
                    _sharedServiceProvider = services.BuildServiceProvider();
                }
            }
        }
        return _sharedServiceProvider;
    }

    public static DbContextOptions<AppDbContext> GetSharedDbContextOptions()
    {
        if (_databaseName == null)
        {
            GetSharedServiceProvider(); // Initialize if not already done
        }

        return new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(_databaseName!)
            .EnableSensitiveDataLogging()
            .EnableDetailedErrors()
            .Options;
    }

    public static void Reset()
    {
        lock (_lock)
        {
            (_sharedServiceProvider as IDisposable)?.Dispose();
            _sharedServiceProvider = null;
            _databaseName = null;
        }
    }
}