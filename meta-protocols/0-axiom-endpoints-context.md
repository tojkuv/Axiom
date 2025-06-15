Axiom Endpoints - gRPC Type Generation System
Objective
Implement a comprehensive gRPC type generation system that extracts domain models from Axiom Endpoints and generates language-specific type packages for Swift, Kotlin, C#, and other ecosystems, enabling teams to use gRPC-generated types as their canonical domain models.
Current State
You have completed:

✅ Type-safe endpoints with full gRPC support
✅ Source generation for proto files
✅ Protocol unification (HTTP/gRPC)
✅ Event-driven architecture
✅ All other framework features

Goal
Create a type generation system that:

Extracts domain models from C# endpoint definitions
Generates comprehensive .proto files with all type information
Runs protoc to generate language-specific types
Packages generated types for each ecosystem (Swift Package, Maven, NuGet)
Versions and publishes type packages automatically
Preserves documentation and validation rules
Handles complex types including generics, collections, and nested types
Supports incremental updates without breaking changes
Enables direct usage as domain models in client applications
Maintains backward compatibility through proto versioning

Implementation Plan
Phase 1: Proto Generation from C# Types
1. Enhanced Proto Generator
csharp// src/AxiomEndpoints.ProtoGen/Core/ProtoTypeGenerator.cs
namespace AxiomEndpoints.ProtoGen.Core;

/// <summary>
/// Generates comprehensive proto files from C# types
/// </summary>
public class ProtoTypeGenerator
{
    private readonly ProtoGeneratorOptions _options;
    private readonly TypeAnalyzer _typeAnalyzer;
    private readonly Dictionary<Type, ProtoMessage> _processedTypes = new();

    public ProtoTypeGenerator(ProtoGeneratorOptions options)
    {
        _options = options;
        _typeAnalyzer = new TypeAnalyzer();
    }

    public async Task<ProtoPackage> GenerateProtoPackageAsync(Assembly assembly)
    {
        var package = new ProtoPackage
        {
            Name = _options.PackageName ?? assembly.GetName().Name!.ToLowerInvariant(),
            CSharpNamespace = assembly.GetName().Name,
            Version = assembly.GetName().Version?.ToString() ?? "1.0.0",
            Options = new ProtoOptions
            {
                JavaPackage = $"com.{_options.Organization ?? "company"}.{package.Name}",
                JavaMultipleFiles = true,
                SwiftPrefix = _options.SwiftPrefix ?? "",
                ObjcClassPrefix = _options.ObjcClassPrefix ?? "AX",
                GoPackage = $"github.com/{_options.Organization ?? "company"}/{package.Name}"
            }
        };

        // Extract all types used in endpoints
        var endpointTypes = ExtractEndpointTypes(assembly);
        var eventTypes = ExtractEventTypes(assembly);
        var domainTypes = ExtractDomainTypes(assembly);

        // Process all types
        foreach (var type in endpointTypes.Concat(eventTypes).Concat(domainTypes).Distinct())
        {
            ProcessType(type, package);
        }

        // Generate service definitions from endpoints
        GenerateServices(assembly, package);

        // Add well-known types imports
        AddWellKnownImports(package);

        // Sort messages by dependency order
        package.Messages = SortByDependency(package.Messages);

        return package;
    }

    private void ProcessType(Type type, ProtoPackage package)
    {
        if (_processedTypes.ContainsKey(type) || ShouldSkipType(type))
            return;

        if (type.IsEnum)
        {
            var protoEnum = GenerateEnum(type);
            package.Enums.Add(protoEnum);
            _processedTypes[type] = protoEnum;
        }
        else if (IsCollectionType(type))
        {
            // Process element type
            var elementType = GetElementType(type);
            ProcessType(elementType, package);
        }
        else if (type.IsClass || type.IsValueType)
        {
            var protoMessage = GenerateMessage(type, package);
            package.Messages.Add(protoMessage);
            _processedTypes[type] = protoMessage;
        }
    }

    private ProtoMessage GenerateMessage(Type type, ProtoPackage package)
    {
        var message = new ProtoMessage
        {
            Name = GetProtoMessageName(type),
            CSharpType = type.FullName!,
            Documentation = ExtractXmlDocumentation(type)
        };

        // Handle inheritance
        if (type.BaseType != null && type.BaseType != typeof(object) &&
            !type.BaseType.IsAbstract && !IsSystemType(type.BaseType))
        {
            ProcessType(type.BaseType, package);
            message.BaseType = GetProtoMessageName(type.BaseType);
        }

        // Process properties
        var properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Where(p => p.CanRead && !p.IsSpecialName);

        int fieldNumber = 1;
        foreach (var property in properties)
        {
            var field = GenerateField(property, fieldNumber++, package);
            if (field != null)
            {
                message.Fields.Add(field);
            }
        }

        // Add metadata for special types
        if (IsTimestampType(type))
        {
            message.Options.Add("(axiom.timestamp) = true");
        }

        if (IsDomainEvent(type))
        {
            message.Options.Add("(axiom.domain_event) = true");
        }

        // Handle generic types
        if (type.IsGenericType)
        {
            message.IsGeneric = true;
            message.GenericParameters = type.GetGenericArguments()
                .Select(t => t.Name)
                .ToList();
        }

        return message;
    }

    private ProtoField? GenerateField(PropertyInfo property, int fieldNumber, ProtoPackage package)
    {
        var propertyType = property.PropertyType;
        var field = new ProtoField
        {
            Name = ToSnakeCase(property.Name),
            CSharpName = property.Name,
            FieldNumber = fieldNumber,
            Documentation = ExtractXmlDocumentation(property)
        };

        // Handle nullable types
        if (Nullable.GetUnderlyingType(propertyType) != null)
        {
            propertyType = Nullable.GetUnderlyingType(propertyType)!;
            field.IsOptional = true;
        }

        // Handle collections
        if (IsCollectionType(propertyType))
        {
            field.IsRepeated = true;
            propertyType = GetElementType(propertyType);

            if (IsDictionaryType(property.PropertyType))
            {
                // Handle as map
                var keyType = property.PropertyType.GetGenericArguments()[0];
                var valueType = property.PropertyType.GetGenericArguments()[1];
                field.IsMap = true;
                field.ProtoType = $"map<{GetProtoType(keyType)}, {GetProtoType(valueType)}>";

                // Process value type if custom
                if (!IsWellKnownType(valueType))
                {
                    ProcessType(valueType, package);
                }

                return field;
            }
        }

        // Get proto type
        field.ProtoType = GetProtoType(propertyType);

        // Process custom types
        if (!IsWellKnownType(propertyType))
        {
            ProcessType(propertyType, package);
        }

        // Add field options
        AddFieldOptions(field, property);

        return field;
    }

    private void AddFieldOptions(ProtoField field, PropertyInfo property)
    {
        // Add validation rules
        var validationAttributes = property.GetCustomAttributes()
            .Where(a => IsValidationAttribute(a))
            .ToList();

        foreach (var attr in validationAttributes)
        {
            switch (attr)
            {
                case RequiredAttribute:
                    field.Options.Add("(axiom.required) = true");
                    break;

                case StringLengthAttribute stringLength:
                    field.Options.Add($"(axiom.min_length) = {stringLength.MinimumLength}");
                    field.Options.Add($"(axiom.max_length) = {stringLength.MaximumLength}");
                    break;

                case RangeAttribute range:
                    field.Options.Add($"(axiom.min_value) = {range.Minimum}");
                    field.Options.Add($"(axiom.max_value) = {range.Maximum}");
                    break;

                case RegularExpressionAttribute regex:
                    field.Options.Add($"(axiom.pattern) = \"{EscapeString(regex.Pattern)}\"");
                    break;
            }
        }

        // Add serialization options
        var jsonProperty = property.GetCustomAttribute<JsonPropertyNameAttribute>();
        if (jsonProperty != null)
        {
            field.Options.Add($"json_name = \"{jsonProperty.Name}\"");
        }

        // Mark as deprecated if needed
        if (property.GetCustomAttribute<ObsoleteAttribute>() != null)
        {
            field.Options.Add("deprecated = true");
        }
    }

    private string GetProtoType(Type type)
    {
        // Well-known proto types
        var typeMap = new Dictionary<Type, string>
        {
            [typeof(bool)] = "bool",
            [typeof(int)] = "int32",
            [typeof(uint)] = "uint32",
            [typeof(long)] = "int64",
            [typeof(ulong)] = "uint64",
            [typeof(float)] = "float",
            [typeof(double)] = "double",
            [typeof(string)] = "string",
            [typeof(byte[])] = "bytes",
            [typeof(DateTime)] = "google.protobuf.Timestamp",
            [typeof(DateTimeOffset)] = "google.protobuf.Timestamp",
            [typeof(TimeSpan)] = "google.protobuf.Duration",
            [typeof(Guid)] = "string", // With format annotation
            [typeof(decimal)] = "axiom.Decimal", // Custom decimal type
            [typeof(DateOnly)] = "google.type.Date",
            [typeof(TimeOnly)] = "google.type.TimeOfDay"
        };

        if (typeMap.TryGetValue(type, out var protoType))
            return protoType;

        if (type.IsEnum)
            return GetProtoMessageName(type);

        if (type.IsGenericType)
        {
            var genericDef = type.GetGenericTypeDefinition();
            if (genericDef == typeof(List<>) || genericDef == typeof(IList<>) ||
                genericDef == typeof(IEnumerable<>) || genericDef == typeof(HashSet<>))
            {
                // Handled by IsRepeated
                return GetProtoType(type.GetGenericArguments()[0]);
            }

            if (genericDef == typeof(Dictionary<,>) || genericDef == typeof(IDictionary<,>))
            {
                // Handled as map
                var keyType = type.GetGenericArguments()[0];
                var valueType = type.GetGenericArguments()[1];
                return $"map<{GetProtoType(keyType)}, {GetProtoType(valueType)}>";
            }

            // Handle other generic types
            return GetProtoMessageName(type);
        }

        return GetProtoMessageName(type);
    }
}

/// <summary>
/// Proto package representation
/// </summary>
public class ProtoPackage
{
    public required string Name { get; init; }
    public required string CSharpNamespace { get; init; }
    public required string Version { get; init; }
    public required ProtoOptions Options { get; init; }
    public List<string> Imports { get; } = new();
    public List<ProtoMessage> Messages { get; set; } = new();
    public List<ProtoEnum> Enums { get; } = new();
    public List<ProtoService> Services { get; } = new();
}

public class ProtoOptions
{
    public string? JavaPackage { get; set; }
    public bool JavaMultipleFiles { get; set; }
    public string? SwiftPrefix { get; set; }
    public string? ObjcClassPrefix { get; set; }
    public string? GoPackage { get; set; }
}
2. Proto File Writer
csharp// src/AxiomEndpoints.ProtoGen/Writers/ProtoFileWriter.cs
namespace AxiomEndpoints.ProtoGen.Writers;

/// <summary>
/// Writes proto packages to .proto files
/// </summary>
public class ProtoFileWriter
{
    private readonly ProtoWriterOptions _options;

    public ProtoFileWriter(ProtoWriterOptions options)
    {
        _options = options;
    }

    public async Task WritePackageAsync(ProtoPackage package, string outputPath)
    {
        // Create directory structure
        var baseDir = Path.Combine(outputPath, package.Name);
        Directory.CreateDirectory(baseDir);

        // Write main proto file
        var mainProtoPath = Path.Combine(baseDir, $"{package.Name}.proto");
        await WriteProtoFileAsync(mainProtoPath, package);

        // Write separate files for large messages if needed
        if (_options.SplitLargeFiles && package.Messages.Count > _options.MessagesPerFile)
        {
            await WriteSplitFilesAsync(package, baseDir);
        }

        // Write service proto files
        foreach (var service in package.Services)
        {
            var serviceProtoPath = Path.Combine(baseDir, $"{ToSnakeCase(service.Name)}_service.proto");
            await WriteServiceProtoAsync(serviceProtoPath, service, package);
        }

        // Write custom options file
        await WriteCustomOptionsAsync(Path.Combine(baseDir, "axiom_options.proto"));

        // Write build configuration files
        await WriteBuildConfigsAsync(package, baseDir);
    }

    private async Task WriteProtoFileAsync(string path, ProtoPackage package)
    {
        using var writer = new StreamWriter(path);

        // Header
        await writer.WriteLineAsync("// Generated by Axiom Endpoints");
        await writer.WriteLineAsync($"// Version: {package.Version}");
        await writer.WriteLineAsync($"// Generated at: {DateTime.UtcNow:O}");
        await writer.WriteLineAsync();

        // Syntax
        await writer.WriteLineAsync("syntax = \"proto3\";");
        await writer.WriteLineAsync();

        // Package
        await writer.WriteLineAsync($"package {package.Name};");
        await writer.WriteLineAsync();

        // Options
        if (!string.IsNullOrEmpty(package.Options.JavaPackage))
        {
            await writer.WriteLineAsync($"option java_package = \"{package.Options.JavaPackage}\";");
        }
        if (package.Options.JavaMultipleFiles)
        {
            await writer.WriteLineAsync("option java_multiple_files = true;");
        }
        if (!string.IsNullOrEmpty(package.Options.SwiftPrefix))
        {
            await writer.WriteLineAsync($"option swift_prefix = \"{package.Options.SwiftPrefix}\";");
        }
        if (!string.IsNullOrEmpty(package.Options.ObjcClassPrefix))
        {
            await writer.WriteLineAsync($"option objc_class_prefix = \"{package.Options.ObjcClassPrefix}\";");
        }
        if (!string.IsNullOrEmpty(package.Options.GoPackage))
        {
            await writer.WriteLineAsync($"option go_package = \"{package.Options.GoPackage}\";");
        }
        await writer.WriteLineAsync($"option csharp_namespace = \"{package.CSharpNamespace}.Grpc\";");
        await writer.WriteLineAsync();

        // Imports
        foreach (var import in package.Imports.Distinct().OrderBy(i => i))
        {
            await writer.WriteLineAsync($"import \"{import}\";");
        }

        if (package.Imports.Any())
        {
            await writer.WriteLineAsync();
        }

        // Enums
        foreach (var protoEnum in package.Enums)
        {
            await WriteEnumAsync(writer, protoEnum);
            await writer.WriteLineAsync();
        }

        // Messages
        foreach (var message in package.Messages)
        {
            await WriteMessageAsync(writer, message);
            await writer.WriteLineAsync();
        }
    }

    private async Task WriteMessageAsync(StreamWriter writer, ProtoMessage message)
    {
        // Documentation
        if (!string.IsNullOrEmpty(message.Documentation))
        {
            await WriteDocumentationAsync(writer, message.Documentation);
        }

        // Message definition
        await writer.WriteLineAsync($"message {message.Name} {{");

        // Options
        foreach (var option in message.Options)
        {
            await writer.WriteLineAsync($"  option {option};");
        }

        if (message.Options.Any())
        {
            await writer.WriteLineAsync();
        }

        // Fields
        foreach (var field in message.Fields)
        {
            // Field documentation
            if (!string.IsNullOrEmpty(field.Documentation))
            {
                await WriteDocumentationAsync(writer, field.Documentation, indent: "  ");
            }

            // Field definition
            var fieldDef = field.IsRepeated && !field.IsMap ? "repeated " : "";
            fieldDef += $"{field.ProtoType} {field.Name} = {field.FieldNumber}";

            // Field options
            if (field.Options.Any())
            {
                fieldDef += " [" + string.Join(", ", field.Options) + "]";
            }

            await writer.WriteLineAsync($"  {fieldDef};");
        }

        // Nested types
        if (message.NestedTypes.Any())
        {
            await writer.WriteLineAsync();
            foreach (var nested in message.NestedTypes)
            {
                await WriteNestedMessageAsync(writer, nested, indent: "  ");
            }
        }

        await writer.WriteLineAsync("}");
    }

    private async Task WriteCustomOptionsAsync(string path)
    {
        using var writer = new StreamWriter(path);

        await writer.WriteLineAsync("// Custom options for Axiom types");
        await writer.WriteLineAsync();
        await writer.WriteLineAsync("syntax = \"proto3\";");
        await writer.WriteLineAsync();
        await writer.WriteLineAsync("package axiom;");
        await writer.WriteLineAsync();
        await writer.WriteLineAsync("import \"google/protobuf/descriptor.proto\";");
        await writer.WriteLineAsync();

        // Field options
        await writer.WriteLineAsync("extend google.protobuf.FieldOptions {");
        await writer.WriteLineAsync("  bool required = 50001;");
        await writer.WriteLineAsync("  int32 min_length = 50002;");
        await writer.WriteLineAsync("  int32 max_length = 50003;");
        await writer.WriteLineAsync("  string pattern = 50004;");
        await writer.WriteLineAsync("  string min_value = 50005;");
        await writer.WriteLineAsync("  string max_value = 50006;");
        await writer.WriteLineAsync("}");
        await writer.WriteLineAsync();

        // Message options
        await writer.WriteLineAsync("extend google.protobuf.MessageOptions {");
        await writer.WriteLineAsync("  bool domain_event = 50101;");
        await writer.WriteLineAsync("  bool timestamp = 50102;");
        await writer.WriteLineAsync("  string aggregate = 50103;");
        await writer.WriteLineAsync("}");
        await writer.WriteLineAsync();

        // Custom decimal type
        await writer.WriteLineAsync("// Decimal type for financial calculations");
        await writer.WriteLineAsync("message Decimal {");
        await writer.WriteLineAsync("  // The whole units of the amount");
        await writer.WriteLineAsync("  int64 units = 1;");
        await writer.WriteLineAsync("  // Number of nano (10^-9) units of the amount");
        await writer.WriteLineAsync("  int32 nanos = 2;");
        await writer.WriteLineAsync("}");
    }
}
Phase 2: Language-Specific Type Generation
3. Protoc Integration
csharp// src/AxiomEndpoints.ProtoGen/Compilation/ProtocCompiler.cs
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
                args.Add("--grpc_out={outputPath}");
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
        }

        // Add proto files
        args.Add(protoPath);

        // Add dependencies
        var dependencies = DiscoverProtoDependencies(protoPath);
        args.AddRange(dependencies);

        return args;
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
Phase 3: Package Generation
4. Language-Specific Packagers
csharp// src/AxiomEndpoints.ProtoGen/Packaging/IPackageGenerator.cs
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
/// Swift Package generator
/// </summary>
public class SwiftPackageGenerator : IPackageGenerator
{
    public async Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata)
    {
        var packageDir = Path.Combine(compilation.OutputPath, metadata.PackageName);
        Directory.CreateDirectory(packageDir);

        // Create Package.swift
        var packageSwift = $@"// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: ""{metadata.PackageName}"",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: ""{metadata.PackageName}"",
            targets: [""{metadata.PackageName}""])
    ],
    dependencies: [
        .package(url: ""https://github.com/apple/swift-protobuf.git"", from: ""1.25.0""),
        .package(url: ""https://github.com/grpc/grpc-swift.git"", from: ""1.21.0"")
    ],
    targets: [
        .target(
            name: ""{metadata.PackageName}"",
            dependencies: [
                .product(name: ""SwiftProtobuf"", package: ""swift-protobuf""),
                .product(name: ""GRPC"", package: ""grpc-swift"")
            ],
            path: ""Sources""
        ),
        .testTarget(
            name: ""{metadata.PackageName}Tests"",
            dependencies: [""{metadata.PackageName}""],
            path: ""Tests""
        )
    ]
)";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "Package.swift"),
            packageSwift);

        // Create directory structure
        var sourcesDir = Path.Combine(packageDir, "Sources", metadata.PackageName);
        Directory.CreateDirectory(sourcesDir);

        // Copy generated files
        foreach (var file in compilation.GeneratedFiles)
        {
            var destPath = Path.Combine(sourcesDir, Path.GetFileName(file));
            File.Copy(file, destPath, overwrite: true);
        }

        // Generate convenience extensions
        await GenerateSwiftExtensionsAsync(sourcesDir, metadata);

        // Create README
        await GenerateReadmeAsync(packageDir, metadata, "Swift");

        // Create .gitignore
        await File.WriteAllTextAsync(
            Path.Combine(packageDir, ".gitignore"),
            @".DS_Store
/.build
/Packages
/*.xcodeproj
xcuserdata/
DerivedData/
.swiftpm/
");

        return new PackageResult
        {
            Success = true,
            PackagePath = packageDir,
            Language = Language.Swift
        };
    }

    private async Task GenerateSwiftExtensionsAsync(string sourcesDir, PackageMetadata metadata)
    {
        var extensions = $@"// Convenience extensions for {metadata.PackageName}
import Foundation
import SwiftProtobuf

// MARK: - Date Conversions
extension Google_Protobuf_Timestamp {{
    public init(date: Date) {{
        let timeInterval = date.timeIntervalSince1970
        self.seconds = Int64(timeInterval)
        self.nanos = Int32((timeInterval - Double(self.seconds)) * 1_000_000_000)
    }}

    public var date: Date {{
        return Date(timeIntervalSince1970: Double(seconds) + Double(nanos) / 1_000_000_000)
    }}
}}

// MARK: - JSON Coding
extension Message {{
    public func jsonData() throws -> Data {{
        return try JSONEncoder().encode(self)
    }}

    public static func from(jsonData: Data) throws -> Self {{
        return try JSONDecoder().decode(Self.self, from: jsonData)
    }}
}}

// MARK: - Validation
public protocol Validatable {{
    func validate() throws
}}

public enum ValidationError: Error {{
    case required(field: String)
    case invalidLength(field: String, min: Int?, max: Int?)
    case invalidRange(field: String, min: Any?, max: Any?)
    case invalidPattern(field: String, pattern: String)
}}
";

        await File.WriteAllTextAsync(
            Path.Combine(sourcesDir, "Extensions.swift"),
            extensions);
    }
}

/// <summary>
/// Kotlin/Maven package generator
/// </summary>
public class KotlinPackageGenerator : IPackageGenerator
{
    public async Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata)
    {
        var packageDir = Path.Combine(compilation.OutputPath, metadata.PackageName);
        Directory.CreateDirectory(packageDir);

        // Create Maven structure
        var srcDir = Path.Combine(packageDir, "src", "main", "kotlin",
            metadata.GroupId.Replace('.', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(srcDir);

        // Copy generated files
        foreach (var file in compilation.GeneratedFiles)
        {
            var destPath = Path.Combine(srcDir, Path.GetFileName(file));
            File.Copy(file, destPath, overwrite: true);
        }

        // Create pom.xml
        var pomXml = $@"<?xml version=""1.0"" encoding=""UTF-8""?>
<project xmlns=""http://maven.apache.org/POM/4.0.0""
         xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
         xsi:schemaLocation=""http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd"">
    <modelVersion>4.0.0</modelVersion>

    <groupId>{metadata.GroupId}</groupId>
    <artifactId>{metadata.PackageName}</artifactId>
    <version>{metadata.Version}</version>
    <packaging>jar</packaging>

    <name>{metadata.PackageName}</name>
    <description>gRPC types for {metadata.ServiceName}</description>

    <properties>
        <kotlin.version>1.9.22</kotlin.version>
        <grpc.version>1.61.0</grpc.version>
        <protobuf.version>3.25.2</protobuf.version>
        <grpc.kotlin.version>1.4.1</grpc.kotlin.version>
        <coroutines.version>1.7.3</coroutines.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
            <version>${{kotlin.version}}</version>
        </dependency>

        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-kotlin</artifactId>
            <version>${{protobuf.version}}</version>
        </dependency>

        <dependency>
            <groupId>io.grpc</groupId>
            <artifactId>grpc-kotlin-stub</artifactId>
            <version>${{grpc.kotlin.version}}</version>
        </dependency>

        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-coroutines-core</artifactId>
            <version>${{coroutines.version}}</version>
        </dependency>

        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-serialization-json</artifactId>
            <version>1.6.2</version>
        </dependency>
    </dependencies>

    <build>
        <sourceDirectory>src/main/kotlin</sourceDirectory>
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
                <version>${{kotlin.version}}</version>
            </plugin>
        </plugins>
    </build>
</project>";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "pom.xml"),
            pomXml);

        // Create Gradle alternative
        var buildGradle = $@"plugins {{
    id 'org.jetbrains.kotlin.jvm' version '1.9.22'
    id 'org.jetbrains.kotlin.plugin.serialization' version '1.9.22'
    id 'maven-publish'
}}

group = '{metadata.GroupId}'
version = '{metadata.Version}'

repositories {{
    mavenCentral()
}}

dependencies {{
    implementation 'org.jetbrains.kotlin:kotlin-stdlib'
    implementation 'com.google.protobuf:protobuf-kotlin:3.25.2'
    implementation 'io.grpc:grpc-kotlin-stub:1.4.1'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2'
}}

publishing {{
    publications {{
        maven(MavenPublication) {{
            from components.java
        }}
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "build.gradle.kts"),
            buildGradle);

        // Generate Kotlin extensions
        await GenerateKotlinExtensionsAsync(srcDir, metadata);

        return new PackageResult
        {
            Success = true,
            PackagePath = packageDir,
            Language = Language.Kotlin
        };
    }

    private async Task GenerateKotlinExtensionsAsync(string srcDir, PackageMetadata metadata)
    {
        var extensions = $@"// Extensions for {metadata.PackageName}
package {metadata.GroupId}

import com.google.protobuf.Timestamp
import com.google.protobuf.kotlin.toByteString
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import java.time.Instant
import java.util.Date

// Timestamp conversions
fun Timestamp.toInstant(): Instant = Instant.ofEpochSecond(seconds, nanos.toLong())
fun Instant.toTimestamp(): Timestamp = Timestamp.newBuilder()
    .setSeconds(epochSecond)
    .setNanos(nano)
    .build()

fun Timestamp.toDate(): Date = Date(seconds * 1000 + nanos / 1_000_000)
fun Date.toTimestamp(): Timestamp = time.let {{ millis ->
    Timestamp.newBuilder()
        .setSeconds(millis / 1000)
        .setNanos(((millis % 1000) * 1_000_000).toInt())
        .build()
}}

// JSON serialization
inline fun <reified T> T.toJson(): String = Json.encodeToString(this)
inline fun <reified T> String.fromJson(): T = Json.decodeFromString(this)

// Validation
interface Validatable {{
    fun validate(): ValidationResult
}}

data class ValidationResult(
    val isValid: Boolean,
    val errors: List<ValidationError> = emptyList()
)

data class ValidationError(
    val field: String,
    val message: String
)
";

        await File.WriteAllTextAsync(
            Path.Combine(srcDir, "Extensions.kt"),
            extensions);
    }
}

/// <summary>
/// NuGet package generator for C#
/// </summary>
public class NuGetPackageGenerator : IPackageGenerator
{
    public async Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata)
    {
        var packageDir = Path.Combine(compilation.OutputPath, metadata.PackageName);
        Directory.CreateDirectory(packageDir);

        // Create .csproj
        var csproj = $@"<Project Sdk=""Microsoft.NET.Sdk"">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>12</LangVersion>
    <Nullable>enable</Nullable>
    <PackageId>{metadata.PackageName}</PackageId>
    <Version>{metadata.Version}</Version>
    <Authors>{metadata.Authors}</Authors>
    <Company>{metadata.Company}</Company>
    <Description>gRPC types for {metadata.ServiceName}</Description>
    <PackageTags>grpc;protobuf;axiom</PackageTags>
    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include=""Google.Protobuf"" Version=""3.25.2"" />
    <PackageReference Include=""Grpc.Core.Api"" Version=""2.60.0"" />
    <PackageReference Include=""Grpc.Net.Client"" Version=""2.60.0"" />
  </ItemGroup>
</Project>";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, $"{metadata.PackageName}.csproj"),
            csproj);

        // Copy generated files
        foreach (var file in compilation.GeneratedFiles)
        {
            var destPath = Path.Combine(packageDir, Path.GetFileName(file));
            File.Copy(file, destPath, overwrite: true);
        }

        // Generate extensions
        var extensions = $@"// Extensions for {metadata.PackageName}
using System;
using Google.Protobuf.WellKnownTypes;

namespace {metadata.PackageName}
{{
    public static class ProtoExtensions
    {{
        // Timestamp conversions
        public static DateTime ToDateTime(this Timestamp timestamp)
        {{
            return timestamp.ToDateTime();
        }}

        public static Timestamp ToTimestamp(this DateTime dateTime)
        {{
            return Timestamp.FromDateTime(dateTime.ToUniversalTime());
        }}

        public static DateTimeOffset ToDateTimeOffset(this Timestamp timestamp)
        {{
            return timestamp.ToDateTimeOffset();
        }}

        public static Timestamp ToTimestamp(this DateTimeOffset dateTimeOffset)
        {{
            return Timestamp.FromDateTimeOffset(dateTimeOffset);
        }}

        // Validation
        public static bool TryValidate<T>(this T message, out List<string> errors)
            where T : IMessage
        {{
            errors = new List<string>();
            // Validation logic based on custom options
            return errors.Count == 0;
        }}
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "Extensions.cs"),
            extensions);

        return new PackageResult
        {
            Success = true,
            PackagePath = packageDir,
            Language = Language.CSharp
        };
    }
}
Phase 4: CI/CD Integration
5. Automated Package Publishing
csharp// src/AxiomEndpoints.ProtoGen/Publishing/PackagePublisher.cs
namespace AxiomEndpoints.ProtoGen.Publishing;

/// <summary>
/// Publishes packages to respective registries
/// </summary>
public class PackagePublisher
{
    private readonly PublishingOptions _options;
    private readonly ILogger<PackagePublisher> _logger;

    public async Task PublishAsync(PackageResult package, PublishTarget target)
    {
        switch (package.Language)
        {
            case Language.Swift:
                await PublishSwiftPackageAsync(package, target);
                break;

            case Language.Kotlin:
            case Language.Java:
                await PublishMavenPackageAsync(package, target);
                break;

            case Language.CSharp:
                await PublishNuGetPackageAsync(package, target);
                break;
        }
    }

    private async Task PublishSwiftPackageAsync(PackageResult package, PublishTarget target)
    {
        switch (target)
        {
            case PublishTarget.GitHub:
                // Create git repo and push
                await RunCommandAsync("git", "init", package.PackagePath);
                await RunCommandAsync("git", "add .", package.PackagePath);
                await RunCommandAsync("git", "commit -m \"Release v{package.Version}\"", package.PackagePath);
                await RunCommandAsync("git", $"tag v{package.Version}", package.PackagePath);
                await RunCommandAsync("git", $"remote add origin {_options.GitHubRepo}", package.PackagePath);
                await RunCommandAsync("git", "push -u origin main --tags", package.PackagePath);
                break;

            case PublishTarget.Private:
                // Copy to private Swift package registry
                var registryPath = Path.Combine(_options.PrivateRegistryPath, "swift", package.PackageName);
                CopyDirectory(package.PackagePath, registryPath);
                break;
        }
    }

    private async Task PublishMavenPackageAsync(PackageResult package, PublishTarget target)
    {
        switch (target)
        {
            case PublishTarget.MavenCentral:
                await RunCommandAsync("mvn", "deploy", package.PackagePath);
                break;

            case PublishTarget.GitHubPackages:
                await RunCommandAsync("mvn", "deploy -DaltDeploymentRepository=github::default::https://maven.pkg.github.com/{owner}/{repo}", package.PackagePath);
                break;

            case PublishTarget.Private:
                await RunCommandAsync("mvn", $"deploy -DaltDeploymentRepository=private::default::{_options.PrivateMavenRepo}", package.PackagePath);
                break;
        }
    }

    private async Task PublishNuGetPackageAsync(PackageResult package, PublishTarget target)
    {
        switch (target)
        {
            case PublishTarget.NuGetOrg:
                await RunCommandAsync("dotnet", $"nuget push *.nupkg --api-key {_options.NuGetApiKey} --source https://api.nuget.org/v3/index.json", package.PackagePath);
                break;

            case PublishTarget.GitHubPackages:
                await RunCommandAsync("dotnet", $"nuget push *.nupkg --api-key {_options.GitHubToken} --source https://nuget.pkg.github.com/{_options.GitHubOwner}/index.json", package.PackagePath);
                break;

            case PublishTarget.Private:
                await RunCommandAsync("dotnet", $"nuget push *.nupkg --source {_options.PrivateNuGetFeed}", package.PackagePath);
                break;
        }
    }
}

public enum PublishTarget
{
    NuGetOrg,
    MavenCentral,
    GitHub,
    GitHubPackages,
    Private
}
Phase 5: CLI Tool
6. Command Line Interface
csharp// src/AxiomEndpoints.ProtoGen.Cli/Program.cs
using System.CommandLine;

var rootCommand = new RootCommand("Axiom Endpoints Proto Generator");

var generateCommand = new Command("generate", "Generate proto files and packages from assemblies");
var assemblyOption = new Option<FileInfo>("--assembly", "Path to the assembly containing Axiom endpoints") { IsRequired = true };
var outputOption = new Option<DirectoryInfo>("--output", "Output directory") { IsRequired = true };
var languagesOption = new Option<string[]>("--languages", "Target languages (swift, kotlin, csharp)") { IsRequired = true };
var packageNameOption = new Option<string>("--package-name", "Package name");
var versionOption = new Option<string>("--version", "Package version");

generateCommand.AddOption(assemblyOption);
generateCommand.AddOption(outputOption);
generateCommand.AddOption(languagesOption);
generateCommand.AddOption(packageNameOption);
generateCommand.AddOption(versionOption);

generateCommand.SetHandler(async (assembly, output, languages, packageName, version) =>
{
    var generator = new ProtoPackageGenerator();
    await generator.GenerateAsync(new GenerateOptions
    {
        AssemblyPath = assembly.FullName,
        OutputPath = output.FullName,
        Languages = languages.Select(l => Enum.Parse<Language>(l, true)).ToList(),
        PackageName = packageName,
        Version = version ?? "1.0.0"
    });
}, assemblyOption, outputOption, languagesOption, packageNameOption, versionOption);

var publishCommand = new Command("publish", "Publish generated packages");
// ... publish options

rootCommand.AddCommand(generateCommand);
rootCommand.AddCommand(publishCommand);

return await rootCommand.InvokeAsync(args);

// Usage:
// axiom-protogen generate --assembly MyApi.dll --output ./generated --languages swift,kotlin,csharp
// axiom-protogen publish --path ./generated/swift --target github
Phase 6: GitHub Actions Integration
7. Automated CI/CD
yaml# .github/workflows/generate-grpc-types.yml
name: Generate gRPC Types

on:
  push:
    branches: [main]
    paths:
      - 'src/**/*.cs'
      - '**/Endpoints/**/*.cs'
      - '**/Events/**/*.cs'
      - '**/Models/**/*.cs'

jobs:
  generate-types:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 9.0.x

    - name: Install Proto Generator
      run: dotnet tool install -g axiom-protogen

    - name: Build Assembly
      run: dotnet build -c Release

    - name: Generate Proto Package
      run: |
        axiom-protogen generate \
          --assembly ./bin/Release/net9.0/MyApi.dll \
          --output ./generated \
          --languages swift,kotlin,csharp \
          --version ${{ github.run_number }}.0.0

    - name: Setup Protoc
      uses: arduino/setup-protoc@v2
      with:
        version: '25.x'
        include-pre-releases: false

    - name: Generate Swift Package
      run: |
        axiom-protogen compile \
          --proto ./generated/myapi \
          --language swift \
          --output ./packages/swift

    - name: Generate Kotlin Package
      run: |
        axiom-protogen compile \
          --proto ./generated/myapi \
          --language kotlin \
          --output ./packages/kotlin

    - name: Generate NuGet Package
      run: |
        axiom-protogen compile \
          --proto ./generated/myapi \
          --language csharp \
          --output ./packages/nuget

    - name: Publish Swift Package
      run: |
        cd packages/swift
        git init
        git add .
        git commit -m "Release v${{ github.run_number }}.0.0"
        git tag v${{ github.run_number }}.0.0
        git remote add origin https://github.com/${{ github.repository_owner }}/MyApi.Swift.git
        git push -u origin main --tags

    - name: Publish to Maven
      run: |
        cd packages/kotlin
        mvn deploy
      env:
        MAVEN_USERNAME: ${{ secrets.MAVEN_USERNAME }}
        MAVEN_PASSWORD: ${{ secrets.MAVEN_PASSWORD }}

    - name: Publish to NuGet
      run: |
        cd packages/nuget
        dotnet nuget push *.nupkg \
          --api-key ${{ secrets.NUGET_API_KEY }} \
          --source https://api.nuget.org/v3/index.json
Phase 7: Usage Examples
8. Using Generated Types in Client Apps
Swift Example
swift// Package.swift
dependencies: [
    .package(url: "https://github.com/mycompany/MyApi.Swift.git", from: "1.0.0")
]

// Usage
import MyApiTypes
import GRPC

// Use generated types directly as domain models
let todo = Todo.with {
    $0.id = UUID().uuidString
    $0.title = "Build something awesome"
    $0.isComplete = false
    $0.createdAt = Google_Protobuf_Timestamp(date: Date())
}

// Types are fully compatible with gRPC clients
let client = TodoServiceAsyncClient(channel: channel)
let response = try await client.createTodo(todo)
Kotlin Example
kotlin// build.gradle.kts
dependencies {
    implementation("com.mycompany:myapi-types:1.0.0")
}

// Usage
import com.mycompany.myapi.*
import kotlinx.coroutines.flow.*

// Use as domain models
val todo = todo {
    id = UUID.randomUUID().toString()
    title = "Build something awesome"
    isComplete = false
    createdAt = Date().toTimestamp()
}

// Direct use with gRPC
val stub = TodoServiceGrpcKt.TodoServiceCoroutineStub(channel)
val response = stub.createTodo(todo)

// Streaming
stub.streamTodos(Empty.getDefaultInstance())
    .collect { event ->
        println("Received: $event")
    }
C# Example
csharp// Using generated types in another service
using MyApi.Grpc;

// Types work as domain models
var todo = new Todo
{
    Id = Guid.NewGuid().ToString(),
    Title = "Build something awesome",
    IsComplete = false,
    CreatedAt = Timestamp.FromDateTime(DateTime.UtcNow)
};

// Use with any gRPC client
var client = new TodoService.TodoServiceClient(channel);
var response = await client.CreateTodoAsync(todo);

// Streaming
using var stream = client.StreamTodos(new Empty());
await foreach (var todoEvent in stream.ResponseStream.ReadAllAsync())
{
    Console.WriteLine($"Received: {todoEvent}");
}
Key Benefits

Single Source of Truth: C# types define the contract once
No Duplication: Client apps use gRPC types directly as domain models
Type Safety: Full compile-time type checking across all platforms
Native Performance: protoc generates optimal code for each platform
Version Control: Proto files handle backward compatibility
Documentation: XML docs preserved in generated code
Validation: Rules embedded in proto options
Streaming Support: Native async streaming in each language
Standard Tooling: Works with existing gRPC ecosystem
Automated Updates: CI/CD keeps types synchronized

This approach ensures all client applications have strongly-typed domain models that exactly match the server implementation, eliminating model drift and integration bugs.
