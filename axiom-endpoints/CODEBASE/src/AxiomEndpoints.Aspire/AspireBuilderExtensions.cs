using System.Reflection;
using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;
using AxiomEndpoints.Aspire.PackageGeneration;
using Microsoft.Extensions.DependencyInjection;

namespace AxiomEndpoints.Aspire;

/// <summary>
/// Aspire builder extensions for Axiom Endpoints
/// </summary>
public static class AspireBuilderExtensions
{
    /// <summary>
    /// Add Axiom package generation support to the application
    /// </summary>
    public static IDistributedApplicationBuilder AddAxiomPackageGeneration(this IDistributedApplicationBuilder builder)
    {
        builder.Services.AddSingleton<IPackageGenerationService, PackageGenerationService>();
        return builder;
    }

    /// <summary>
    /// Add enhanced Axiom package generation with validation, hooks, and code quality improvements
    /// </summary>
    public static IDistributedApplicationBuilder AddEnhancedAxiomPackageGeneration(
        this IDistributedApplicationBuilder builder,
        Action<EnhancedPackageGenerationOptions>? configure = null)
    {
        var options = new EnhancedPackageGenerationOptions();
        configure?.Invoke(options);

        // Register enhanced services
        builder.Services.AddEnhancedPackageGeneration();

        // Configure validation pipeline if enabled
        if (options.EnableValidation)
        {
            builder.Services.ConfigureValidationPipeline(pipeline =>
                pipeline.AddAllValidators());
        }

        // Configure hook pipeline if enabled
        if (options.EnableHooks)
        {
            builder.Services.ConfigureHookPipeline(hooks =>
            {
                if (options.EnableBuiltInHooks)
                    hooks.AddBuiltInHooks();
                else
                    hooks.AddAllHooks();
            });
        }

        return builder;
    }
    
    /// <summary>
    /// Add a project with Axiom package generation using simple API with smart conventions
    /// </summary>
    public static SimplePackageBuilder WithAxiomPackageGeneration<T>(
        this IResourceBuilder<T> builder,
        params PackageLanguage[] languages)
        where T : IResource
    {
        var projectName = builder.Resource.Name?.Replace("-", "").Replace("_", "") ?? "Package";
        return builder.WithPackageGeneration(projectName, languages);
    }
    
    /// <summary>
    /// Add a project with Axiom package generation using prefix and languages
    /// </summary>
    public static SimplePackageBuilder WithAxiomPackageGeneration<T>(
        this IResourceBuilder<T> builder,
        string prefix,
        params PackageLanguage[] languages)
        where T : IResource
    {
        return builder.WithPackageGeneration(prefix, languages);
    }
    
    /// <summary>
    /// Add a project with Axiom package generation using advanced fluent configuration
    /// </summary>
    public static IResourceBuilder<T> WithAxiomPackageGenerationAdvanced<T>(
        this IResourceBuilder<T> builder,
        Action<PackageGenerationOptionsBuilder> configure)
        where T : IResource
    {
        // Add package generation resource
        var packageGenName = $"{builder.Resource.Name}-packages";
        builder.ApplicationBuilder.AddPackageGeneration(packageGenName, builder, configure);
        
        return builder;
    }
    
    /// <summary>
    /// Add a project with Axiom package generation using simple configuration callback
    /// </summary>
    public static IResourceBuilder<T> WithAxiomPackageGenerationAdvanced<T>(
        this IResourceBuilder<T> builder,
        Action<PackageGenerationOptions> configure)
        where T : IResource
    {
        // Add package generation resource
        var packageGenName = $"{builder.Resource.Name}-packages";
        builder.ApplicationBuilder.AddPackageGeneration(packageGenName, builder, configure);
        
        return builder;
    }
}

/// <summary>
/// Axiom service annotation for Aspire
/// </summary>
public class AxiomServiceAnnotation : IResourceAnnotation
{
    public string Type => "axiom.service";
}

/// <summary>
/// Basic Axiom project resource implementation
/// </summary>
public class AxiomProjectResource : IAxiomResource
{
    private readonly List<EndpointMetadata> _endpoints = new();
    private readonly List<EventTopicMetadata> _eventTopics = new();

    public AxiomProjectResource(string name, string projectPath)
    {
        Name = name;
        ProjectPath = projectPath;
    }

    public string Name { get; }
    public string ProjectPath { get; }
    public IReadOnlyList<EndpointMetadata> Endpoints => _endpoints;
    public IReadOnlyList<EventTopicMetadata> EventTopics => _eventTopics;

    internal void AddEndpoints(IEnumerable<EndpointMetadata> endpoints)
    {
        _endpoints.AddRange(endpoints);
    }

    internal void AddEventTopics(IEnumerable<EventTopicMetadata> topics)
    {
        _eventTopics.AddRange(topics);
    }
}