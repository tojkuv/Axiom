namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Builder for fluent configuration of package generation options
/// </summary>
public class PackageGenerationOptionsBuilder
{
    private readonly PackageGenerationOptions _options = new();

    /// <summary>
    /// Set the base output path for all packages
    /// </summary>
    public PackageGenerationOptionsBuilder BaseOutputPath(string path)
    {
        _options.BaseOutputPath = path;
        return this;
    }

    /// <summary>
    /// Set whether to generate packages on build
    /// </summary>
    public PackageGenerationOptionsBuilder GenerateOnBuild(bool generate = true)
    {
        _options.GenerateOnBuild = generate;
        return this;
    }

    /// <summary>
    /// Set default package prefix for all languages
    /// </summary>
    public PackageGenerationOptionsBuilder DefaultPackagePrefix(string prefix)
    {
        _options.DefaultPackagePrefix = prefix;
        return this;
    }

    /// <summary>
    /// Set default version for all languages
    /// </summary>
    public PackageGenerationOptionsBuilder DefaultVersion(string version)
    {
        _options.DefaultVersion = version;
        return this;
    }

    /// <summary>
    /// Enable or disable parallel generation
    /// </summary>
    public PackageGenerationOptionsBuilder ParallelGeneration(bool parallel = true, int? maxConcurrency = null)
    {
        _options.ParallelGeneration = parallel;
        if (maxConcurrency.HasValue)
        {
            _options.MaxConcurrency = maxConcurrency.Value;
        }
        return this;
    }

    /// <summary>
    /// Add a global option that applies to all languages
    /// </summary>
    public PackageGenerationOptionsBuilder WithGlobalOption(string key, string value)
    {
        _options.GlobalOptions[key] = value;
        return this;
    }

    /// <summary>
    /// Add Swift package configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddSwiftPackage(Action<LanguagePackageConfigBuilder> configure)
    {
        var builder = new LanguagePackageConfigBuilder();
        configure(builder);
        var config = builder.Build();
        
        // Set defaults if not specified
        if (string.IsNullOrEmpty(config.OutputPath))
            config.OutputPath = Path.Combine(_options.BaseOutputPath, PackageLanguage.Swift.GetDefaultDirectoryName());
        if (string.IsNullOrEmpty(config.PackageName) && !string.IsNullOrEmpty(_options.DefaultPackagePrefix))
            config.PackageName = $"{_options.DefaultPackagePrefix}SDK";
        if (config.Version == "1.0.0" && _options.DefaultVersion != "1.0.0")
            config.Version = _options.DefaultVersion;

        _options.Languages[PackageLanguage.Swift] = config;
        return this;
    }

    /// <summary>
    /// Add Swift package with simple configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddSwiftPackage(string outputPath, string packageName, string? version = null)
    {
        return AddSwiftPackage(config => config
            .OutputPath(outputPath)
            .PackageName(packageName)
            .Version(version ?? _options.DefaultVersion));
    }

    /// <summary>
    /// Add Kotlin package configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddKotlinPackage(Action<LanguagePackageConfigBuilder> configure)
    {
        var builder = new LanguagePackageConfigBuilder();
        configure(builder);
        var config = builder.Build();
        
        // Set defaults if not specified
        if (string.IsNullOrEmpty(config.OutputPath))
            config.OutputPath = Path.Combine(_options.BaseOutputPath, PackageLanguage.Kotlin.GetDefaultDirectoryName());
        if (string.IsNullOrEmpty(config.PackageName) && !string.IsNullOrEmpty(_options.DefaultPackagePrefix))
            config.PackageName = $"com.{_options.DefaultPackagePrefix.ToLowerInvariant()}.sdk";
        if (config.Version == "1.0.0" && _options.DefaultVersion != "1.0.0")
            config.Version = _options.DefaultVersion;

        _options.Languages[PackageLanguage.Kotlin] = config;
        return this;
    }

    /// <summary>
    /// Add Kotlin package with simple configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddKotlinPackage(string outputPath, string packageName, string? version = null)
    {
        return AddKotlinPackage(config => config
            .OutputPath(outputPath)
            .PackageName(packageName)
            .Version(version ?? _options.DefaultVersion));
    }

    /// <summary>
    /// Add C# package configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddCSharpPackage(Action<LanguagePackageConfigBuilder> configure)
    {
        var builder = new LanguagePackageConfigBuilder();
        configure(builder);
        var config = builder.Build();
        
        // Set defaults if not specified
        if (string.IsNullOrEmpty(config.OutputPath))
            config.OutputPath = Path.Combine(_options.BaseOutputPath, PackageLanguage.CSharp.GetDefaultDirectoryName());
        if (string.IsNullOrEmpty(config.PackageName) && !string.IsNullOrEmpty(_options.DefaultPackagePrefix))
            config.PackageName = $"{_options.DefaultPackagePrefix}.Client";
        if (config.Version == "1.0.0" && _options.DefaultVersion != "1.0.0")
            config.Version = _options.DefaultVersion;

        _options.Languages[PackageLanguage.CSharp] = config;
        return this;
    }

    /// <summary>
    /// Add C# package with simple configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddCSharpPackage(string outputPath, string packageName, string? version = null)
    {
        return AddCSharpPackage(config => config
            .OutputPath(outputPath)
            .PackageName(packageName)
            .Version(version ?? _options.DefaultVersion));
    }

    /// <summary>
    /// Add all common languages with default configuration
    /// </summary>
    public PackageGenerationOptionsBuilder AddAllLanguages(string? swiftPackageName = null, string? kotlinPackageName = null, string? csharpPackageName = null)
    {
        AddSwiftPackage(config => config
            .PackageName(swiftPackageName ?? $"{_options.DefaultPackagePrefix}SDK")
            .IncludeDocumentation()
            .IncludeSamples());

        AddKotlinPackage(config => config
            .PackageName(kotlinPackageName ?? $"com.{_options.DefaultPackagePrefix?.ToLowerInvariant()}.sdk")
            .IncludeDocumentation()
            .IncludeSamples());

        AddCSharpPackage(config => config
            .PackageName(csharpPackageName ?? $"{_options.DefaultPackagePrefix}.Client")
            .IncludeDocumentation()
            .IncludeSamples());

        return this;
    }

    /// <summary>
    /// Configure a specific language package
    /// </summary>
    public PackageGenerationOptionsBuilder ConfigureLanguage(PackageLanguage language, Action<LanguagePackageConfigBuilder> configure)
    {
        return language switch
        {
            PackageLanguage.Swift => AddSwiftPackage(configure),
            PackageLanguage.Kotlin => AddKotlinPackage(configure),
            PackageLanguage.CSharp => AddCSharpPackage(configure),
            _ => throw new ArgumentOutOfRangeException(nameof(language), language, null)
        };
    }

    /// <summary>
    /// Build the final options
    /// </summary>
    public PackageGenerationOptions Build() => _options;

    /// <summary>
    /// Implicit conversion to PackageGenerationOptions
    /// </summary>
    public static implicit operator PackageGenerationOptions(PackageGenerationOptionsBuilder builder) => builder.Build();
}