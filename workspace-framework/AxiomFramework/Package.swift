// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AxiomFramework",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
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
            dependencies: ["AxiomMacros"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release)),
                .define("TESTING", .when(platforms: [], configuration: .debug)),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("GlobalConcurrency")
            ]
        ),
        .target(
            name: "AxiomTesting",
            dependencies: ["Axiom"],
            swiftSettings: [
                .define("TESTING"),
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .macro(
            name: "AxiomMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .define("RELEASE", .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "AxiomTests",
            dependencies: ["Axiom", "AxiomTesting"],
            swiftSettings: [
                .define("TESTING"),
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "AxiomMacrosTests",
            dependencies: [
                "AxiomMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: [
                .define("TESTING")
            ]
        ),
    ]
)