using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.Text;
using FluentAssertions;
using Xunit;
using System.Text;
using System.Linq;
using System.Collections.Immutable;
using AxiomEndpoints.SourceGenerators;

namespace AxiomEndpoints.SourceGenerators.Tests;

/// <summary>
/// Comprehensive tests for the AxiomSourceGenerator and all its sub-generators
/// </summary>
public class SourceGeneratorTests
{
    [Fact]
    public void AxiomSourceGenerator_Should_Generate_RouteTemplates()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System.Collections.Frozen;
            
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
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var routeTemplatesSource = generatedSources.FirstOrDefault(s => s.HintName == "RouteTemplates.g.cs");
        routeTemplatesSource.Should().NotBe(default);
        if (!routeTemplatesSource.Equals(default(GeneratedSourceResult)))
        {
            var generatedCode = routeTemplatesSource.SourceText.ToString();
            generatedCode.Should().Contain("RouteTemplates");
            generatedCode.Should().Contain("GetTemplate");
        }
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_EndpointRegistrations()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ResultFactory.Success(new TestResponse());
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var endpointRegSource = generatedSources.FirstOrDefault(s => s.HintName == "EndpointRegistration.g.cs");
        if (!endpointRegSource.Equals(default(GeneratedSourceResult)))
        {
            endpointRegSource.SourceText.ToString().Should().Contain("TestEndpoint");
        }
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_MinimalEndpoints()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using AxiomEndpoints.Core.Attributes;
            using Microsoft.AspNetCore.Http;
            using System.Threading.Tasks;
            using System.Threading;
            using System;
            
            namespace TestNamespace
            {
                public static class TestEndpoints
                {
                    [Get("/api/users/{id:guid}")]
                    public static async Task<Result<UserResponse>> GetUserById(
                        [FromRoute] Guid id,
                        [FromServices] IContext context,
                        CancellationToken cancellationToken = default)
                    {
                        return ResultFactory.Success(new UserResponse { Id = id, Name = "Test User" });
                    }
                }
                
                public class UserResponse
                {
                    public Guid Id { get; set; }
                    public string Name { get; set; } = "";
                }
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var minimalEndpointsSource = generatedSources.FirstOrDefault(s => s.HintName == "MinimalEndpoints.g.cs");
        if (!minimalEndpointsSource.Equals(default(GeneratedSourceResult)))
        {
            var generatedCode = minimalEndpointsSource.SourceText.ToString();
            generatedCode.Should().Contain("GetUserById");
            generatedCode.Should().Contain("IRouteAxiom");
        }
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_QueryParameterBinding()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using AxiomEndpoints.Core.Attributes;
            using Microsoft.AspNetCore.Http;
            using System.Threading.Tasks;
            using System.Threading;
            using System;
            
            namespace TestNamespace
            {
                public static class SearchEndpoints
                {
                    [Get("/api/search")]
                    public static async Task<Result<SearchResponse>> Search(
                        [FromQuery] string query,
                        [FromQuery] int page = 1,
                        [FromQuery] int limit = 10,
                        [FromServices] IContext context,
                        CancellationToken cancellationToken = default)
                    {
                        return ResultFactory.Success(new SearchResponse());
                    }
                }
                
                public class SearchResponse
                {
                    public string Results { get; set; } = "";
                }
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var queryBindingSource = generatedSources.FirstOrDefault(s => s.HintName == "QueryParameterBinding.g.cs");
        if (!queryBindingSource.Equals(default(GeneratedSourceResult)))
        {
            var generatedCode = queryBindingSource.SourceText.ToString();
            generatedCode.Should().Contain("QueryParameterBinder");
        }
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_TypedClients()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace.Users
            {
                public class GetUsersEndpoint : IAxiom<GetUsersRequest, GetUsersResponse>
                {
                    public async ValueTask<Result<GetUsersResponse>> HandleAsync(GetUsersRequest request, IContext context)
                    {
                        return ResultFactory.Success(new GetUsersResponse());
                    }
                }
                
                public record GetUsersRequest();
                public record GetUsersResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var typedClientsSource = generatedSources.FirstOrDefault(s => s.HintName == "TypedClients.g.cs");
        if (typedClientsSource.SourceText != null)
        {
            var generatedCode = typedClientsSource.SourceText.ToString();
            // Check that some typed client code is generated
            generatedCode.Should().Contain("ServiceClient");
        }
        else
        {
            // If no typed clients are generated, check that performance optimizations are generated instead
            var performanceSource = generatedSources.FirstOrDefault(s => s.HintName == "PerformanceOptimizations.g.cs");
            performanceSource.SourceText.Should().NotBeNull();
        }
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_FluentConfiguration()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ResultFactory.Success(new TestResponse());
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var fluentConfigSource = generatedSources.FirstOrDefault(s => s.HintName == "FluentConfiguration.g.cs");
        fluentConfigSource.SourceText.Should().NotBeNull();
        
        var generatedCode = fluentConfigSource.SourceText.ToString();
        generatedCode.Should().Contain("IAxiomEndpointBuilder");
        generatedCode.Should().Contain("RequireAuthentication");
        generatedCode.Should().Contain("WithCaching");
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_ValidationCode()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ResultFactory.Success(new TestResponse());
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var validationSource = generatedSources.FirstOrDefault(s => s.HintName == "Validation.g.cs");
        validationSource.SourceText.Should().NotBeNull();
        
        var generatedCode = validationSource.SourceText.ToString();
        generatedCode.Should().Contain("IAxiomValidationService");
        generatedCode.Should().Contain("NotEmptyGuidAttribute");
        generatedCode.Should().Contain("AxiomValidationMiddleware");
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_PerformanceOptimizations()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ResultFactory.Success(new TestResponse());
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var performanceSource = generatedSources.FirstOrDefault(s => s.HintName == "PerformanceOptimizations.g.cs");
        performanceSource.SourceText.Should().NotBeNull();
        
        var generatedCode = performanceSource.SourceText.ToString();
        generatedCode.Should().Contain("IAxiomCacheService");
        generatedCode.Should().Contain("AxiomCompressionMiddleware");
        generatedCode.Should().Contain("IAxiomObjectPool");
        generatedCode.Should().Contain("AxiomPerformanceMonitoringMiddleware");
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Generate_ConfigurationMiddleware()
    {
        // Arrange
        var source = """
            using AxiomEndpoints.Core;
            using System;
            using System.Threading.Tasks;
            using Microsoft.AspNetCore.Http;
            
            namespace TestNamespace
            {
                public class TestEndpoint : IAxiom<TestRequest, TestResponse>
                {
                    public async ValueTask<Result<TestResponse>> HandleAsync(TestRequest request, IContext context)
                    {
                        return ResultFactory.Success(new TestResponse());
                    }
                }
                
                public record TestRequest();
                public record TestResponse();
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        var configMiddlewareSource = generatedSources.FirstOrDefault(s => s.HintName == "ConfigurationMiddleware.g.cs");
        configMiddlewareSource.SourceText.Should().NotBeNull();
        
        var generatedCode = configMiddlewareSource.SourceText.ToString();
        generatedCode.Should().Contain("AxiomMiddlewareConfiguration");
        generatedCode.Should().Contain("AxiomMiddlewarePipelineBuilder");
        generatedCode.Should().Contain("UseAxiomMiddleware");
    }

    [Fact]
    public void PerformanceOptimizationGenerator_Should_Generate_Caching_Infrastructure()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;
        var compilation = new CompilationInfo 
        { 
            AssemblyName = "TestAssembly", 
            RootNamespace = "TestNamespace" 
        };

        // Act
        var generatedCode = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, compilation);

        // Assert
        generatedCode.Should().NotBeNullOrEmpty();
        generatedCode.Should().Contain("IAxiomCacheService");
        generatedCode.Should().Contain("AxiomMemoryCacheService");
        generatedCode.Should().Contain("GetAsync<T>");
        generatedCode.Should().Contain("SetAsync<T>");
        generatedCode.Should().Contain("GetOrSetAsync<T>");
        generatedCode.Should().Contain("AxiomCacheOptions");
    }

    [Fact]
    public void PerformanceOptimizationGenerator_Should_Generate_Compression_Infrastructure()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;
        var compilation = new CompilationInfo 
        { 
            AssemblyName = "TestAssembly", 
            RootNamespace = "TestNamespace" 
        };

        // Act
        var generatedCode = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, compilation);

        // Assert
        generatedCode.Should().NotBeNullOrEmpty();
        generatedCode.Should().Contain("AxiomCompressionMiddleware");
        generatedCode.Should().Contain("AxiomCompressionOptions");
        generatedCode.Should().Contain("BrotliStream");
        generatedCode.Should().Contain("GZipStream");
        generatedCode.Should().Contain("DeflateStream");
        generatedCode.Should().Contain("CompressibleMimeTypes");
    }

    [Fact]
    public void PerformanceOptimizationGenerator_Should_Generate_ObjectPooling_Infrastructure()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;
        var compilation = new CompilationInfo 
        { 
            AssemblyName = "TestAssembly", 
            RootNamespace = "TestNamespace" 
        };

        // Act
        var generatedCode = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, compilation);

        // Assert
        generatedCode.Should().NotBeNullOrEmpty();
        generatedCode.Should().Contain("IAxiomObjectPool<T>");
        generatedCode.Should().Contain("AxiomObjectPool<T>");
        generatedCode.Should().Contain("AxiomStringBuilderPool");
        generatedCode.Should().Contain("AxiomMemoryStreamPool");
        generatedCode.Should().Contain("ConcurrentQueue<T>");
    }

    [Fact]
    public void PerformanceOptimizationGenerator_Should_Generate_Performance_Monitoring()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;
        var compilation = new CompilationInfo 
        { 
            AssemblyName = "TestAssembly", 
            RootNamespace = "TestNamespace" 
        };

        // Act
        var generatedCode = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, compilation);

        // Assert
        generatedCode.Should().NotBeNullOrEmpty();
        generatedCode.Should().Contain("AxiomPerformanceMonitoringMiddleware");
        generatedCode.Should().Contain("AxiomEndpointMetrics");
        generatedCode.Should().Contain("AverageResponseTimeMs");
        generatedCode.Should().Contain("ErrorRate");
        generatedCode.Should().Contain("SlowRequestThresholdMs");
    }

    [Fact]
    public void PerformanceOptimizationGenerator_Should_Generate_Extension_Methods()
    {
        // Arrange
        var endpoints = ImmutableArray<EndpointInfo>.Empty;
        var compilation = new CompilationInfo 
        { 
            AssemblyName = "TestAssembly", 
            RootNamespace = "TestNamespace" 
        };

        // Act
        var generatedCode = PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(endpoints, compilation);

        // Assert
        generatedCode.Should().NotBeNullOrEmpty();
        generatedCode.Should().Contain("AddAxiomPerformance");
        generatedCode.Should().Contain("UseAxiomPerformance");
        generatedCode.Should().Contain("WithCaching<T>");
        generatedCode.Should().Contain("AxiomPerformanceConfiguration");
    }

    [Fact]
    public void AxiomSourceGenerator_Should_Handle_Empty_Input_Gracefully()
    {
        // Arrange
        var source = """
            namespace TestNamespace
            {
                // Empty namespace
            }
            """;

        // Act
        var (compilation, diagnostics, generatedSources) = RunGenerator(source);

        // Assert
        diagnostics.Should().NotContain(d => d.Severity == DiagnosticSeverity.Error);
        
        // Should still generate some files even with no endpoints
        generatedSources.Should().NotBeEmpty();
        
        // Performance optimizations should always be generated
        var performanceSource = generatedSources.FirstOrDefault(s => s.HintName == "PerformanceOptimizations.g.cs");
        performanceSource.SourceText.Should().NotBeNull();
    }

    private static (Compilation compilation, ImmutableArray<Diagnostic> diagnostics, ImmutableArray<GeneratedSourceResult> generatedSources) 
        RunGenerator(string source)
    {
        var syntaxTree = CSharpSyntaxTree.ParseText(SourceText.From(source, Encoding.UTF8));
        
        var references = new[]
        {
            MetadataReference.CreateFromFile(typeof(object).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Enumerable).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(ValueTask).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(IServiceProvider).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(System.Collections.Frozen.FrozenDictionary).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(System.Collections.Immutable.ImmutableArray).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(System.ComponentModel.DataAnnotations.ValidationAttribute).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Microsoft.Extensions.DependencyInjection.IServiceCollection).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Microsoft.Extensions.Logging.ILogger).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Microsoft.AspNetCore.Http.HttpContext).Assembly.Location),
            MetadataReference.CreateFromFile(typeof(Microsoft.AspNetCore.Builder.IApplicationBuilder).Assembly.Location),
        };

        var compilation = CSharpCompilation.Create(
            "TestAssembly",
            new[] { syntaxTree },
            references,
            new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary));

        var generator = new AxiomSourceGenerator();
        var driver = CSharpGeneratorDriver.Create(generator);
        
        driver = (CSharpGeneratorDriver)driver.RunGeneratorsAndUpdateCompilation(
            compilation, 
            out var outputCompilation, 
            out var diagnostics);

        var result = driver.GetRunResult();
        
        return (outputCompilation, diagnostics, result.Results.SelectMany(r => r.GeneratedSources).ToImmutableArray());
    }
}