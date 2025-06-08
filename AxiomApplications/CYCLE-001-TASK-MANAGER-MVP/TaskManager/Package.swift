// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskManager",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TaskManager",
            targets: ["TaskManager"]
        ),
    ],
    dependencies: [
        .package(name: "Axiom", path: "../../../workspace-framework/AxiomFramework")
    ],
    targets: [
        .target(
            name: "TaskManager",
            dependencies: [
                .product(name: "Axiom", package: "Axiom")
            ]
        ),
        .testTarget(
            name: "TaskManagerTests",
            dependencies: [
                "TaskManager",
                .product(name: "AxiomTesting", package: "Axiom")
            ]
        ),
    ]
)