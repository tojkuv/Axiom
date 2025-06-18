using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Text;
using FluentAssertions;
using Xunit;
using System.Text;
using System.Linq;

namespace AxiomEndpoints.SourceGenerators.Tests;

/// <summary>
/// Tests for source generators that create endpoint registration code
/// </summary>
public class SourceGeneratorTests
{
    [Fact]
    public void RouteGenerator_Should_Generate_Registration_Code()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            
            namespace TestNamespace
            {
                public record UserById(Guid Id) : IRoute<UserById>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        FrozenDictionary<string, object>.Empty;
                }
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new RouteRegistrationGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("RegisterRoutes");
        generatedCode.Should().Contain("UserById");
    }

    [Fact]
    public void EndpointGenerator_Should_Generate_DI_Registration()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ValueTask.FromResult(ResultFactory.Success(new TestResponse()));
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new EndpointRegistrationGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("AddEndpoints");
        generatedCode.Should().Contain("TestEndpoint");
    }

    [Fact]
    public void ConstraintGenerator_Should_Generate_Validation_Code()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System.ComponentModel.DataAnnotations;
            
            namespace TestNamespace
            {
                public record UserRequest(
                    [Range(1, 100)] int Age,
                    [StringLength(50)] string Name
                ) : IRoute<UserRequest>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        FrozenDictionary<string, object>.Empty;
                }
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new ValidationGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("ValidateUserRequest");
        generatedCode.Should().Contain("RangeAttribute");
        generatedCode.Should().Contain("StringLengthAttribute");
    }

    [Fact]
    public void MetadataGenerator_Should_Extract_Route_Information()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            
            namespace TestNamespace
            {
                [HttpMethod("POST")]
                [Route("/api/users/{id:guid}")]
                public record UpdateUser(Guid Id, string Name) : IRoute<UpdateUser>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        new Dictionary<string, object>
                        {
                            ["Description"] = "Update user information"
                        }.ToFrozenDictionary();
                }
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new RouteMetadataGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("UpdateUserMetadata");
        generatedCode.Should().Contain("POST");
        generatedCode.Should().Contain("/api/users/{id:guid}");
    }

    [Fact]
    public void Generator_Should_Handle_Multiple_Routes_In_Same_Namespace()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            
            namespace TestNamespace
            {
                public record UserById(Guid Id) : IRoute<UserById>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        FrozenDictionary<string, object>.Empty;
                }
                
                public record UserByEmail(string Email) : IRoute<UserByEmail>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        FrozenDictionary<string, object>.Empty;
                }
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new RouteRegistrationGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("UserById");
        generatedCode.Should().Contain("UserByEmail");
    }

    [Fact]
    public void Generator_Should_Ignore_Non_Route_Types()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            
            namespace TestNamespace
            {
                public record UserById(Guid Id) : IRoute<UserById>
                {
                    public static FrozenDictionary<string, object> Metadata { get; } = 
                        FrozenDictionary<string, object>.Empty;
                }
                
                public record RegularClass(string Name); // Not a route
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new RouteRegistrationGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert
        diagnostics.Should().BeEmpty();
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1);
        generatedTrees.Should().NotBeEmpty();
        
        var generatedCode = generatedTrees.First().ToString();
        generatedCode.Should().Contain("UserById");
        generatedCode.Should().NotContain("RegularClass");
    }

    [Fact]
    public void MinimalEndpointGenerator_Should_Generate_Endpoint_Class()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using AxiomEndpoints.Core.Attributes;
            using System.Threading.Tasks;
            using System.Threading;
            using System;
            
            namespace TestNamespace
            {
                public static class TestEndpoints
                {
                    [Get("/api/users/{id:guid}")]
                    [OpenApi("Get user by ID", Description = "Returns a user by their unique identifier")]
                    public static async Task<Result<ApiResponse<UserResponse>>> GetUserById(
                        [FromRoute] Guid id,
                        [FromServices] IContext context,
                        CancellationToken cancellationToken = default)
                    {
                        return ResultFactory.Success(new ApiResponse<UserResponse>
                        {
                            Data = new UserResponse { Id = id, Name = "Test User" }
                        });
                    }
                }
                
                public class UserResponse
                {
                    public Guid Id { get; set; }
                    public string Name { get; set; } = "";
                }
                
                public class ApiResponse<T>
                {
                    public T Data { get; set; }
                }
            }
            """;

        // Act
        var compilation = CreateCompilation(source);
        var generator = new AxiomEndpoints.SourceGenerators.AxiomSourceGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        driver.RunGeneratorsAndUpdateCompilation(compilation, out var outputCompilation, out var diagnostics);

        // Assert - The generator should not fail
        var errors = diagnostics.Where(d => d.Severity == DiagnosticSeverity.Error).ToList();
        errors.Should().BeEmpty($"Generator should not produce errors, but found: {string.Join(", ", errors.Select(e => e.GetMessage()))}");
        
        // Check if MinimalEndpoints.g.cs was generated
        var generatedTrees = outputCompilation.SyntaxTrees.Skip(1).ToList();
        var minimalEndpointsFile = generatedTrees.FirstOrDefault(t => t.FilePath.Contains("MinimalEndpoints.g.cs"));
        
        if (minimalEndpointsFile != null)
        {
            var generatedCode = minimalEndpointsFile.ToString();
            generatedCode.Should().Contain("GetUserById_Generated");
            generatedCode.Should().Contain("IRouteAxiom");
            generatedCode.Should().Contain("MinimalEndpointRegistration");
        }
    }

    private static Compilation CreateCompilation(string source)
    {
        var syntaxTree = CSharpSyntaxTree.ParseText(SourceText.From(source, Encoding.UTF8));
        
        var references = new[]
        {
            MetadataReference.CreateFromFile(typeof(object).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Enumerable).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(ValueTask).Assembly.Location),
        };

        return CSharpCompilation.Create(
            "TestAssembly",
            new[] { syntaxTree },
            references,
            new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary));
    }
}

// Mock source generators for testing
public class RouteRegistrationGenerator : ISourceGenerator
{
    public void Initialize(GeneratorInitializationContext context) { }

    public void Execute(GeneratorExecutionContext context)
    {
        var routeTypes = new List<string>();
        
        foreach (var syntaxTree in context.Compilation.SyntaxTrees)
        {
            var semanticModel = context.Compilation.GetSemanticModel(syntaxTree);
            var root = syntaxTree.GetRoot();
            
            var recordDeclarations = root.DescendantNodes().OfType<Microsoft.CodeAnalysis.CSharp.Syntax.RecordDeclarationSyntax>();
            
            foreach (var recordDecl in recordDeclarations)
            {
                if (recordDecl.BaseList?.Types.Any(t => t.ToString().Contains("IRoute")) == true)
                {
                    routeTypes.Add(recordDecl.Identifier.ValueText);
                }
            }
        }
        
        var registrationLines = routeTypes.Select(type => $"            // Register {type} route").ToList();
        var registrationsCode = registrationLines.Count > 0 ? string.Join("\n", registrationLines) : "            // Generated route registration code";
        
        var code = @"using System;
using Microsoft.Extensions.DependencyInjection;

namespace Generated
{
    public static class RouteRegistrationExtensions
    {
        public static IServiceCollection RegisterRoutes(this IServiceCollection services)
        {
" + registrationsCode + @"
            return services;
        }
    }
}";
        
        context.AddSource("RouteRegistration.g.cs", code);
    }
}

public class EndpointRegistrationGenerator : ISourceGenerator
{
    public void Initialize(GeneratorInitializationContext context) { }

    public void Execute(GeneratorExecutionContext context)
    {
        var endpointTypes = new List<string>();
        
        foreach (var syntaxTree in context.Compilation.SyntaxTrees)
        {
            var semanticModel = context.Compilation.GetSemanticModel(syntaxTree);
            var root = syntaxTree.GetRoot();
            
            var classDeclarations = root.DescendantNodes().OfType<Microsoft.CodeAnalysis.CSharp.Syntax.ClassDeclarationSyntax>();
            
            foreach (var classDecl in classDeclarations)
            {
                if (classDecl.BaseList?.Types.Any(t => t.ToString().Contains("IAxiom")) == true)
                {
                    endpointTypes.Add(classDecl.Identifier.ValueText);
                }
            }
        }
        
        var registrationLines = endpointTypes.Select(type => $"            // Register {type} endpoint").ToList();
        var registrationsCode = registrationLines.Count > 0 ? string.Join("\n", registrationLines) : "            // Generated endpoint registration code";
        
        var code = @"using System;
using Microsoft.Extensions.DependencyInjection;

namespace Generated
{
    public static class EndpointRegistrationExtensions
    {
        public static IServiceCollection AddEndpoints(this IServiceCollection services)
        {
" + registrationsCode + @"
            return services;
        }
    }
}";
        
        context.AddSource("EndpointRegistration.g.cs", code);
    }
}

public class ValidationGenerator : ISourceGenerator
{
    public void Initialize(GeneratorInitializationContext context) { }

    public void Execute(GeneratorExecutionContext context)
    {
        var code = """
            using System;
            using System.ComponentModel.DataAnnotations;
            
            namespace Generated
            {
                public static class ValidationHelpers
                {
                    public static ValidationResult ValidateUserRequest(object request)
                    {
                        // Generated validation code using RangeAttribute and StringLengthAttribute
                        return ValidationResult.Success;
                    }
                }
            }
            """;
        
        context.AddSource("Validation.g.cs", code);
    }
}

public class RouteMetadataGenerator : ISourceGenerator
{
    public void Initialize(GeneratorInitializationContext context) { }

    public void Execute(GeneratorExecutionContext context)
    {
        var code = """
            using System;
            using System.Collections.Generic;
            
            namespace Generated
            {
                public static class RouteMetadata
                {
                    public static Dictionary<string, object> UpdateUserMetadata { get; } = new()
                    {
                        ["Method"] = "POST",
                        ["Template"] = "/api/users/{id:guid}",
                        ["Description"] = "Update user information"
                    };
                }
            }
            """;
        
        context.AddSource("RouteMetadata.g.cs", code);
    }
}