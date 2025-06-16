using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using AxiomEndpointsExample.Api;
using AutoFixture;
using FluentAssertions;
using FluentAssertions.Extensions;

namespace AxiomEndpointsExample.Tests.Infrastructure;

/// <summary>
/// Base class for all test classes providing common setup and utilities
/// </summary>
[TestClass]
public abstract class TestBase
{
    protected IFixture Fixture { get; private set; } = null!;
    protected IServiceProvider ServiceProvider { get; private set; } = null!;
    protected ILogger Logger { get; private set; } = null!;

    [TestInitialize]
    public virtual async Task TestInitializeAsync()
    {
        // Configure AutoFixture
        Fixture = new Fixture();
        ConfigureFixture(Fixture);

        // Setup service provider
        var services = new ServiceCollection();
        ConfigureServices(services);
        ServiceProvider = services.BuildServiceProvider();

        // Setup logger
        Logger = ServiceProvider.GetRequiredService<ILogger<TestBase>>();

        // Additional setup
        await AdditionalSetupAsync();
    }

    [TestCleanup]
    public virtual async Task TestCleanupAsync()
    {
        await AdditionalCleanupAsync();
        
        if (ServiceProvider is IDisposable disposable)
        {
            disposable.Dispose();
        }
    }

    protected virtual void ConfigureFixture(IFixture fixture)
    {
        // Configure AutoFixture behaviors
        fixture.Behaviors.OfType<ThrowingRecursionBehavior>().ToList()
            .ForEach(b => fixture.Behaviors.Remove(b));
        fixture.Behaviors.Add(new OmitOnRecursionBehavior());

        // Configure specific customizations
        fixture.Customize<DateTime>(composer => composer.FromFactory(() => DateTime.UtcNow));
        fixture.Customize<Guid>(composer => composer.FromFactory(() => Guid.NewGuid()));
    }

    protected virtual void ConfigureServices(IServiceCollection services)
    {
        // Add logging
        services.AddLogging(builder => builder.AddConsole().SetMinimumLevel(LogLevel.Debug));
        
        // Add common test services
        services.AddSingleton<IFixture>(Fixture);
    }

    protected virtual Task AdditionalSetupAsync() => Task.CompletedTask;
    protected virtual Task AdditionalCleanupAsync() => Task.CompletedTask;

    /// <summary>
    /// Asserts that an action completes within the specified timeout
    /// </summary>
    protected static async Task AssertCompletesWithinAsync(TimeSpan timeout, Func<Task> action)
    {
        using var cts = new CancellationTokenSource(timeout);
        try
        {
            await action();
        }
        catch (OperationCanceledException) when (cts.Token.IsCancellationRequested)
        {
            throw new AssertFailedException($"Operation did not complete within {timeout}");
        }
    }

    /// <summary>
    /// Asserts that an action throws the expected exception
    /// </summary>
    protected static async Task<T> AssertThrowsAsync<T>(Func<Task> action) where T : Exception
    {
        try
        {
            await action();
            throw new AssertFailedException($"Expected {typeof(T).Name} to be thrown, but no exception was thrown.");
        }
        catch (T ex)
        {
            return ex;
        }
        catch (Exception ex)
        {
            throw new AssertFailedException($"Expected {typeof(T).Name} to be thrown, but {ex.GetType().Name} was thrown instead.");
        }
    }
}