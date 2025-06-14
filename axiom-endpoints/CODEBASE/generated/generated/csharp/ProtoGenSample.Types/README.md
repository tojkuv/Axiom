# ProtoGenSample.Types

gRPC types for ProtoGenSample

## Installation

Install via NuGet Package Manager:

```
Install-Package ProtoGenSample.Types
```

Or via .NET CLI:

```
dotnet add package ProtoGenSample.Types
```

## Usage

```csharp
using ProtoGenSample.Types;

// Types work as domain models
var request = new CreateProductRequest
{
    Name = "Build something awesome",
    Description = "Using gRPC types as domain models",
    Category = ProductCategory.Electronics
};

// Use with any gRPC client
var client = new ProductService.ProductServiceClient(channel);
var response = await client.CreateProductAsync(request);

// Validation
var validationResult = request.Validate();
if (!validationResult.IsValid)
{
    foreach (var error in validationResult.Errors)
    {
        Console.WriteLine($"{error.Field}: {error.Message}");
    }
}
```
