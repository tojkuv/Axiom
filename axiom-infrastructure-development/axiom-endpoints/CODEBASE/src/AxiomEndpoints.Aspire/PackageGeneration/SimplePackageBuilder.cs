using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Simplified package generation builder with smart conventions
/// </summary>
public class SimplePackageBuilder
{
    private readonly IResourceBuilder<PackageGenerationResource> _builder;
    private readonly PackageGenerationOptions _options;

    internal SimplePackageBuilder(IResourceBuilder<PackageGenerationResource> builder)
    {
        _builder = builder;
        _options = builder.Resource.Options;
    }

    /// <summary>
    /// Set the base output directory for all packages
    /// </summary>
    public SimplePackageBuilder To(string outputPath)
    {
        _options.BaseOutputPath = outputPath;
        UpdateLanguagePaths();
        return this;
    }

    /// <summary>
    /// Set the version for all packages
    /// </summary>
    public SimplePackageBuilder Version(string version)
    {
        _options.DefaultVersion = version;
        foreach (var config in _options.Languages.Values)
        {
            config.Version = version;
        }
        return this;
    }

    /// <summary>
    /// Override Swift package name (defaults to {Prefix}SDK)
    /// </summary>
    public SimplePackageBuilder SwiftName(string name)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.Swift, out var config))
        {
            config.PackageName = name;
        }
        return this;
    }

    /// <summary>
    /// Override Kotlin package name (defaults to com.{prefix}.sdk)
    /// </summary>
    public SimplePackageBuilder KotlinName(string name)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.Kotlin, out var config))
        {
            config.PackageName = name;
        }
        return this;
    }

    /// <summary>
    /// Override C# package name (defaults to {Prefix}.Client)
    /// </summary>
    public SimplePackageBuilder CSharpName(string name)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.CSharp, out var config))
        {
            config.PackageName = name;
        }
        return this;
    }

    /// <summary>
    /// Set Swift output path (overrides convention)
    /// </summary>
    public SimplePackageBuilder SwiftTo(string path)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.Swift, out var config))
        {
            config.OutputPath = path;
        }
        return this;
    }

    /// <summary>
    /// Set Kotlin output path (overrides convention)
    /// </summary>
    public SimplePackageBuilder KotlinTo(string path)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.Kotlin, out var config))
        {
            config.OutputPath = path;
        }
        return this;
    }

    /// <summary>
    /// Set C# output path (overrides convention)
    /// </summary>
    public SimplePackageBuilder CSharpTo(string path)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.CSharp, out var config))
        {
            config.OutputPath = path;
        }
        return this;
    }

    /// <summary>
    /// Override TypeScript package name (defaults to @{prefix}/grpc-client)
    /// </summary>
    public SimplePackageBuilder TypeScriptName(string name)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.TypeScript, out var config))
        {
            config.PackageName = name;
        }
        return this;
    }

    /// <summary>
    /// Set TypeScript output path (overrides convention)
    /// </summary>
    public SimplePackageBuilder TypeScriptTo(string path)
    {
        if (_options.Languages.TryGetValue(PackageLanguage.TypeScript, out var config))
        {
            config.OutputPath = path;
        }
        return this;
    }

    /// <summary>
    /// Include documentation in all packages
    /// </summary>
    public SimplePackageBuilder WithDocs(bool include = true)
    {
        foreach (var config in _options.Languages.Values)
        {
            config.IncludeDocumentation = include;
        }
        return this;
    }

    /// <summary>
    /// Include samples in all packages
    /// </summary>
    public SimplePackageBuilder WithSamples(bool include = true)
    {
        foreach (var config in _options.Languages.Values)
        {
            config.IncludeSamples = include;
        }
        return this;
    }

    /// <summary>
    /// Enable parallel generation with optional concurrency limit
    /// </summary>
    public SimplePackageBuilder Parallel(int? maxConcurrency = null)
    {
        _options.ParallelGeneration = true;
        if (maxConcurrency.HasValue)
        {
            _options.MaxConcurrency = maxConcurrency.Value;
        }
        return this;
    }

    /// <summary>
    /// Add a global option for all languages
    /// </summary>
    public SimplePackageBuilder WithOption(string key, string value)
    {
        _options.GlobalOptions[key] = value;
        return this;
    }

    /// <summary>
    /// Access the underlying resource builder for advanced configuration
    /// </summary>
    public IResourceBuilder<PackageGenerationResource> Advanced() => _builder;

    /// <summary>
    /// Get the underlying resource builder
    /// </summary>
    public IResourceBuilder<PackageGenerationResource> Build() => _builder;

    private void UpdateLanguagePaths()
    {
        foreach (var (language, config) in _options.Languages)
        {
            // Only update if using the default convention path
            var conventionPath = Path.Combine("generated-packages", language.GetDefaultDirectoryName());
            if (config.OutputPath.EndsWith(conventionPath) || config.OutputPath == conventionPath)
            {
                config.OutputPath = Path.Combine(_options.BaseOutputPath, language.GetDefaultDirectoryName());
            }
        }
    }
}

/// <summary>
/// Extension methods for creating simplified package builders
/// </summary>
public static class SimplePackageBuilderExtensions
{
    /// <summary>
    /// Create a simple package builder from a resource builder
    /// </summary>
    public static SimplePackageBuilder Simple(this IResourceBuilder<PackageGenerationResource> builder)
    {
        return new SimplePackageBuilder(builder);
    }
}