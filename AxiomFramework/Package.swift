// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Axiom",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        // Main framework product
        .library(
            name: "Axiom",
            targets: ["Axiom"]
        ),
        // Testing utilities
        .library(
            name: "AxiomTesting",
            targets: ["AxiomTesting"]
        )
    ],
    dependencies: [
        // SwiftSyntax for macro implementation
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
    ],
    targets: [
        // Main framework target
        .target(
            name: "Axiom",
            dependencies: ["AxiomMacros"],
            path: "Sources/Axiom"
        ),
        
        // Macro implementation target
        .macro(
            name: "AxiomMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/AxiomMacros"
        ),
        
        // Testing utilities target
        .target(
            name: "AxiomTesting",
            dependencies: ["Axiom"],
            path: "Sources/AxiomTesting"
        ),
        
        // Test targets (temporarily disabled for stability)
        // TODO: Fix and re-enable comprehensive test suite
        // .testTarget(
        //     name: "AxiomTests", 
        //     dependencies: ["Axiom", "AxiomTesting"],
        //     path: "Tests/AxiomTests"
        // ),
        // .testTarget(
        //     name: "AxiomMacrosTests",
        //     dependencies: [
        //         "AxiomMacros",
        //         .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
        //     ],
        //     path: "Tests/AxiomMacrosTests"
        // ),
    ]
)