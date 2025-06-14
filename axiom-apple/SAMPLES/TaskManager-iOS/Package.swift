// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskManager-iOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "TaskManager-iOS",
            targets: ["TaskManager-iOS"]
        ),
    ],
    dependencies: [
        .package(path: "../../CODEBASE"),
        .package(path: "../TaskManager-Shared")
    ],
    targets: [
        .executableTarget(
            name: "TaskManager-iOS",
            dependencies: [
                .product(name: "Axiom", package: "CODEBASE"),
                .product(name: "TaskManager-Shared", package: "TaskManager-Shared")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TaskManager-iOSTests",
            dependencies: ["TaskManager-iOS"],
            path: "Tests"
        ),
    ]
)