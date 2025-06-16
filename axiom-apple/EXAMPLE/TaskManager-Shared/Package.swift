// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskManager-Shared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TaskManager-Shared",
            targets: ["TaskManager-Shared"]
        ),
    ],
    dependencies: [
        .package(path: "../../CODEBASE")
    ],
    targets: [
        .target(
            name: "TaskManager-Shared",
            dependencies: [
                .product(name: "Axiom", package: "CODEBASE")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TaskManager-SharedTests",
            dependencies: ["TaskManager-Shared"],
            path: "Tests"
        ),
    ]
)