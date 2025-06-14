using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace AxiomEndpoints.Aspire.Configuration;

public static class AspireConfigurationExtensions
{
    /// <summary>
    /// Add Aspire configuration with hot reload
    /// </summary>
    public static IHostApplicationBuilder AddAxiomAspireConfiguration(
        this IHostApplicationBuilder builder)
    {
        // Add Aspire configuration sources - would be enhanced when full Aspire is available
        // builder.Configuration.AddAspireConfiguration();

        // Add configuration reloading
        builder.Services.AddSingleton<IConfigurationRefresher>(sp =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            return new AspireConfigurationRefresher(config);
        });

        // Add typed configuration
        builder.Services.AddOptions<AxiomOptions>()
            .Configure<IConfiguration>((options, config) =>
            {
                config.GetSection("Axiom").Bind(options);

                // Auto-configure from Aspire environment
                if (config["ASPIRE_ENVIRONMENT"] == "Development")
                {
                    options.EnableDetailedErrors = true;
                    options.EnableSwagger = true;
                    options.EnableDeveloperExceptionPage = true;
                }
            });

        // Add feature flags integration - would be enhanced when full Aspire is available
        // builder.Services.AddAspireFeatureManagement();

        return builder;
    }

    /// <summary>
    /// Configuration for endpoint behavior
    /// </summary>
    public static IServiceCollection ConfigureAxiomEndpoint<TEndpoint>(
        this IServiceCollection services,
        Action<EndpointConfiguration> configure)
        where TEndpoint : class
    {
        services.Configure<EndpointConfiguration>(
            typeof(TEndpoint).Name,
            configure);

        return services;
    }
}

/// <summary>
/// Per-endpoint configuration
/// </summary>
public class EndpointConfiguration
{
    public TimeSpan? Timeout { get; set; }
    public int? MaxConcurrency { get; set; }
    public bool? EnableCaching { get; set; }
    public bool? EnableCompression { get; set; }
    public Dictionary<string, object> Metadata { get; set; } = new();
}

/// <summary>
/// Dynamic configuration with Aspire
/// </summary>
public interface IConfigurationRefresher
{
    event EventHandler<ConfigurationChangedEventArgs>? ConfigurationChanged;
    ValueTask RefreshAsync(CancellationToken ct = default);
}

public class ConfigurationChangedEventArgs : EventArgs
{
    public required IConfigurationSection Section { get; init; }
    public required string Key { get; init; }
    public string? OldValue { get; init; }
    public string? NewValue { get; init; }
}

/// <summary>
/// Simple implementation of configuration refresher
/// </summary>
public class AspireConfigurationRefresher : IConfigurationRefresher
{
    private readonly IConfiguration _configuration;

    public AspireConfigurationRefresher(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public event EventHandler<ConfigurationChangedEventArgs>? ConfigurationChanged;

    public ValueTask RefreshAsync(CancellationToken ct = default)
    {
        // TODO: Implement actual configuration refresh logic when Aspire integration is complete
        return ValueTask.CompletedTask;
    }

    protected virtual void OnConfigurationChanged(ConfigurationChangedEventArgs e)
    {
        ConfigurationChanged?.Invoke(this, e);
    }
}