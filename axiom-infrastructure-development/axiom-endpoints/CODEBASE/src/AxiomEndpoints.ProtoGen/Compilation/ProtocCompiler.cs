using System.Diagnostics;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.ProtoGen.Compilation;

/// <summary>
/// Manages protobuf file generation (no compilation - just .proto file creation for MCP tool consumption)
/// </summary>
public class ProtocCompiler
{
    private readonly ILogger<ProtocCompiler> _logger;

    public ProtocCompiler(ILogger<ProtocCompiler> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Writes a .proto file to the specified output path for MCP tool consumption.
    /// No compilation is performed - this is just file generation.
    /// </summary>
    public async Task<ProtoGenerationResult> GenerateProtoFileAsync(
        string protoContent,
        string fileName,
        string outputPath)
    {
        try
        {
            Directory.CreateDirectory(outputPath);
            var filePath = Path.Combine(outputPath, fileName);
            
            await File.WriteAllTextAsync(filePath, protoContent);
            
            _logger.LogInformation("Generated proto file: {FilePath}", filePath);
            
            return new ProtoGenerationResult
            {
                Success = true,
                OutputPath = outputPath,
                GeneratedFiles = [filePath]
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate proto file {FileName}", fileName);
            return new ProtoGenerationResult
            {
                Success = false,
                Error = ex.Message,
                OutputPath = outputPath
            };
        }
}
}

/// <summary>
/// Proto file generation result (no compilation, just .proto file creation)
/// </summary>
public class ProtoGenerationResult
{
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string OutputPath { get; init; } = "";
    public List<string> GeneratedFiles { get; set; } = new();
}