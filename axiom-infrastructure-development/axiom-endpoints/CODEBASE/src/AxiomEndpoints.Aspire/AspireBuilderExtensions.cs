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
    /// Add Axiom service with fluent configuration
    /// </summary>
    public static AxiomServiceBuilder AddAxiomService(
        this IDistributedApplicationBuilder builder,
        string name)
    {
        return new AxiomServiceBuilder(builder, name);
    }

    /// <summary>
    /// Add Axiom API service with enhanced configuration
    /// </summary>
    public static AxiomApiBuilder AddAxiomApi(
        this IDistributedApplicationBuilder builder,
        string name,
        string projectPath)
    {
        return new AxiomApiBuilder(builder, name, projectPath);
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
public class AxiomProjectResource : IAxiomResource, IResource
{
    private readonly List<EndpointMetadata> _endpoints = new();
    private readonly List<EventTopicMetadata> _eventTopics = new();
    private readonly ResourceAnnotationCollection _annotations = new();

    public AxiomProjectResource(string name, string projectPath)
    {
        Name = name;
        ProjectPath = projectPath;
    }

    public string Name { get; }
    public string ProjectPath { get; }
    public IReadOnlyList<EndpointMetadata> Endpoints => _endpoints;
    public IReadOnlyList<EventTopicMetadata> EventTopics => _eventTopics;
    public ResourceAnnotationCollection Annotations => _annotations;

    internal void AddEndpoints(IEnumerable<EndpointMetadata> endpoints)
    {
        _endpoints.AddRange(endpoints);
    }

    internal void AddEventTopics(IEnumerable<EventTopicMetadata> topics)
    {
        _eventTopics.AddRange(topics);
    }
}

/// <summary>
/// Fluent builder for Axiom services
/// </summary>
public class AxiomServiceBuilder
{
    private readonly IDistributedApplicationBuilder _builder;
    private readonly string _name;
    private readonly List<EndpointMetadata> _endpoints = new();
    private readonly List<EventTopicMetadata> _eventTopics = new();
    private bool _enableHealthChecks = true;
    private bool _enableServiceDiscovery = true;
    private bool _enableTelemetry = true;

    internal AxiomServiceBuilder(IDistributedApplicationBuilder builder, string name)
    {
        _builder = builder;
        _name = name;
    }

    /// <summary>
    /// Add an endpoint to this service
    /// </summary>
    public AxiomServiceBuilder WithEndpoint<TEndpoint>(string route, HttpMethod method, string? description = null)
        where TEndpoint : class
    {
        _endpoints.Add(new EndpointMetadata
        {
            EndpointType = typeof(TEndpoint),
            Route = route,
            Method = method,
            SupportsGrpc = false,
            Description = description
        });
        return this;
    }

    /// <summary>
    /// Add event topic to this service
    /// </summary>
    public AxiomServiceBuilder WithEventTopic(string topicName, Type eventType, EventRole role)
    {
        _eventTopics.Add(new EventTopicMetadata
        {
            TopicName = topicName,
            EventType = eventType,
            Role = role
        });
        return this;
    }

    /// <summary>
    /// Configure health checks
    /// </summary>
    public AxiomServiceBuilder WithHealthChecks(bool enabled = true)
    {
        _enableHealthChecks = enabled;
        return this;
    }

    /// <summary>
    /// Configure service discovery
    /// </summary>
    public AxiomServiceBuilder WithServiceDiscovery(bool enabled = true)
    {
        _enableServiceDiscovery = enabled;
        return this;
    }

    /// <summary>
    /// Configure telemetry
    /// </summary>
    public AxiomServiceBuilder WithTelemetry(bool enabled = true)
    {
        _enableTelemetry = enabled;
        return this;
    }

    /// <summary>
    /// Build the Axiom service resource
    /// </summary>
    public IResourceBuilder<AxiomProjectResource> Build()
    {
        var resource = new AxiomProjectResource(_name, "");
        resource.AddEndpoints(_endpoints);
        resource.AddEventTopics(_eventTopics);

        var resourceBuilder = _builder.AddResource(resource);

        if (_enableHealthChecks)
        {
            resourceBuilder.WithAnnotation(new HealthCheckAnnotation());
        }

        if (_enableServiceDiscovery)
        {
            resourceBuilder.WithAnnotation(new ServiceDiscoveryAnnotation());
        }

        if (_enableTelemetry)
        {
            resourceBuilder.WithAnnotation(new TelemetryAnnotation());
        }

        return resourceBuilder;
    }
}

/// <summary>
/// Fluent builder for Axiom API services
/// </summary>
public class AxiomApiBuilder : AxiomServiceBuilder
{
    private readonly string _projectPath;
    private bool _enableSwagger = false;
    private bool _enableCors = false;
    private bool _enableRateLimiting = false;

    internal AxiomApiBuilder(IDistributedApplicationBuilder builder, string name, string projectPath)
        : base(builder, name)
    {
        _projectPath = projectPath;
    }

    /// <summary>
    /// Enable Swagger/OpenAPI documentation
    /// </summary>
    public AxiomApiBuilder WithSwagger(bool enabled = true)
    {
        _enableSwagger = enabled;
        return this;
    }

    /// <summary>
    /// Enable CORS
    /// </summary>
    public AxiomApiBuilder WithCors(bool enabled = true)
    {
        _enableCors = enabled;
        return this;
    }

    /// <summary>
    /// Enable rate limiting
    /// </summary>
    public AxiomApiBuilder WithRateLimiting(bool enabled = true)
    {
        _enableRateLimiting = enabled;
        return this;
    }

    /// <summary>
    /// Build the Axiom API service
    /// </summary>
    public new IResourceBuilder<AxiomProjectResource> Build()
    {
        var resourceBuilder = base.Build();

        if (_enableSwagger)
        {
            resourceBuilder.WithAnnotation(new SwaggerAnnotation());
        }

        if (_enableCors)
        {
            resourceBuilder.WithAnnotation(new CorsAnnotation());
        }

        if (_enableRateLimiting)
        {
            resourceBuilder.WithAnnotation(new RateLimitingAnnotation());
        }

        return resourceBuilder;
    }
}

/// <summary>
/// Health check annotation
/// </summary>
public class HealthCheckAnnotation : IResourceAnnotation
{
    public string Type => "axiom.healthcheck";
}

/// <summary>
/// Service discovery annotation
/// </summary>
public class ServiceDiscoveryAnnotation : IResourceAnnotation
{
    public string Type => "axiom.servicediscovery";
}

/// <summary>
/// Telemetry annotation
/// </summary>
public class TelemetryAnnotation : IResourceAnnotation
{
    public string Type => "axiom.telemetry";
}

/// <summary>
/// Swagger annotation
/// </summary>
public class SwaggerAnnotation : IResourceAnnotation
{
    public string Type => "axiom.swagger";
}

/// <summary>
/// CORS annotation
/// </summary>
public class CorsAnnotation : IResourceAnnotation
{
    public string Type => "axiom.cors";
}

/// <summary>
/// Rate limiting annotation
/// </summary>
public class RateLimitingAnnotation : IResourceAnnotation
{
    public string Type => "axiom.ratelimiting";
}