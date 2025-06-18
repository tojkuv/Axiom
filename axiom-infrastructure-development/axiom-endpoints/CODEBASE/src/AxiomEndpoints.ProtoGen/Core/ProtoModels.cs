namespace AxiomEndpoints.ProtoGen.Core;

/// <summary>
/// Proto package representation
/// </summary>
public class ProtoPackage
{
    public required string Name { get; set; }
    public required string CSharpNamespace { get; set; }
    public required string Version { get; set; }
    public required ProtoOptions Options { get; set; }
    public List<string> Imports { get; } = new();
    public List<ProtoMessage> Messages { get; set; } = new();
    public List<ProtoEnum> Enums { get; } = new();
    public List<ProtoService> Services { get; } = new();
}

public class ProtoOptions
{
    public string? JavaPackage { get; set; }
    public bool JavaMultipleFiles { get; set; }
    public string? SwiftPrefix { get; set; }
    public string? ObjcClassPrefix { get; set; }
    public string? GoPackage { get; set; }
}

public class ProtoMessage
{
    public required string Name { get; init; }
    public required string CSharpType { get; init; }
    public string? Documentation { get; set; }
    public string? BaseType { get; set; }
    public bool IsGeneric { get; set; }
    public List<string> GenericParameters { get; set; } = new();
    public List<ProtoField> Fields { get; set; } = new();
    public List<ProtoMessage> NestedTypes { get; set; } = new();
    public List<string> Options { get; set; } = new();
}

public class ProtoField
{
    public required string Name { get; init; }
    public required string CSharpName { get; init; }
    public string ProtoType { get; set; } = "";
    public required int FieldNumber { get; init; }
    public string? Documentation { get; set; }
    public bool IsRepeated { get; set; }
    public bool IsOptional { get; set; }
    public bool IsMap { get; set; }
    public List<string> Options { get; set; } = new();
}

public class ProtoEnum
{
    public required string Name { get; init; }
    public required string CSharpType { get; init; }
    public string? Documentation { get; set; }
    public List<ProtoEnumValue> Values { get; set; } = new();
    public List<string> Options { get; set; } = new();
}

public class ProtoEnumValue
{
    public required string Name { get; init; }
    public required int Value { get; init; }
    public string? Documentation { get; set; }
    public List<string> Options { get; set; } = new();
}

public class ProtoService
{
    public required string Name { get; init; }
    public string? Documentation { get; set; }
    public List<ProtoRpc> Rpcs { get; set; } = new();
    public List<string> Options { get; set; } = new();
}

public class ProtoRpc
{
    public required string Name { get; init; }
    public required string RequestType { get; init; }
    public required string ResponseType { get; init; }
    public bool IsServerStreaming { get; set; }
    public bool IsClientStreaming { get; set; }
    public string? Documentation { get; set; }
    public List<string> Options { get; set; } = new();
}

public class ProtoGeneratorOptions
{
    public string? PackageName { get; set; }
    public string? Organization { get; set; }
    public string? SwiftPrefix { get; set; }
    public string? ObjcClassPrefix { get; set; }
    public bool IncludeValidation { get; set; } = true;
    public bool IncludeDocumentation { get; set; } = true;
    public bool GenerateServices { get; set; } = true;
}

public class TypeAnalyzer
{
    // Placeholder for type analysis functionality
    // In a real implementation, this would use Roslyn to analyze types
}