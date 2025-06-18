using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Text;
using System.Collections.Immutable;
using System.Linq;
using System.Text;

namespace AxiomEndpoints.SourceGenerators;

[Generator]
public class AxiomSourceGenerator : IIncrementalGenerator
{
    public void Initialize(IncrementalGeneratorInitializationContext context)
    {
        // Step 1: Find all route types
        var routeTypes = context.SyntaxProvider
            .CreateSyntaxProvider(
                predicate: static (node, _) => node is TypeDeclarationSyntax,
                transform: static (context, _) => GetRouteInfo(context))
            .Where(static info => info is not null)
            .Select(static (info, _) => info!);

        // Step 2: Find all endpoint types
        var endpointTypes = context.SyntaxProvider
            .CreateSyntaxProvider(
                predicate: static (node, _) => node is TypeDeclarationSyntax,
                transform: static (context, _) => GetEndpointInfo(context))
            .Where(static info => info is not null)
            .Select(static (info, _) => info!);

        // Step 3: Collect compilation info
        var compilationInfo = context.CompilationProvider
            .Select(static (compilation, _) => new CompilationInfo
            {
                AssemblyName = compilation.AssemblyName ?? "Unknown",
                RootNamespace = compilation.AssemblyName ?? "Generated",
                Compilation = compilation
            });

        // Step 4: Generate route templates
        var routeTemplates = routeTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => RouteTemplateGenerator.GenerateRouteTemplates(data.Left, data.Right));

        // Step 5: Generate endpoint registrations (only for ASP.NET Core projects)
        var endpointRegistrations = endpointTypes
            .Collect()
            .Combine(routeTemplates)
            .Combine(compilationInfo)
            .Select(static (data, _) => (data.Right.Compilation != null && HasAspNetCoreReferences(data.Right.Compilation)) 
                ? EndpointRegistrationGenerator.GenerateEndpointRegistrations(data.Left.Left, data.Left.Right, data.Right)
                : string.Empty);

        // Step 6: Generate outputs
        context.RegisterSourceOutput(routeTemplates, EmitRouteTemplates);
        context.RegisterSourceOutput(endpointRegistrations, EmitEndpointRegistrations);

        // Step 6.1: Generate OpenAPI documentation
        var openApiGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => OpenApiGenerator.GenerateOpenApiDocuments(data.Left, data.Right));

        context.RegisterSourceOutput(openApiGeneration, EmitOpenApiDocuments);


        // Step 6.3: Generate minimal endpoints
        var minimalEndpoints = context.SyntaxProvider
            .CreateSyntaxProvider(
                predicate: static (node, _) => node is MethodDeclarationSyntax,
                transform: static (context, _) => MinimalEndpointGenerator.GetMinimalEndpointInfo(context))
            .Where(static info => info is not null)
            .Select(static (info, _) => info!);

        var minimalEndpointGeneration = minimalEndpoints
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => MinimalEndpointGenerator.GenerateMinimalEndpoints(data.Left, data.Right));

        context.RegisterSourceOutput(minimalEndpointGeneration, EmitMinimalEndpoints);

        // Step 6.4: Generate query parameter binding
        var queryParameterBindingGeneration = minimalEndpoints
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => QueryParameterBindingGenerator.GenerateParameterBinding(data.Left, data.Right));

        context.RegisterSourceOutput(queryParameterBindingGeneration, EmitQueryParameterBinding);

        // Step 6.5: Generate typed clients for cross-service communication
        var typedClientGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => TypedClientGenerator.GenerateTypedClients(data.Left, data.Right));

        context.RegisterSourceOutput(typedClientGeneration, EmitTypedClients);

        // Step 6.6: Generate typed client registration extensions
        var typedClientRegistrationGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => TypedClientRegistrationGenerator.GenerateClientRegistration(data.Left, data.Right));

        context.RegisterSourceOutput(typedClientRegistrationGeneration, EmitTypedClientRegistration);

        // Step 6.7: Generate configuration-driven middleware
        var configurationMiddlewareGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => ConfigurationDrivenMiddlewareGenerator.GenerateMiddlewareConfiguration(data.Left, data.Right));

        context.RegisterSourceOutput(configurationMiddlewareGeneration, EmitConfigurationMiddleware);

        // Step 6.8: Generate fluent endpoint configuration API
        var fluentConfigurationGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => FluentEndpointConfigurationGenerator.GenerateFluentConfiguration(data.Left, data.Right));

        context.RegisterSourceOutput(fluentConfigurationGeneration, EmitFluentConfiguration);

        // Step 6.9: Generate validation system
        var validationGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => ValidationGenerator.GenerateValidationCode(data.Left, data.Right));

        context.RegisterSourceOutput(validationGeneration, EmitValidation);

        // Step 6.10: Generate performance optimizations
        var performanceGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => PerformanceOptimizationGenerator.GeneratePerformanceOptimizations(data.Left, data.Right));

        context.RegisterSourceOutput(performanceGeneration, EmitPerformanceOptimizations);

        // Other client generation removed - MCP tool will handle platform-specific generation

        // Step 7: Generate proto files (for MCP tool consumption)
        var streamingTypes = context.SyntaxProvider
            .CreateSyntaxProvider(
                predicate: static (node, _) => node is TypeDeclarationSyntax,
                transform: static (context, _) => StreamingEndpointDetector.GetStreamingInfo(context))
            .Where(static info => info is not null)
            .Select(static (info, _) => info!);

        var protoGeneration = endpointTypes
            .Collect()
            .Combine(streamingTypes.Collect())
            .Combine(compilationInfo)
            .Select(static (data, _) => ProtoGenerator.GenerateProtoFile(data.Left.Left, data.Left.Right, data.Right));

        context.RegisterSourceOutput(protoGeneration, EmitProtoFile);

        // All client and service generation removed - MCP tool will handle this

        // Step 8: Generate middleware pipelines (for all projects with middleware) - DISABLED TEMPORARILY
        // var middlewareEndpoints = context.SyntaxProvider
        //     .CreateSyntaxProvider(
        //         predicate: static (node, _) => node is TypeDeclarationSyntax,
        //         transform: static (context, _) => MiddlewarePipelineGenerator.GetEndpointWithMiddleware(context))
        //     .Where(static info => info is not null)
        //     .Select(static (info, _) => info!);

        // var middlewarePipelineGeneration = middlewareEndpoints
        //     .Collect()
        //     .Combine(compilationInfo)
        //     .Select(static (data, _) => MiddlewarePipelineGenerator.GenerateMiddlewarePipelines(data.Left, data.Right));

        // context.RegisterSourceOutput(middlewarePipelineGeneration, EmitMiddlewarePipelines);
    }

    private static RouteInfo? GetRouteInfo(GeneratorSyntaxContext context)
    {
        var node = (TypeDeclarationSyntax)context.Node;
        var symbol = context.SemanticModel.GetDeclaredSymbol(node);

        if (symbol is null || !IsRouteType(symbol))
            return null;

        // Extract parameters from constructor
        var parameters = ImmutableArray<RouteParameter>.Empty;
        var constructors = symbol.Constructors;
        if (constructors.Length > 0)
        {
            var constructor = constructors[0];
            var paramBuilder = ImmutableArray.CreateBuilder<RouteParameter>();

            foreach (var param in constructor.Parameters)
            {
                paramBuilder.Add(new RouteParameter
                {
                    Name = param.Name,
                    Type = param.Type.ToDisplayString(),
                    IsOptional = param.HasExplicitDefaultValue,
                    Constraint = null // TODO: Extract from attributes
                });
            }

            parameters = paramBuilder.ToImmutable();
        }

        // Build full type name including nested hierarchy
        var fullTypeName = symbol.Name;
        var currentContainer = symbol.ContainingType;
        
        // Walk up the nested type hierarchy
        while (currentContainer is not null)
        {
            fullTypeName = $"{currentContainer.Name}.{fullTypeName}";
            currentContainer = currentContainer.ContainingType;
        }

        return new RouteInfo
        {
            TypeName = fullTypeName,
            Namespace = symbol.ContainingNamespace.ToDisplayString(),
            Template = "", // Will be built by RouteTemplateBuilder
            Parameters = parameters,
            IsNested = symbol.ContainingType is not null,
            ParentTypeName = symbol.ContainingType?.Name
        };
    }

    private static EndpointInfo? GetEndpointInfo(GeneratorSyntaxContext context)
    {
        var node = (TypeDeclarationSyntax)context.Node;
        var symbol = context.SemanticModel.GetDeclaredSymbol(node);

        if (symbol is null || !IsEndpointType(symbol))
            return null;

        // Extract interface information
        var axiomInterface = symbol.AllInterfaces.FirstOrDefault(i =>
            i.IsGenericType && i.Name.Contains("Axiom"));

        if (axiomInterface is null)
            return null;

        var routeType = "";
        var requestType = "";
        var responseType = "";
        var kind = EndpointKind.Unary;

        // Determine endpoint kind based on interface type
        if (axiomInterface.Name.StartsWith("IServerStreamAxiom"))
        {
            kind = EndpointKind.ServerStream;
        }
        else if (axiomInterface.Name.StartsWith("IClientStreamAxiom"))
        {
            kind = EndpointKind.ClientStream;
        }
        else if (axiomInterface.Name.StartsWith("IBidirectionalStreamAxiom"))
        {
            kind = EndpointKind.BidirectionalStream;
        }

        if (axiomInterface.TypeArguments.Length >= 2)
        {
            requestType = axiomInterface.TypeArguments[0].ToDisplayString();
            responseType = axiomInterface.TypeArguments[1].ToDisplayString();

            // For IRouteAxiom, the first argument is the route type
            if (axiomInterface.Name == "IRouteAxiom")
            {
                routeType = requestType;
            }
            // For streaming endpoints with route, check if first argument is route type
            else if (axiomInterface.TypeArguments.Length >= 3 && kind != EndpointKind.Unary)
            {
                var potentialRouteType = axiomInterface.TypeArguments[0];
                if (potentialRouteType is INamedTypeSymbol routeTypeSymbol &&
                    routeTypeSymbol.AllInterfaces.Any(i => i.Name == "IRoute"))
                {
                    routeType = potentialRouteType.ToDisplayString();
                    requestType = axiomInterface.TypeArguments[1].ToDisplayString();
                    responseType = axiomInterface.TypeArguments[2].ToDisplayString();
                }
            }
        }

        return new EndpointInfo
        {
            TypeName = symbol.Name,
            Namespace = symbol.ContainingNamespace.ToDisplayString(),
            RouteType = routeType,
            RequestType = requestType,
            ResponseType = responseType,
            HttpMethod = GetHttpMethod(kind, axiomInterface), 
            RequiresAuthorization = false, // TODO: Extract from attributes
            Scopes = ImmutableArray<string>.Empty,
            Kind = kind
        };
    }

    private static string GetHttpMethod(EndpointKind kind, INamedTypeSymbol axiomInterface)
    {
        return kind switch
        {
            EndpointKind.ServerStream => "Get",
            EndpointKind.ClientStream => "Post",
            EndpointKind.BidirectionalStream => "Get", // WebSocket upgrade
            _ => "Get" // Default for unary
        };
    }

    private static bool IsRouteType(INamedTypeSymbol typeSymbol)
    {
        return typeSymbol.AllInterfaces.Any(i =>
            i.IsGenericType &&
            i.Name == "IRoute" &&
            i.TypeArguments.Length == 1 &&
            SymbolEqualityComparer.Default.Equals(i.TypeArguments[0], typeSymbol));
    }

    private static bool IsEndpointType(INamedTypeSymbol typeSymbol)
    {
        // Only include concrete, non-abstract classes that implement Axiom interfaces
        if (typeSymbol.IsAbstract || typeSymbol.TypeKind != TypeKind.Class)
            return false;
            
        return typeSymbol.AllInterfaces.Any(i =>
            i.IsGenericType &&
            (i.Name == "IAxiom" || i.Name == "IRouteAxiom" ||
             i.Name == "IServerStreamAxiom" || i.Name == "IClientStreamAxiom" ||
             i.Name == "IBidirectionalStreamAxiom"));
    }

    private static void EmitRouteTemplates(SourceProductionContext context, string source)
    {
        context.AddSource("RouteTemplates.g.cs", SourceText.From(source, Encoding.UTF8));
    }

    private static void EmitEndpointRegistrations(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("EndpointRegistration.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitProtoFile(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            // Generate proto file for MCP tool consumption
            // Note: This generates a C# file containing the proto content as a constant
            // The actual .proto file should be written to disk during build
            var protoAsSource = $@"// <auto-generated/>
// This file contains the generated protobuf definitions for MCP tool consumption

namespace Generated.Proto
{{
    /// <summary>
    /// Generated protobuf definitions for Axiom endpoints.
    /// The MCP tool will use this to generate client code for various platforms.
    /// </summary>
    public static class AxiomProtoDefinitions
    {{
        /// <summary>
        /// The complete protobuf definition for all Axiom endpoints.
        /// </summary>
        public const string ProtoContent = @""{source.Replace("\"", "\"\"")}"";
    }}
}}";
            
            context.AddSource("AxiomProto.g.cs", SourceText.From(protoAsSource, Encoding.UTF8));
        }
    }

    private static void EmitMiddlewarePipelines(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("MiddlewarePipelines.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitOpenApiDocuments(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("OpenApiDocuments.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitValidationCode(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("ValidationCode.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitMinimalEndpoints(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("MinimalEndpoints.g.cs", SourceText.From(source, Encoding.UTF8));
        }
        else
        {
            // Always emit a debug file to verify the generator is running
            var debugSource = @"// <auto-generated/>
// This file is generated by AxiomSourceGenerator to verify it's running
// If you see this file but no actual generated endpoints, the source generator
// is running but not finding any minimal endpoint methods with HTTP attributes

namespace Generated.Debug
{
    public static class SourceGeneratorDebug
    {
        public const string Message = ""AxiomSourceGenerator MinimalEndpoints generator ran but found no endpoints"";
        public static readonly System.DateTime GeneratedAt = System.DateTime.UtcNow;
    }
}";
            context.AddSource("MinimalEndpointsDebug.g.cs", SourceText.From(debugSource, Encoding.UTF8));
        }
    }

    private static void EmitQueryParameterBinding(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("QueryParameterBinding.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitTypedClients(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("TypedClients.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitTypedClientRegistration(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("TypedClientRegistration.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitConfigurationMiddleware(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("ConfigurationMiddleware.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitFluentConfiguration(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("FluentConfiguration.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitValidation(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("Validation.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitPerformanceOptimizations(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("PerformanceOptimizations.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static bool HasAspNetCoreReferences(Compilation compilation)
    {
        return compilation.ReferencedAssemblyNames.Any(name => 
            name.Name.Equals("Microsoft.AspNetCore") ||
            name.Name.Equals("Microsoft.AspNetCore.App") ||
            (name.Name.Contains("Microsoft.AspNetCore") && 
             name.Name.Contains("Builder")) ||
            (name.Name.Contains("Microsoft.Extensions") && 
             name.Name.Contains("DependencyInjection") &&
             !name.Name.Contains("Abstractions")));
    }

    private static bool HasGrpcReferences(Compilation compilation)
    {
        return compilation.ReferencedAssemblyNames.Any(name => 
            name.Name.Contains("Grpc.Core") ||
            name.Name.Contains("Grpc.Net") ||
            name.Name.Contains("Google.Protobuf") ||
            name.Name.Equals("Grpc.AspNetCore"));
    }
}