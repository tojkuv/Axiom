// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AxiomStudio-macOS",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "AxiomStudio-macOS",
            targets: ["AxiomStudio-macOS"]
        )
    ],
    dependencies: [
        .package(path: "../AxiomStudio-Shared"),
        .package(path: "../../../CODEBASE"),
    ],
    targets: [
        .executableTarget(
            name: "AxiomStudio-macOS",
            dependencies: [
                .product(name: "AxiomStudio-Shared", package: "AxiomStudio-Shared"),
                .product(name: "AxiomCore", package: "CODEBASE"),
                .product(name: "AxiomArchitecture", package: "CODEBASE"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AxiomStudio-macOSTests",
            dependencies: ["AxiomStudio-macOS"],
            path: "Tests"
        ),
    ]
)