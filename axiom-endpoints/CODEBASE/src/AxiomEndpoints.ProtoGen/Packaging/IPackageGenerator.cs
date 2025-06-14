using AxiomEndpoints.ProtoGen.Compilation;

namespace AxiomEndpoints.ProtoGen.Packaging;

/// <summary>
/// Base interface for package generators
/// </summary>
public interface IPackageGenerator
{
    Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata);
}

/// <summary>
/// Package metadata
/// </summary>
public class PackageMetadata
{
    public required string PackageName { get; init; }
    public required string ServiceName { get; init; }
    public required string Version { get; init; }
    public required string GroupId { get; init; }
    public string Authors { get; init; } = "";
    public string Company { get; init; } = "";
    public string Description { get; init; } = "";
    public string RepositoryUrl { get; init; } = "";
    public string LicenseUrl { get; init; } = "";
    public List<string> Tags { get; init; } = new();
}

/// <summary>
/// Package generation result
/// </summary>
public class PackageResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string PackagePath { get; init; } = "";
    public Language Language { get; init; }
    public List<string> GeneratedFiles { get; set; } = new();
}