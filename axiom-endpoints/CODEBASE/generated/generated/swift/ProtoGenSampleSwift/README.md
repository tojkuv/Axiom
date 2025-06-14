# ProtoGenSampleSwift

gRPC types for ProtoGenSample

## Installation

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/company/ProtoGenSampleSwift.git", from: "1.0.0")
]
```

## Usage

```swift
import ProtoGenSampleSwift
import GRPC

// Use generated types directly as domain models
let request = CreateProductRequest.with {
    $0.name = "Build something awesome"
    $0.description = "Using gRPC types as domain models"
    $0.category = .electronics
}

// Types are fully compatible with gRPC clients
let client = ProductServiceAsyncClient(channel: channel)
let response = try await client.createProduct(request)
```
