using Aspire.Hosting;
using Aspire.Hosting.ApplicationModel;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Aspire builder extensions for package generation
/// </summary>
public static class PackageGenerationBuilderExtensions
{
    #region Ultra-Simple API (Level 1)
    
    /// <summary>
    /// Add package generation with just languages - uses smart conventions
    /// </summary>
    public static SimplePackageBuilder WithPackageGeneration<T>(
        this IResourceBuilder<T> builder,
        params PackageLanguage[] languages)
        where T : IResource
    {
        return builder.WithPackageGeneration("Package", languages);
    }
    
    /// <summary>
    /// Add package generation with prefix and languages - uses smart conventions
    /// </summary>
    public static SimplePackageBuilder WithPackageGeneration<T>(
        this IResourceBuilder<T> builder,
        string prefix,
        params PackageLanguage[] languages)
        where T : IResource
    {
        return builder.WithPackageGeneration(prefix, "generated-packages", languages);
    }
    
    /// <summary>
    /// Add package generation with prefix, output path, and languages
    /// </summary>
    public static SimplePackageBuilder WithPackageGeneration<T>(
        this IResourceBuilder<T> builder,
        string prefix,
        string outputPath,
        params PackageLanguage[] languages)
        where T : IResource
    {
        var packageGenName = $"{builder.Resource.Name}-packages";
        var packageBuilder = builder.ApplicationBuilder.AddPackageGeneration(packageGenName, builder, options =>
        {
            options.DefaultPackagePrefix = prefix;
            options.BaseOutputPath = outputPath;
            options.DefaultVersion = "1.0.0";
            
            // Add languages with smart conventions
            foreach (var language in languages)
            {
                var config = new LanguagePackageConfig
                {
                    OutputPath = Path.Combine(outputPath, language.GetDefaultDirectoryName()),
                    PackageName = GetConventionalPackageName(prefix, language),
                    Version = "1.0.0",
                    IncludeDocumentation = true,
                    IncludeSamples = false
                };
                options.Languages[language] = config;
            }
        });
        
        return new SimplePackageBuilder(packageBuilder);
    }
    
    private static string GetConventionalPackageName(string prefix, PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => $"{prefix}SDK",
            PackageLanguage.Kotlin => $"com.{prefix.ToLowerInvariant()}.sdk",
            PackageLanguage.CSharp => $"{prefix}.Client",
            PackageLanguage.TypeScript => $"@{prefix.ToLowerInvariant()}/grpc-client",
            _ => throw new ArgumentOutOfRangeException(nameof(language))
        };
    }
    
    #endregion
    
    #region Advanced API (Level 3)

    /// <summary>
    /// Add package generation for a project
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> AddPackageGeneration<T>(
        this IDistributedApplicationBuilder builder,
        string name,
        IResourceBuilder<T> sourceProject)
        where T : IResource
    {
        var options = new PackageGenerationOptions();
        var resource = new PackageGenerationResource(name, sourceProject.Resource, options);
        return builder.AddResource(resource);
    }

    /// <summary>
    /// Add package generation with fluent configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> AddPackageGeneration<T>(
        this IDistributedApplicationBuilder builder,
        string name,
        IResourceBuilder<T> sourceProject,
        Action<PackageGenerationOptionsBuilder> configure)
        where T : IResource
    {
        var optionsBuilder = new PackageGenerationOptionsBuilder();
        configure(optionsBuilder);
        var options = optionsBuilder.Build();
        var resource = new PackageGenerationResource(name, sourceProject.Resource, options);
        return builder.AddResource(resource);
    }

    /// <summary>
    /// Add package generation with simple configuration callback
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> AddPackageGeneration<T>(
        this IDistributedApplicationBuilder builder,
        string name,
        IResourceBuilder<T> sourceProject,
        Action<PackageGenerationOptions> configure)
        where T : IResource
    {
        var options = new PackageGenerationOptions();
        configure(options);
        var resource = new PackageGenerationResource(name, sourceProject.Resource, options);
        return builder.AddResource(resource);
    }

    /// <summary>
    /// Configure languages for package generation using type-safe enums
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithLanguages(
        this IResourceBuilder<PackageGenerationResource> builder,
        params PackageLanguage[] languages)
    {
        foreach (var language in languages)
        {
            var config = new LanguagePackageConfig
            {
                OutputPath = Path.Combine(builder.Resource.Options.BaseOutputPath, language.GetDefaultDirectoryName()),
                PackageName = $"{builder.Resource.Options.DefaultPackagePrefix ?? "Package"}{(language == PackageLanguage.Swift ? "SDK" : language == PackageLanguage.CSharp ? ".Client" : ".SDK")}",
                Version = builder.Resource.Options.DefaultVersion
            };
            builder.Resource.Options.Languages[language] = config;
        }
        return builder;
    }

    /// <summary>
    /// Configure base output path for all packages
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithBaseOutputPath(
        this IResourceBuilder<PackageGenerationResource> builder,
        string outputPath)
    {
        builder.Resource.Options.BaseOutputPath = outputPath;
        return builder;
    }

    /// <summary>
    /// Configure default package name prefix
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithDefaultPackagePrefix(
        this IResourceBuilder<PackageGenerationResource> builder,
        string prefix)
    {
        builder.Resource.Options.DefaultPackagePrefix = prefix;
        return builder;
    }

    /// <summary>
    /// Configure default package version
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithDefaultVersion(
        this IResourceBuilder<PackageGenerationResource> builder,
        string version)
    {
        builder.Resource.Options.DefaultVersion = version;
        return builder;
    }

    /// <summary>
    /// Add Swift package configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithSwiftPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        string outputPath,
        string packageName,
        string? version = null)
    {
        builder.Resource.Options.Languages[PackageLanguage.Swift] = new LanguagePackageConfig
        {
            OutputPath = outputPath,
            PackageName = packageName,
            Version = version ?? builder.Resource.Options.DefaultVersion,
            IncludeDocumentation = true
        };
        return builder;
    }

    /// <summary>
    /// Add Swift package with detailed configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithSwiftPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        Action<LanguagePackageConfigBuilder> configure)
    {
        var configBuilder = new LanguagePackageConfigBuilder();
        configure(configBuilder);
        builder.Resource.Options.Languages[PackageLanguage.Swift] = configBuilder.Build();
        return builder;
    }

    /// <summary>
    /// Add Kotlin package configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithKotlinPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        string outputPath,
        string packageName,
        string? version = null)
    {
        builder.Resource.Options.Languages[PackageLanguage.Kotlin] = new LanguagePackageConfig
        {
            OutputPath = outputPath,
            PackageName = packageName,
            Version = version ?? builder.Resource.Options.DefaultVersion,
            IncludeDocumentation = true
        };
        return builder;
    }

    /// <summary>
    /// Add Kotlin package with detailed configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithKotlinPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        Action<LanguagePackageConfigBuilder> configure)
    {
        var configBuilder = new LanguagePackageConfigBuilder();
        configure(configBuilder);
        builder.Resource.Options.Languages[PackageLanguage.Kotlin] = configBuilder.Build();
        return builder;
    }

    /// <summary>
    /// Add C# package configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithCSharpPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        string outputPath,
        string packageName,
        string? version = null)
    {
        builder.Resource.Options.Languages[PackageLanguage.CSharp] = new LanguagePackageConfig
        {
            OutputPath = outputPath,
            PackageName = packageName,
            Version = version ?? builder.Resource.Options.DefaultVersion,
            IncludeDocumentation = true
        };
        return builder;
    }

    /// <summary>
    /// Add C# package with detailed configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithCSharpPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        Action<LanguagePackageConfigBuilder> configure)
    {
        var configBuilder = new LanguagePackageConfigBuilder();
        configure(configBuilder);
        builder.Resource.Options.Languages[PackageLanguage.CSharp] = configBuilder.Build();
        return builder;
    }

    /// <summary>
    /// Add TypeScript package configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithTypeScriptPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        string outputPath,
        string packageName,
        string? version = null)
    {
        builder.Resource.Options.Languages[PackageLanguage.TypeScript] = new LanguagePackageConfig
        {
            OutputPath = outputPath,
            PackageName = packageName,
            Version = version ?? builder.Resource.Options.DefaultVersion,
            IncludeDocumentation = true
        };
        return builder;
    }

    /// <summary>
    /// Add TypeScript package with detailed configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithTypeScriptPackage(
        this IResourceBuilder<PackageGenerationResource> builder,
        Action<LanguagePackageConfigBuilder> configure)
    {
        var configBuilder = new LanguagePackageConfigBuilder();
        configure(configBuilder);
        builder.Resource.Options.Languages[PackageLanguage.TypeScript] = configBuilder.Build();
        return builder;
    }

    /// <summary>
    /// Add all common languages with default configuration
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithAllLanguages(
        this IResourceBuilder<PackageGenerationResource> builder,
        string? swiftPackageName = null,
        string? kotlinPackageName = null,
        string? csharpPackageName = null,
        string? typescriptPackageName = null)
    {
        var prefix = builder.Resource.Options.DefaultPackagePrefix ?? "Package";
        
        return builder
            .WithSwiftPackage(
                Path.Combine(builder.Resource.Options.BaseOutputPath, "swift"),
                swiftPackageName ?? $"{prefix}SDK")
            .WithKotlinPackage(
                Path.Combine(builder.Resource.Options.BaseOutputPath, "kotlin"),
                kotlinPackageName ?? $"com.{prefix.ToLowerInvariant()}.sdk")
            .WithCSharpPackage(
                Path.Combine(builder.Resource.Options.BaseOutputPath, "csharp"),
                csharpPackageName ?? $"{prefix}.Client")
            .WithTypeScriptPackage(
                Path.Combine(builder.Resource.Options.BaseOutputPath, "typescript"),
                typescriptPackageName ?? $"@{prefix.ToLowerInvariant()}/grpc-client");
    }

    /// <summary>
    /// Disable generation on build
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithManualGeneration(
        this IResourceBuilder<PackageGenerationResource> builder)
    {
        builder.Resource.Options.GenerateOnBuild = false;
        return builder;
    }

    /// <summary>
    /// Add global generation option
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithGlobalOption(
        this IResourceBuilder<PackageGenerationResource> builder,
        string key,
        string value)
    {
        builder.Resource.Options.GlobalOptions[key] = value;
        return builder;
    }

    /// <summary>
    /// Configure parallel generation settings
    /// </summary>
    public static IResourceBuilder<PackageGenerationResource> WithParallelGeneration(
        this IResourceBuilder<PackageGenerationResource> builder,
        bool enabled = true,
        int? maxConcurrency = null)
    {
        builder.Resource.Options.ParallelGeneration = enabled;
        if (maxConcurrency.HasValue)
        {
            builder.Resource.Options.MaxConcurrency = maxConcurrency.Value;
        }
        return builder;
    }
    
    #endregion
}