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
            .Select(static (data, _) => HasAspNetCoreReferences(data.Right.Compilation) 
                ? EndpointRegistrationGenerator.GenerateEndpointRegistrations(data.Left.Left, data.Left.Right, data.Right)
                : string.Empty);

        // Step 6: Generate outputs
        context.RegisterSourceOutput(routeTemplates, EmitRouteTemplates);
        context.RegisterSourceOutput(endpointRegistrations, EmitEndpointRegistrations);

        // Step 7: Generate additional artifacts
        var clientGeneration = endpointTypes
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => TypedClientGenerator.GenerateTypedClient(data.Left, data.Right));

        context.RegisterSourceOutput(clientGeneration, EmitTypedClient);

        // Step 8: Generate proto files (only for gRPC projects)
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
            .Select(static (data, _) => HasGrpcReferences(data.Right.Compilation)
                ? ProtoGenerator.GenerateProtoFile(data.Left.Left, data.Left.Right, data.Right)
                : string.Empty);

        context.RegisterSourceOutput(protoGeneration, EmitProtoFile);

        // Step 9: Generate gRPC service implementations (only for gRPC projects)
        var grpcServiceGeneration = endpointTypes
            .Collect()
            .Combine(streamingTypes.Collect())
            .Combine(compilationInfo)
            .Select(static (data, _) => HasGrpcReferences(data.Right.Compilation)
                ? GrpcServiceGenerator.GenerateGrpcServices(data.Left.Left, data.Left.Right, data.Right)
                : string.Empty);

        context.RegisterSourceOutput(grpcServiceGeneration, EmitGrpcServices);

        // Step 10: Generate unified gRPC/HTTP clients (only for gRPC projects)
        var unifiedClientGeneration = endpointTypes
            .Collect()
            .Combine(streamingTypes.Collect())
            .Combine(compilationInfo)
            .Select(static (data, _) => HasGrpcReferences(data.Right.Compilation)
                ? GrpcClientGenerator.GenerateUnifiedClient(data.Left.Left, data.Left.Right, data.Right)
                : string.Empty);

        context.RegisterSourceOutput(unifiedClientGeneration, EmitUnifiedClient);

        // Step 11: Generate middleware pipelines (for all projects with middleware)
        var middlewareEndpoints = context.SyntaxProvider
            .CreateSyntaxProvider(
                predicate: static (node, _) => node is TypeDeclarationSyntax,
                transform: static (context, _) => MiddlewarePipelineGenerator.GetEndpointWithMiddleware(context))
            .Where(static info => info is not null)
            .Select(static (info, _) => info!);

        var middlewarePipelineGeneration = middlewareEndpoints
            .Collect()
            .Combine(compilationInfo)
            .Select(static (data, _) => MiddlewarePipelineGenerator.GenerateMiddlewarePipelines(data.Left, data.Right));

        context.RegisterSourceOutput(middlewarePipelineGeneration, EmitMiddlewarePipelines);
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

        return new RouteInfo
        {
            TypeName = symbol.Name,
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
            EndpointKind.ServerStream => "GET",
            EndpointKind.ClientStream => "POST",
            EndpointKind.BidirectionalStream => "GET", // WebSocket upgrade
            _ => "GET" // Default for unary
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

    private static void EmitTypedClient(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("AxiomClient.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitProtoFile(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            // Don't generate proto files as C# source - they should be separate files
            // For now, disable proto generation to avoid compilation errors
            // context.AddSource("services.proto", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitGrpcServices(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("GrpcServices.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitUnifiedClient(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("AxiomUnifiedClient.g.cs", SourceText.From(source, Encoding.UTF8));
        }
    }

    private static void EmitMiddlewarePipelines(SourceProductionContext context, string source)
    {
        if (!string.IsNullOrEmpty(source))
        {
            context.AddSource("MiddlewarePipelines.g.cs", SourceText.From(source, Encoding.UTF8));
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