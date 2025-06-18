// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "axiom-ios-observability-client",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AxiomHotReloadiOS",
            targets: ["AxiomHotReloadiOS"]
        ),
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]
        ),
        .library(
            name: "SwiftUIRenderer", 
            targets: ["SwiftUIRenderer"]
        ),
        .library(
            name: "HotReloadProtocol",
            targets: ["HotReloadProtocol"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "AxiomHotReloadiOS",
            dependencies: [
                "HotReloadProtocol",
                "NetworkClient", 
                "SwiftUIRenderer"
            ]
        ),
        .target(
            name: "HotReloadProtocol",
            dependencies: []
        ),
        .target(
            name: "NetworkClient",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                "HotReloadProtocol"
            ]
        ),
        .target(
            name: "SwiftUIRenderer",
            dependencies: [
                "HotReloadProtocol"
            ]
        ),
        .testTarget(
            name: "AxiomHotReloadiOSTests",
            dependencies: ["AxiomHotReloadiOS"]
        ),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient"]
        ),
        .testTarget(
            name: "SwiftUIRendererTests",
            dependencies: ["SwiftUIRenderer"]
        )
    ]
)