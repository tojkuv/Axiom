# Package Generation Example

This example demonstrates how to use **Axiom Endpoints** to build APIs and generate **gRPC client packages** for multiple programming languages.

## 🎯 What This Example Shows

- **Complete API Implementation**: A library management system with books, genres, and events
- **Aspire-Integrated Package Generation**: Automatic generation of Swift, Kotlin, and C# gRPC clients during build
- **Type Safety**: Comprehensive validation attributes that carry over to generated packages
- **Real-time Events**: Event-driven architecture with domain events
- **Production Ready**: Complete packages with proper manifests and documentation

## 📚 Library Management API

The example implements a comprehensive library management system with:

### Core Features
- **Book CRUD**: Create, read, update, delete books
- **Advanced Search**: Filter by genre, author, year, price, availability with pagination
- **Genre Management**: Predefined categories with descriptions
- **Inventory Tracking**: Available vs total copies
- **Event System**: Real-time events for all operations

### Domain Model
- **Books**: Title, Author, ISBN, Genre, Price, Copies, Specifications
- **Genres**: 20+ predefined categories (Fiction, Science, Technology, etc.)
- **Events**: BookAdded, BookUpdated, BookBorrowed, BookReturned
- **Validation**: Comprehensive validation attributes for type safety

## 🚀 Getting Started

### 1. Run with Aspire

```bash
cd SAMPLES/PackageGenerationExample/AppHost
dotnet run
```

This will:
- Launch the Aspire dashboard
- Start the Library Management API
- Automatically generate client packages during build
- Monitor the application health and logs

Visit the Aspire dashboard to see the running services and package generation status.

### 2. Access the API

Once running, the API will be available at the endpoint shown in the Aspire dashboard.
Visit the API endpoint to see the Swagger documentation and test the endpoints.

### 3. Package Generation

Packages are automatically generated when you build the Aspire project:

```bash
cd SAMPLES/PackageGenerationExample/AppHost
dotnet build
```

This will:
- Build the API project
- Extract types using AxiomEndpoints.ProtoGen
- Generate protobuf files
- Compile to Swift, Kotlin, and C# packages
- Create complete packages with manifests and documentation

### 3. Use Generated Packages

The generated packages are located in the configured output directories:

```
generated-packages/
├── swift/
│   └── LibraryManagementSDK/       # Swift Package Manager package
│       ├── Package.swift
│       ├── Sources/
│       ├── Documentation/
│       └── Samples/
├── kotlin/
│   └── com.librarymanagement.sdk/  # Gradle/Maven package
│       ├── build.gradle.kts
│       ├── src/main/kotlin/
│       ├── docs/
│       └── samples/
├── csharp/
│   └── LibraryManagement.Client/   # .NET project/NuGet package
│       ├── LibraryManagement.Client.csproj
│       ├── Generated/
│       ├── Documentation/
│       └── Samples/
└── README.md                       # Integration guide
```

## 📱 Client Usage Examples

### Swift (iOS/macOS)
```swift
import LibraryApiSwift

let request = Libraryapi_CreateBookRequest.with {
    $0.title = "Swift Programming Guide"
    $0.author = "Apple Inc."
    $0.genre = .technology
    $0.totalCopies = 5
}

let client = Libraryapi_LibraryServiceAsyncClient(channel: channel)
let response = try await client.createBook(request)
```

### Kotlin (Android/JVM)
```kotlin
import com.axiom.libraryapi.*

val request = CreateBookRequest.newBuilder()
    .setTitle("Kotlin Programming")
    .setAuthor("JetBrains") 
    .setGenre(BookGenre.TECHNOLOGY)
    .setTotalCopies(3)
    .build()

val client = LibraryServiceGrpc.newBlockingStub(channel)
val response = client.createBook(request)
```

### C# (.NET)
```csharp
using LibraryApi.Grpc;

var request = new CreateBookRequest
{
    Title = "C# Programming Guide",
    Author = "Microsoft",
    Genre = BookGenre.Technology,
    TotalCopies = 4
};

var client = new LibraryService.LibraryServiceClient(channel);
var response = await client.CreateBookAsync(request);
```

## 🔧 Key Features Demonstrated

### 1. Type Safety
- Validation attributes from C# carry over to proto definitions
- Strong typing in all generated languages
- Compile-time safety for API contracts

### 2. Comprehensive Domain Model
- Complex nested types (BookSpecification)
- Enumerations with meaningful values
- Collections and dictionaries
- Timestamps and metadata

### 3. Event-Driven Architecture
- Domain events for all major operations
- Real-time streaming support
- Audit trail capabilities

### 4. Production-Ready Packages
- Complete package manifests (Package.swift, build.gradle.kts, .csproj)
- Proper dependencies and versioning
- Comprehensive documentation
- Ready for distribution

## 📊 API Endpoints

### Books
- `POST /api/books` - Create a new book
- `GET /api/books/{id}` - Get a specific book
- `GET /api/books` - Search books with filters
- `PUT /api/books/{id}` - Update a book
- `DELETE /api/books/{id}` - Delete a book

### Genres
- `GET /api/genres` - Get all available genres

### System
- `GET /health` - Health check
- `GET /api/info` - API information
- `GET /` - Swagger documentation (development)

## 🎯 Key Benefits

### For API Developers
- **Single Source of Truth**: Define your API once in C#
- **Automatic Client Generation**: No manual proto file writing
- **Type Safety**: Validation rules preserved across languages
- **Documentation**: Self-documenting with XML comments

### For Client Developers
- **Native Packages**: Platform-specific packages (SPM, Gradle, NuGet)
- **Type Safety**: Strong typing in target languages
- **Complete**: All dependencies and documentation included
- **Ready to Use**: Copy and integrate immediately

### For Organizations
- **Consistency**: Same API contract across all platforms
- **Efficiency**: Faster client development
- **Maintainability**: Single source to update
- **Quality**: Reduced integration errors

## 🔄 Development Workflow

1. **Develop API**: Build endpoints using Axiom Endpoints
2. **Build with Aspire**: Run `dotnet build` in AppHost - packages generate automatically
3. **Distribute**: Copy packages from `generated-packages/` to client applications
4. **Integrate**: Use type-safe clients in your apps
5. **Iterate**: Update API and rebuild - packages regenerate automatically

## ⚙️ Configuration

Package generation uses a **progressive disclosure API** - simple by default, powerful when needed:

### 🎯 Level 1: Ultra-Simple (90% of use cases)

```csharp
// Just specify languages - everything else uses smart conventions!
var libraryApi = builder.AddProject<Projects.PackageGenerationExample>("library-api")
    .WithAxiomPackageGeneration(PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp);

// Smart conventions create:
// - Swift: Package "PackageSDK" in "generated-packages/swift/"
// - Kotlin: Package "com.package.sdk" in "generated-packages/kotlin/"
// - C#: Package "Package.Client" in "generated-packages/csharp/"
```

### 🎯 Level 2: Common Customizations

```csharp
// Override only what's different from conventions
var customApi = builder.AddProject<Projects.PackageGenerationExample>("library-api")
    .WithAxiomPackageGeneration("LibraryManagement", PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp)
        .To("../custom-packages")           // Custom output path
        .Version("2.0.0")                   // Custom version
        .SwiftName("LibrarySDK")             // Override Swift name only
        .KotlinName("com.library.client")    // Override Kotlin name only
        .WithDocs()                          // Include documentation
        .WithSamples()                       // Include samples
        .Parallel(maxConcurrency: 3);        // Parallel generation
```

### 🎯 Level 3: Advanced (Complex scenarios)

```csharp
// Full power when you need fine-grained control
var advancedApi = builder.AddProject<Projects.PackageGenerationExample>("library-api")
    .WithAxiomPackageGenerationAdvanced(options =>
    {
        options
            .DefaultPackagePrefix("LibraryManagement")
            .AddSwiftPackage(config => config
                .OutputPath("../ios-sdk")
                .PackageName("LibraryManagementSDK")
                .IncludeDocumentation()
                .AddDependency("SwiftProtobuf", "1.25.0")
                .WithOption("minimum-deployment", "iOS 15.0"))
            .AddKotlinPackage(config => config
                .OutputPath("../android-sdk")
                .WithOption("kotlin-version", "1.9.0"));
    });
```

## 🚀 Dramatic Verbosity Reduction

**Before (Old API):**
```csharp
// 25+ lines for basic setup
.WithAxiomPackageGeneration(options =>
{
    options.Languages.Add("Swift");
    options.Languages.Add("Kotlin");
    options.Languages.Add("CSharp");
    options.OutputPath = "../generated-packages";
    options.PackageNamePrefix = "LibraryManagement";
    options.PackageVersion = "1.0.0";
    options.GenerateOnBuild = true;
    options.CleanOutputPath = true;
    options.AdditionalOptions["swift-package-name"] = "LibraryManagementSDK";
    options.AdditionalOptions["kotlin-package-name"] = "com.librarymanagement.sdk";
    options.AdditionalOptions["csharp-package-name"] = "LibraryManagement.Client";
    // ... more configuration
});
```

**After (New API):**
```csharp
// 1 line for the same result!
.WithAxiomPackageGeneration("LibraryManagement", PackageLanguage.Swift, PackageLanguage.Kotlin, PackageLanguage.CSharp)
```

**That's a 95% reduction in code for common scenarios!**

### Key Benefits

- ✅ **Smart Conventions**: Automatic paths, names, and settings based on language best practices
- ✅ **Type-Safe Languages**: No more string typos with `PackageLanguage` enum
- ✅ **Progressive Complexity**: Simple for common cases, powerful for advanced needs
- ✅ **Override-Only**: Only specify what's different from conventions
- ✅ **Short Method Names**: `.To()`, `.Version()`, `.WithDocs()` instead of verbose method names
- ✅ **Individual Paths**: Each language can have completely custom output directories
- ✅ **Minimal Nesting**: Flat method chains instead of nested lambdas

## 🎉 Next Steps

- **Customize the Domain**: Modify models and endpoints for your use case
- **Add Authentication**: Integrate security into your API
- **Deploy**: Host your API and distribute packages
- **Scale**: Add more endpoints and generate updated packages

This example shows the complete power of **Axiom Endpoints** for building APIs that seamlessly integrate with multi-platform client applications through automatically generated, type-safe gRPC packages!