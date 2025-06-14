// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskManager-macOS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TaskManager-macOS",
            targets: ["TaskManager-macOS"]
        ),
    ],
    dependencies: [
        .package(path: "../../CODEBASE"),
        .package(path: "../TaskManager-Shared")
    ],
    targets: [
        .executableTarget(
            name: "TaskManager-macOS",
            dependencies: [
                .product(name: "Axiom", package: "CODEBASE"),
                .product(name: "TaskManager-Shared", package: "TaskManager-Shared")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TaskManager-macOSTests",
            dependencies: ["TaskManager-macOS"],
            path: "Tests"
        ),
    ]
)