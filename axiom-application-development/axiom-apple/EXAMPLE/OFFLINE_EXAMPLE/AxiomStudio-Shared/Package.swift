// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AxiomStudio-Shared",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v26),
        .tvOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "AxiomStudio-Shared",
            targets: ["AxiomStudio-Shared"]
        ),
    ],
    dependencies: [
        .package(path: "../../../CODEBASE")
    ],
    targets: [
        .target(
            name: "AxiomStudio-Shared",
            dependencies: [
                .product(name: "AxiomCore", package: "CODEBASE"),
                .product(name: "AxiomArchitecture", package: "CODEBASE"),
                .product(name: "AxiomCapabilities", package: "CODEBASE"),
                .product(name: "AxiomCapabilityDomains", package: "CODEBASE"),
                .product(name: "AxiomPlatform", package: "CODEBASE"),
                .product(name: "AxiomTesting", package: "CODEBASE")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AxiomStudio-SharedTests",
            dependencies: ["AxiomStudio-Shared"],
            path: "Tests"
        ),
    ]
)