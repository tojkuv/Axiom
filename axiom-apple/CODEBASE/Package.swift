// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AxiomApple",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "AxiomApple", targets: ["AxiomApple"]),
        .library(name: "AxiomCore", targets: ["AxiomCore"]),
        .library(name: "AxiomArchitecture", targets: ["AxiomArchitecture"]),
        .library(name: "AxiomPlatform", targets: ["AxiomPlatform"]),
        .library(name: "AxiomCapabilities", targets: ["AxiomCapabilities"]),
        .library(name: "AxiomCapabilityDomains", targets: ["AxiomCapabilityDomains"]),
        .library(name: "AxiomTesting", targets: ["AxiomTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        // Layer 1: Foundation (zero dependencies)
        .target(
            name: "AxiomCore",
            dependencies: [],
            path: "Sources/AxiomCore"
        ),
        
        // Layer 2: Architecture (depends only on Core)
        .target(
            name: "AxiomArchitecture",
            dependencies: ["AxiomCore"],
            path: "Sources/AxiomArchitecture"
        ),
        
        // Layer 3: Platform Integration
        .target(
            name: "AxiomPlatform",
            dependencies: ["AxiomArchitecture"],
            path: "Sources/AxiomPlatform"
        ),
        
        // Layer 4: Capabilities
        .target(
            name: "AxiomCapabilities",
            dependencies: ["AxiomPlatform"],
            path: "Sources/AxiomCapabilities"
        ),
        
        // Layer 5: Capability Domains
        .target(
            name: "AxiomCapabilityDomains",
            dependencies: ["AxiomCapabilities", "AxiomPlatform"],
            path: "Sources/AxiomCapabilityDomains"
        ),
        
        // Developer Tools (isolated)
        .macro(
            name: "AxiomMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/AxiomMacros"
        ),
        
        .target(
            name: "AxiomTesting",
            dependencies: ["AxiomCore", "AxiomArchitecture", "AxiomPlatform", "AxiomCapabilities"],
            path: "Sources/AxiomTesting"
        ),
        
        // Umbrella target (convenience)
        .target(
            name: "AxiomApple",
            dependencies: [
                "AxiomCore", 
                "AxiomArchitecture", 
                "AxiomPlatform",
                "AxiomCapabilities", 
                "AxiomCapabilityDomains", 
                "AxiomMacros"
            ],
            path: "Sources/AxiomApple"
        ),
        
        // Module-specific Test Targets
        .testTarget(
            name: "AxiomCoreTests",
            dependencies: ["AxiomCore", "AxiomArchitecture", "AxiomTesting"],
            path: "Tests/AxiomCore"
        ),
        .testTarget(
            name: "AxiomArchitectureTests", 
            dependencies: ["AxiomArchitecture", "AxiomCore", "AxiomMacros", "AxiomTesting"],
            path: "Tests/AxiomArchitecture"
        ),
        .testTarget(
            name: "AxiomPlatformTests",
            dependencies: ["AxiomPlatform", "AxiomArchitecture", "AxiomTesting"],
            path: "Tests/AxiomPlatform"
        ),
        .testTarget(
            name: "AxiomCapabilityTests",
            dependencies: ["AxiomCapabilities", "AxiomCapabilityDomains", "AxiomPlatform", "AxiomTesting"],
            path: "Tests/AxiomCapabilities"
        ),
        .testTarget(
            name: "AxiomCapabilityDomainsTests",
            dependencies: ["AxiomCapabilityDomains", "AxiomCapabilities", "AxiomPlatform", "AxiomArchitecture", "AxiomTesting"],
            path: "Tests/AxiomCapabilityDomains"
        ),
        .testTarget(
            name: "AxiomMacrosTests",
            dependencies: [
                "AxiomMacros", 
                "AxiomCore", 
                "AxiomTesting", 
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            path: "Tests/AxiomMacros"
        ),
        .testTarget(
            name: "AxiomIntegrationTests",
            dependencies: ["AxiomApple", "AxiomTesting"],
            path: "Tests/Integration"
        ),
    ]
)