// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ProtoGenSampleSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "ProtoGenSampleSwift",
            targets: ["ProtoGenSampleSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "ProtoGenSampleSwift",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRPC", package: "grpc-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ProtoGenSampleSwiftTests",
            dependencies: ["ProtoGenSampleSwift"],
            path: "Tests"
        )
    ]
)
