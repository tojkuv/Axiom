// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "axiom-applications-observability-server",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AxiomObservabilityServer",
            targets: ["AxiomHotReloadServer"]
        ),
        .library(
            name: "AxiomHotReloadServer",
            targets: ["AxiomHotReloadServer"]
        ),
        .library(
            name: "HotReloadProtocol", 
            targets: ["HotReloadProtocol"]
        ),
        .library(
            name: "SwiftUIHotReload",
            targets: ["SwiftUIHotReload"]
        ),
        .library(
            name: "ComposeHotReload", 
            targets: ["ComposeHotReload"]
        ),
        .library(
            name: "NetworkCore",
            targets: ["NetworkCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.40.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AxiomHotReloadServer",
            dependencies: [
                "HotReloadProtocol",
                "SwiftUIHotReload", 
                "ComposeHotReload",
                "NetworkCore",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "HotReloadProtocol",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .target(
            name: "SwiftUIHotReload",
            dependencies: [
                "HotReloadProtocol",
                "NetworkCore",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "ComposeHotReload", 
            dependencies: [
                "HotReloadProtocol",
                "NetworkCore",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "NetworkCore",
            dependencies: [
                "HotReloadProtocol",
                .product(name: "WebSocketKit", package: "websocket-kit"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "AxiomHotReloadServerTests",
            dependencies: ["AxiomHotReloadServer"]
        ),
        .testTarget(
            name: "SwiftUIHotReloadTests", 
            dependencies: ["SwiftUIHotReload"]
        ),
        .testTarget(
            name: "ComposeHotReloadTests",
            dependencies: ["ComposeHotReload"] 
        ),
        .testTarget(
            name: "NetworkCoreTests",
            dependencies: ["NetworkCore"]
        )
    ]
)