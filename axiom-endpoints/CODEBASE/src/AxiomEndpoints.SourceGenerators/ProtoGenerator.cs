using System;
using System.Collections.Immutable;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;

namespace AxiomEndpoints.SourceGenerators;

internal static class ProtoGenerator
{
    public static string GenerateProtoFile(
        ImmutableArray<EndpointInfo> endpoints,
        ImmutableArray<StreamingEndpointInfo> streamingEndpoints,
        CompilationInfo compilation)
    {
        var sb = new StringBuilder();

        sb.AppendLine("syntax = \"proto3\";");
        sb.AppendLine();
        sb.AppendLine($"package {compilation.RootNamespace.ToLowerInvariant()};");
        sb.AppendLine();
        sb.AppendLine("import \"google/protobuf/empty.proto\";");
        sb.AppendLine("import \"google/protobuf/timestamp.proto\";");
        sb.AppendLine();

        // Generate services
        var services = endpoints
            .Where(e => e.Kind != EndpointKind.Unary || ShouldIncludeInGrpc(e))
            .Concat(streamingEndpoints.Select(s => new EndpointInfo
            {
                TypeName = s.TypeName,
                Namespace = s.Namespace,
                RequestType = s.RequestType,
                ResponseType = s.ResponseType,
                Kind = MapStreamingMode(s.Mode)
            }))
            .GroupBy(e => GetServiceName(e))
            .ToList();

        foreach (var service in services)
        {
            sb.AppendLine($"service {service.Key} {{");

            foreach (var endpoint in service)
            {
                GenerateRpc(sb, endpoint);
            }

            sb.AppendLine("}");
            sb.AppendLine();
        }

        // Generate message types (simplified - real implementation would analyze types)
        GenerateMessageTypes(sb, endpoints.Concat(streamingEndpoints.Select(s => new EndpointInfo
        {
            TypeName = s.TypeName,
            RequestType = s.RequestType,
            ResponseType = s.ResponseType,
            Kind = MapStreamingMode(s.Mode)
        })).ToArray());

        return sb.ToString();
    }

    private static void GenerateRpc(StringBuilder sb, EndpointInfo endpoint)
    {
        var (reqStream, respStream) = endpoint.Kind switch
        {
            EndpointKind.ServerStream => ("", "stream "),
            EndpointKind.ClientStream => ("stream ", ""),
            EndpointKind.BidirectionalStream => ("stream ", "stream "),
            _ => ("", "")
        };

        var requestType = GetProtoTypeName(endpoint.RequestType);
        var responseType = GetProtoTypeName(endpoint.ResponseType);

        sb.AppendLine($"  rpc {endpoint.TypeName}({reqStream}{requestType}) returns ({respStream}{responseType});");
    }

    private static void GenerateMessageTypes(StringBuilder sb, EndpointInfo[] endpoints)
    {
        var messageTypes = new System.Collections.Generic.Dictionary<string, MessageTypeInfo>();

        foreach (var endpoint in endpoints)
        {
            CollectMessageTypes(messageTypes, endpoint.RequestType);
            CollectMessageTypes(messageTypes, endpoint.ResponseType);
        }

        foreach (var messageType in messageTypes.Values.OrderBy(x => x.Name))
        {
            GenerateMessage(sb, messageType);
        }
    }

    private static void CollectMessageTypes(System.Collections.Generic.Dictionary<string, MessageTypeInfo> messageTypes, string csharpType)
    {
        var protoTypeName = GetProtoTypeName(csharpType);
        
        if (IsWellKnownType(protoTypeName) || IsBuiltInType(protoTypeName) || messageTypes.ContainsKey(protoTypeName))
        {
            return;
        }

        var messageInfo = AnalyzeCSharpType(csharpType);
        if (messageInfo != null)
        {
            messageTypes[protoTypeName] = messageInfo;
            
            // Recursively collect nested types
            foreach (var field in messageInfo.Fields)
            {
                if (!IsBuiltInType(field.ProtoType) && !IsWellKnownType(field.ProtoType))
                {
                    CollectMessageTypes(messageTypes, field.CSharpType);
                }
            }
        }
    }

    private static MessageTypeInfo? AnalyzeCSharpType(string csharpType)
    {
        // For now, create a simplified message structure
        // In a full implementation, this would use Roslyn to analyze the actual type
        var typeName = GetProtoTypeName(csharpType);
        
        var fields = new System.Collections.Generic.List<ProtoField>();
        
        // Add some common fields based on type patterns
        if (csharpType.Contains("Request"))
        {
            fields.Add(new ProtoField { Name = "id", ProtoType = "string", CSharpType = "string", Number = 1 });
        }
        else if (csharpType.Contains("Response") || csharpType.Contains("Todo"))
        {
            fields.Add(new ProtoField { Name = "id", ProtoType = "string", CSharpType = "string", Number = 1 });
            fields.Add(new ProtoField { Name = "title", ProtoType = "string", CSharpType = "string", Number = 2 });
            fields.Add(new ProtoField { Name = "is_complete", ProtoType = "bool", CSharpType = "bool", Number = 3 });
            fields.Add(new ProtoField { Name = "created_at", ProtoType = "google.protobuf.Timestamp", CSharpType = "System.DateTime", Number = 4 });
        }
        else
        {
            // Generic message with common field
            fields.Add(new ProtoField { Name = "value", ProtoType = "string", CSharpType = "string", Number = 1 });
        }

        return new MessageTypeInfo
        {
            Name = typeName,
            CSharpType = csharpType,
            Fields = fields
        };
    }

    private static void GenerateMessage(StringBuilder sb, MessageTypeInfo messageType)
    {
        sb.AppendLine($"message {messageType.Name} {{");

        foreach (var field in messageType.Fields)
        {
            var repeated = field.IsRepeated ? "repeated " : "";
            var optional = field.IsOptional ? "optional " : "";
            
            sb.AppendLine($"  {repeated}{optional}{field.ProtoType} {field.Name} = {field.Number};");
        }

        sb.AppendLine("}");
        sb.AppendLine();
    }

    private static bool IsBuiltInType(string typeName)
    {
        return typeName switch
        {
            "string" => true,
            "int32" => true,
            "int64" => true,
            "uint32" => true,
            "uint64" => true,
            "float" => true,
            "double" => true,
            "bool" => true,
            "bytes" => true,
            _ => false
        };
    }

    private static string GetServiceName(EndpointInfo endpoint)
    {
        // Extract service name from namespace or use a default
        var parts = endpoint.Namespace.Split('.');
        var serviceName = parts.Length > 1 ? parts[parts.Length - 1] : "DefaultService";
        
        // Ensure it ends with "Service"
        if (!serviceName.EndsWith("Service", StringComparison.OrdinalIgnoreCase))
        {
            serviceName += "Service";
        }

        return serviceName;
    }

    private static string GetProtoTypeName(string csharpType)
    {
        // Handle built-in types first
        var builtInType = MapBuiltInType(csharpType);
        if (builtInType != null)
            return builtInType;

        // Handle collections
        if (IsCollectionType(csharpType))
        {
            var elementType = ExtractElementType(csharpType);
            return GetProtoTypeName(elementType);
        }

        // Remove namespace and generic parameters for proto naming
        var typeName = csharpType.Split('.').Last().Split('<').First();
        
        // Convert to proto naming convention (PascalCase)
        return typeName;
    }

    private static string? MapBuiltInType(string csharpType)
    {
        return csharpType switch
        {
            "System.String" or "string" => "string",
            "System.Int32" or "int" => "int32",
            "System.Int64" or "long" => "int64",
            "System.UInt32" or "uint" => "uint32",
            "System.UInt64" or "ulong" => "uint64",
            "System.Single" or "float" => "float",
            "System.Double" or "double" => "double",
            "System.Boolean" or "bool" => "bool",
            "System.Byte[]" or "byte[]" => "bytes",
            "System.Guid" => "string", // Guid as string in proto
            "System.DateTime" => "google.protobuf.Timestamp",
            "System.DateTimeOffset" => "google.protobuf.Timestamp",
            "System.TimeSpan" => "google.protobuf.Duration",
            "System.Decimal" => "string", // Decimal as string with custom conversion
            _ => null
        };
    }

    private static bool IsCollectionType(string csharpType)
    {
        return csharpType.Contains("List<") || 
               csharpType.Contains("IEnumerable<") || 
               csharpType.Contains("ICollection<") ||
               csharpType.Contains("[]");
    }

    private static string ExtractElementType(string csharpType)
    {
        if (csharpType.EndsWith("[]"))
        {
            return csharpType.Substring(0, csharpType.Length - 2);
        }

        var start = csharpType.IndexOf('<') + 1;
        var end = csharpType.LastIndexOf('>');
        if (start > 0 && end > start)
        {
            return csharpType.Substring(start, end - start);
        }

        return csharpType;
    }

    private static bool IsWellKnownType(string typeName)
    {
        return typeName switch
        {
            "Empty" => true,
            "Timestamp" => true,
            "Duration" => true,
            "Any" => true,
            _ => false
        };
    }

    private static bool ShouldIncludeInGrpc(EndpointInfo endpoint)
    {
        // Include all endpoints in gRPC for now
        // Could be made configurable via attributes
        return true;
    }

    private static EndpointKind MapStreamingMode(StreamingMode mode)
    {
        return mode switch
        {
            StreamingMode.ServerStream => EndpointKind.ServerStream,
            StreamingMode.ClientStream => EndpointKind.ClientStream,
            StreamingMode.Bidirectional => EndpointKind.BidirectionalStream,
            _ => EndpointKind.Unary
        };
    }
}

internal class MessageTypeInfo
{
    public string Name { get; set; } = string.Empty;
    public string CSharpType { get; set; } = string.Empty;
    public System.Collections.Generic.List<ProtoField> Fields { get; set; } = new();
}

internal class ProtoField
{
    public string Name { get; set; } = string.Empty;
    public string ProtoType { get; set; } = string.Empty;
    public string CSharpType { get; set; } = string.Empty;
    public int Number { get; set; }
    public bool IsRepeated { get; set; }
    public bool IsOptional { get; set; }
}