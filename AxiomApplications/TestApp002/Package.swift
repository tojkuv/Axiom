// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestApp002",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        // No external dependencies for now
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TestApp002Core",
            dependencies: [],
            path: "Sources/TestApp002"
        ),
        .executableTarget(
            name: "TestApp002",
            dependencies: ["TestApp002Core"],
            path: "Sources/TestApp002Executable"
        ),
        .testTarget(
            name: "TestApp002Tests",
            dependencies: ["TestApp002Core"]
        )
    ]
)
