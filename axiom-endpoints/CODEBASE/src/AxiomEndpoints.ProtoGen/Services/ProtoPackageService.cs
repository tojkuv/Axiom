using System.Reflection;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.ProtoGen.Core;
using AxiomEndpoints.ProtoGen.Writers;
using AxiomEndpoints.ProtoGen.Compilation;
using AxiomEndpoints.ProtoGen.Packaging;

namespace AxiomEndpoints.ProtoGen.Core;

/// <summary>
/// Main service for generating proto packages from assemblies
/// </summary>
public class ProtoPackageService
{
    private readonly ProtoTypeGenerator _typeGenerator;
    private readonly ProtoFileWriter _fileWriter;
    private readonly ProtocCompiler _compiler;
    private readonly IEnumerable<IPackageGenerator> _packageGenerators;
    private readonly ILogger<ProtoPackageService> _logger;

    public ProtoPackageService(
        ProtoTypeGenerator typeGenerator,
        ProtoFileWriter fileWriter,
        ProtocCompiler compiler,
        IEnumerable<IPackageGenerator> packageGenerators,
        ILogger<ProtoPackageService> logger)
    {
        _typeGenerator = typeGenerator;
        _fileWriter = fileWriter;
        _compiler = compiler;
        _packageGenerators = packageGenerators;
        _logger = logger;
    }

    public async Task<GenerateResult> GenerateAsync(GenerateOptions options)
    {
        try
        {
            _logger.LogInformation("Loading assembly: {AssemblyPath}", options.AssemblyPath);
            
            // Load the assembly
            var assembly = Assembly.LoadFrom(options.AssemblyPath);
            
            // Generate proto package
            _logger.LogInformation("Generating proto package from assembly");
            var protoPackage = await _typeGenerator.GenerateProtoPackageAsync(assembly);
            
            // Override with user options
            if (!string.IsNullOrEmpty(options.PackageName))
                protoPackage.Name = options.PackageName.ToLowerInvariant();
            
            if (!string.IsNullOrEmpty(options.Version))
                protoPackage.Version = options.Version;
            
            // Write proto files
            _logger.LogInformation("Writing proto files to: {OutputPath}", options.OutputPath);
            await _fileWriter.WritePackageAsync(protoPackage, options.OutputPath);
            
            var generatedPackages = new List<PackageResult>();
            
            // Generate packages for each language
            foreach (var language in options.Languages)
            {
                _logger.LogInformation("Processing language: {Language}", language);
                
                var protoFilePath = Path.Combine(options.OutputPath, protoPackage.Name, $"{protoPackage.Name}.proto");
                var languageOutputPath = Path.Combine(options.OutputPath, "generated", language.ToString().ToLowerInvariant());
                
                // Compile proto to language-specific types
                _logger.LogInformation("Compiling proto for {Language}", language);
                var compilationResult = await _compiler.CompileAsync(protoFilePath, language, languageOutputPath);
                
                if (!compilationResult.Success)
                {
                    _logger.LogError("Compilation failed for {Language}: {Error}", language, compilationResult.Error);
                    continue;
                }
                
                // Generate package
                var packageGenerator = GetPackageGenerator(language);
                if (packageGenerator != null)
                {
                    _logger.LogInformation("Generating {Language} package", language);
                    
                    var metadata = new PackageMetadata
                    {
                        PackageName = GetLanguageSpecificPackageName(protoPackage.Name, language),
                        ServiceName = protoPackage.Name,
                        Version = protoPackage.Version,
                        GroupId = GetGroupId(protoPackage.Name, options.Organization),
                        Authors = options.Authors,
                        Company = options.Organization ?? "",
                        Description = options.Description,
                        RepositoryUrl = options.RepositoryUrl
                    };
                    
                    var packageResult = await packageGenerator.GeneratePackageAsync(compilationResult, metadata);
                    
                    if (packageResult.Success)
                    {
                        generatedPackages.Add(packageResult);
                        _logger.LogInformation("Successfully generated {Language} package at: {Path}", 
                            language, packageResult.PackagePath);
                    }
                    else
                    {
                        _logger.LogError("Package generation failed for {Language}: {Error}", 
                            language, packageResult.Error);
                    }
                }
                else
                {
                    _logger.LogWarning("No package generator found for language: {Language}", language);
                }
            }
            
            return new GenerateResult
            {
                Success = true,
                ProtoPackage = protoPackage,
                GeneratedPackages = generatedPackages
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate proto packages");
            return new GenerateResult
            {
                Success = false,
                Error = ex.Message
            };
        }
    }

    private IPackageGenerator? GetPackageGenerator(Language language)
    {
        return language switch
        {
            Language.Swift => _packageGenerators.OfType<SwiftPackageGenerator>().FirstOrDefault(),
            Language.Kotlin => _packageGenerators.OfType<KotlinPackageGenerator>().FirstOrDefault(),
            Language.CSharp => _packageGenerators.OfType<NuGetPackageGenerator>().FirstOrDefault(),
            _ => null
        };
    }

    private string GetLanguageSpecificPackageName(string baseName, Language language)
    {
        return language switch
        {
            Language.Swift => $"{baseName.ToPascalCase()}Swift",
            Language.Kotlin => $"{baseName}-kotlin",
            Language.CSharp => $"{baseName.ToPascalCase()}.Types",
            Language.Java => $"{baseName}-java",
            Language.TypeScript => $"@{baseName}/types",
            _ => baseName
        };
    }

    private string GetGroupId(string packageName, string? organization)
    {
        var org = organization?.ToLowerInvariant() ?? "com.company";
        return $"{org}.{packageName.ToLowerInvariant()}";
    }
}

/// <summary>
/// Options for generating proto packages
/// </summary>
public class GenerateOptions
{
    public required string AssemblyPath { get; init; }
    public required string OutputPath { get; init; }
    public required List<Language> Languages { get; init; }
    public string? PackageName { get; init; }
    public string? Version { get; init; }
    public string? Organization { get; init; }
    public string Authors { get; init; } = "";
    public string Description { get; init; } = "";
    public string RepositoryUrl { get; init; } = "";
}

/// <summary>
/// Result of proto package generation
/// </summary>
public class GenerateResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public ProtoPackage? ProtoPackage { get; set; }
    public List<PackageResult> GeneratedPackages { get; set; } = new();
}

/// <summary>
/// Extension methods for string manipulation
/// </summary>
public static class StringExtensions
{
    public static string ToPascalCase(this string input)
    {
        if (string.IsNullOrEmpty(input))
            return input;

        var words = input.Split(new[] { '-', '_', '.' }, StringSplitOptions.RemoveEmptyEntries);
        var result = string.Join("", words.Select(word => 
            char.ToUpperInvariant(word[0]) + (word.Length > 1 ? word[1..].ToLowerInvariant() : "")));
        
        return result;
    }
}