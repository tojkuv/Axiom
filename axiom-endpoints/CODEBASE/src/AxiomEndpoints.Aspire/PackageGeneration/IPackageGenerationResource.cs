using Aspire.Hosting.ApplicationModel;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Aspire resource for package generation
/// </summary>
public interface IPackageGenerationResource : IResource
{
    /// <summary>
    /// Source project to generate packages from
    /// </summary>
    IResource SourceProject { get; }
    
    /// <summary>
    /// Package generation configuration
    /// </summary>
    PackageGenerationOptions Options { get; }
}

/// <summary>
/// Configuration options for package generation
/// </summary>
public class PackageGenerationOptions
{
    /// <summary>
    /// Language-specific package configurations
    /// </summary>
    public Dictionary<PackageLanguage, LanguagePackageConfig> Languages { get; set; } = new();
    
    /// <summary>
    /// Base output directory for all packages (relative to project)
    /// </summary>
    public string BaseOutputPath { get; set; } = "generated-packages";
    
    /// <summary>
    /// Whether to generate packages on build
    /// </summary>
    public bool GenerateOnBuild { get; set; } = true;
    
    /// <summary>
    /// Global generation options that apply to all languages
    /// </summary>
    public Dictionary<string, string> GlobalOptions { get; set; } = new();
    
    /// <summary>
    /// Default package name prefix (used if not specified per language)
    /// </summary>
    public string? DefaultPackagePrefix { get; set; }
    
    /// <summary>
    /// Default package version (used if not specified per language)
    /// </summary>
    public string DefaultVersion { get; set; } = "1.0.0";
    
    /// <summary>
    /// Whether to generate packages in parallel
    /// </summary>
    public bool ParallelGeneration { get; set; } = true;
    
    /// <summary>
    /// Maximum number of concurrent package generation tasks
    /// </summary>
    public int MaxConcurrency { get; set; } = Environment.ProcessorCount;
}

/// <summary>
/// Package generation resource implementation
/// </summary>
public class PackageGenerationResource : Resource, IPackageGenerationResource
{
    public PackageGenerationResource(string name, IResource sourceProject, PackageGenerationOptions options)
        : base(name)
    {
        SourceProject = sourceProject;
        Options = options;
    }

    public IResource SourceProject { get; }
    public PackageGenerationOptions Options { get; }
}