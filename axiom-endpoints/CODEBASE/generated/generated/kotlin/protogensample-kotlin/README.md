# protogensample-kotlin

gRPC types for ProtoGenSample

## Installation

### Gradle

Add this dependency to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.company.protogensample:protogensample-kotlin:1.0.0")
}
```

## Usage

```kotlin
import com.company.protogensample.*
import kotlinx.coroutines.flow.*

// Use as domain models
val request = createProductRequest {
    name = "Build something awesome"
    description = "Using gRPC types as domain models"
    category = ProductCategory.ELECTRONICS
}

// Direct use with gRPC
val stub = ProductServiceGrpcKt.ProductServiceCoroutineStub(channel)
val response = stub.createProduct(request)
```
