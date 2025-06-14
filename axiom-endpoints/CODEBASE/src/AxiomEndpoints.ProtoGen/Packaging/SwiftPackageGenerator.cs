using AxiomEndpoints.ProtoGen.Compilation;

namespace AxiomEndpoints.ProtoGen.Packaging;

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

        try
        {
            // Create Package.swift
            await GeneratePackageSwiftAsync(packageDir, metadata);

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
            await GenerateGitIgnoreAsync(packageDir);

            // Create test structure
            await GenerateTestStructureAsync(packageDir, metadata);

            return new PackageResult
            {
                Success = true,
                PackagePath = packageDir,
                Language = Language.Swift,
                GeneratedFiles = Directory.GetFiles(packageDir, "*.*", SearchOption.AllDirectories).ToList()
            };
        }
        catch (Exception ex)
        {
            return new PackageResult
            {
                Success = false,
                Error = ex.Message,
                PackagePath = packageDir,
                Language = Language.Swift
            };
        }
    }

    private async Task GeneratePackageSwiftAsync(string packageDir, PackageMetadata metadata)
    {
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

// MARK: - Convenience Initializers
extension Google_Protobuf_Empty {{
    public static let `default` = Google_Protobuf_Empty()
}}

// MARK: - Result Handling
public extension Result where Success: Message {{
    func toProtoResult() -> ProtoResult {{
        switch self {{
        case .success(let value):
            return ProtoResult.with {{
                $0.success = true
                $0.data = try! value.serializedData()
            }}
        case .failure(let error):
            return ProtoResult.with {{
                $0.success = false
                $0.error = error.localizedDescription
            }}
        }}
    }}
}}

public struct ProtoResult {{
    public var success: Bool = false
    public var data: Data = Data()
    public var error: String = """"
    
    public static func with(_ configure: (inout ProtoResult) -> Void) -> ProtoResult {{
        var result = ProtoResult()
        configure(&result)
        return result
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(sourcesDir, "Extensions.swift"),
            extensions);
    }

    private async Task GenerateReadmeAsync(string packageDir, PackageMetadata metadata, string language)
    {
        var readme = $@"# {metadata.PackageName}

{metadata.Description}

## Installation

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: ""{metadata.RepositoryUrl}"", from: ""{metadata.Version}"")
]
```

## Usage

```swift
import {metadata.PackageName}
import GRPC

// Use generated types directly as domain models
let request = CreateTodoRequest.with {{
    $0.title = ""Build something awesome""
    $0.description = ""Using gRPC types as domain models""
    $0.priority = .medium
}}

// Types are fully compatible with gRPC clients
let client = TodoServiceAsyncClient(channel: channel)
let response = try await client.createTodo(request)
```

## Features

- ✅ Type-safe gRPC client generation
- ✅ Native Swift types with Codable support
- ✅ Convenient extensions for common operations
- ✅ Validation support
- ✅ JSON serialization/deserialization
- ✅ iOS, macOS, tvOS, and watchOS support

## Generated at

{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC

## Version

{metadata.Version}
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "README.md"),
            readme);
    }

    private async Task GenerateGitIgnoreAsync(string packageDir)
    {
        var gitignore = @".DS_Store
/.build
/Packages
/*.xcodeproj
xcuserdata/
DerivedData/
.swiftpm/
Package.resolved
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, ".gitignore"),
            gitignore);
    }

    private async Task GenerateTestStructureAsync(string packageDir, PackageMetadata metadata)
    {
        var testsDir = Path.Combine(packageDir, "Tests", $"{metadata.PackageName}Tests");
        Directory.CreateDirectory(testsDir);

        var testFile = $@"import XCTest
@testable import {metadata.PackageName}

final class {metadata.PackageName}Tests: XCTestCase {{
    func testMessageSerialization() throws {{
        // Add tests for message serialization/deserialization
        XCTAssertTrue(true, ""Placeholder test"")
    }}
    
    func testValidation() throws {{
        // Add tests for validation
        XCTAssertTrue(true, ""Placeholder test"")
    }}
    
    func testDateConversions() throws {{
        // Test timestamp conversions
        let now = Date()
        let timestamp = Google_Protobuf_Timestamp(date: now)
        let converted = timestamp.date
        
        XCTAssertEqual(now.timeIntervalSince1970, converted.timeIntervalSince1970, accuracy: 0.001)
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(testsDir, $"{metadata.PackageName}Tests.swift"),
            testFile);
    }
}