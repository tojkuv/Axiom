using System.Diagnostics;
using System.Reflection;
using AxiomEndpoints.ProtoGen;
using AxiomEndpoints.ProtoGen.Core;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Service for managing protobuf package generation in Aspire applications
/// </summary>
public interface IPackageGenerationService
{
    /// <summary>
    /// Generate protobuf packages for a project
    /// </summary>
    Task<PackageGenerationResult> GeneratePackagesAsync(
        string projectPath,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Generate protobuf packages from assembly
    /// </summary>
    Task<PackageGenerationResult> GeneratePackagesFromAssemblyAsync(
        Assembly assembly,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Check if packages need regeneration
    /// </summary>
    Task<bool> ShouldRegenerateAsync(
        string projectPath,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Package generation result
/// </summary>
public class PackageGenerationResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public TimeSpan Duration { get; set; }
    public List<GeneratedPackage> GeneratedPackages { get; set; } = new();
    public List<string> Warnings { get; set; } = new();
}

/// <summary>
/// Generated package information
/// </summary>
public class GeneratedPackage
{
    public required string Language { get; set; }
    public required string OutputPath { get; set; }
    public required long SizeBytes { get; set; }
    public required DateTime GeneratedAt { get; set; }
    public List<string> Files { get; set; } = new();
}

/// <summary>
/// Implementation of protobuf package generation service
/// </summary>
public class PackageGenerationService : IPackageGenerationService
{
    private readonly ILogger<PackageGenerationService> _logger;
    private readonly ProtoPackageService _protoService;

    public PackageGenerationService(
        ILogger<PackageGenerationService> logger,
        ProtoPackageService protoService)
    {
        _logger = logger;
        _protoService = protoService;
    }

    public async Task<PackageGenerationResult> GeneratePackagesAsync(
        string projectPath,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default)
    {
        var stopwatch = Stopwatch.StartNew();
        var result = new PackageGenerationResult();

        try
        {
            _logger.LogInformation("Starting protobuf package generation for project: {ProjectPath}", projectPath);

            // Build project to get assembly
            var buildResult = await BuildProjectAsync(projectPath, cancellationToken);
            if (!buildResult.Success)
            {
                result.Error = $"Failed to build project: {buildResult.Error}";
                return result;
            }

            // Load assembly
            var assembly = Assembly.LoadFrom(buildResult.AssemblyPath!);
            
            // Generate packages from assembly
            return await GeneratePackagesFromAssemblyAsync(assembly, options, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating protobuf packages for project: {ProjectPath}", projectPath);
            result.Error = ex.Message;
            return result;
        }
        finally
        {
            result.Duration = stopwatch.Elapsed;
        }
    }

    public async Task<PackageGenerationResult> GeneratePackagesFromAssemblyAsync(
        Assembly assembly,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default)
    {
        var stopwatch = Stopwatch.StartNew();
        var result = new PackageGenerationResult();

        try
        {
            _logger.LogInformation("Generating protobuf packages from assembly: {AssemblyName}", assembly.GetName().Name);

            // Setup base output directory
            var baseOutputDir = Path.GetFullPath(options.BaseOutputPath);
            Directory.CreateDirectory(baseOutputDir);

            // Generate protobuf package
            try
            {
                var packageResult = await GenerateProtoPackageAsync(
                    assembly, options, cancellationToken);
                
                if (packageResult != null)
                {
                    result.GeneratedPackages.Add(packageResult);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to generate protobuf package");
                result.Warnings.Add($"Failed to generate protobuf package: {ex.Message}");
            }

            result.Success = result.GeneratedPackages.Count > 0;
            
            _logger.LogInformation("Protobuf package generation completed. Generated {Count} packages in {Duration}",
                result.GeneratedPackages.Count, stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating protobuf packages from assembly: {AssemblyName}", assembly.GetName().Name);
            result.Error = ex.Message;
        }
        finally
        {
            result.Duration = stopwatch.Elapsed;
        }

        return result;
    }

    public async Task<bool> ShouldRegenerateAsync(
        string projectPath,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var outputDir = Path.GetFullPath(options.BaseOutputPath);
            if (!Directory.Exists(outputDir))
            {
                return true; // No packages exist
            }

            // Check if project files are newer than generated packages
            var projectFile = Directory.GetFiles(projectPath, "*.csproj").FirstOrDefault();
            if (projectFile != null)
            {
                var projectLastWrite = File.GetLastWriteTimeUtc(projectFile);
                var packageDirs = Directory.GetDirectories(outputDir);
                
                foreach (var packageDir in packageDirs)
                {
                    var packageFiles = Directory.GetFiles(packageDir, "*", SearchOption.AllDirectories);
                    if (!packageFiles.Any() || packageFiles.Any(f => File.GetLastWriteTimeUtc(f) < projectLastWrite))
                    {
                        return true;
                    }
                }
            }

            return false;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error checking if regeneration needed for: {ProjectPath}", projectPath);
            return true; // Regenerate on error
        }
    }

    private async Task<GeneratedPackage?> GenerateProtoPackageAsync(
        Assembly assembly,
        PackageGenerationOptions options,
        CancellationToken cancellationToken)
    {
        var outputDir = Path.GetFullPath(options.BaseOutputPath);
        
        // Clean output if requested
        if (Directory.Exists(outputDir))
        {
            Directory.Delete(outputDir, true);
        }
        Directory.CreateDirectory(outputDir);

        var startTime = DateTime.UtcNow;

        try
        {
            // Use actual ProtoGen service to generate protobuf files
            var packageName = options.DefaultPackagePrefix ?? "axiom-package";
            var protoGenOptions = new AxiomEndpoints.ProtoGen.Core.GenerateOptions
            {
                AssemblyPath = assembly.Location,
                OutputPath = outputDir,
                PackageName = packageName,
                Version = options.DefaultVersion,
                Organization = "axiom",
                Authors = "Axiom Endpoints",
                Description = $"Generated protobuf package for {packageName}",
                RepositoryUrl = ""
            };

            var result = await _protoService.GenerateAsync(protoGenOptions);
            
            if (!result.Success)
            {
                _logger.LogError("Failed to generate protobuf package: {Error}", result.Error);
                return null;
            }

            // Create package metadata
            await CreateProtoPackageMetadataAsync(outputDir, options, result.ProtoPackage, cancellationToken);

            // Collect all generated files
            var files = Directory.GetFiles(outputDir, "*", SearchOption.AllDirectories)
                .Select(f => Path.GetRelativePath(outputDir, f))
                .ToList();

            var totalSize = files.Sum(f => new FileInfo(Path.Combine(outputDir, f)).Length);

            return new GeneratedPackage
            {
                Language = "protobuf",
                OutputPath = outputDir,
                Files = files,
                SizeBytes = totalSize,
                GeneratedAt = startTime
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating protobuf package");
            return null;
        }
    }

    private async Task CreateProtoPackageMetadataAsync(
        string outputDir, 
        PackageGenerationOptions options, 
        AxiomEndpoints.ProtoGen.Core.ProtoPackage? protoPackage,
        CancellationToken cancellationToken)
    {
        var packageName = options.DefaultPackagePrefix ?? "axiom-package";
        var metadata = new
        {
            packageName = packageName,
            version = options.DefaultVersion,
            language = "protobuf",
            generatedAt = DateTime.UtcNow,
            protoPackage = protoPackage?.Name,
            description = $"Generated protobuf package for {packageName}"
        };

        var json = System.Text.Json.JsonSerializer.Serialize(metadata, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
        await File.WriteAllTextAsync(Path.Combine(outputDir, "package-metadata.json"), json, cancellationToken);
    }

    private async Task<BuildResult> BuildProjectAsync(string projectPath, CancellationToken cancellationToken)
    {
        try
        {
            var projectFile = Directory.GetFiles(projectPath, "*.csproj").FirstOrDefault();
            if (projectFile == null)
            {
                return new BuildResult { Success = false, Error = "No project file found" };
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = "dotnet",
                Arguments = $"build \"{projectFile}\" --configuration Release --no-restore",
                WorkingDirectory = projectPath,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            using var process = Process.Start(startInfo);
            if (process == null)
            {
                return new BuildResult { Success = false, Error = "Failed to start build process" };
            }

            await process.WaitForExitAsync(cancellationToken);

            if (process.ExitCode != 0)
            {
                var error = await process.StandardError.ReadToEndAsync(cancellationToken);
                return new BuildResult { Success = false, Error = error };
            }

            // Find the built assembly
            var binDir = Path.Combine(projectPath, "bin", "Release");
            var assemblyPath = Directory.GetFiles(binDir, "*.dll", SearchOption.AllDirectories)
                .FirstOrDefault(f => Path.GetFileNameWithoutExtension(f) == Path.GetFileNameWithoutExtension(projectFile));

            return new BuildResult 
            { 
                Success = true, 
                AssemblyPath = assemblyPath 
            };
        }
        catch (Exception ex)
        {
            return new BuildResult { Success = false, Error = ex.Message };
        }
    }

    private class BuildResult
    {
        public bool Success { get; set; }
        public string? Error { get; set; }
        public string? AssemblyPath { get; set; }
    }
}