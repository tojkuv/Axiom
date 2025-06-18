// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskManager-iOS-Tests",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TaskManager-iOS-Tests",
            targets: ["TaskManager-iOS-Tests"]
        ),
    ],
    dependencies: [
        .package(path: "../../../CODEBASE"),
        .package(path: "../../TaskManager-Shared"),
        .package(path: "../")
    ],
    targets: [
        .testTarget(
            name: "TaskManager-iOS-Tests",
            dependencies: [
                .product(name: "Axiom", package: "CODEBASE"),
                .product(name: "TaskManager-Shared", package: "TaskManager-Shared"),
                .product(name: "TaskManager-iOS", package: "TaskManager-iOS")
            ],
            path: "TaskManager_iOSTests"
        ),
    ]
)