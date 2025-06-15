using AxiomEndpoints.Aspire.PackageGeneration.Hooks;
using AxiomEndpoints.Aspire.PackageGeneration.Validation;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Extension methods for registering enhanced package generation services
/// </summary>
public static class ServiceRegistration
{
    /// <summary>
    /// Add enhanced package generation services to the service collection
    /// </summary>
    public static IServiceCollection AddEnhancedPackageGeneration(this IServiceCollection services)
    {
        // Register validation pipeline and validators
        services.AddScoped<IValidationPipeline, ValidationPipeline>();
        services.AddScoped<IConfigurationValidator, BasicConfigurationValidator>();
        services.AddScoped<IConfigurationValidator, LanguageSpecificValidator>();

        // Register hook pipeline and built-in hooks
        services.AddScoped<IHookPipeline, HookPipeline>();
        services.AddScoped<IGenerationHook, OutputDirectoryValidationHook>();
        services.AddScoped<IGenerationHook, CleanOutputHook>();
        services.AddScoped<IGenerationHook, PackageMetadataHook>();
        services.AddScoped<IGenerationHook, NotificationHook>();

        // Register enhanced package generation service
        services.AddScoped<IPackageGenerationService, EnhancedPackageGenerationService>();

        return services;
    }

    /// <summary>
    /// Configure the validation pipeline with validators
    /// </summary>
    public static IServiceCollection ConfigureValidationPipeline(
        this IServiceCollection services,
        Action<ValidationPipelineBuilder> configure)
    {
        services.AddScoped<IValidationPipeline>(provider =>
        {
            var logger = provider.GetRequiredService<ILogger<ValidationPipeline>>();
            var pipeline = new ValidationPipeline(logger);
            
            var builder = new ValidationPipelineBuilder(pipeline, provider);
            configure(builder);
            
            return pipeline;
        });

        return services;
    }

    /// <summary>
    /// Configure the hook pipeline with hooks
    /// </summary>
    public static IServiceCollection ConfigureHookPipeline(
        this IServiceCollection services,
        Action<HookPipelineBuilder> configure)
    {
        services.AddScoped<IHookPipeline>(provider =>
        {
            var logger = provider.GetRequiredService<ILogger<HookPipeline>>();
            var pipeline = new HookPipeline(logger);
            
            var builder = new HookPipelineBuilder(pipeline, provider);
            configure(builder);
            
            return pipeline;
        });

        return services;
    }
}

/// <summary>
/// Builder for configuring validation pipeline
/// </summary>
public class ValidationPipelineBuilder
{
    private readonly ValidationPipeline _pipeline;
    private readonly IServiceProvider _serviceProvider;

    internal ValidationPipelineBuilder(ValidationPipeline pipeline, IServiceProvider serviceProvider)
    {
        _pipeline = pipeline;
        _serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Add all registered validators
    /// </summary>
    public ValidationPipelineBuilder AddAllValidators()
    {
        var validators = _serviceProvider.GetServices<IConfigurationValidator>();
        foreach (var validator in validators)
        {
            _pipeline.AddValidator(validator);
        }
        return this;
    }

    /// <summary>
    /// Add a specific validator type
    /// </summary>
    public ValidationPipelineBuilder AddValidator<T>() where T : class, IConfigurationValidator
    {
        var validator = _serviceProvider.GetRequiredService<T>();
        _pipeline.AddValidator(validator);
        return this;
    }

    /// <summary>
    /// Add a validator instance
    /// </summary>
    public ValidationPipelineBuilder AddValidator(IConfigurationValidator validator)
    {
        _pipeline.AddValidator(validator);
        return this;
    }
}

/// <summary>
/// Builder for configuring hook pipeline
/// </summary>
public class HookPipelineBuilder
{
    private readonly HookPipeline _pipeline;
    private readonly IServiceProvider _serviceProvider;

    internal HookPipelineBuilder(HookPipeline pipeline, IServiceProvider serviceProvider)
    {
        _pipeline = pipeline;
        _serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Add all registered hooks
    /// </summary>
    public HookPipelineBuilder AddAllHooks()
    {
        var hooks = _serviceProvider.GetServices<IGenerationHook>();
        foreach (var hook in hooks)
        {
            _pipeline.RegisterHook(hook);
        }
        return this;
    }

    /// <summary>
    /// Add built-in hooks with default configuration
    /// </summary>
    public HookPipelineBuilder AddBuiltInHooks()
    {
        return AddHook<OutputDirectoryValidationHook>()
               .AddHook<CleanOutputHook>()
               .AddHook<PackageMetadataHook>()
               .AddHook<NotificationHook>();
    }

    /// <summary>
    /// Add a specific hook type
    /// </summary>
    public HookPipelineBuilder AddHook<T>() where T : class, IGenerationHook
    {
        var hook = _serviceProvider.GetRequiredService<T>();
        _pipeline.RegisterHook(hook);
        return this;
    }

    /// <summary>
    /// Add a hook instance
    /// </summary>
    public HookPipelineBuilder AddHook(IGenerationHook hook)
    {
        _pipeline.RegisterHook(hook);
        return this;
    }

    /// <summary>
    /// Add pre-generation hooks only
    /// </summary>
    public HookPipelineBuilder AddPreGenerationHooks()
    {
        return AddHook<OutputDirectoryValidationHook>();
    }

    /// <summary>
    /// Add post-generation hooks only
    /// </summary>
    public HookPipelineBuilder AddPostGenerationHooks()
    {
        return AddHook<PackageMetadataHook>()
               .AddHook<NotificationHook>();
    }
}

/// <summary>
/// Configuration options for enhanced package generation
/// </summary>
public class EnhancedPackageGenerationOptions
{
    /// <summary>
    /// Enable validation pipeline
    /// </summary>
    public bool EnableValidation { get; set; } = true;

    /// <summary>
    /// Enable hook pipeline
    /// </summary>
    public bool EnableHooks { get; set; } = true;

    /// <summary>
    /// Enable built-in hooks
    /// </summary>
    public bool EnableBuiltInHooks { get; set; } = true;

    /// <summary>
    /// Default code quality level
    /// </summary>
    public CodeQualityLevel DefaultQuality { get; set; } = CodeQualityLevel.Standard;

    /// <summary>
    /// Enable parallel validation
    /// </summary>
    public bool ParallelValidation { get; set; } = false;

    /// <summary>
    /// Validation timeout in milliseconds
    /// </summary>
    public int ValidationTimeoutMs { get; set; } = 30000;
}

/// <summary>
/// Code quality levels
/// </summary>
public enum CodeQualityLevel
{
    Minimal,
    Standard,
    High,
    Maximum
}