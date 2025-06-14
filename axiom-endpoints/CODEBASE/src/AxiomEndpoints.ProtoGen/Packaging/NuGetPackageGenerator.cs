using AxiomEndpoints.ProtoGen.Compilation;

namespace AxiomEndpoints.ProtoGen.Packaging;

/// <summary>
/// NuGet package generator for C#
/// </summary>
public class NuGetPackageGenerator : IPackageGenerator
{
    public async Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata)
    {
        var packageDir = Path.Combine(compilation.OutputPath, metadata.PackageName);
        Directory.CreateDirectory(packageDir);

        try
        {
            // Create .csproj
            await GenerateCsprojAsync(packageDir, metadata);

            // Copy generated files
            foreach (var file in compilation.GeneratedFiles)
            {
                var destPath = Path.Combine(packageDir, Path.GetFileName(file));
                File.Copy(file, destPath, overwrite: true);
            }

            // Generate extensions
            await GenerateExtensionsAsync(packageDir, metadata);

            // Generate validation helpers
            await GenerateValidationHelpersAsync(packageDir, metadata);

            // Create README
            await GenerateReadmeAsync(packageDir, metadata, "C#");

            // Create .gitignore
            await GenerateGitIgnoreAsync(packageDir);

            // Create test project
            await GenerateTestProjectAsync(packageDir, metadata);

            // Create Directory.Build.props
            await GenerateDirectoryBuildPropsAsync(packageDir, metadata);

            return new PackageResult
            {
                Success = true,
                PackagePath = packageDir,
                Language = Language.CSharp,
                GeneratedFiles = Directory.GetFiles(packageDir, "*.*", SearchOption.AllDirectories).ToList()
            };
        }
        catch (Exception ex)
        {
            return new PackageResult
            {
                Success = false,
                Error = ex.Message,
                PackagePath = packageDir,
                Language = Language.CSharp
            };
        }
    }

    private async Task GenerateCsprojAsync(string packageDir, PackageMetadata metadata)
    {
        var csproj = $@"<Project Sdk=""Microsoft.NET.Sdk"">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>13</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningLevel>5</WarningLevel>
    
    <!-- Package Information -->
    <PackageId>{metadata.PackageName}</PackageId>
    <Version>{metadata.Version}</Version>
    <Authors>{metadata.Authors}</Authors>
    <Company>{metadata.Company}</Company>
    <Description>gRPC types for {metadata.ServiceName}</Description>
    <PackageTags>grpc;protobuf;axiom;{string.Join(";", metadata.Tags)}</PackageTags>
    <PackageProjectUrl>{metadata.RepositoryUrl}</PackageProjectUrl>
    <RepositoryUrl>{metadata.RepositoryUrl}</RepositoryUrl>
    <PackageLicenseUrl>{metadata.LicenseUrl}</PackageLicenseUrl>
    <PackageReadmeFile>README.md</PackageReadmeFile>
    
    <!-- NuGet Package Settings -->
    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>
    <IncludeSymbols>true</IncludeSymbols>
    <SymbolPackageFormat>snupkg</SymbolPackageFormat>
    <PackageOutputPath>./nupkg</PackageOutputPath>
    
    <!-- Source Link -->
    <PublishRepositoryUrl>true</PublishRepositoryUrl>
    <EmbedUntrackedSources>true</EmbedUntrackedSources>
    <DebugType>embedded</DebugType>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include=""Google.Protobuf"" Version=""3.25.2"" />
    <PackageReference Include=""Grpc.Core.Api"" Version=""2.60.0"" />
    <PackageReference Include=""Grpc.Net.Client"" Version=""2.60.0"" />
    <PackageReference Include=""System.Text.Json"" Version=""8.0.4"" />
    <PackageReference Include=""System.ComponentModel.Annotations"" Version=""5.0.0"" />
    <PackageReference Include=""Microsoft.SourceLink.GitHub"" Version=""8.0.0"" PrivateAssets=""All"" />
  </ItemGroup>

  <ItemGroup>
    <None Include=""README.md"" Pack=""true"" PackagePath="""" />
  </ItemGroup>

  <ItemGroup>
    <AssemblyAttribute Include=""System.Runtime.CompilerServices.InternalsVisibleTo"">
      <_Parameter1>{metadata.PackageName}.Tests</_Parameter1>
    </AssemblyAttribute>
  </ItemGroup>

</Project>";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, $"{metadata.PackageName}.csproj"),
            csproj);
    }

    private async Task GenerateExtensionsAsync(string packageDir, PackageMetadata metadata)
    {
        var extensions = $@"// Extensions for {metadata.PackageName}
#nullable enable

using System.Text.Json;
using Google.Protobuf;
using Google.Protobuf.WellKnownTypes;

namespace {metadata.PackageName};

/// <summary>
/// Extension methods for protobuf types
/// </summary>
public static class ProtoExtensions
{{
    // Timestamp conversions
    public static DateTime ToDateTime(this Timestamp timestamp)
    {{
        return timestamp.ToDateTime();
    }}

    public static Timestamp ToTimestamp(this DateTime dateTime)
    {{
        return Timestamp.FromDateTime(dateTime.ToUniversalTime());
    }}

    public static DateTimeOffset ToDateTimeOffset(this Timestamp timestamp)
    {{
        return timestamp.ToDateTimeOffset();
    }}

    public static Timestamp ToTimestamp(this DateTimeOffset dateTimeOffset)
    {{
        return Timestamp.FromDateTimeOffset(dateTimeOffset);
    }}

    // Duration conversions
    public static TimeSpan ToTimeSpan(this Duration duration)
    {{
        return duration.ToTimeSpan();
    }}

    public static Duration ToDuration(this TimeSpan timeSpan)
    {{
        return Duration.FromTimeSpan(timeSpan);
    }}

    // JSON serialization
    public static string ToJson<T>(this T message) where T : IMessage<T>
    {{
        return JsonFormatter.Default.Format(message);
    }}

    public static T FromJson<T>(this string json, MessageParser<T> parser) where T : IMessage<T>
    {{
        return parser.ParseJson(json);
    }}

    // System.Text.Json integration
    public static JsonElement ToJsonElement<T>(this T message) where T : IMessage<T>
    {{
        var json = message.ToJson();
        return JsonSerializer.Deserialize<JsonElement>(json);
    }}

    public static string ToSystemTextJson<T>(this T message, JsonSerializerOptions? options = null) where T : IMessage<T>
    {{
        var jsonElement = message.ToJsonElement();
        return JsonSerializer.Serialize(jsonElement, options);
    }}

    // Validation helpers
    public static ValidationResult Validate<T>(this T message) where T : IMessage<T>
    {{
        var errors = new List<ValidationError>();
        
        // Use reflection to check for custom validation attributes
        var type = typeof(T);
        var properties = type.GetProperties();
        
        foreach (var property in properties)
        {{
            var value = property.GetValue(message);
            var validationErrors = ValidateProperty(property, value);
            errors.AddRange(validationErrors);
        }}
        
        return new ValidationResult(errors.Count == 0, errors);
    }}

    private static List<ValidationError> ValidateProperty(System.Reflection.PropertyInfo property, object? value)
    {{
        var errors = new List<ValidationError>();
        
        // Check for validation attributes
        var attributes = property.GetCustomAttributes(typeof(System.ComponentModel.DataAnnotations.ValidationAttribute), true);
        
        foreach (System.ComponentModel.DataAnnotations.ValidationAttribute attr in attributes)
        {{
            if (!attr.IsValid(value))
            {{
                errors.Add(new ValidationError(
                    property.Name,
                    attr.ErrorMessage ?? $""Validation failed for {{property.Name}}"",
                    attr.GetType().Name
                ));
            }}
        }}
        
        return errors;
    }}

    // Null safety helpers
    public static T OrDefault<T>(this T? message) where T : class, IMessage<T>, new()
    {{
        return message ?? new T();
    }}

    public static bool IsNullOrDefault<T>(this T? message) where T : class, IMessage<T>
    {{
        return message == null || message.Equals(Activator.CreateInstance<T>());
    }}

    // Collection helpers
    public static void AddRange<T>(this RepeatedField<T> field, IEnumerable<T> items)
    {{
        foreach (var item in items)
        {{
            field.Add(item);
        }}
    }}

    public static List<T> ToList<T>(this RepeatedField<T> field)
    {{
        return new List<T>(field);
    }}

    public static T[] ToArray<T>(this RepeatedField<T> field)
    {{
        return field.ToArray();
    }}

    // Deep copy helper
    public static T DeepClone<T>(this T message) where T : IMessage<T>
    {{
        return message.Clone();
    }}

    // Equality helpers
    public static bool EqualsDeep<T>(this T message, T other) where T : IMessage<T>
    {{
        return message.Equals(other);
    }}
}}

/// <summary>
/// Validation result
/// </summary>
public record ValidationResult(bool IsValid, IReadOnlyList<ValidationError> Errors)
{{
    public static ValidationResult Success() => new(true, Array.Empty<ValidationError>());
    
    public static ValidationResult Failure(params ValidationError[] errors) => new(false, errors);
    
    public static ValidationResult Failure(IEnumerable<ValidationError> errors) => new(false, errors.ToArray());
}}

/// <summary>
/// Validation error
/// </summary>
public record ValidationError(string Field, string Message, string? Code = null);

/// <summary>
/// Result type for API operations
/// </summary>
public abstract record Result<T>
{{
    public abstract bool IsSuccess {{ get; }}
    public abstract bool IsFailure => !IsSuccess;
    
    public abstract T Value {{ get; }}
    public abstract string Error {{ get; }}
    
    public static Result<T> Success(T value) => new SuccessResult<T>(value);
    public static Result<T> Failure(string error) => new FailureResult<T>(error);
    
    public Result<TNew> Map<TNew>(Func<T, TNew> mapper)
    {{
        return IsSuccess ? Result<TNew>.Success(mapper(Value)) : Result<TNew>.Failure(Error);
    }}
    
    public async Task<Result<TNew>> MapAsync<TNew>(Func<T, Task<TNew>> mapper)
    {{
        return IsSuccess ? Result<TNew>.Success(await mapper(Value)) : Result<TNew>.Failure(Error);
    }}
    
    public Result<TNew> FlatMap<TNew>(Func<T, Result<TNew>> mapper)
    {{
        return IsSuccess ? mapper(Value) : Result<TNew>.Failure(Error);
    }}
    
    public async Task<Result<TNew>> FlatMapAsync<TNew>(Func<T, Task<Result<TNew>>> mapper)
    {{
        return IsSuccess ? await mapper(Value) : Result<TNew>.Failure(Error);
    }}
}}

internal record SuccessResult<T>(T Value) : Result<T>
{{
    public override bool IsSuccess => true;
    public override string Error => throw new InvalidOperationException(""Success result does not have an error"");
}}

internal record FailureResult<T>(string Error) : Result<T>
{{
    public override bool IsSuccess => false;
    public override T Value => throw new InvalidOperationException(""Failure result does not have a value"");
}}";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "Extensions.cs"),
            extensions);
    }

    private async Task GenerateValidationHelpersAsync(string packageDir, PackageMetadata metadata)
    {
        var validation = $@"// Validation helpers for {metadata.PackageName}
#nullable enable

using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace {metadata.PackageName}.Validation;

/// <summary>
/// Custom validation attributes for protobuf messages
/// </summary>
public class ProtoRequiredAttribute : ValidationAttribute
{{
    public override bool IsValid(object? value)
    {{
        return value switch
        {{
            null => false,
            string str => !string.IsNullOrWhiteSpace(str),
            _ => true
        }};
    }}
}}

public class ProtoStringLengthAttribute : ValidationAttribute
{{
    public int MinimumLength {{ get; set; }}
    public int MaximumLength {{ get; set; }}

    public ProtoStringLengthAttribute(int maximumLength)
    {{
        MaximumLength = maximumLength;
    }}

    public override bool IsValid(object? value)
    {{
        if (value is not string str)
            return true;

        return str.Length >= MinimumLength && str.Length <= MaximumLength;
    }}
}}

public class ProtoRangeAttribute : ValidationAttribute
{{
    public object Minimum {{ get; set; }}
    public object Maximum {{ get; set; }}

    public ProtoRangeAttribute(object minimum, object maximum)
    {{
        Minimum = minimum;
        Maximum = maximum;
    }}

    public override bool IsValid(object? value)
    {{
        if (value == null)
            return true;

        if (value is IComparable comparable)
        {{
            return comparable.CompareTo(Minimum) >= 0 && comparable.CompareTo(Maximum) <= 0;
        }}

        return true;
    }}
}}

public class ProtoRegularExpressionAttribute : ValidationAttribute
{{
    public string Pattern {{ get; set; }}
    public RegexOptions Options {{ get; set; }} = RegexOptions.None;

    public ProtoRegularExpressionAttribute(string pattern)
    {{
        Pattern = pattern;
    }}

    public override bool IsValid(object? value)
    {{
        if (value is not string str)
            return true;

        return Regex.IsMatch(str, Pattern, Options);
    }}
}}

/// <summary>
/// Validation service for protobuf messages
/// </summary>
public static class ProtoValidator
{{
    public static ValidationResult ValidateMessage<T>(T message) where T : class
    {{
        var errors = new List<ValidationError>();
        var type = typeof(T);
        var properties = type.GetProperties();

        foreach (var property in properties)
        {{
            var value = property.GetValue(message);
            var propertyErrors = ValidateProperty(property.Name, value, property);
            errors.AddRange(propertyErrors);
        }}

        return new ValidationResult(errors.Count == 0, errors);
    }}

    private static List<ValidationError> ValidateProperty(string propertyName, object? value, System.Reflection.PropertyInfo property)
    {{
        var errors = new List<ValidationError>();
        var attributes = property.GetCustomAttributes(typeof(ValidationAttribute), true);

        foreach (ValidationAttribute attr in attributes)
        {{
            if (!attr.IsValid(value))
            {{
                errors.Add(new ValidationError(
                    propertyName,
                    attr.ErrorMessage ?? $""Validation failed for {{propertyName}}"",
                    attr.GetType().Name.Replace(""Attribute"", """")
                ));
            }}
        }}

        return errors;
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "Validation.cs"),
            validation);
    }

    private async Task GenerateReadmeAsync(string packageDir, PackageMetadata metadata, string language)
    {
        var readme = $@"# {metadata.PackageName}

{metadata.Description}

## Installation

Install via NuGet Package Manager:

```
Install-Package {metadata.PackageName}
```

Or via .NET CLI:

```
dotnet add package {metadata.PackageName}
```

Or add to your `.csproj` file:

```xml
<PackageReference Include=""{metadata.PackageName}"" Version=""{metadata.Version}"" />
```

## Usage

```csharp
using {metadata.PackageName};

// Types work as domain models
var request = new CreateTodoRequest
{{
    Title = ""Build something awesome"",
    Description = ""Using gRPC types as domain models"",
    Priority = Priority.Medium
}};

// Use with any gRPC client
var client = new TodoService.TodoServiceClient(channel);
var response = await client.CreateTodoAsync(request);

// Validation
var validationResult = request.Validate();
if (!validationResult.IsValid)
{{
    foreach (var error in validationResult.Errors)
    {{
        Console.WriteLine($""{{error.Field}}: {{error.Message}}"");
    }}
}}

// JSON serialization
var json = request.ToJson();
var systemTextJson = request.ToSystemTextJson();

// Timestamp conversions
var timestamp = DateTime.UtcNow.ToTimestamp();
var dateTime = timestamp.ToDateTime();

// Streaming
using var stream = client.StreamTodos(new Empty());
await foreach (var todoEvent in stream.ResponseStream.ReadAllAsync())
{{
    Console.WriteLine($""Received: {{todoEvent}}"");
}}
```

## Features

- ✅ Type-safe gRPC client generation
- ✅ Native .NET types with nullable reference types
- ✅ Validation framework with custom attributes
- ✅ JSON serialization support (both Protobuf JSON and System.Text.Json)
- ✅ Extension methods for common operations
- ✅ Result type for error handling
- ✅ Timestamp and Duration conversions
- ✅ Deep cloning and equality helpers
- ✅ Source Link support for debugging

## Generated at

{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC

## Version

{metadata.Version}
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "README.md"),
            readme);
    }

    private async Task GenerateGitIgnoreAsync(string packageDir)
    {
        var gitignore = @"bin/
obj/
*.user
*.suo
.vs/
.vscode/
nupkg/
TestResults/
*.log
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, ".gitignore"),
            gitignore);
    }

    private async Task GenerateTestProjectAsync(string packageDir, PackageMetadata metadata)
    {
        var testDir = Path.Combine(packageDir, "tests");
        Directory.CreateDirectory(testDir);

        var testCsproj = $@"<Project Sdk=""Microsoft.NET.Sdk"">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>13</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include=""Microsoft.NET.Test.Sdk"" Version=""17.8.0"" />
    <PackageReference Include=""xunit"" Version=""2.6.4"" />
    <PackageReference Include=""xunit.runner.visualstudio"" Version=""2.5.5"" />
    <PackageReference Include=""coverlet.collector"" Version=""6.0.0"" />
    <PackageReference Include=""FluentAssertions"" Version=""6.12.0"" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include=""../{metadata.PackageName}.csproj"" />
  </ItemGroup>

</Project>";

        await File.WriteAllTextAsync(
            Path.Combine(testDir, $"{metadata.PackageName}.Tests.csproj"),
            testCsproj);

        var testFile = $@"using FluentAssertions;
using Google.Protobuf.WellKnownTypes;
using {metadata.PackageName};

namespace {metadata.PackageName}.Tests;

public class ExtensionsTests
{{
    [Fact]
    public void TimestampConversions_ShouldWork()
    {{
        // Arrange
        var now = DateTime.UtcNow;
        
        // Act
        var timestamp = now.ToTimestamp();
        var converted = timestamp.ToDateTime();
        
        // Assert
        converted.Should().BeCloseTo(now, TimeSpan.FromMilliseconds(1));
    }}
    
    [Fact]
    public void DateTimeOffsetConversions_ShouldWork()
    {{
        // Arrange
        var now = DateTimeOffset.UtcNow;
        
        // Act
        var timestamp = now.ToTimestamp();
        var converted = timestamp.ToDateTimeOffset();
        
        // Assert
        converted.Should().BeCloseTo(now, TimeSpan.FromMilliseconds(1));
    }}
    
    [Fact]
    public void DurationConversions_ShouldWork()
    {{
        // Arrange
        var timeSpan = TimeSpan.FromMinutes(5);
        
        // Act
        var duration = timeSpan.ToDuration();
        var converted = duration.ToTimeSpan();
        
        // Assert
        converted.Should().Be(timeSpan);
    }}
    
    [Fact]
    public void ValidationResult_Success_ShouldWork()
    {{
        // Act
        var result = ValidationResult.Success();
        
        // Assert
        result.IsValid.Should().BeTrue();
        result.Errors.Should().BeEmpty();
    }}
    
    [Fact]
    public void ValidationResult_Failure_ShouldWork()
    {{
        // Arrange
        var error = new ValidationError(""Field"", ""Error message"");
        
        // Act
        var result = ValidationResult.Failure(error);
        
        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(error);
    }}
    
    [Fact]
    public void Result_Success_ShouldWork()
    {{
        // Act
        var result = Result<string>.Success(""test"");
        
        // Assert
        result.IsSuccess.Should().BeTrue();
        result.IsFailure.Should().BeFalse();
        result.Value.Should().Be(""test"");
    }}
    
    [Fact]
    public void Result_Failure_ShouldWork()
    {{
        // Act
        var result = Result<string>.Failure(""error"");
        
        // Assert
        result.IsSuccess.Should().BeFalse();
        result.IsFailure.Should().BeTrue();
        result.Error.Should().Be(""error"");
    }}
    
    [Fact]
    public void Result_Map_ShouldWork()
    {{
        // Arrange
        var result = Result<int>.Success(5);
        
        // Act
        var mapped = result.Map(x => x.ToString());
        
        // Assert
        mapped.IsSuccess.Should().BeTrue();
        mapped.Value.Should().Be(""5"");
    }}
    
    [Fact]
    public void Result_FlatMap_ShouldWork()
    {{
        // Arrange
        var result = Result<int>.Success(5);
        
        // Act
        var flatMapped = result.FlatMap(x => Result<string>.Success(x.ToString()));
        
        // Assert
        flatMapped.IsSuccess.Should().BeTrue();
        flatMapped.Value.Should().Be(""5"");
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(testDir, "ExtensionsTests.cs"),
            testFile);
    }

    private async Task GenerateDirectoryBuildPropsAsync(string packageDir, PackageMetadata metadata)
    {
        var directoryBuildProps = $@"<Project>

  <PropertyGroup>
    <Company>{metadata.Company}</Company>
    <Product>{metadata.PackageName}</Product>
    <Copyright>Copyright © {DateTime.UtcNow.Year} {metadata.Company}</Copyright>
    <RepositoryUrl>{metadata.RepositoryUrl}</RepositoryUrl>
    <RepositoryType>git</RepositoryType>
  </PropertyGroup>

  <PropertyGroup Condition=""'$(Configuration)' == 'Release'"">
    <Optimize>true</Optimize>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
  </PropertyGroup>

</Project>";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "Directory.Build.props"),
            directoryBuildProps);
    }
}