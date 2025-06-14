using System.Diagnostics;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.ProtoGen.Compilation;

/// <summary>
/// Manages protoc compilation for different languages
/// </summary>
public class ProtocCompiler
{
    private readonly ProtocOptions _options;
    private readonly ILogger<ProtocCompiler> _logger;

    public ProtocCompiler(ProtocOptions options, ILogger<ProtocCompiler> logger)
    {
        _options = options;
        _logger = logger;
    }

    public async Task<CompilationResult> CompileAsync(
        string protoPath,
        Language language,
        string outputPath)
    {
        var result = new CompilationResult
        {
            Language = language,
            OutputPath = outputPath
        };

        try
        {
            // Ensure protoc is available
            var protocPath = await EnsureProtocAsync();

            // Get language-specific arguments
            var args = GetProtocArguments(protoPath, language, outputPath);

            // Run protoc
            var processResult = await RunProtocAsync(protocPath, args);

            if (processResult.ExitCode == 0)
            {
                result.Success = true;
                result.GeneratedFiles = DiscoverGeneratedFiles(outputPath, language);

                // Post-process generated files
                await PostProcessFilesAsync(result.GeneratedFiles, language);
            }
            else
            {
                result.Success = false;
                result.Error = processResult.StandardError;
            }
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Error = ex.Message;
            _logger.LogError(ex, "Failed to compile proto for {Language}", language);
        }

        return result;
    }

    private List<string> GetProtocArguments(string protoPath, Language language, string outputPath)
    {
        var args = new List<string>
        {
            $"--proto_path={Path.GetDirectoryName(protoPath)}",
            $"--proto_path={_options.WellKnownTypesPath}",
        };

        // Add custom proto paths
        foreach (var includePath in _options.IncludePaths)
        {
            args.Add($"--proto_path={includePath}");
        }

        // Language-specific arguments
        switch (language)
        {
            case Language.CSharp:
                args.Add($"--csharp_out={outputPath}");
                args.Add("--csharp_opt=file_extension=.g.cs");
                args.Add($"--grpc_out={outputPath}");
                args.Add("--grpc_opt=no_server=true"); // Only generate client/types
                args.Add($"--plugin=protoc-gen-grpc={_options.GrpcCSharpPlugin}");
                break;

            case Language.Swift:
                args.Add($"--swift_out={outputPath}");
                args.Add("--swift_opt=Visibility=Public");
                args.Add("--swift_opt=FileNaming=DropPath");
                args.Add($"--grpc-swift_out={outputPath}");
                args.Add("--grpc-swift_opt=Client=false,Server=false"); // Only types
                args.Add($"--plugin=protoc-gen-grpc-swift={_options.GrpcSwiftPlugin}");
                break;

            case Language.Kotlin:
                args.Add($"--kotlin_out={outputPath}");
                args.Add($"--grpckt_out={outputPath}");
                args.Add("--grpckt_opt=mode=lite"); // Android-friendly
                args.Add($"--plugin=protoc-gen-grpckt={_options.GrpcKotlinPlugin}");
                break;

            case Language.Java:
                args.Add($"--java_out={outputPath}");
                args.Add("--java_opt=lite"); // Android-friendly
                args.Add($"--grpc-java_out={outputPath}");
                args.Add($"--plugin=protoc-gen-grpc-java={_options.GrpcJavaPlugin}");
                break;

            case Language.TypeScript:
                args.Add($"--ts_out={outputPath}");
                args.Add("--ts_opt=esModuleInterop=true");
                args.Add($"--grpc-web_out=import_style=typescript,mode=grpcweb:{outputPath}");
                args.Add($"--plugin=protoc-gen-ts={_options.TypeScriptPlugin}");
                break;

            case Language.Go:
                args.Add($"--go_out={outputPath}");
                args.Add("--go_opt=paths=source_relative");
                args.Add($"--go-grpc_out={outputPath}");
                args.Add("--go-grpc_opt=paths=source_relative");
                break;

            case Language.Python:
                args.Add($"--python_out={outputPath}");
                args.Add($"--grpc_python_out={outputPath}");
                break;

            case Language.Rust:
                args.Add($"--rust_out={outputPath}");
                args.Add($"--plugin=protoc-gen-rust={_options.RustPlugin}");
                break;
        }

        // Add proto files
        args.Add(protoPath);

        // Add dependencies
        var dependencies = DiscoverProtoDependencies(protoPath);
        args.AddRange(dependencies);

        return args;
    }

    private async Task<string> EnsureProtocAsync()
    {
        // Try to find protoc in common locations
        var protocPaths = new[]
        {
            _options.ProtocPath,
            "protoc",
            "/usr/local/bin/protoc",
            "/opt/homebrew/bin/protoc",
            "C:\\tools\\protoc\\bin\\protoc.exe"
        }.Where(p => !string.IsNullOrEmpty(p));

        foreach (var path in protocPaths)
        {
            try
            {
                var result = await RunCommandAsync(path, "--version");
                if (result.ExitCode == 0)
                {
                    _logger.LogInformation("Found protoc at {Path}", path);
                    return path;
                }
            }
            catch
            {
                // Continue searching
            }
        }

        // Download protoc if not found
        return await DownloadProtocAsync();
    }

    private async Task<string> DownloadProtocAsync()
    {
        var protocDir = Path.Combine(_options.ToolsDirectory, "protoc");
        var protocPath = Path.Combine(protocDir, OperatingSystem.IsWindows() ? "protoc.exe" : "protoc");

        if (File.Exists(protocPath))
        {
            return protocPath;
        }

        _logger.LogInformation("Downloading protoc...");

        // Determine platform and architecture
        var platform = OperatingSystem.IsWindows() ? "win64" : 
                      OperatingSystem.IsMacOS() ? "osx-x86_64" : 
                      "linux-x86_64";

        var version = "25.2";
        var downloadUrl = $"https://github.com/protocolbuffers/protobuf/releases/download/v{version}/protoc-{version}-{platform}.zip";

        using var httpClient = new HttpClient();
        var zipBytes = await httpClient.GetByteArrayAsync(downloadUrl);
        
        var tempZipPath = Path.GetTempFileName();
        await File.WriteAllBytesAsync(tempZipPath, zipBytes);

        Directory.CreateDirectory(protocDir);
        System.IO.Compression.ZipFile.ExtractToDirectory(tempZipPath, protocDir);
        File.Delete(tempZipPath);

        // Make executable on Unix systems
        if (!OperatingSystem.IsWindows())
        {
            await RunCommandAsync("chmod", $"+x {protocPath}");
        }

        _logger.LogInformation("Downloaded protoc to {Path}", protocPath);
        return protocPath;
    }

    private async Task<ProcessResult> RunProtocAsync(string protocPath, List<string> args)
    {
        return await RunCommandAsync(protocPath, string.Join(" ", args.Select(a => $"\"{a}\"")));
    }

    private async Task<ProcessResult> RunCommandAsync(string command, string arguments)
    {
        var processInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = new Process { StartInfo = processInfo };
        process.Start();

        var stdout = await process.StandardOutput.ReadToEndAsync();
        var stderr = await process.StandardError.ReadToEndAsync();

        await process.WaitForExitAsync();

        return new ProcessResult
        {
            ExitCode = process.ExitCode,
            StandardOutput = stdout,
            StandardError = stderr
        };
    }

    private List<string> DiscoverGeneratedFiles(string outputPath, Language language)
    {
        if (!Directory.Exists(outputPath))
            return new List<string>();

        var patterns = language switch
        {
            Language.CSharp => new[] { "*.g.cs", "*Grpc.cs" },
            Language.Swift => new[] { "*.pb.swift", "*.grpc.swift" },
            Language.Kotlin => new[] { "*.kt" },
            Language.Java => new[] { "*.java" },
            Language.TypeScript => new[] { "*.ts", "*.d.ts" },
            Language.Go => new[] { "*.pb.go", "*_grpc.pb.go" },
            Language.Python => new[] { "*_pb2.py", "*_pb2_grpc.py" },
            Language.Rust => new[] { "*.rs" },
            _ => new[] { "*.*" }
        };

        var files = new List<string>();
        foreach (var pattern in patterns)
        {
            files.AddRange(Directory.GetFiles(outputPath, pattern, SearchOption.AllDirectories));
        }

        return files;
    }

    private List<string> DiscoverProtoDependencies(string protoPath)
    {
        var dependencies = new List<string>();
        var protoDir = Path.GetDirectoryName(protoPath);
        
        if (string.IsNullOrEmpty(protoDir))
            return dependencies;

        // Find all proto files in the same directory
        var protoFiles = Directory.GetFiles(protoDir, "*.proto")
            .Where(f => f != protoPath)
            .ToList();

        dependencies.AddRange(protoFiles);

        return dependencies;
    }

    private async Task PostProcessFilesAsync(List<string> files, Language language)
    {
        foreach (var file in files)
        {
            switch (language)
            {
                case Language.Swift:
                    await PostProcessSwiftFileAsync(file);
                    break;

                case Language.Kotlin:
                    await PostProcessKotlinFileAsync(file);
                    break;

                case Language.CSharp:
                    await PostProcessCSharpFileAsync(file);
                    break;
            }
        }
    }

    private async Task PostProcessSwiftFileAsync(string filePath)
    {
        var content = await File.ReadAllTextAsync(filePath);

        // Add package imports
        content = "import Foundation\nimport SwiftProtobuf\nimport GRPC\n\n" + content;

        // Add Codable conformance
        content = Regex.Replace(
            content,
            @"struct (\w+):\s*SwiftProtobuf\.Message",
            "struct $1: SwiftProtobuf.Message, Codable");

        // Add convenience initializers
        content = AddSwiftConvenienceInit(content);

        await File.WriteAllTextAsync(filePath, content);
    }

    private async Task PostProcessKotlinFileAsync(string filePath)
    {
        var content = await File.ReadAllTextAsync(filePath);

        // Add kotlinx.serialization
        content = Regex.Replace(
            content,
            @"class (\w+) :",
            "@kotlinx.serialization.Serializable\nclass $1 :");

        // Add data class modifiers where appropriate
        content = AddKotlinDataClassModifiers(content);

        await File.WriteAllTextAsync(filePath, content);
    }

    private async Task PostProcessCSharpFileAsync(string filePath)
    {
        var content = await File.ReadAllTextAsync(filePath);

        // Add nullable reference types
        if (!content.Contains("#nullable enable"))
        {
            content = "#nullable enable\n\n" + content;
        }

        // Add System.Text.Json attributes if needed
        content = AddJsonAttributes(content);

        await File.WriteAllTextAsync(filePath, content);
    }

    private string AddSwiftConvenienceInit(string content)
    {
        // Add convenience initializers for Swift structs
        // This is a simplified implementation
        return content;
    }

    private string AddKotlinDataClassModifiers(string content)
    {
        // Add data class modifiers where appropriate
        // This is a simplified implementation
        return content;
    }

    private string AddJsonAttributes(string content)
    {
        // Add System.Text.Json attributes
        // This is a simplified implementation
        return content;
    }
}

/// <summary>
/// Compilation result
/// </summary>
public class CompilationResult
{
    public Language Language { get; init; }
    public bool Success { get; set; }
    public string? Error { get; set; }
    public string OutputPath { get; init; } = "";
    public List<string> GeneratedFiles { get; set; } = new();
}

public enum Language
{
    CSharp,
    Swift,
    Kotlin,
    Java,
    TypeScript,
    Go,
    Python,
    Rust
}

public class ProtocOptions
{
    public string ProtocPath { get; set; } = "protoc";
    public string WellKnownTypesPath { get; set; } = "";
    public List<string> IncludePaths { get; set; } = new();
    public string ToolsDirectory { get; set; } = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".axiom-tools");
    
    // Plugin paths
    public string GrpcCSharpPlugin { get; set; } = "grpc_csharp_plugin";
    public string GrpcSwiftPlugin { get; set; } = "protoc-gen-grpc-swift";
    public string GrpcKotlinPlugin { get; set; } = "protoc-gen-grpckt";
    public string GrpcJavaPlugin { get; set; } = "protoc-gen-grpc-java";
    public string TypeScriptPlugin { get; set; } = "protoc-gen-ts";
    public string RustPlugin { get; set; } = "protoc-gen-rust";
}

public class ProcessResult
{
    public int ExitCode { get; set; }
    public string StandardOutput { get; set; } = "";
    public string StandardError { get; set; } = "";
}