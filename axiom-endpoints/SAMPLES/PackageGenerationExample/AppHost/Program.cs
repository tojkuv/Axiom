using AxiomEndpoints.Aspire;
using AxiomEndpoints.Aspire.PackageGeneration;

var builder = DistributedApplication.CreateBuilder(args);

// Add Axiom package generation support
builder.AddAxiomPackageGeneration();

// 🎯 LEVEL 1: Ultra-Simple API (90% of use cases)
// Just specify what you want - everything else uses smart conventions!
var libraryApi = builder.AddProject<Projects.PackageGenerationExample>("library-api")
    .WithExternalHttpEndpoints()
    .WithAxiomPackageGeneration(PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp);

// 🎯 LEVEL 2: Common Customizations
// Override only what's different from conventions
var customizedApi = builder.AddProject<Projects.PackageGenerationExample>("library-api-custom")
    .WithExternalHttpEndpoints()
    .WithAxiomPackageGeneration("LibraryManagement", PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp)
        .To("../custom-packages")           // Custom output path
        .Version("2.0.0")                   // Custom version
        .SwiftName("LibrarySDK")             // Override Swift name
        .KotlinName("com.library.client")    // Override Kotlin name
        .WithDocs()                          // Include documentation
        .WithSamples()                       // Include samples
        .Parallel(maxConcurrency: 3);        // Parallel generation

// 🎯 Alternative: Even more concise with prefix and path
var ultraSimple = builder.AddProject<Projects.PackageGenerationExample>("library-api-ultra")
    .WithExternalHttpEndpoints()
    .WithPackageGeneration("LibraryManagement", "../packages", 
        PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp)
        .WithDocs()
        .WithSamples();

// 🎯 LEVEL 3: Advanced Configuration (for complex scenarios)
// Full power when you need it
var advancedApi = builder.AddProject<Projects.PackageGenerationExample>("library-api-advanced")
    .WithExternalHttpEndpoints()
    .WithAxiomPackageGenerationAdvanced(options =>
    {
        options
            .DefaultPackagePrefix("LibraryManagement")
            .DefaultVersion("1.0.0")
            .BaseOutputPath("../advanced-packages")
            .ParallelGeneration(true, maxConcurrency: 3)
            
            // Full detailed configuration when needed
            .AddSwiftPackage(config => config
                .OutputPath("../advanced-packages/swift")
                .PackageName("LibraryManagementSDK")
                .IncludeDocumentation()
                .IncludeSamples()
                .WithOption("platform-support", "iOS,macOS,tvOS,watchOS")
                .WithOption("minimum-deployment", "iOS 15.0, macOS 12.0")
                .AddDependency("SwiftProtobuf", "1.25.0")
                .AddDependency("GRPC", "1.8.0"))
            
            .AddKotlinPackage(config => config
                .OutputPath("../advanced-packages/kotlin")
                .PackageName("com.librarymanagement.sdk")
                .IncludeDocumentation()
                .IncludeSamples()
                .WithOption("kotlin-version", "1.9.0")
                .WithOption("target-jvm", "17")
                .AddDependency("com.google.protobuf:protobuf-kotlin", "3.25.0")
                .AddDependency("io.grpc:grpc-kotlin-stub", "1.4.0"))
            
            .AddCSharpPackage(config => config
                .OutputPath("../advanced-packages/csharp")
                .PackageName("LibraryManagement.Client")
                .IncludeDocumentation()
                .IncludeSamples()
                .WithOption("target-framework", "net8.0")
                .WithOption("nullable-enable", "true")
                .AddDependency("Google.Protobuf", "3.25.0")
                .AddDependency("Grpc.Net.Client", "2.59.0"));
    });

// 🎯 Alternative Advanced: Fluent extensions for medium complexity
var fluentAdvanced = builder.AddPackageGeneration("library-packages-fluent", customizedApi.Build())
    .WithDefaultPackagePrefix("LibraryManagement")
    .WithDefaultVersion("1.0.0")
    .WithBaseOutputPath("../fluent-packages")
    .WithLanguages(PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp)
    .WithSwiftPackage("../fluent-packages/swift", "LibraryManagementSDK")
    .WithKotlinPackage("../fluent-packages/kotlin", "com.librarymanagement.sdk")
    .WithCSharpPackage("../fluent-packages/csharp", "LibraryManagement.Client")
    .WithGlobalOption("include-documentation", "true")
    .WithParallelGeneration(enabled: true, maxConcurrency: 2);

var app = builder.Build();

await app.RunAsync();