using System.Reflection;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.ProtoGen.Core;
using AxiomEndpoints.ProtoGen.Writers;
using AxiomEndpoints.ProtoGen.Compilation;

namespace AxiomEndpoints.ProtoGen.Core;

/// <summary>
/// Main service for generating proto files from assemblies (no client generation - just .proto files for MCP consumption)
/// </summary>
public class ProtoPackageService
{
    private readonly ProtoTypeGenerator _typeGenerator;
    private readonly ProtoFileWriter _fileWriter;
    private readonly ProtocCompiler _protoGenerator;
    private readonly ILogger<ProtoPackageService> _logger;

    public ProtoPackageService(
        ProtoTypeGenerator typeGenerator,
        ProtoFileWriter fileWriter,
        ProtocCompiler protoGenerator,
        ILogger<ProtoPackageService> logger)
    {
        _typeGenerator = typeGenerator;
        _fileWriter = fileWriter;
        _protoGenerator = protoGenerator;
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
            
            // Write proto files for MCP tool consumption
            _logger.LogInformation("Writing proto files to: {OutputPath}", options.OutputPath);
            await _fileWriter.WritePackageAsync(protoPackage, options.OutputPath);
            
            // Generate the .proto file for MCP consumption
            var protoFilePath = Path.Combine(options.OutputPath, protoPackage.Name, $"{protoPackage.Name}.proto");
            if (File.Exists(protoFilePath))
            {
                var protoContent = await File.ReadAllTextAsync(protoFilePath);
                var protoOutputPath = Path.Combine(options.OutputPath, "mcp");
                
                var generationResult = await _protoGenerator.GenerateProtoFileAsync(
                    protoContent, 
                    $"{protoPackage.Name}.proto", 
                    protoOutputPath);
                
                if (generationResult.Success)
                {
                    _logger.LogInformation("Proto file generated for MCP consumption at: {Path}", protoOutputPath);
                }
                else
                {
                    _logger.LogError("Failed to generate proto file for MCP: {Error}", generationResult.Error);
                }
            }
            
            return new GenerateResult
            {
                Success = true,
                ProtoPackage = protoPackage,
                GeneratedFiles = [protoFilePath]
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate proto files");
            return new GenerateResult
            {
                Success = false,
                Error = ex.Message
            };
        }
}
}

/// <summary>
/// Options for generating proto files (no client packages - just .proto files for MCP consumption)
/// </summary>
public class GenerateOptions
{
    public required string AssemblyPath { get; init; }
    public required string OutputPath { get; init; }
    public string? PackageName { get; init; }
    public string? Version { get; init; }
    public string? Organization { get; init; }
    public string Authors { get; init; } = "";
    public string Description { get; init; } = "";
    public string RepositoryUrl { get; init; } = "";
}

/// <summary>
/// Result of proto file generation (no packages - just .proto files for MCP consumption)
/// </summary>
public class GenerateResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public ProtoPackage? ProtoPackage { get; set; }
    public List<string> GeneratedFiles { get; set; } = new();
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