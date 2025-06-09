// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AxiomFramework",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Axiom",
            targets: ["Axiom"]
        ),
        .library(
            name: "AxiomTesting",
            targets: ["AxiomTesting"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Axiom",
            dependencies: ["AxiomMacros"]
        ),
        .target(
            name: "AxiomTesting",
            dependencies: ["Axiom"]
        ),
        .macro(
            name: "AxiomMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "AxiomTests",
            dependencies: ["Axiom", "AxiomTesting"]
        ),
        .testTarget(
            name: "AxiomMacrosTests",
            dependencies: [
                "AxiomMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)