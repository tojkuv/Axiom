using System.Diagnostics;
using System.Reflection;
using AxiomEndpoints.ProtoGen;
using AxiomEndpoints.ProtoGen.Core;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Service for managing package generation in Aspire applications
/// </summary>
public interface IPackageGenerationService
{
    /// <summary>
    /// Generate packages for a project
    /// </summary>
    Task<PackageGenerationResult> GeneratePackagesAsync(
        string projectPath,
        PackageGenerationOptions options,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Generate packages from assembly
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
/// Implementation of package generation service
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
            _logger.LogInformation("Starting package generation for project: {ProjectPath}", projectPath);

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
            _logger.LogError(ex, "Error generating packages for project: {ProjectPath}", projectPath);
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
            _logger.LogInformation("Generating packages from assembly: {AssemblyName}", assembly.GetName().Name);

            // Setup base output directory
            var baseOutputDir = Path.GetFullPath(options.BaseOutputPath);
            Directory.CreateDirectory(baseOutputDir);

            // Generate packages for each language
            foreach (var (language, config) in options.Languages)
            {
                cancellationToken.ThrowIfCancellationRequested();

                try
                {
                    var packageResult = await GenerateLanguagePackageAsync(
                        assembly, language, config, cancellationToken);
                    
                    if (packageResult != null)
                    {
                        result.GeneratedPackages.Add(packageResult);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to generate {Language} package", language.ToProtoGenString());
                    result.Warnings.Add($"Failed to generate {language.ToProtoGenString()} package: {ex.Message}");
                }
            }

            result.Success = result.GeneratedPackages.Count > 0;
            
            _logger.LogInformation("Package generation completed. Generated {Count} packages in {Duration}",
                result.GeneratedPackages.Count, stopwatch.Elapsed);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating packages from assembly: {AssemblyName}", assembly.GetName().Name);
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

    private async Task<GeneratedPackage?> GenerateLanguagePackageAsync(
        Assembly assembly,
        PackageLanguage language,
        LanguagePackageConfig config,
        CancellationToken cancellationToken)
    {
        var languageOutputDir = Path.GetFullPath(config.OutputPath);
        
        // Clean output if requested
        if (config.CleanOutput && Directory.Exists(languageOutputDir))
        {
            Directory.Delete(languageOutputDir, true);
        }
        Directory.CreateDirectory(languageOutputDir);

        var startTime = DateTime.UtcNow;

        // For now, simulate package generation since ProtoGen integration needs work
        // TODO: Integrate with actual ProtoGen service when ready
        await Task.Delay(100, cancellationToken); // Simulate work
        
        // Create a dummy file to show generation worked
        var dummyFile = Path.Combine(languageOutputDir, $"Generated_{language.ToProtoGenString()}.txt");
        await File.WriteAllTextAsync(dummyFile, 
            $"Generated {language.ToProtoGenString()} package '{config.PackageName}' at {startTime}\n" +
            $"Version: {config.Version}\n" +
            $"Documentation: {config.IncludeDocumentation}\n" +
            $"Samples: {config.IncludeSamples}\n", 
            cancellationToken);

        // Collect generated files
        var files = Directory.GetFiles(languageOutputDir, "*", SearchOption.AllDirectories)
            .Select(f => Path.GetRelativePath(languageOutputDir, f))
            .ToList();

        var totalSize = files.Sum(f => new FileInfo(Path.Combine(languageOutputDir, f)).Length);

        return new GeneratedPackage
        {
            Language = language.ToProtoGenString(),
            OutputPath = languageOutputDir,
            Files = files,
            SizeBytes = totalSize,
            GeneratedAt = startTime
        };
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