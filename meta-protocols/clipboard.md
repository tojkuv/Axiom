gRPC-First Client Generation for Axiom Endpoints
You're absolutely right! Instead of building custom SDK generators for each language, we should leverage gRPC's mature ecosystem. This approach gives us:

Battle-tested code generation maintained by the gRPC community
Native performance with HTTP/2 and Protobuf
Streaming support built-in for all languages
Type safety from .proto files
Smaller payloads with binary encoding

Architecture Overview
mermaidgraph TD
    A[Axiom Endpoints<br/>C# Code] --> B[Proto Generator]
    B --> C[.proto Files]
    C --> D[protoc Compiler]
    D --> E[Swift gRPC Client]
    D --> F[Kotlin gRPC Client]
    D --> G[C# gRPC Client]
    D --> H[gRPC-Web Client]

    A --> I[gRPC Server<br/>Implementation]
    A --> J[HTTP Gateway<br/>REST Compatibility]

    I --> K[gRPC Endpoint]
    J --> L[REST Endpoint]

    E --> K
    F --> K
    G --> K
    H --> J
Implementation
1. Enhanced Proto File Generation
csharp// src/AxiomEndpoints.Grpc.Generator/ProtoGenerator.cs
namespace AxiomEndpoints.Grpc.Generator;

/// <summary>
/// Generates comprehensive .proto files from Axiom Endpoints
/// </summary>
public class EnhancedProtoGenerator
{
    private readonly ProtoOptions _options;

    public async Task<ProtoPackage> GenerateProtoPackageAsync(Assembly assembly)
    {
        var package = new ProtoPackage
        {
            Name = assembly.GetName().Name!.ToLowerInvariant(),
            Services = new List<ProtoService>(),
            Messages = new List<ProtoMessage>(),
            Enums = new List<ProtoEnum>(),
            Options = GenerateFileOptions(assembly)
        };

        // Group endpoints by service
        var endpoints = DiscoverEndpoints(assembly);
        var services = endpoints.GroupBy(e => e.ServiceName ?? "DefaultService");

        foreach (var service in services)
        {
            var protoService = GenerateService(service);
            package.Services.Add(protoService);
        }

        // Extract all types
        var types = ExtractAllTypes(endpoints);
        foreach (var type in types)
        {
            if (type.IsEnum)
            {
                package.Enums.Add(GenerateEnum(type));
            }
            else
            {
                package.Messages.Add(GenerateMessage(type));
            }
        }

        // Generate multiple .proto files if needed
        return OrganizeIntoFiles(package);
    }

    private ProtoFileOptions GenerateFileOptions(Assembly assembly)
    {
        return new ProtoFileOptions
        {
            JavaPackage = $"com.{_options.Organization}.{assembly.GetName().Name!.ToLowerInvariant()}",
            JavaOuterClassname = $"{assembly.GetName().Name}Proto",
            CsharpNamespace = $"{assembly.GetName().Name}.Grpc",
            GoPackage = $"github.com/{_options.Organization}/{assembly.GetName().Name!.ToLowerInvariant()}/pb",
            SwiftPrefix = _options.SwiftPrefix ?? assembly.GetName().Name,
            ObjcClassPrefix = _options.ObjcPrefix ?? assembly.GetName().Name!.ToUpperInvariant(),
            OptimizeFor = "SPEED",

            // Additional options for better client generation
            CcEnableArenas = true,
            Deprecated = false,
            JavaMultipleFiles = true,
            JavaStringCheckUtf8 = true
        };
    }

    private ProtoService GenerateService(IGrouping<string, EndpointInfo> serviceEndpoints)
    {
        var service = new ProtoService
        {
            Name = serviceEndpoints.Key,
            Methods = new List<ProtoMethod>()
        };

        foreach (var endpoint in serviceEndpoints)
        {
            var method = GenerateMethod(endpoint);
            service.Methods.Add(method);

            // Add HTTP annotations for gRPC Gateway
            AddHttpAnnotations(method, endpoint);
        }

        return service;
    }

    private ProtoMethod GenerateMethod(EndpointInfo endpoint)
    {
        return new ProtoMethod
        {
            Name = endpoint.MethodName,
            InputType = GetMessageName(endpoint.RequestType),
            OutputType = GetMessageName(endpoint.ResponseType),
            ClientStreaming = endpoint.StreamingMode == StreamingMode.ClientStream ||
                            endpoint.StreamingMode == StreamingMode.Bidirectional,
            ServerStreaming = endpoint.StreamingMode == StreamingMode.ServerStream ||
                            endpoint.StreamingMode == StreamingMode.Bidirectional,
            Options = GenerateMethodOptions(endpoint)
        };
    }

    private void AddHttpAnnotations(ProtoMethod method, EndpointInfo endpoint)
    {
        // Add google.api.http annotations for REST gateway
        var httpRule = new HttpRule
        {
            Selector = $"{endpoint.ServiceName}.{method.Name}",
            Pattern = endpoint.HttpMethod.ToLowerInvariant() switch
            {
                "get" => new HttpRule.PatternCase.Get(endpoint.Route),
                "post" => new HttpRule.PatternCase.Post(endpoint.Route) { Body = "*" },
                "put" => new HttpRule.PatternCase.Put(endpoint.Route) { Body = "*" },
                "delete" => new HttpRule.PatternCase.Delete(endpoint.Route),
                "patch" => new HttpRule.PatternCase.Patch(endpoint.Route) { Body = "*" },
                _ => throw new NotSupportedException($"HTTP method {endpoint.HttpMethod} not supported")
            }
        };

        method.Options.Add("google.api.http", httpRule);
    }

    private ProtoMessage GenerateMessage(Type type)
    {
        var message = new ProtoMessage
        {
            Name = GetMessageName(type),
            Fields = new List<ProtoField>()
        };

        // Handle inheritance
        if (type.BaseType != null && type.BaseType != typeof(object))
        {
            // Use composition instead of inheritance for proto
            message.Fields.Add(new ProtoField
            {
                Name = "base",
                Type = GetMessageName(type.BaseType),
                Number = 1,
                Label = ProtoLabel.Optional
            });
        }

        // Generate fields
        var properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance);
        var fieldNumber = type.BaseType != null ? 2 : 1;

        foreach (var property in properties)
        {
            if (ShouldIncludeProperty(property))
            {
                var field = GenerateField(property, fieldNumber++);
                message.Fields.Add(field);
            }
        }

        // Add validation rules if present
        AddValidationRules(message, type);

        return message;
    }

    private ProtoField GenerateField(PropertyInfo property, int fieldNumber)
    {
        var field = new ProtoField
        {
            Name = ToSnakeCase(property.Name),
            Number = fieldNumber,
            Type = GetProtoType(property.PropertyType),
            Label = GetFieldLabel(property),
            Options = new Dictionary<string, object>()
        };

        // Add field options
        if (property.GetCustomAttribute<ObsoleteAttribute>() != null)
        {
            field.Options["deprecated"] = true;
        }

        // Add JSON name if different from proto name
        if (field.Name != property.Name.ToLowerInvariant())
        {
            field.Options["json_name"] = property.Name;
        }

        // Add validation rules
        AddFieldValidation(field, property);

        return field;
    }

    private void AddFieldValidation(ProtoField field, PropertyInfo property)
    {
        // Add protoc-gen-validate rules
        var validationRules = new Dictionary<string, object>();

        // Required validation
        if (property.GetCustomAttribute<RequiredAttribute>() != null)
        {
            validationRules["required"] = true;
        }

        // String validations
        if (property.PropertyType == typeof(string))
        {
            var minLength = property.GetCustomAttribute<MinLengthAttribute>();
            if (minLength != null)
            {
                validationRules["string.min_len"] = minLength.Length;
            }

            var maxLength = property.GetCustomAttribute<MaxLengthAttribute>();
            if (maxLength != null)
            {
                validationRules["string.max_len"] = maxLength.Length;
            }

            var pattern = property.GetCustomAttribute<RegularExpressionAttribute>();
            if (pattern != null)
            {
                validationRules["string.pattern"] = pattern.Pattern;
            }

            var email = property.GetCustomAttribute<EmailAddressAttribute>();
            if (email != null)
            {
                validationRules["string.email"] = true;
            }
        }

        // Numeric validations
        if (IsNumericType(property.PropertyType))
        {
            var range = property.GetCustomAttribute<RangeAttribute>();
            if (range != null)
            {
                validationRules[$"{field.Type}.gte"] = range.Minimum;
                validationRules[$"{field.Type}.lte"] = range.Maximum;
            }
        }

        if (validationRules.Any())
        {
            field.Options["validate.rules"] = validationRules;
        }
    }
}

/// <summary>
/// Proto file content generator with proper formatting
/// </summary>
public class ProtoFileWriter
{
    public string WriteProtoFile(ProtoPackage package)
    {
        var sb = new StringBuilder();

        // File header
        sb.AppendLine("syntax = \"proto3\";");
        sb.AppendLine();
        sb.AppendLine($"package {package.Name};");
        sb.AppendLine();

        // Imports
        WriteImports(sb, package);

        // File options
        WriteFileOptions(sb, package.Options);

        // Services
        foreach (var service in package.Services)
        {
            WriteService(sb, service);
        }

        // Messages
        foreach (var message in package.Messages)
        {
            WriteMessage(sb, message);
        }

        // Enums
        foreach (var @enum in package.Enums)
        {
            WriteEnum(sb, @enum);
        }

        return sb.ToString();
    }

    private void WriteImports(StringBuilder sb, ProtoPackage package)
    {
        var imports = new HashSet<string>();

        // Standard imports
        imports.Add("google/protobuf/timestamp.proto");
        imports.Add("google/protobuf/duration.proto");
        imports.Add("google/protobuf/empty.proto");
        imports.Add("google/protobuf/wrappers.proto");

        // HTTP annotations for gRPC Gateway
        if (package.Services.Any(s => s.Methods.Any(m => m.Options.ContainsKey("google.api.http"))))
        {
            imports.Add("google/api/annotations.proto");
            imports.Add("google/api/field_behavior.proto");
        }

        // Validation
        if (package.Messages.Any(m => m.Fields.Any(f => f.Options.ContainsKey("validate.rules"))))
        {
            imports.Add("validate/validate.proto");
        }

        foreach (var import in imports.OrderBy(i => i))
        {
            sb.AppendLine($"import \"{import}\";");
        }

        sb.AppendLine();
    }
}
2. Service-Side gRPC Implementation
csharp// src/AxiomEndpoints.Grpc/GrpcEndpointAdapter.cs
namespace AxiomEndpoints.Grpc;

/// <summary>
/// Adapts Axiom Endpoints to gRPC services with zero overhead
/// </summary>
public class GrpcEndpointAdapter<TService> where TService : class
{
    private readonly IServiceProvider _services;
    private readonly ILogger<GrpcEndpointAdapter<TService>> _logger;

    public GrpcEndpointAdapter(IServiceProvider services, ILogger<GrpcEndpointAdapter<TService>> logger)
    {
        _services = services;
        _logger = logger;
    }

    /// <summary>
    /// Creates a gRPC method handler from an Axiom endpoint
    /// </summary>
    public UnaryServerMethod<TRequest, TResponse> CreateUnaryMethod<TEndpoint, TRequest, TResponse>(
        IAxiom<TRequest, TResponse> endpoint)
        where TRequest : class
        where TResponse : class
    {
        return async (request, context) =>
        {
            using var scope = _services.CreateScope();
            var axiomContext = CreateContext(context, scope.ServiceProvider);

            try
            {
                // Apply cross-cutting concerns
                var pipeline = scope.ServiceProvider
                    .GetRequiredService<IMiddlewarePipeline<TRequest, TResponse>>();

                var result = await pipeline.ExecuteAsync(
                    request,
                    axiomContext,
                    (req, ctx) => endpoint.HandleAsync(req, ctx));

                return result.Match(
                    success: response => response,
                    failure: error => throw error.ToRpcException());
            }
            catch (RpcException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception in gRPC endpoint {Endpoint}",
                    typeof(TEndpoint).Name);

                throw new RpcException(new Status(StatusCode.Internal, "Internal server error"));
            }
        };
    }

    /// <summary>
    /// Creates a server streaming handler
    /// </summary>
    public ServerStreamingServerMethod<TRequest, TResponse> CreateServerStreamingMethod<TEndpoint, TRequest, TResponse>(
        IServerStreamAxiom<TRequest, TResponse> endpoint)
        where TRequest : class
        where TResponse : class
    {
        return async (request, responseStream, context) =>
        {
            using var scope = _services.CreateScope();
            var axiomContext = CreateContext(context, scope.ServiceProvider);

            try
            {
                await foreach (var item in endpoint.StreamAsync(request, axiomContext)
                    .WithCancellation(context.CancellationToken))
                {
                    await responseStream.WriteAsync(item);
                }
            }
            catch (OperationCanceledException) when (context.CancellationToken.IsCancellationRequested)
            {
                // Client cancelled - normal behavior
            }
        };
    }
}

/// <summary>
/// Source-generated gRPC service implementation
/// </summary>
[GeneratedCode("AxiomEndpoints.SourceGenerators", "1.0.0")]
public partial class TodoServiceGrpcImpl : TodoService.TodoServiceBase
{
    private readonly GrpcEndpointAdapter<TodoService> _adapter;

    public TodoServiceGrpcImpl(GrpcEndpointAdapter<TodoService> adapter)
    {
        _adapter = adapter;
    }

    public override Task<Todo> CreateTodo(CreateTodoRequest request, ServerCallContext context)
    {
        var endpoint = context.GetHttpContext().RequestServices
            .GetRequiredService<CreateTodoEndpoint>();

        var handler = _adapter.CreateUnaryMethod<CreateTodoEndpoint, CreateTodoRequest, Todo>(endpoint);
        return handler(request, context);
    }

    public override async Task StreamTodos(
        StreamTodosRequest request,
        IServerStreamWriter<TodoEvent> responseStream,
        ServerCallContext context)
    {
        var endpoint = context.GetHttpContext().RequestServices
            .GetRequiredService<StreamTodosEndpoint>();

        var handler = _adapter.CreateServerStreamingMethod<StreamTodosEndpoint, StreamTodosRequest, TodoEvent>(endpoint);
        await handler(request, responseStream, context);
    }
}
3. Client Generation Configuration
csharp// src/AxiomEndpoints.Grpc.Generator/ClientGeneratorConfig.cs
namespace AxiomEndpoints.Grpc.Generator;

/// <summary>
/// Configuration for generating gRPC clients
/// </summary>
public class GrpcClientGeneratorConfig
{
    public List<ClientLanguage> Languages { get; set; } = new();
    public bool GenerateDescriptorSet { get; set; } = true;
    public bool EnableGrpcWeb { get; set; } = true;
    public bool GenerateGateway { get; set; } = true;
}

public class ClientLanguage
{
    public required string Language { get; init; }
    public required Dictionary<string, string> Options { get; init; }

    // Predefined configurations
    public static ClientLanguage Swift => new()
    {
        Language = "swift",
        Options = new()
        {
            ["grpc-swift_opt"] = "Visibility=Public,Server=false,Client=true,TestClient=false",
            ["plugin"] = "protoc-gen-grpc-swift",
            ["swift_opt"] = "Visibility=Public"
        }
    };

    public static ClientLanguage Kotlin => new()
    {
        Language = "kotlin",
        Options = new()
        {
            ["kotlin_out"] = "lite",
            ["grpckt_out"] = ".",
            ["plugin"] = "protoc-gen-grpckt"
        }
    };

    public static ClientLanguage CSharp => new()
    {
        Language = "csharp",
        Options = new()
        {
            ["csharp_opt"] = "file_extension=.g.cs,base_namespace=",
            ["grpc_opt"] = "no_server,file_suffix=.GrpcClient"
        }
    };
}

/// <summary>
/// Generates build files for each platform
/// </summary>
public class BuildFileGenerator
{
    public void GenerateSwiftPackage(string outputPath, ProtoPackage package)
    {
        var packageSwift = $@"// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: ""{package.Name}Client"",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: ""{package.Name}Client"",
            targets: [""{package.Name}Client""])
    ],
    dependencies: [
        .package(url: ""https://github.com/grpc/grpc-swift.git"", from: ""1.21.0""),
        .package(url: ""https://github.com/apple/swift-protobuf.git"", from: ""1.25.0"")
    ],
    targets: [
        .target(
            name: ""{package.Name}Client"",
            dependencies: [
                .product(name: ""GRPC"", package: ""grpc-swift""),
                .product(name: ""SwiftProtobuf"", package: ""swift-protobuf"")
            ],
            path: ""Sources"",
            resources: [.copy(""Resources"")]
        ),
        .testTarget(
            name: ""{package.Name}ClientTests"",
            dependencies: [""{package.Name}Client""],
            path: ""Tests""
        )
    ]
)";

        File.WriteAllText(Path.Combine(outputPath, "Package.swift"), packageSwift);

        // Generate additional Swift helpers
        GenerateSwiftHelpers(outputPath, package);
    }

    private void GenerateSwiftHelpers(string outputPath, ProtoPackage package)
    {
        var helpers = $@"import Foundation
import GRPC
import NIO
import SwiftProtobuf

/// Axiom gRPC client with convenience methods
public class {package.Name}Client {{
    private let channel: GRPCChannel
    private let callOptions: CallOptions

    public init(
        host: String,
        port: Int = 443,
        useTLS: Bool = true,
        token: String? = nil
    ) {{
        let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)

        let channelBuilder = useTLS
            ? ClientConnection.usingPlatformAppropriateTLS(for: group)
            : ClientConnection.insecure(group: group)

        self.channel = try! channelBuilder
            .connect(host: host, port: port)
            .wait()

        var options = CallOptions()
        if let token = token {{
            options.customMetadata.add(name: ""authorization"", value: ""Bearer \(token)"")
        }}
        self.callOptions = options
    }}

    deinit {{
        try? channel.close().wait()
    }}
}}

// Extension for async/await support
extension {package.Name}Client {{
    public func createTodo(_ request: CreateTodoRequest) async throws -> Todo {{
        let client = TodoService_ServiceAsyncClient(channel: channel, defaultCallOptions: callOptions)
        return try await client.createTodo(request)
    }}

    public func streamTodos(_ request: StreamTodosRequest) -> AsyncThrowingStream<TodoEvent, Error> {{
        let client = TodoService_ServiceAsyncClient(channel: channel, defaultCallOptions: callOptions)
        return client.streamTodos(request).makeAsyncIterator()
    }}
}}

// SwiftUI Observable wrapper
@MainActor
public class {package.Name}ObservableClient: ObservableObject {{
    private let client: {package.Name}Client

    @Published public var todos: [Todo] = []
    @Published public var isLoading = false
    @Published public var error: Error?

    public init(client: {package.Name}Client) {{
        self.client = client
    }}

    public func loadTodos() async {{
        isLoading = true
        error = nil

        do {{
            let request = GetTodosRequest()
            let response = try await client.getTodos(request)
            todos = response.todos
        }} catch {{
            self.error = error
        }}

        isLoading = false
    }}
}}";

        var sourcePath = Path.Combine(outputPath, "Sources", $"{package.Name}Client");
        Directory.CreateDirectory(sourcePath);
        File.WriteAllText(Path.Combine(sourcePath, "Helpers.swift"), helpers);
    }

    public void GenerateKotlinGradle(string outputPath, ProtoPackage package)
    {
        var buildGradle = $@"import com.google.protobuf.gradle.*

plugins {{
    id 'com.android.library' version '8.2.0'
    id 'org.jetbrains.kotlin.android' version '1.9.20'
    id 'com.google.protobuf' version '0.9.4'
    id 'maven-publish'
}}

group = 'com.{package.Options.JavaPackage}'
version = '1.0.0'

android {{
    namespace = '{package.Options.JavaPackage}'
    compileSdk = 34

    defaultConfig {{
        minSdk = 21
        targetSdk = 34
    }}

    compileOptions {{
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }}

    kotlinOptions {{
        jvmTarget = '17'
    }}
}}

dependencies {{
    implementation 'io.grpc:grpc-kotlin-stub:1.4.0'
    implementation 'io.grpc:grpc-protobuf:1.59.0'
    implementation 'io.grpc:grpc-okhttp:1.59.0'
    implementation 'com.google.protobuf:protobuf-kotlin:3.24.4'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
}}

protobuf {{
    protoc {{
        artifact = 'com.google.protobuf:protoc:3.24.4'
    }}

    plugins {{
        grpc {{
            artifact = 'io.grpc:protoc-gen-grpc-java:1.59.0'
        }}
        grpckt {{
            artifact = 'io.grpc:protoc-gen-grpc-kotlin:1.4.0:jdk8@jar'
        }}
    }}

    generateProtoTasks {{
        all()*.plugins {{
            grpc {{}}
            grpckt {{}}
        }}
    }}
}}";

        File.WriteAllText(Path.Combine(outputPath, "build.gradle"), buildGradle);

        // Generate Kotlin convenience extensions
        GenerateKotlinExtensions(outputPath, package);
    }

    private void GenerateKotlinExtensions(string outputPath, ProtoPackage package)
    {
        var extensions = $@"package {package.Options.JavaPackage}

import io.grpc.ManagedChannel
import io.grpc.ManagedChannelBuilder
import io.grpc.Metadata
import io.grpc.stub.MetadataUtils
import kotlinx.coroutines.flow.Flow
import java.util.concurrent.TimeUnit

/**
 * Axiom gRPC client for {package.Name}
 */
class {package.Name}Client(
    private val host: String,
    private val port: Int = 443,
    private val useTls: Boolean = true,
    private val token: String? = null
) {{
    private val channel: ManagedChannel = ManagedChannelBuilder
        .forAddress(host, port)
        .apply {{
            if (useTls) {{
                useTransportSecurity()
            }} else {{
                usePlaintext()
            }}
        }}
        .build()

    private val metadata = Metadata().apply {{
        token?.let {{
            put(Metadata.Key.of(""authorization"", Metadata.ASCII_STRING_MARSHALLER), ""Bearer $it"")
        }}
    }}

    private val stub = TodoServiceGrpcKt.TodoServiceCoroutineStub(channel)
        .let {{ if (token != null) MetadataUtils.attachHeaders(it, metadata) else it }}

    // Unary call example
    suspend fun createTodo(request: CreateTodoRequest): Todo {{
        return stub.createTodo(request)
    }}

    // Server streaming example
    fun streamTodos(request: StreamTodosRequest): Flow<TodoEvent> {{
        return stub.streamTodos(request)
    }}

    fun shutdown() {{
        channel.shutdown().awaitTermination(5, TimeUnit.SECONDS)
    }}
}}

// Android ViewModel integration
class TodoViewModel(
    private val client: {package.Name}Client
) : ViewModel() {{

    private val _todos = MutableStateFlow<List<Todo>>(emptyList())
    val todos: StateFlow<List<Todo>> = _todos.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    fun loadTodos() {{
        viewModelScope.launch {{
            _isLoading.value = true
            try {{
                val response = client.getTodos(GetTodosRequest.getDefaultInstance())
                _todos.value = response.todosList
            }} catch (e: Exception) {{
                // Handle error
            }} finally {{
                _isLoading.value = false
            }}
        }}
    }}

    fun observeTodoUpdates() {{
        viewModelScope.launch {{
            client.streamTodos(StreamTodosRequest.getDefaultInstance())
                .collect {{ event ->
                    // Handle todo updates
                    when (event.eventTypeCase) {{
                        TodoEvent.EventTypeCase.CREATED -> {{
                            _todos.value = _todos.value + event.created.todo
                        }}
                        TodoEvent.EventTypeCase.UPDATED -> {{
                            _todos.value = _todos.value.map {{
                                if (it.id == event.updated.todo.id) event.updated.todo else it
                            }}
                        }}
                        TodoEvent.EventTypeCase.DELETED -> {{
                            _todos.value = _todos.value.filter {{ it.id != event.deleted.todoId }}
                        }}
                    }}
                }}
        }}
    }}
}}";

        var srcPath = Path.Combine(outputPath, "src", "main", "kotlin",
            package.Options.JavaPackage.Replace('.', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(srcPath);
        File.WriteAllText(Path.Combine(srcPath, "Extensions.kt"), extensions);
    }
}
4. Build System Integration
csharp// src/AxiomEndpoints.Grpc.Generator/BuildIntegration.cs
namespace AxiomEndpoints.Grpc.Generator;

/// <summary>
/// MSBuild task for automatic proto generation
/// </summary>
public class GenerateGrpcClientsTask : Task
{
    [Required]
    public string AssemblyPath { get; set; }

    [Required]
    public string OutputPath { get; set; }

    public string[] Languages { get; set; } = ["swift", "kotlin", "csharp"];

    public override bool Execute()
    {
        try
        {
            var generator = new GrpcClientGenerator();
            var assembly = Assembly.LoadFrom(AssemblyPath);

            // Generate proto files
            var protoPackage = generator.GenerateProtoPackage(assembly);
            var protoPath = Path.Combine(OutputPath, "proto");
            Directory.CreateDirectory(protoPath);

            foreach (var protoFile in protoPackage.Files)
            {
                var filePath = Path.Combine(protoPath, protoFile.Name);
                File.WriteAllText(filePath, protoFile.Content);
            }

            // Generate clients for each language
            foreach (var language in Languages)
            {
                var langPath = Path.Combine(OutputPath, language);
                Directory.CreateDirectory(langPath);

                GenerateClient(protoPath, langPath, language);
            }

            return true;
        }
        catch (Exception ex)
        {
            Log.LogErrorFromException(ex);
            return false;
        }
    }

    private void GenerateClient(string protoPath, string outputPath, string language)
    {
        var protocArgs = language switch
        {
            "swift" => GenerateSwiftProtocArgs(protoPath, outputPath),
            "kotlin" => GenerateKotlinProtocArgs(protoPath, outputPath),
            "csharp" => GenerateCSharpProtocArgs(protoPath, outputPath),
            _ => throw new NotSupportedException($"Language {language} not supported")
        };

        var processInfo = new ProcessStartInfo
        {
            FileName = "protoc",
            Arguments = protocArgs,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };

        using var process = Process.Start(processInfo);
        process.WaitForExit();

        if (process.ExitCode != 0)
        {
            var error = process.StandardError.ReadToEnd();
            throw new InvalidOperationException($"protoc failed: {error}");
        }
    }
}

/// <summary>
/// NuGet package with MSBuild targets
/// </summary>
public class AxiomGrpcTargets
{
    public static string GenerateTargetsFile() => @"<?xml version=""1.0"" encoding=""utf-8""?>
<Project xmlns=""http://schemas.microsoft.com/developer/msbuild/2003"">
  <PropertyGroup>
    <AxiomGrpcGenerateClients Condition=""'$(AxiomGrpcGenerateClients)' == ''"">true</AxiomGrpcGenerateClients>
    <AxiomGrpcLanguages Condition=""'$(AxiomGrpcLanguages)' == ''"">swift;kotlin;csharp</AxiomGrpcLanguages>
    <AxiomGrpcOutputPath Condition=""'$(AxiomGrpcOutputPath)' == ''"">$(MSBuildProjectDirectory)\generated-clients</AxiomGrpcOutputPath>
  </PropertyGroup>

  <Target Name=""GenerateAxiomGrpcClients""
          AfterTargets=""Build""
          Condition=""'$(AxiomGrpcGenerateClients)' == 'true'"">
    <GenerateGrpcClientsTask
      AssemblyPath=""$(TargetPath)""
      OutputPath=""$(AxiomGrpcOutputPath)""
      Languages=""$(AxiomGrpcLanguages)"" />
  </Target>
</Project>";
}
5. Usage Examples
Swift (iOS/macOS)
swift// Add to Package.swift or use Xcode package manager
// .package(url: "https://github.com/mycompany/todoapi-client-swift.git", from: "1.0.0")

import TodoApiClient
import SwiftUI

// Initialize client
let client = TodoApiClient(
    host: "api.example.com",
    port: 443,
    useTLS: true,
    token: authToken
)

// Simple async/await usage
func createTodo() async throws {
    let request = CreateTodoRequest.with {
        $0.title = "Build gRPC clients"
        $0.description = "Use native protoc generation"
    }

    let todo = try await client.createTodo(request)
    print("Created todo: \(todo.id)")
}

// Streaming with AsyncSequence
func observeTodos() async {
    let request = StreamTodosRequest()

    do {
        for try await event in client.streamTodos(request) {
            switch event.eventType {
            case .created(let created):
                print("New todo: \(created.todo.title)")
            case .updated(let updated):
                print("Updated: \(updated.todo.title)")
            case .deleted(let deleted):
                print("Deleted: \(deleted.todoID)")
            }
        }
    } catch {
        print("Stream error: \(error)")
    }
}

// SwiftUI integration
struct TodoListView: View {
    @StateObject private var viewModel = TodoViewModel(client: client)

    var body: some View {
        List(viewModel.todos) { todo in
            TodoRow(todo: todo)
        }
        .task {
            await viewModel.startObserving()
        }
    }
}

class TodoViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    private let client: TodoApiClient

    func startObserving() async {
        let request = StreamTodosRequest()

        for try await event in client.streamTodos(request) {
            await MainActor.run {
                handleEvent(event)
            }
        }
    }
}
Kotlin (Android)
kotlin// Add to build.gradle
// implementation 'com.mycompany:todoapi-client:1.0.0'

import com.mycompany.todoapi.*
import kotlinx.coroutines.*
import androidx.lifecycle.*

// Initialize client
val client = TodoApiClient(
    host = "api.example.com",
    port = 443,
    useTls = true,
    token = authToken
)

// Coroutine usage
class TodoRepository(private val client: TodoApiClient) {
    suspend fun createTodo(title: String, description: String): Todo {
        val request = createTodoRequest {
            this.title = title
            this.description = description
        }

        return client.createTodo(request)
    }

    fun observeTodos(): Flow<TodoEvent> {
        val request = streamTodosRequest {}
        return client.streamTodos(request)
    }
}

// Android ViewModel
class TodoViewModel(
    private val repository: TodoRepository
) : ViewModel() {
    private val _todos = MutableLiveData<List<Todo>>()
    val todos: LiveData<List<Todo>> = _todos

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    init {
        observeTodoUpdates()
    }

    private fun observeTodoUpdates() {
        viewModelScope.launch {
            repository.observeTodos().collect { event ->
                when (event.eventTypeCase) {
                    TodoEvent.EventTypeCase.CREATED -> {
                        val currentTodos = _todos.value.orEmpty()
                        _todos.value = currentTodos + event.created.todo
                    }
                    TodoEvent.EventTypeCase.UPDATED -> {
                        _todos.value = _todos.value?.map {
                            if (it.id == event.updated.todo.id) {
                                event.updated.todo
                            } else it
                        }
                    }
                    TodoEvent.EventTypeCase.DELETED -> {
                        _todos.value = _todos.value?.filter {
                            it.id != event.deleted.todoId
                        }
                    }
                }
            }
        }
    }

    fun createTodo(title: String, description: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                repository.createTodo(title, description)
            } catch (e: Exception) {
                // Handle error
            } finally {
                _isLoading.value = false
            }
        }
    }
}

// Compose UI
@Composable
fun TodoListScreen(viewModel: TodoViewModel = viewModel()) {
    val todos by viewModel.todos.observeAsState(emptyList())
    val isLoading by viewModel.isLoading.observeAsState(false)

    LazyColumn {
        items(todos) { todo ->
            TodoItem(todo = todo)
        }
    }

    if (isLoading) {
        CircularProgressIndicator()
    }
}
C# Client (Unity, MAUI, Console)
csharp// Install: dotnet add package TodoApi.GrpcClient

using TodoApi.Grpc;
using Grpc.Net.Client;
using Grpc.Core;

// Initialize client
var channel = GrpcChannel.ForAddress("https://api.example.com", new GrpcChannelOptions
{
    HttpHandler = new SocketsHttpHandler
    {
        PooledConnectionIdleTimeout = TimeSpan.FromMinutes(5),
        KeepAlivePingDelay = TimeSpan.FromSeconds(60),
        KeepAlivePingTimeout = TimeSpan.FromSeconds(30),
        EnableMultipleHttp2Connections = true
    }
});

var client = new TodoService.TodoServiceClient(channel);

// Add auth metadata
var metadata = new Metadata
{
    { "authorization", $"Bearer {authToken}" }
};

var callOptions = new CallOptions(metadata);

// Simple call
var request = new CreateTodoRequest
{
    Title = "Build gRPC clients",
    Description = "Use native protoc generation"
};

var todo = await client.CreateTodoAsync(request, callOptions);

// Streaming
using var streamCall = client.StreamTodos(
    new StreamTodosRequest(),
    callOptions);

await foreach (var todoEvent in streamCall.ResponseStream.ReadAllAsync())
{
    switch (todoEvent.EventTypeCase)
    {
        case TodoEvent.EventTypeOneofCase.Created:
            Console.WriteLine($"New: {todoEvent.Created.Todo.Title}");
            break;
        case TodoEvent.EventTypeOneofCase.Updated:
            Console.WriteLine($"Updated: {todoEvent.Updated.Todo.Title}");
            break;
        case TodoEvent.EventTypeOneofCase.Deleted:
            Console.WriteLine($"Deleted: {todoEvent.Deleted.TodoId}");
            break;
    }
}

// Unity integration
public class TodoManager : MonoBehaviour
{
    private TodoService.TodoServiceClient client;
    private CancellationTokenSource cts;

    async void Start()
    {
        var channel = GrpcChannel.ForAddress("https://api.example.com");
        client = new TodoService.TodoServiceClient(channel);
        cts = new CancellationTokenSource();

        await ObserveTodos();
    }

    async Task ObserveTodos()
    {
        using var call = client.StreamTodos(new StreamTodosRequest());

        await foreach (var evt in call.ResponseStream.ReadAllAsync(cts.Token))
        {
            // Update UI on main thread
            UnityMainThreadDispatcher.Instance().Enqueue(() =>
            {
                HandleTodoEvent(evt);
            });
        }
    }

    void OnDestroy()
    {
        cts?.Cancel();
    }
}
6. Key Advantages of gRPC Approach
1. Native Performance

Binary protocol (Protocol Buffers) - 3-10x smaller than JSON
HTTP/2 multiplexing - multiple streams over single connection
Built-in compression

2. First-Class Streaming

Server streaming for real-time updates
Client streaming for file uploads
Bidirectional for chat/collaboration
Native language support (AsyncSequence, Flow, IAsyncEnumerable)

3. Type Safety

Generated from single source of truth (.proto)
Compile-time validation
IDE autocomplete and refactoring

4. Cross-Platform Consistency

Same API across all platforms
Consistent error handling
Unified authentication

5. Ecosystem Benefits

Battle-tested code generators
Community support
Extensive tooling (grpcurl, Postman, etc.)

7. HTTP/REST Compatibility
csharp// Enable gRPC Gateway for REST clients
app.MapGrpcService<TodoServiceGrpcImpl>();
app.MapGrpcGateway(); // Auto-generates REST endpoints from proto

// Generates:
// POST /v1/todos -> CreateTodo
// GET /v1/todos/{id} -> GetTodo
// GET /v1/todos/stream -> StreamTodos (SSE)
8. Continuous Integration
yaml# .github/workflows/grpc-clients.yml
name: Generate gRPC Clients

on:
  push:
    branches: [main]
    paths:
      - '**/*.proto'
      - 'src/**/*.cs'

jobs:
  generate-clients:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 9.0.x

      - name: Build
        run: dotnet build

      - name: Generate Proto
        run: |
          dotnet tool install -g axiom-proto-gen
          axiom-proto-gen \
            --assembly ./bin/Release/net9.0/TodoApi.dll \
            --output ./proto

      - name: Generate Swift Package
        run: |
          protoc \
            --swift_out=./clients/swift \
            --grpc-swift_out=Client=true,Server=false:./clients/swift \
            ./proto/*.proto

      - name: Generate Kotlin Package
        run: |
          protoc \
            --kotlin_out=./clients/kotlin \
            --grpc-kotlin_out=./clients/kotlin \
            ./proto/*.proto

      - name: Publish Packages
        run: |
          # Publish to package registries
          cd clients/swift && swift package publish
          cd clients/kotlin && ./gradlew publish
This gRPC-first approach leverages the mature gRPC ecosystem while maintaining all the benefits of Axiom Endpoints' type-safe, source-generated architecture. Clients get native performance, streaming support, and consistent APIs across all platforms.RetryLwe already have client frameworks that rely on gRPC types in each ecosystem . we need to generate the gRPC types that they will use in their respective client implementations to integrate endpoint services . we do not create the clients for them . just the gRPC typesEditDecoded gRPC type generation strategy for client frameworks.1sAh, I see! The user is clarifying that they don't want to generate full client implementations. They already have established client frameworks in Swift, Kotlin, and C# that know how to work with gRPC types. What they need is just the type generation - the .proto files and the resulting generated types (messages, enums, service interfaces) that their existing client frameworks will consume.
So the focus should be on:

Generating high-quality .proto files from Axiom Endpoints
Running protoc to generate the language-specific types
Packaging those types in a way that's easy for their client teams to consume
NOT generating any client implementation code - just the types/interfaces

This is actually a cleaner approach - let each platform team use their own patterns and frameworks while ensuring type safety through the generated contracts.gRPC Type Generation for Axiom Endpoints
You're absolutely right! The focus should be on generating just the gRPC types (messages, enums, service definitions) that existing client frameworks will consume. This gives teams the flexibility to use their own patterns while ensuring type safety.
Architecture Overview
mermaidgraph TD
    A[Axiom Endpoints<br/>C# Code] --> B[Proto Generator]
    B --> C[.proto Files]
    C --> D[protoc Compiler]

    D --> E[Swift Types<br/>*.pb.swift + *_grpc.swift]
    D --> F[Kotlin Types<br/>*.pb.kt + *GrpcKt.kt]
    D --> G[C# Types<br/>*.cs + *Grpc.cs]

    E --> H[iOS Team's<br/>Client Framework]
    F --> I[Android Team's<br/>Client Framework]
    G --> J[Unity/MAUI Team's<br/>Client Framework]
Implementation
1. Enhanced Proto Generation from Axiom Endpoints
csharp// src/AxiomEndpoints.Grpc.TypeGen/ProtoFileGenerator.cs
namespace AxiomEndpoints.Grpc.TypeGen;

/// <summary>
/// Generates .proto files optimized for type generation
/// </summary>
public class ProtoFileGenerator
{
    private readonly ProtoGenerationOptions _options;

    public ProtoFileGenerator(ProtoGenerationOptions options)
    {
        _options = options;
    }

    public async Task<ProtoPackage> GenerateProtoFilesAsync(Assembly assembly)
    {
        var package = new ProtoPackage
        {
            Name = GetPackageName(assembly),
            Version = assembly.GetName().Version!,
            Files = new List<ProtoFile>()
        };

        // Generate organized proto files
        package.Files.Add(await GenerateCommonTypesProto(assembly));
        package.Files.Add(await GenerateMessagesProto(assembly));
        package.Files.Add(await GenerateServicesProto(assembly));

        if (_options.GenerateWellKnownTypes)
        {
            package.Files.Add(GenerateWellKnownTypesProto());
        }

        return package;
    }

    private async Task<ProtoFile> GenerateMessagesProto(Assembly assembly)
    {
        var file = new ProtoFile
        {
            Name = $"{_options.FilePrefix}_messages.proto",
            Package = GetPackageName(assembly),
            Imports = new List<string>
            {
                "google/protobuf/timestamp.proto",
                "google/protobuf/duration.proto",
                "google/protobuf/wrappers.proto",
                "google/protobuf/any.proto"
            }
        };

        // Extract all types used in endpoints
        var types = ExtractAllTypes(assembly);

        // Generate messages preserving C# structure
        foreach (var type in types.Where(t => !t.IsEnum))
        {
            var message = GenerateMessage(type);
            file.Messages.Add(message);
        }

        // Generate enums
        foreach (var type in types.Where(t => t.IsEnum))
        {
            var enumDef = GenerateEnum(type);
            file.Enums.Add(enumDef);
        }

        return file;
    }

    private ProtoMessage GenerateMessage(Type type)
    {
        var message = new ProtoMessage
        {
            Name = GetProtoMessageName(type),
            Comment = ExtractXmlDocumentation(type)
        };

        // Handle nullable reference types properly
        var nullabilityContext = new NullabilityInfoContext();
        var properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Where(p => p.CanRead && p.CanWrite);

        int fieldNumber = 1;
        foreach (var property in properties)
        {
            if (ShouldSkipProperty(property)) continue;

            var field = GenerateField(property, fieldNumber++, nullabilityContext);
            message.Fields.Add(field);
        }

        // Add oneof for discriminated unions
        if (IsDiscriminatedUnion(type))
        {
            GenerateOneOfFields(message, type);
        }

        // Add nested types
        foreach (var nestedType in type.GetNestedTypes())
        {
            if (IsMessageType(nestedType))
            {
                message.NestedMessages.Add(GenerateMessage(nestedType));
            }
        }

        return message;
    }

    private ProtoField GenerateField(PropertyInfo property, int fieldNumber, NullabilityInfoContext nullabilityContext)
    {
        var nullabilityInfo = nullabilityContext.Create(property);
        var isNullable = nullabilityInfo.ReadState == NullabilityState.Nullable;

        var field = new ProtoField
        {
            Name = ToSnakeCase(property.Name),
            Number = fieldNumber,
            Comment = ExtractXmlDocumentation(property)
        };

        // Handle different type mappings
        var propertyType = property.PropertyType;

        // Collections
        if (IsCollectionType(propertyType, out var elementType))
        {
            field.Label = ProtoLabel.Repeated;
            field.Type = GetProtoType(elementType);

            // Use map for dictionaries
            if (IsDictionaryType(propertyType, out var keyType, out var valueType))
            {
                field.Type = $"map<{GetProtoType(keyType)}, {GetProtoType(valueType)}>";
                field.Label = ProtoLabel.None;
            }
        }
        // Nullable value types -> wrapper types
        else if (isNullable && propertyType.IsValueType)
        {
            field.Type = GetWrapperType(propertyType) ?? GetProtoType(propertyType);
        }
        // Regular types
        else
        {
            field.Type = GetProtoType(propertyType);
        }

        // Add field options
        AddFieldOptions(field, property);

        return field;
    }

    private void AddFieldOptions(ProtoField field, PropertyInfo property)
    {
        var options = new List<string>();

        // JSON name if different from proto name
        if (field.Name != property.Name.ToLowerInvariant())
        {
            options.Add($"json_name = \"{property.Name}\"");
        }

        // Deprecated
        if (property.GetCustomAttribute<ObsoleteAttribute>() != null)
        {
            options.Add("deprecated = true");
        }

        // C# specific options for better type generation
        if (_options.IncludeCSharpOptions)
        {
            // Preserve property name casing
            options.Add($"(csharp_property_name) = \"{property.Name}\"");
        }

        field.Options = options;
    }

    private string GetProtoType(Type type)
    {
        // Handle nullable
        type = Nullable.GetUnderlyingType(type) ?? type;

        // Primitive mappings
        var mapping = type switch
        {
            _ when type == typeof(bool) => "bool",
            _ when type == typeof(byte) => "uint32",
            _ when type == typeof(sbyte) => "int32",
            _ when type == typeof(short) => "int32",
            _ when type == typeof(ushort) => "uint32",
            _ when type == typeof(int) => "int32",
            _ when type == typeof(uint) => "uint32",
            _ when type == typeof(long) => "int64",
            _ when type == typeof(ulong) => "uint64",
            _ when type == typeof(float) => "float",
            _ when type == typeof(double) => "double",
            _ when type == typeof(decimal) => "string", // With custom option
            _ when type == typeof(string) => "string",
            _ when type == typeof(byte[]) => "bytes",
            _ when type == typeof(DateTime) => "google.protobuf.Timestamp",
            _ when type == typeof(DateTimeOffset) => "google.protobuf.Timestamp",
            _ when type == typeof(TimeSpan) => "google.protobuf.Duration",
            _ when type == typeof(Guid) => "string",
            _ when type == typeof(Uri) => "string",
            _ when type.IsEnum => GetProtoMessageName(type),
            _ => GetProtoMessageName(type)
        };

        return mapping;
    }

    private string? GetWrapperType(Type type)
    {
        type = Nullable.GetUnderlyingType(type) ?? type;

        return type switch
        {
            _ when type == typeof(bool) => "google.protobuf.BoolValue",
            _ when type == typeof(int) => "google.protobuf.Int32Value",
            _ when type == typeof(uint) => "google.protobuf.UInt32Value",
            _ when type == typeof(long) => "google.protobuf.Int64Value",
            _ when type == typeof(ulong) => "google.protobuf.UInt64Value",
            _ when type == typeof(float) => "google.protobuf.FloatValue",
            _ when type == typeof(double) => "google.protobuf.DoubleValue",
            _ when type == typeof(string) => "google.protobuf.StringValue",
            _ when type == typeof(byte[]) => "google.protobuf.BytesValue",
            _ => null
        };
    }
}

/// <summary>
/// Service definition generator
/// </summary>
public class ServiceProtoGenerator
{
    public ProtoFile GenerateServicesProto(Assembly assembly)
    {
        var file = new ProtoFile
        {
            Name = "services.proto",
            Package = GetPackageName(assembly),
            Imports = new List<string>
            {
                "messages.proto",
                "google/protobuf/empty.proto",
                "google/api/annotations.proto" // For HTTP bindings
            }
        };

        // Group endpoints by service
        var services = DiscoverServices(assembly);

        foreach (var service in services)
        {
            var protoService = new ProtoService
            {
                Name = service.Name,
                Comment = service.Description
            };

            foreach (var endpoint in service.Endpoints)
            {
                var method = GenerateServiceMethod(endpoint);
                protoService.Methods.Add(method);
            }

            file.Services.Add(protoService);
        }

        return file;
    }

    private ProtoMethod GenerateServiceMethod(EndpointMetadata endpoint)
    {
        var method = new ProtoMethod
        {
            Name = GetMethodName(endpoint),
            InputType = GetProtoMessageName(endpoint.RequestType),
            OutputType = GetProtoMessageName(endpoint.ResponseType),
            Comment = endpoint.Description
        };

        // Handle streaming
        switch (endpoint.StreamingMode)
        {
            case StreamingMode.ServerStream:
                method.ServerStreaming = true;
                break;
            case StreamingMode.ClientStream:
                method.ClientStreaming = true;
                break;
            case StreamingMode.Bidirectional:
                method.ClientStreaming = true;
                method.ServerStreaming = true;
                break;
        }

        // Add HTTP bindings for REST gateway compatibility
        if (_options.GenerateHttpBindings)
        {
            AddHttpBinding(method, endpoint);
        }

        return method;
    }

    private void AddHttpBinding(ProtoMethod method, EndpointMetadata endpoint)
    {
        var httpRule = new Dictionary<string, object>();

        // Build HTTP pattern
        var pattern = endpoint.HttpMethod.ToLower() switch
        {
            "get" => endpoint.Route,
            "post" => endpoint.Route,
            "put" => endpoint.Route,
            "delete" => endpoint.Route,
            "patch" => endpoint.Route,
            _ => throw new NotSupportedException($"HTTP method {endpoint.HttpMethod} not supported")
        };

        httpRule[endpoint.HttpMethod.ToLower()] = pattern;

        // Body for POST/PUT/PATCH
        if (endpoint.HttpMethod is "POST" or "PUT" or "PATCH")
        {
            httpRule["body"] = "*";
        }

        // Response body mapping
        if (endpoint.ResponseType != typeof(void))
        {
            httpRule["response_body"] = "*";
        }

        method.Options["google.api.http"] = httpRule;
    }
}
2. Proto File Writer with Platform Optimizations
csharp// src/AxiomEndpoints.Grpc.TypeGen/ProtoFileWriter.cs
namespace AxiomEndpoints.Grpc.TypeGen;

/// <summary>
/// Writes proto files with platform-specific optimizations
/// </summary>
public class OptimizedProtoFileWriter
{
    private readonly ProtoWriterOptions _options;

    public string WriteProtoFile(ProtoFile file)
    {
        var sb = new StringBuilder();

        // File header
        sb.AppendLine("// Generated by Axiom Endpoints");
        sb.AppendLine($"// Version: {file.Version}");
        sb.AppendLine($"// Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
        sb.AppendLine();
        sb.AppendLine("syntax = \"proto3\";");
        sb.AppendLine();

        // Package
        sb.AppendLine($"package {file.Package};");
        sb.AppendLine();

        // File-level options for each platform
        WriteFileOptions(sb, file);

        // Imports
        if (file.Imports.Any())
        {
            foreach (var import in file.Imports.OrderBy(i => i))
            {
                sb.AppendLine($"import \"{import}\";");
            }
            sb.AppendLine();
        }

        // Services
        foreach (var service in file.Services)
        {
            WriteService(sb, service);
        }

        // Messages
        foreach (var message in file.Messages)
        {
            WriteMessage(sb, message, 0);
        }

        // Enums
        foreach (var enumDef in file.Enums)
        {
            WriteEnum(sb, enumDef, 0);
        }

        return sb.ToString();
    }

    private void WriteFileOptions(StringBuilder sb, ProtoFile file)
    {
        // C# options
        sb.AppendLine($"option csharp_namespace = \"{file.Package}.Grpc\";");

        // Java/Kotlin options
        sb.AppendLine($"option java_package = \"com.{_options.Organization}.{file.Package}\";");
        sb.AppendLine($"option java_outer_classname = \"{ToPascalCase(file.Name.Replace(".proto", ""))}Proto\";");
        sb.AppendLine("option java_multiple_files = true;");

        // Swift options
        sb.AppendLine($"option swift_prefix = \"{_options.SwiftPrefix ?? ""}\";");

        // Objective-C options (for compatibility)
        sb.AppendLine($"option objc_class_prefix = \"{_options.ObjcPrefix ?? file.Package.ToUpper()}\";");

        // Optimization
        sb.AppendLine("option optimize_for = SPEED;");

        sb.AppendLine();
    }

    private void WriteMessage(StringBuilder sb, ProtoMessage message, int indent)
    {
        var indentStr = new string(' ', indent);

        // Comment
        if (!string.IsNullOrEmpty(message.Comment))
        {
            WriteComment(sb, message.Comment, indent);
        }

        sb.AppendLine($"{indentStr}message {message.Name} {{");

        // Reserved field numbers for future use
        if (message.ReservedNumbers.Any())
        {
            sb.AppendLine($"{indentStr}  reserved {string.Join(", ", message.ReservedNumbers)};");
        }

        // Fields
        foreach (var field in message.Fields.OrderBy(f => f.Number))
        {
            WriteField(sb, field, indent + 2);
        }

        // Oneof groups
        foreach (var oneofGroup in message.OneofGroups)
        {
            sb.AppendLine($"{indentStr}  oneof {oneofGroup.Name} {{");
            foreach (var field in oneofGroup.Fields)
            {
                WriteField(sb, field, indent + 4);
            }
            sb.AppendLine($"{indentStr}  }}");
        }

        // Nested messages
        foreach (var nested in message.NestedMessages)
        {
            sb.AppendLine();
            WriteMessage(sb, nested, indent + 2);
        }

        // Nested enums
        foreach (var nested in message.NestedEnums)
        {
            sb.AppendLine();
            WriteEnum(sb, nested, indent + 2);
        }

        sb.AppendLine($"{indentStr}}}");
    }

    private void WriteField(StringBuilder sb, ProtoField field, int indent)
    {
        var indentStr = new string(' ', indent);

        // Comment
        if (!string.IsNullOrEmpty(field.Comment))
        {
            WriteComment(sb, field.Comment, indent);
        }

        // Field definition
        var label = field.Label == ProtoLabel.Repeated ? "repeated " : "";
        var options = field.Options.Any()
            ? $" [{string.Join(", ", field.Options)}]"
            : "";

        sb.AppendLine($"{indentStr}{label}{field.Type} {field.Name} = {field.Number}{options};");
    }
}
3. Type Generation Pipeline
csharp// src/AxiomEndpoints.Grpc.TypeGen/TypeGenerationPipeline.cs
namespace AxiomEndpoints.Grpc.TypeGen;

/// <summary>
/// Orchestrates the type generation process
/// </summary>
public class TypeGenerationPipeline
{
    private readonly TypeGenerationOptions _options;
    private readonly ILogger<TypeGenerationPipeline> _logger;

    public async Task GenerateTypesAsync(Assembly assembly, string outputPath)
    {
        _logger.LogInformation("Starting type generation for {Assembly}", assembly.GetName().Name);

        // Step 1: Generate proto files
        var protoGenerator = new ProtoFileGenerator(_options.Proto);
        var protoPackage = await protoGenerator.GenerateProtoFilesAsync(assembly);

        // Step 2: Write proto files
        var protoPath = Path.Combine(outputPath, "proto");
        Directory.CreateDirectory(protoPath);

        foreach (var file in protoPackage.Files)
        {
            var filePath = Path.Combine(protoPath, file.Name);
            await File.WriteAllTextAsync(filePath, file.Content);
            _logger.LogInformation("Generated {ProtoFile}", file.Name);
        }

        // Step 3: Generate types for each language
        var tasks = new List<Task>();

        if (_options.Languages.Contains(Language.Swift))
        {
            tasks.Add(GenerateSwiftTypes(protoPath, outputPath));
        }

        if (_options.Languages.Contains(Language.Kotlin))
        {
            tasks.Add(GenerateKotlinTypes(protoPath, outputPath));
        }

        if (_options.Languages.Contains(Language.CSharp))
        {
            tasks.Add(GenerateCSharpTypes(protoPath, outputPath));
        }

        await Task.WhenAll(tasks);

        // Step 4: Generate metadata and documentation
        await GenerateMetadata(protoPackage, outputPath);
    }

    private async Task GenerateSwiftTypes(string protoPath, string outputPath)
    {
        var swiftPath = Path.Combine(outputPath, "swift");
        Directory.CreateDirectory(swiftPath);

        // Run protoc for Swift
        var protocArgs = new List<string>
        {
            $"--proto_path={protoPath}",
            $"--swift_out={swiftPath}",
            "--swift_opt=Visibility=Public",
            "--swift_opt=FileNaming=PathToUnderscores",
            $"--grpc-swift_out={swiftPath}",
            "--grpc-swift_opt=Visibility=Public",
            "--grpc-swift_opt=Server=false", // Only generate client interfaces
            "--grpc-swift_opt=Client=true",
            "--grpc-swift_opt=TestClient=false",
            "--grpc-swift_opt=FileNaming=PathToUnderscores"
        };

        // Add all proto files
        protocArgs.AddRange(Directory.GetFiles(protoPath, "*.proto"));

        await RunProtocAsync(protocArgs);

        // Generate Package.swift
        await GenerateSwiftPackageFile(swiftPath, protoPackage);

        // Generate convenience extensions
        await GenerateSwiftExtensions(swiftPath, protoPackage);
    }

    private async Task GenerateSwiftPackageFile(string swiftPath, ProtoPackage package)
    {
        var packageFile = $@"// swift-tools-version: 5.9
// Generated by Axiom Endpoints

import PackageDescription

let package = Package(
    name: ""{package.Name}GrpcTypes"",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: ""{package.Name}GrpcTypes"",
            targets: [""{package.Name}GrpcTypes""])
    ],
    dependencies: [
        .package(url: ""https://github.com/apple/swift-protobuf.git"", from: ""1.25.0""),
        .package(url: ""https://github.com/grpc/grpc-swift.git"", from: ""1.21.0"")
    ],
    targets: [
        .target(
            name: ""{package.Name}GrpcTypes"",
            dependencies: [
                .product(name: ""SwiftProtobuf"", package: ""swift-protobuf""),
                .product(name: ""GRPC"", package: ""grpc-swift"")
            ],
            path: ""Sources""
        )
    ],
    swiftLanguageVersions: [.v5]
)";

        await File.WriteAllTextAsync(Path.Combine(swiftPath, "Package.swift"), packageFile);
    }

    private async Task GenerateSwiftExtensions(string swiftPath, ProtoPackage package)
    {
        var extensions = $@"// Generated extensions for better Swift ergonomics
import Foundation
import SwiftProtobuf
import GRPC

// MARK: - Date Conversions
extension Google_Protobuf_Timestamp {{
    /// Initialize from Swift Date
    public init(date: Date) {{
        let timeInterval = date.timeIntervalSince1970
        self.seconds = Int64(timeInterval)
        self.nanos = Int32((timeInterval - Double(self.seconds)) * 1_000_000_000)
    }}

    /// Convert to Swift Date
    public var date: Date {{
        return Date(timeIntervalSince1970: Double(seconds) + Double(nanos) / 1_000_000_000)
    }}
}}

// MARK: - UUID Conversions
extension String {{
    /// Initialize from UUID
    public init(uuid: UUID) {{
        self = uuid.uuidString
    }}
}}

extension UUID {{
    /// Initialize from proto string field
    public init?(protoString: String) {{
        self.init(uuidString: protoString)
    }}
}}

// MARK: - Error Handling
extension GRPCStatus {{
    /// Convert to localized error
    public var localizedError: LocalizedError {{
        return GRPCError(status: self)
    }}
}}

struct GRPCError: LocalizedError {{
    let status: GRPCStatus

    var errorDescription: String? {{
        return status.message ?? ""gRPC error: \(status.code)""
    }}

    var failureReason: String? {{
        return status.message
    }}
}}

// MARK: - Async Sequences
#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension GRPCAsyncResponseStream {{
    /// Convert to AsyncThrowingStream for easier consumption
    public func toAsyncThrowingStream() -> AsyncThrowingStream<Element, Error> {{
        AsyncThrowingStream {{ continuation in
            Task {{
                do {{
                    for try await element in self {{
                        continuation.yield(element)
                    }}
                    continuation.finish()
                }} catch {{
                    continuation.finish(throwing: error)
                }}
            }}
        }}
    }}
}}
#endif
";

        var sourcesPath = Path.Combine(swiftPath, "Sources");
        Directory.CreateDirectory(sourcesPath);
        await File.WriteAllTextAsync(Path.Combine(sourcesPath, "Extensions.swift"), extensions);
    }

    private async Task GenerateKotlinTypes(string protoPath, string outputPath)
    {
        var kotlinPath = Path.Combine(outputPath, "kotlin");
        Directory.CreateDirectory(kotlinPath);

        // Generate build.gradle.kts
        await GenerateKotlinBuildFile(kotlinPath, protoPackage);

        // Create proto source directory
        var protoSrcPath = Path.Combine(kotlinPath, "src", "main", "proto");
        Directory.CreateDirectory(protoSrcPath);

        // Copy proto files
        foreach (var protoFile in Directory.GetFiles(protoPath, "*.proto"))
        {
            File.Copy(protoFile, Path.Combine(protoSrcPath, Path.GetFileName(protoFile)));
        }

        // Generate Kotlin extensions
        await GenerateKotlinExtensions(kotlinPath, protoPackage);
    }

    private async Task GenerateKotlinBuildFile(string kotlinPath, ProtoPackage package)
    {
        var buildFile = $@"// Generated by Axiom Endpoints
import com.google.protobuf.gradle.*

plugins {{
    id(""com.android.library"") version ""8.2.0""
    id(""org.jetbrains.kotlin.android"") version ""1.9.20""
    id(""com.google.protobuf"") version ""0.9.4""
    `maven-publish`
}}

group = ""com.{_options.Organization}.{package.Name.ToLower()}""
version = ""{package.Version}""

android {{
    namespace = ""com.{_options.Organization}.{package.Name.ToLower()}.grpc""
    compileSdk = 34

    defaultConfig {{
        minSdk = 21
        testInstrumentationRunner = ""androidx.test.runner.AndroidJUnitRunner""
    }}

    compileOptions {{
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }}

    kotlinOptions {{
        jvmTarget = ""17""
    }}

    publishing {{
        singleVariant(""release"") {{
            withSourcesJar()
        }}
    }}
}}

dependencies {{
    implementation(""io.grpc:grpc-protobuf:1.59.0"")
    implementation(""io.grpc:grpc-kotlin-stub:1.4.0"")
    implementation(""com.google.protobuf:protobuf-kotlin:3.24.4"")
    implementation(""org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3"")
}}

protobuf {{
    protoc {{
        artifact = ""com.google.protobuf:protoc:3.24.4""
    }}

    plugins {{
        create(""grpc"") {{
            artifact = ""io.grpc:protoc-gen-grpc-java:1.59.0""
        }}
        create(""grpckt"") {{
            artifact = ""io.grpc:protoc-gen-grpc-kotlin:1.4.0:jdk8@jar""
        }}
    }}

    generateProtoTasks {{
        all().forEach {{
            it.plugins {{
                create(""grpc"")
                create(""grpckt"")
            }}
            it.builtins {{
                create(""kotlin"")
            }}
        }}
    }}
}}

publishing {{
    publications {{
        register<MavenPublication>(""release"") {{
            groupId = ""com.{_options.Organization}.{package.Name.ToLower()}""
            artifactId = ""{package.Name.ToLower()}-grpc-types""
            version = ""{package.Version}""

            afterEvaluate {{
                from(components[""release""])
            }}
        }}
    }}
}}";

        await File.WriteAllTextAsync(Path.Combine(kotlinPath, "build.gradle.kts"), buildFile);
    }

    private async Task GenerateMetadata(ProtoPackage package, string outputPath)
    {
        var metadata = new
        {
            package = package.Name,
            version = package.Version.ToString(),
            generatedAt = DateTime.UtcNow,
            services = package.Files
                .SelectMany(f => f.Services)
                .Select(s => new
                {
                    name = s.Name,
                    methods = s.Methods.Select(m => new
                    {
                        name = m.Name,
                        inputType = m.InputType,
                        outputType = m.OutputType,
                        clientStreaming = m.ClientStreaming,
                        serverStreaming = m.ServerStreaming
                    })
                }),
            messages = package.Files
                .SelectMany(f => f.Messages)
                .Select(m => new
                {
                    name = m.Name,
                    fields = m.Fields.Select(f => new
                    {
                        name = f.Name,
                        type = f.Type,
                        number = f.Number
                    })
                })
        };

        var json = JsonSerializer.Serialize(metadata, new JsonSerializerOptions
        {
            WriteIndented = true
        });

        await File.WriteAllTextAsync(Path.Combine(outputPath, "metadata.json"), json);
    }
}
4. MSBuild Integration
csharp// src/AxiomEndpoints.Grpc.TypeGen/Build/AxiomGrpcTypes.targets
<Project>
  <PropertyGroup>
    <GenerateAxiomGrpcTypes Condition="'$(GenerateAxiomGrpcTypes)' == ''">true</GenerateAxiomGrpcTypes>
    <AxiomGrpcTypesOutputPath Condition="'$(AxiomGrpcTypesOutputPath)' == ''">$(MSBuildProjectDirectory)/grpc-types</AxiomGrpcTypesOutputPath>
    <AxiomGrpcLanguages Condition="'$(AxiomGrpcLanguages)' == ''">Swift;Kotlin;CSharp</AxiomGrpcLanguages>
  </PropertyGroup>

  <Target Name="GenerateAxiomGrpcTypes"
          AfterTargets="Build"
          Condition="'$(GenerateAxiomGrpcTypes)' == 'true'">

    <Exec Command="dotnet tool restore" />

    <Exec Command="dotnet axiom-grpc-typegen
          --assembly &quot;$(TargetPath)&quot;
          --output &quot;$(AxiomGrpcTypesOutputPath)&quot;
          --languages $(AxiomGrpcLanguages)
          --organization $(OrganizationName)
          --swift-prefix $(SwiftPrefix)
          --include-http-bindings true" />

    <Message Text="Generated gRPC types in $(AxiomGrpcTypesOutputPath)" Importance="high" />
  </Target>

  <!-- Package types for distribution -->
  <Target Name="PackageGrpcTypes"
          AfterTargets="GenerateAxiomGrpcTypes"
          Condition="'$(PackageGrpcTypes)' == 'true'">

    <Exec Command="cd $(AxiomGrpcTypesOutputPath)/swift &amp;&amp; swift build"
          Condition="$(AxiomGrpcLanguages.Contains('Swift'))" />

    <Exec Command="cd $(AxiomGrpcTypesOutputPath)/kotlin &amp;&amp; ./gradlew build"
          Condition="$(AxiomGrpcLanguages.Contains('Kotlin'))" />

    <Exec Command="cd $(AxiomGrpcTypesOutputPath)/csharp &amp;&amp; dotnet pack"
          Condition="$(AxiomGrpcLanguages.Contains('CSharp'))" />
  </Target>
</Project>
5. Usage in Client Frameworks
The generated types integrate seamlessly with existing client frameworks:
Swift Client Framework
swift// Your existing client framework
import Foundation
import TodoApiGrpcTypes
import GRPC

class TodoServiceClient {
    private let grpcClient: TodoService_ServiceAsyncClient

    init(channel: GRPCChannel) {
        self.grpcClient = TodoService_ServiceAsyncClient(channel: channel)
    }

    // Your framework's methods using the generated types
    func createTodo(title: String, description: String?) async throws -> Todo {
        var request = CreateTodoRequest()
        request.title = title
        if let description = description {
            request.description = description
        }

        return try await grpcClient.createTodo(request)
    }
}
Kotlin Client Framework
kotlin// Your existing client framework
package com.yourcompany.framework

import com.myorg.todoapi.grpc.*
import kotlinx.coroutines.flow.Flow

class TodoServiceClient(private val stub: TodoServiceGrpcKt.TodoServiceCoroutineStub) {

    // Your framework's methods using the generated types
    suspend fun createTodo(title: String, description: String?): Todo {
        val request = createTodoRequest {
            this.title = title
            description?.let { this.description = it }
        }

        return stub.createTodo(request)
    }

    fun streamTodos(): Flow<TodoEvent> {
        val request = streamTodosRequest {}
        return stub.streamTodos(request)
    }
}
C# Client Framework
csharp// Your existing client framework
using TodoApi.Grpc;
using Grpc.Core;

public class TodoServiceClient
{
    private readonly TodoService.TodoServiceClient _grpcClient;

    public TodoServiceClient(ChannelBase channel)
    {
        _grpcClient = new TodoService.TodoServiceClient(channel);
    }

    // Your framework's methods using the generated types
    public async Task<Todo> CreateTodoAsync(string title, string description = null)
    {
        var request = new CreateTodoRequest
        {
            Title = title,
            Description = description ?? string.Empty
        };

        return await _grpcClient.CreateTodoAsync(request);
    }
}
6. CI/CD Integration
yaml# .github/workflows/grpc-types.yml
name: Generate and Publish gRPC Types

on:
  push:
    branches: [main]
    paths:
      - 'src/**/*.cs'
      - '**/*Endpoint*.cs'

jobs:
  generate-types:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 9.0.x

    - name: Install protoc
      uses: arduino/setup-protoc@v2
      with:
        version: '24.x'
        include-pre-releases: false

    - name: Build
      run: dotnet build --configuration Release

    - name: Generate gRPC Types
      run: |
        dotnet tool install -g axiom-grpc-typegen
        axiom-grpc-typegen \
          --assembly ./bin/Release/net9.0/YourApi.dll \
          --output ./grpc-types \
          --languages Swift,Kotlin,CSharp \
          --organization yourorg

    # Swift Package
    - name: Publish Swift Package
      if: success()
      run: |
        cd grpc-types/swift
        git init
        git add .
        git commit -m "Generated types v${{ github.sha }}"
        git tag ${{ github.sha }}
        git remote add origin https://github.com/${{ github.repository }}-swift-types.git
        git push -u origin main --tags

    # Kotlin/Android Package
    - name: Publish to Maven
      if: success()
      run: |
        cd grpc-types/kotlin
        ./gradlew publish

    # NuGet Package
    - name: Publish to NuGet
      if: success()
      run: |
        cd grpc-types/csharp
        dotnet pack -c Release
        dotnet nuget push bin/Release/*.nupkg \
          --api-key ${{ secrets.NUGET_API_KEY }} \
          --source https://api.nuget.org/v3/index.json
This approach provides:

Clean separation: Types only, no client implementation
Platform idiomatic: Each platform gets native types
Version control: Types are versioned with your API
Easy integration: Drop into any existing client framework
Type safety: Full IntelliSense and compile-time checking
Streaming support: Native async patterns for each platform
