namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Configuration for a specific language package
/// </summary>
public class LanguagePackageConfig
{
    /// <summary>
    /// Output path for this language package (relative to project or absolute)
    /// </summary>
    public string OutputPath { get; set; } = string.Empty;

    /// <summary>
    /// Package name/identifier for this language
    /// </summary>
    public string PackageName { get; set; } = string.Empty;

    /// <summary>
    /// Package version
    /// </summary>
    public string Version { get; set; } = "1.0.0";

    /// <summary>
    /// Whether to enable this language package generation
    /// </summary>
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Whether to clean the output directory before generation
    /// </summary>
    public bool CleanOutput { get; set; } = true;

    /// <summary>
    /// Language-specific generation options
    /// </summary>
    public Dictionary<string, string> Options { get; set; } = new();

    /// <summary>
    /// Additional dependencies to include in the package
    /// </summary>
    public List<PackageDependency> Dependencies { get; set; } = new();

    /// <summary>
    /// Include documentation in the generated package
    /// </summary>
    public bool IncludeDocumentation { get; set; } = true;

    /// <summary>
    /// Include code samples in the generated package
    /// </summary>
    public bool IncludeSamples { get; set; } = false;
}

/// <summary>
/// Package dependency configuration
/// </summary>
public class PackageDependency
{
    /// <summary>
    /// Dependency name/identifier
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Dependency version or version range
    /// </summary>
    public required string Version { get; set; }

    /// <summary>
    /// Optional dependency source/repository
    /// </summary>
    public string? Source { get; set; }

    /// <summary>
    /// Whether this is a development-only dependency
    /// </summary>
    public bool IsDevDependency { get; set; } = false;
}

/// <summary>
/// Builder class for fluent configuration of language packages
/// </summary>
public class LanguagePackageConfigBuilder
{
    private readonly LanguagePackageConfig _config = new();

    /// <summary>
    /// Set the output path for the package
    /// </summary>
    public LanguagePackageConfigBuilder OutputPath(string path)
    {
        _config.OutputPath = path;
        return this;
    }

    /// <summary>
    /// Set the package name
    /// </summary>
    public LanguagePackageConfigBuilder PackageName(string name)
    {
        _config.PackageName = name;
        return this;
    }

    /// <summary>
    /// Set the package version
    /// </summary>
    public LanguagePackageConfigBuilder Version(string version)
    {
        _config.Version = version;
        return this;
    }

    /// <summary>
    /// Enable or disable this package generation
    /// </summary>
    public LanguagePackageConfigBuilder Enabled(bool enabled = true)
    {
        _config.Enabled = enabled;
        return this;
    }

    /// <summary>
    /// Set whether to clean output before generation
    /// </summary>
    public LanguagePackageConfigBuilder CleanOutput(bool clean = true)
    {
        _config.CleanOutput = clean;
        return this;
    }

    /// <summary>
    /// Add a generation option
    /// </summary>
    public LanguagePackageConfigBuilder WithOption(string key, string value)
    {
        _config.Options[key] = value;
        return this;
    }

    /// <summary>
    /// Add multiple generation options
    /// </summary>
    public LanguagePackageConfigBuilder WithOptions(Dictionary<string, string> options)
    {
        foreach (var option in options)
        {
            _config.Options[option.Key] = option.Value;
        }
        return this;
    }

    /// <summary>
    /// Add a package dependency
    /// </summary>
    public LanguagePackageConfigBuilder AddDependency(string name, string version, string? source = null, bool isDevDependency = false)
    {
        _config.Dependencies.Add(new PackageDependency
        {
            Name = name,
            Version = version,
            Source = source,
            IsDevDependency = isDevDependency
        });
        return this;
    }

    /// <summary>
    /// Include documentation in the package
    /// </summary>
    public LanguagePackageConfigBuilder IncludeDocumentation(bool include = true)
    {
        _config.IncludeDocumentation = include;
        return this;
    }

    /// <summary>
    /// Include code samples in the package
    /// </summary>
    public LanguagePackageConfigBuilder IncludeSamples(bool include = true)
    {
        _config.IncludeSamples = include;
        return this;
    }

    /// <summary>
    /// Build the configuration
    /// </summary>
    public LanguagePackageConfig Build() => _config;

    /// <summary>
    /// Implicit conversion to LanguagePackageConfig
    /// </summary>
    public static implicit operator LanguagePackageConfig(LanguagePackageConfigBuilder builder) => builder.Build();
}