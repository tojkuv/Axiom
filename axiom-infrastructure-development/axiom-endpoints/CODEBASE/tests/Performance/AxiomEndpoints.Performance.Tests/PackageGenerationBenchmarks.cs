using System.Diagnostics;
using System.Text;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Order;

namespace AxiomEndpoints.Performance.Tests;

/// <summary>
/// Performance benchmarks for package generation converted from generate-packages.sh
/// Tests proto generation, multi-language compilation, and package creation performance
/// </summary>
[MemoryDiagnoser]
[Orderer(SummaryOrderPolicy.FastestToSlowest)]
[SimpleJob(RuntimeMoniker.Net90)]
public class PackageGenerationBenchmarks
{
    private readonly string _tempDirectory = Path.GetTempPath();
    private readonly string _outputDirectory;

    public PackageGenerationBenchmarks()
    {
        _outputDirectory = Path.Combine(_tempDirectory, "axiom_benchmarks", Guid.NewGuid().ToString());
        Directory.CreateDirectory(_outputDirectory);
    }

    [GlobalSetup]
    public void Setup()
    {
        // Ensure output directory is clean
        if (Directory.Exists(_outputDirectory))
        {
            Directory.Delete(_outputDirectory, true);
        }
        Directory.CreateDirectory(_outputDirectory);
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        // Clean up benchmark artifacts
        if (Directory.Exists(_outputDirectory))
        {
            Directory.Delete(_outputDirectory, true);
        }
    }

    [Benchmark]
    public async Task GenerateProtoFiles_LargeAssembly_Performance()
    {
        // Benchmark scenario from generate-packages.sh lines 27-36
        var outputPath = Path.Combine(_outputDirectory, "proto_benchmark");
        Directory.CreateDirectory(outputPath);

        var protoFiles = CreateSampleProtoFiles();
        
        // Simulate proto file generation
        foreach (var protoFile in protoFiles)
        {
            var filePath = Path.Combine(outputPath, protoFile.Path);
            await File.WriteAllTextAsync(filePath, protoFile.Content);
        }
        
        // Simulate proto compilation
        await SimulateProtoCompilationAsync(protoFiles);
    }

    [Benchmark]
    public async Task GenerateSwiftPackage_FullStructure_Performance()
    {
        // Benchmark scenario from generate-packages.sh lines 189-228
        var outputPath = Path.Combine(_outputDirectory, "swift_benchmark");
        Directory.CreateDirectory(outputPath);

        var packageStructure = CreateSwiftPackageStructure();
        
        // Simulate Swift package generation
        foreach (var file in packageStructure.Files)
        {
            var filePath = Path.Combine(outputPath, file.Key);
            var directory = Path.GetDirectoryName(filePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }
            await File.WriteAllTextAsync(filePath, file.Value);
        }
    }

    [Benchmark]
    public async Task GenerateKotlinPackage_FullStructure_Performance()
    {
        // Benchmark scenario from generate-packages.sh lines 260-300
        var outputPath = Path.Combine(_outputDirectory, "kotlin_benchmark");
        Directory.CreateDirectory(outputPath);

        var packageStructure = CreateKotlinPackageStructure();
        
        // Simulate Kotlin package generation
        foreach (var file in packageStructure.Files)
        {
            var filePath = Path.Combine(outputPath, file.Key);
            var directory = Path.GetDirectoryName(filePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }
            await File.WriteAllTextAsync(filePath, file.Value);
        }
    }

    [Benchmark]
    public async Task GenerateCSharpNuGetPackage_FullStructure_Performance()
    {
        // Benchmark scenario from generate-packages.sh lines 333-389
        var outputPath = Path.Combine(_outputDirectory, "csharp_benchmark");
        Directory.CreateDirectory(outputPath);

        var packageInfo = new PackageInfo(
            "ProtoGenSample.Types",
            "1.0.0",
            ["Axiom Team"],
            "Axiom",
            "Generated gRPC types for ProtoGenSample",
            ["grpc", "protobuf", "axiom"]
        );

        // Simulate C# package generation
        var csprojContent = CreateCSharpProjectFile(packageInfo);
        var readmeContent = CreateReadmeFiles(packageInfo);
        
        await File.WriteAllTextAsync(Path.Combine(outputPath, "ProtoGenSample.Types.csproj"), csprojContent);
        await File.WriteAllTextAsync(Path.Combine(outputPath, "README.md"), readmeContent["README.md"]);
        
        // Simulate generated C# types
        var typesContent = "// Generated C# types from proto files";
        await File.WriteAllTextAsync(Path.Combine(outputPath, "GeneratedTypes.cs"), typesContent);
    }

    [Benchmark]
    public async Task GenerateAllLanguagePackages_ConcurrentExecution_Performance()
    {
        // Benchmark scenario for concurrent multi-language generation
        var outputPath = Path.Combine(_outputDirectory, "multi_lang_benchmark");
        Directory.CreateDirectory(outputPath);

        var swiftPath = Path.Combine(outputPath, "swift");
        var kotlinPath = Path.Combine(outputPath, "kotlin");
        var csharpPath = Path.Combine(outputPath, "csharp");
        
        Directory.CreateDirectory(swiftPath);
        Directory.CreateDirectory(kotlinPath);
        Directory.CreateDirectory(csharpPath);

        var swiftTask = GenerateSwiftPackageAsync(swiftPath);
        var kotlinTask = GenerateKotlinPackageAsync(kotlinPath);
        var csharpTask = GenerateCSharpPackageAsync(csharpPath);

        await Task.WhenAll(swiftTask, kotlinTask, csharpTask);
    }

    private async Task GenerateSwiftPackageAsync(string outputPath)
    {
        var packageStructure = CreateSwiftPackageStructure();
        foreach (var file in packageStructure.Files)
        {
            var filePath = Path.Combine(outputPath, file.Key);
            var directory = Path.GetDirectoryName(filePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }
            await File.WriteAllTextAsync(filePath, file.Value);
        }
    }

    private async Task GenerateKotlinPackageAsync(string outputPath)
    {
        var packageStructure = CreateKotlinPackageStructure();
        foreach (var file in packageStructure.Files)
        {
            var filePath = Path.Combine(outputPath, file.Key);
            var directory = Path.GetDirectoryName(filePath);
            if (!string.IsNullOrEmpty(directory))
            {
                Directory.CreateDirectory(directory);
            }
            await File.WriteAllTextAsync(filePath, file.Value);
        }
    }

    private async Task GenerateCSharpPackageAsync(string outputPath)
    {
        var packageInfo = new PackageInfo("ProtoGenSample.Types", "1.0.0", ["Axiom Team"], "Axiom", "C# gRPC types", ["grpc", "protobuf"]);
        var csprojContent = CreateCSharpProjectFile(packageInfo);
        var readmeContent = CreateReadmeFiles(packageInfo);
        
        await File.WriteAllTextAsync(Path.Combine(outputPath, "ProtoGenSample.Types.csproj"), csprojContent);
        await File.WriteAllTextAsync(Path.Combine(outputPath, "README.md"), readmeContent["README.md"]);
    }

    [Benchmark]
    [Arguments(10)]
    [Arguments(50)]
    [Arguments(100)]
    public async Task GenerateProtoFiles_ScaleTest_Performance(int numberOfTypes)
    {
        // Scale testing with varying numbers of types
        var outputPath = Path.Combine(_tempDirectory, $"scale_test_{numberOfTypes}");
        Directory.CreateDirectory(outputPath);

        var protoFiles = CreateScaledProtoFiles(numberOfTypes);
        
        var stopwatch = Stopwatch.StartNew();
        
        // Simulate processing multiple proto files
        foreach (var protoFile in protoFiles)
        {
            await ProcessProtoFileAsync(protoFile.Path, protoFile.Content);
        }
        
        stopwatch.Stop();
        
        // Cleanup
        if (Directory.Exists(outputPath))
        {
            Directory.Delete(outputPath, true);
        }
    }

    [Benchmark]
    public async Task ParseAssemblyTypes_LargeAssembly_Performance()
    {
        // Benchmark type parsing and analysis
        var types = CreateMockAssemblyTypes(100);
        
        var stopwatch = Stopwatch.StartNew();
        
        var protoTypes = new List<ProtoType>();
        foreach (var type in types)
        {
            var protoType = ConvertToProtoType(type);
            protoTypes.Add(protoType);
        }
        
        stopwatch.Stop();
        
        await Task.CompletedTask; // Async signature for consistency
    }

    [Benchmark]
    public void CreatePackageManifests_AllLanguages_Performance()
    {
        // Benchmark package manifest creation
        var packageInfo = new PackageInfo(
            "TestPackage",
            "1.0.0",
            ["Test Author"],
            "Test Company",
            "Test Description",
            ["test", "benchmark"]
        );

        var stopwatch = Stopwatch.StartNew();
        
        // Generate all package manifests
        var swiftManifest = CreateSwiftPackageManifest(packageInfo);
        var kotlinManifest = CreateKotlinBuildGradle(packageInfo);
        var csharpManifest = CreateCSharpProjectFile(packageInfo);
        var readmeFiles = CreateReadmeFiles(packageInfo);
        
        stopwatch.Stop();
    }

    // Helper methods for benchmarking
    private static async Task SimulateProtoCompilationAsync(List<ProtoFileInfo> protoFiles)
    {
        // Simulate proto compilation time
        foreach (var protoFile in protoFiles)
        {
            await ProcessProtoFileAsync(protoFile.Path, protoFile.Content);
        }
    }

    private static List<ProtoFileInfo> CreateSampleProtoFiles()
    {
        return new List<ProtoFileInfo>
        {
            new("simple.proto", CreateSimpleProtoContent()),
            new("service.proto", CreateServiceProtoContent()),
            new("complex.proto", CreateComplexProtoContent())
        };
    }

    private static List<ProtoFileInfo> CreateScaledProtoFiles(int numberOfTypes)
    {
        var files = new List<ProtoFileInfo>();
        
        for (int i = 0; i < numberOfTypes; i++)
        {
            files.Add(new ProtoFileInfo(
                $"type_{i}.proto",
                CreateScaledProtoContent(i)
            ));
        }
        
        return files;
    }

    private static string CreateSimpleProtoContent()
    {
        return """
            syntax = "proto3";
            package benchmark;
            
            message TestMessage {
                int32 id = 1;
                string name = 2;
                repeated string tags = 3;
            }
            """;
    }

    private static string CreateServiceProtoContent()
    {
        return """
            syntax = "proto3";
            package benchmark;
            
            service TestService {
                rpc GetTest(GetTestRequest) returns (TestResponse);
                rpc ListTests(ListTestRequest) returns (TestListResponse);
            }
            
            message GetTestRequest { int32 id = 1; }
            message TestResponse { string data = 1; }
            message ListTestRequest { int32 page = 1; }
            message TestListResponse { repeated TestResponse items = 1; }
            """;
    }

    private static string CreateComplexProtoContent()
    {
        return """
            syntax = "proto3";
            package benchmark;
            
            message ComplexMessage {
                map<string, string> metadata = 1;
                repeated NestedMessage nested = 2;
                oneof value {
                    string text_value = 3;
                    int32 number_value = 4;
                }
            }
            
            message NestedMessage {
                google.protobuf.Timestamp created_at = 1;
                optional string description = 2;
            }
            """;
    }

    private static string CreateScaledProtoContent(int index)
    {
        return $$"""
            syntax = "proto3";
            package benchmark;
            
            message ScaledMessage{{index}} {
                int32 id = 1;
                string name_{{index}} = 2;
                repeated int32 values_{{index}} = 3;
                map<string, string> properties_{{index}} = 4;
            }
            """;
    }

    private static List<Type> CreateMockAssemblyTypes(int count)
    {
        // Mock assembly types for benchmarking
        return Enumerable.Range(0, count)
            .Select(i => typeof(object)) // Simplified for benchmarking
            .ToList();
    }

    private static ProtoType ConvertToProtoType(Type type)
    {
        // Simplified proto type conversion for benchmarking
        return new ProtoType(
            type.Name,
            type.Namespace ?? "default",
            new List<ProtoField>(),
            ProtoTypeKind.Message
        );
    }

    private static async Task ProcessProtoFileAsync(string path, string content)
    {
        // Simulate proto file processing
        await Task.Delay(1, CancellationToken.None);
        var lines = content.Split('\n');
        var processedContent = string.Join('\n', lines.Where(l => !string.IsNullOrWhiteSpace(l)));
    }

    private static PackageStructure CreateSwiftPackageStructure()
    {
        return new PackageStructure(
            "ProtoGenSampleSwift",
            new Dictionary<string, string>
            {
                ["Package.swift"] = "// Swift package manifest",
                ["Sources/ProtoGenSampleSwift/Types.swift"] = "// Generated Swift types",
                ["README.md"] = "# ProtoGenSampleSwift"
            }
        );
    }

    private static PackageStructure CreateKotlinPackageStructure()
    {
        return new PackageStructure(
            "protogensample-kotlin",
            new Dictionary<string, string>
            {
                ["build.gradle.kts"] = "// Kotlin build script",
                ["src/main/kotlin/Types.kt"] = "// Generated Kotlin types",
                ["README.md"] = "# protogensample-kotlin"
            }
        );
    }

    private static string CreateSwiftPackageManifest(PackageInfo info)
    {
        return $"// Swift package manifest for {info.Name}";
    }

    private static string CreateKotlinBuildGradle(PackageInfo info)
    {
        return $"// Kotlin build.gradle.kts for {info.Name}";
    }

    private static string CreateCSharpProjectFile(PackageInfo info)
    {
        return $"<!-- C# .csproj for {info.Name} -->";
    }

    private static Dictionary<string, string> CreateReadmeFiles(PackageInfo info)
    {
        return new Dictionary<string, string>
        {
            ["README.md"] = $"# {info.Name}\n\n{info.Description}",
            ["CHANGELOG.md"] = $"# Changelog\n\n## {info.Version}\n- Initial release"
        };
    }
}

// Mock types for benchmarking
public record ProtoFileInfo(string Path, string Content);

public record PackageInfo(
    string Name,
    string Version,
    IReadOnlyList<string> Authors,
    string Company,
    string Description,
    IReadOnlyList<string> Tags
);

public record ProtoType(
    string Name,
    string Namespace,
    IReadOnlyList<ProtoField> Fields,
    ProtoTypeKind Kind
);

public record ProtoField(string Name, string Type, int Number);

public enum ProtoTypeKind { Message, Enum, Service }

public record PackageStructure(string Name, IReadOnlyDictionary<string, string> Files);

public record ProtoGenerationResult(bool Success, IReadOnlyList<string> Errors, IReadOnlyList<ProtoFileInfo> GeneratedFiles);

public record PackageGenerationResult(bool Success, PackageStructure Package);

public record NuGetPackageResult(bool Success, string PackageFileName);

public enum PackageLanguage { Swift, Kotlin, CSharp }