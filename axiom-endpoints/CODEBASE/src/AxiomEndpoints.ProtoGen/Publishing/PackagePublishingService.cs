using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.ProtoGen.Publishing;

/// <summary>
/// Service for publishing packages to various registries
/// </summary>
public class PackagePublishingService
{
    private readonly ILogger<PackagePublishingService> _logger;

    public PackagePublishingService(ILogger<PackagePublishingService> logger)
    {
        _logger = logger;
    }

    public async Task<PublishResult> PublishAsync(PublishOptions options)
    {
        try
        {
            _logger.LogInformation("Publishing package from: {PackagePath}", options.PackagePath);
            
            // Detect package type
            var packageType = DetectPackageType(options.PackagePath);
            
            _logger.LogInformation("Detected package type: {PackageType}", packageType);
            
            return packageType switch
            {
                PackageType.Swift => await PublishSwiftPackageAsync(options),
                PackageType.Kotlin => await PublishKotlinPackageAsync(options),
                PackageType.CSharp => await PublishNuGetPackageAsync(options),
                PackageType.Java => await PublishJavaPackageAsync(options),
                _ => new PublishResult
                {
                    Success = false,
                    Error = $"Unsupported package type: {packageType}"
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish package");
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private PackageType DetectPackageType(string packagePath)
    {
        if (File.Exists(Path.Combine(packagePath, "Package.swift")))
            return PackageType.Swift;
        
        if (File.Exists(Path.Combine(packagePath, "pom.xml")))
            return PackageType.Kotlin; // or Java
        
        if (File.Exists(Path.Combine(packagePath, "build.gradle.kts")) || 
            File.Exists(Path.Combine(packagePath, "build.gradle")))
            return PackageType.Kotlin;
        
        if (Directory.GetFiles(packagePath, "*.csproj").Any())
            return PackageType.CSharp;
        
        return PackageType.Unknown;
    }

    private async Task<PublishResult> PublishSwiftPackageAsync(PublishOptions options)
    {
        switch (options.Target)
        {
            case PublishTarget.GitHub:
                return await PublishSwiftToGitHubAsync(options);
            
            case PublishTarget.Private:
                return await PublishSwiftToPrivateAsync(options);
            
            default:
                return new PublishResult
                {
                    Success = false,
                    Error = $"Unsupported publish target for Swift: {options.Target}"
                };
        }
    }

    private async Task<PublishResult> PublishKotlinPackageAsync(PublishOptions options)
    {
        switch (options.Target)
        {
            case PublishTarget.MavenCentral:
                return await PublishToMavenCentralAsync(options);
            
            case PublishTarget.GitHubPackages:
                return await PublishToGitHubPackagesAsync(options);
            
            case PublishTarget.Private:
                return await PublishToPrivateMavenAsync(options);
            
            default:
                return new PublishResult
                {
                    Success = false,
                    Error = $"Unsupported publish target for Kotlin: {options.Target}"
                };
        }
    }

    private async Task<PublishResult> PublishNuGetPackageAsync(PublishOptions options)
    {
        switch (options.Target)
        {
            case PublishTarget.NuGetOrg:
                return await PublishToNuGetOrgAsync(options);
            
            case PublishTarget.GitHubPackages:
                return await PublishToNuGetGitHubAsync(options);
            
            case PublishTarget.Private:
                return await PublishToPrivateNuGetAsync(options);
            
            default:
                return new PublishResult
                {
                    Success = false,
                    Error = $"Unsupported publish target for NuGet: {options.Target}"
                };
        }
    }

    private async Task<PublishResult> PublishJavaPackageAsync(PublishOptions options)
    {
        // Similar to Kotlin but for Java packages
        return await PublishKotlinPackageAsync(options);
    }

    private async Task<PublishResult> PublishSwiftToGitHubAsync(PublishOptions options)
    {
        try
        {
            // Initialize git repository
            await RunCommandAsync("git", "init", options.PackagePath);
            await RunCommandAsync("git", "add .", options.PackagePath);
            await RunCommandAsync("git", "commit -m \"Initial release\"", options.PackagePath);
            
            // TODO: Add remote and push (requires GitHub repository URL)
            _logger.LogInformation("Swift package prepared for GitHub. Manual push required.");
            
            return new PublishResult { Success = true };
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishSwiftToPrivateAsync(PublishOptions options)
    {
        try
        {
            if (string.IsNullOrEmpty(options.RegistryUrl))
            {
                return new PublishResult
                {
                    Success = false,
                    Error = "Registry URL is required for private Swift publishing"
                };
            }

            // Copy to private registry path
            var destinationPath = Path.Combine(options.RegistryUrl, Path.GetFileName(options.PackagePath));
            CopyDirectory(options.PackagePath, destinationPath);
            
            _logger.LogInformation("Swift package copied to private registry: {Destination}", destinationPath);
            
            return new PublishResult { Success = true };
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToMavenCentralAsync(PublishOptions options)
    {
        try
        {
            var result = await RunCommandAsync("mvn", "deploy", options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToGitHubPackagesAsync(PublishOptions options)
    {
        try
        {
            var args = $"deploy -DaltDeploymentRepository=github::default::https://maven.pkg.github.com/OWNER/REPO";
            var result = await RunCommandAsync("mvn", args, options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToPrivateMavenAsync(PublishOptions options)
    {
        try
        {
            if (string.IsNullOrEmpty(options.RegistryUrl))
            {
                return new PublishResult
                {
                    Success = false,
                    Error = "Registry URL is required for private Maven publishing"
                };
            }

            var args = $"deploy -DaltDeploymentRepository=private::default::{options.RegistryUrl}";
            var result = await RunCommandAsync("mvn", args, options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToNuGetOrgAsync(PublishOptions options)
    {
        try
        {
            if (string.IsNullOrEmpty(options.ApiKey))
            {
                return new PublishResult
                {
                    Success = false,
                    Error = "API key is required for NuGet.org publishing"
                };
            }

            var args = $"nuget push *.nupkg --api-key {options.ApiKey} --source https://api.nuget.org/v3/index.json";
            var result = await RunCommandAsync("dotnet", args, options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToNuGetGitHubAsync(PublishOptions options)
    {
        try
        {
            if (string.IsNullOrEmpty(options.ApiKey))
            {
                return new PublishResult
                {
                    Success = false,
                    Error = "GitHub token is required for GitHub Packages publishing"
                };
            }

            var args = $"nuget push *.nupkg --api-key {options.ApiKey} --source https://nuget.pkg.github.com/OWNER/index.json";
            var result = await RunCommandAsync("dotnet", args, options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<PublishResult> PublishToPrivateNuGetAsync(PublishOptions options)
    {
        try
        {
            if (string.IsNullOrEmpty(options.RegistryUrl))
            {
                return new PublishResult
                {
                    Success = false,
                    Error = "Registry URL is required for private NuGet publishing"
                };
            }

            var args = $"nuget push *.nupkg --source {options.RegistryUrl}";
            if (!string.IsNullOrEmpty(options.ApiKey))
            {
                args += $" --api-key {options.ApiKey}";
            }

            var result = await RunCommandAsync("dotnet", args, options.PackagePath);
            
            if (result.ExitCode == 0)
            {
                return new PublishResult { Success = true };
            }
            else
            {
                return new PublishResult
                {
                    Success = false,
                    Error = result.StandardError
                };
            }
        }
        catch (Exception ex)
        {
            return new PublishResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private async Task<ProcessResult> RunCommandAsync(string command, string arguments, string workingDirectory)
    {
        var processInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        _logger.LogDebug("Running command: {Command} {Arguments}", command, arguments);

        using var process = new Process { StartInfo = processInfo };
        process.Start();

        var stdout = await process.StandardOutput.ReadToEndAsync();
        var stderr = await process.StandardError.ReadToEndAsync();

        await process.WaitForExitAsync();

        _logger.LogDebug("Command exited with code: {ExitCode}", process.ExitCode);

        return new ProcessResult
        {
            ExitCode = process.ExitCode,
            StandardOutput = stdout,
            StandardError = stderr
        };
    }

    private void CopyDirectory(string sourceDir, string destinationDir)
    {
        var dir = new DirectoryInfo(sourceDir);
        
        if (!dir.Exists)
            throw new DirectoryNotFoundException($"Source directory not found: {sourceDir}");

        DirectoryInfo[] dirs = dir.GetDirectories();
        Directory.CreateDirectory(destinationDir);

        foreach (FileInfo file in dir.GetFiles())
        {
            string targetFilePath = Path.Combine(destinationDir, file.Name);
            file.CopyTo(targetFilePath, true);
        }

        foreach (DirectoryInfo subDir in dirs)
        {
            string newDestinationDir = Path.Combine(destinationDir, subDir.Name);
            CopyDirectory(subDir.FullName, newDestinationDir);
        }
    }
}

/// <summary>
/// Options for publishing packages
/// </summary>
public class PublishOptions
{
    public required string PackagePath { get; init; }
    public required PublishTarget Target { get; init; }
    public string? ApiKey { get; init; }
    public string? RegistryUrl { get; init; }
}

/// <summary>
/// Result of package publishing
/// </summary>
public class PublishResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string? PublishedUrl { get; set; }
}

/// <summary>
/// Publishing targets
/// </summary>
public enum PublishTarget
{
    NuGetOrg,
    MavenCentral,
    GitHub,
    GitHubPackages,
    Private
}

/// <summary>
/// Package types
/// </summary>
public enum PackageType
{
    Swift,
    Kotlin,
    Java,
    CSharp,
    TypeScript,
    Unknown
}

/// <summary>
/// Process execution result
/// </summary>
public class ProcessResult
{
    public int ExitCode { get; set; }
    public string StandardOutput { get; set; } = "";
    public string StandardError { get; set; } = "";
}