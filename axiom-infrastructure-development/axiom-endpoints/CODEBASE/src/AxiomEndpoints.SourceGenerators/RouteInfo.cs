using System.Collections.Immutable;
using Microsoft.CodeAnalysis;

namespace AxiomEndpoints.SourceGenerators;

internal sealed class RouteInfo
{
    public string TypeName { get; set; } = string.Empty;
    public string Namespace { get; set; } = string.Empty;
    public string Template { get; set; } = string.Empty;
    public ImmutableArray<RouteParameter> Parameters { get; set; } = ImmutableArray<RouteParameter>.Empty;
    public bool IsNested { get; set; }
    public string? ParentTypeName { get; set; }
}

internal sealed class RouteParameter
{
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool IsOptional { get; set; }
    public string? Constraint { get; set; }
}

public sealed class CompilationInfo
{
    public string AssemblyName { get; set; } = string.Empty;
    public string RootNamespace { get; set; } = string.Empty;
    public Compilation? Compilation { get; set; }
}