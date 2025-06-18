// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AxiomStudio-iOS",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "AxiomStudio-iOS",
            targets: ["AxiomStudio-iOS"]
        )
    ],
    dependencies: [
        .package(path: "../AxiomStudio-Shared"),
        .package(path: "../../../CODEBASE"),
    ],
    targets: [
        .executableTarget(
            name: "AxiomStudio-iOS",
            dependencies: [
                .product(name: "AxiomStudio-Shared", package: "AxiomStudio-Shared"),
                .product(name: "AxiomCore", package: "CODEBASE"),
                .product(name: "AxiomArchitecture", package: "CODEBASE"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AxiomStudio-iOSTests",
            dependencies: ["AxiomStudio-iOS"],
            path: "Tests"
        ),
    ]
)