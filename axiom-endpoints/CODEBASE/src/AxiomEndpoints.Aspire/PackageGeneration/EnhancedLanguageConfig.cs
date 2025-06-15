namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Language-specific feature flags
/// </summary>
public class LanguageFeatures
{
    public bool AsyncAwaitSupport { get; set; } = true;
    public bool NullabilityAnnotations { get; set; } = true;
    public bool GenericsSupport { get; set; } = true;
    public bool ImmutableTypes { get; set; } = false;
    public bool MemoryOptimizations { get; set; } = false;
    public bool DebugSymbols { get; set; } = true;
    public bool DocComments { get; set; } = true;
}

/// <summary>
/// Code style configuration
/// </summary>
public class CodeStyleConfig
{
    public NamingConvention NamingConvention { get; set; } = NamingConvention.LanguageDefault;
    public IndentationStyle IndentationStyle { get; set; } = IndentationStyle.Spaces;
    public int IndentSize { get; set; } = 4;
    public LineEndingStyle LineEndingStyle { get; set; } = LineEndingStyle.Unix;
    public bool TrailingCommas { get; set; } = true;
    public int MaxLineLength { get; set; } = 120;
    public bool SortImports { get; set; } = true;
}

/// <summary>
/// Naming convention styles
/// </summary>
public enum NamingConvention
{
    LanguageDefault,
    CamelCase,
    PascalCase,
    SnakeCase,
    KebabCase
}

/// <summary>
/// Indentation styles
/// </summary>
public enum IndentationStyle
{
    Spaces,
    Tabs
}

/// <summary>
/// Line ending styles
/// </summary>
public enum LineEndingStyle
{
    Unix,
    Windows,
    Mac
}

/// <summary>
/// Enhanced Swift package configuration
/// </summary>
public class SwiftPackageConfig : LanguagePackageConfig
{
    public string SwiftVersion { get; set; } = "5.9";
    public List<SwiftPlatformConfig> SupportedPlatforms { get; set; } = new();
    public SwiftToolsVersion ToolsVersion { get; set; } = SwiftToolsVersion.V5_9;
    public SwiftPackageType PackageType { get; set; } = SwiftPackageType.Library;
    public LanguageFeatures Features { get; set; } = new();
    public CodeStyleConfig CodeStyle { get; set; } = new();
    public bool GenerateDocC { get; set; } = false;
    public bool GenerateLinuxSupport { get; set; } = false;
    public List<SwiftCompilerFlag> CompilerFlags { get; set; } = new();

    public SwiftPackageConfig WithiOS(string minimumVersion = "15.0")
    {
        SupportedPlatforms.Add(SwiftPlatformConfig.iOS(minimumVersion));
        return this;
    }

    public SwiftPackageConfig WithmacOS(string minimumVersion = "12.0")
    {
        SupportedPlatforms.Add(SwiftPlatformConfig.macOS(minimumVersion));
        return this;
    }

    public SwiftPackageConfig WithAsyncAwait(bool enabled = true)
    {
        Features.AsyncAwaitSupport = enabled;
        return this;
    }

    public SwiftPackageConfig WithDocC(bool enabled = true)
    {
        GenerateDocC = enabled;
        return this;
    }
}

/// <summary>
/// Enhanced Kotlin package configuration
/// </summary>
public class KotlinPackageConfig : LanguagePackageConfig
{
    public string KotlinVersion { get; set; } = "1.9.20";
    public List<KotlinPlatformConfig> SupportedPlatforms { get; set; } = new();
    public KotlinCompilerMode CompilerMode { get; set; } = KotlinCompilerMode.JVM;
    public LanguageFeatures Features { get; set; } = new();
    public CodeStyleConfig CodeStyle { get; set; } = new();
    public bool GenerateMultiplatform { get; set; } = false;
    public string JavaVersion { get; set; } = "17";
    public List<KotlinCompilerFlag> CompilerFlags { get; set; } = new();

    public KotlinPackageConfig WithJVM(string javaVersion = "17")
    {
        SupportedPlatforms.Add(KotlinPlatformConfig.JVM(javaVersion));
        JavaVersion = javaVersion;
        return this;
    }

    public KotlinPackageConfig WithAndroid(string apiLevel = "24")
    {
        SupportedPlatforms.Add(KotlinPlatformConfig.Android(apiLevel));
        return this;
    }

    public KotlinPackageConfig WithCoroutines(bool enabled = true)
    {
        Features.AsyncAwaitSupport = enabled;
        return this;
    }
}

/// <summary>
/// Enhanced C# package configuration
/// </summary>
public class CSharpPackageConfig : LanguagePackageConfig
{
    public string LanguageVersion { get; set; } = "12";
    public List<CSharpPlatformConfig> SupportedPlatforms { get; set; } = new();
    public bool NullableEnabled { get; set; } = true;
    public LanguageFeatures Features { get; set; } = new();
    public CodeStyleConfig CodeStyle { get; set; } = new();
    public bool GenerateXmlDocumentation { get; set; } = true;
    public bool GenerateSourceLink { get; set; } = false;
    public List<string> CompilerDirectives { get; set; } = new();

    public CSharpPackageConfig WithNetCore(string version = "net8.0")
    {
        SupportedPlatforms.Add(CSharpPlatformConfig.NetCore(version));
        return this;
    }

    public CSharpPackageConfig WithNetStandard(string version = "netstandard2.1")
    {
        SupportedPlatforms.Add(CSharpPlatformConfig.NetStandard(version));
        return this;
    }

    public CSharpPackageConfig WithNullableReference(bool enabled = true)
    {
        NullableEnabled = enabled;
        Features.NullabilityAnnotations = enabled;
        return this;
    }

    public CSharpPackageConfig WithSourceLink(bool enabled = true)
    {
        GenerateSourceLink = enabled;
        return this;
    }
}

/// <summary>
/// Swift tools version
/// </summary>
public enum SwiftToolsVersion
{
    V5_7,
    V5_8,
    V5_9,
    V5_10
}

/// <summary>
/// Swift package types
/// </summary>
public enum SwiftPackageType
{
    Library,
    Executable,
    Plugin
}

/// <summary>
/// Kotlin compiler modes
/// </summary>
public enum KotlinCompilerMode
{
    JVM,
    Multiplatform,
    Native,
    JS
}

/// <summary>
/// Swift compiler flags
/// </summary>
public class SwiftCompilerFlag
{
    public string Flag { get; set; } = string.Empty;
    public string? Value { get; set; }

    public static SwiftCompilerFlag OptimizeForSpeed() => new() { Flag = "-O" };
    public static SwiftCompilerFlag StrictConcurrency() => new() { Flag = "-strict-concurrency", Value = "complete" };
}

/// <summary>
/// Kotlin compiler flags
/// </summary>
public class KotlinCompilerFlag
{
    public string Flag { get; set; } = string.Empty;
    public string? Value { get; set; }

    public static KotlinCompilerFlag OptIn(string annotation) => new() { Flag = "-opt-in", Value = annotation };
    public static KotlinCompilerFlag ExplicitApi() => new() { Flag = "-Xexplicit-api", Value = "strict" };
}

/// <summary>
/// Enhanced TypeScript package configuration
/// </summary>
public class TypeScriptPackageConfig : LanguagePackageConfig
{
    public string TypeScriptVersion { get; set; } = "5.3.0";
    public List<TypeScriptPlatformConfig> SupportedPlatforms { get; set; } = new();
    public TypeScriptTarget Target { get; set; } = TypeScriptTarget.ES2020;
    public TypeScriptModule ModuleSystem { get; set; } = TypeScriptModule.ESNext;
    public LanguageFeatures Features { get; set; } = new();
    public CodeStyleConfig CodeStyle { get; set; } = new();
    public bool GenerateDeclarations { get; set; } = true;
    public bool GenerateSourceMaps { get; set; } = false;
    public bool EnableGRPCWeb { get; set; } = true;
    public bool EnableNodeGRPC { get; set; } = false;
    public List<TypeScriptCompilerOption> CompilerOptions { get; set; } = new();

    public TypeScriptPackageConfig WithBrowser(string esVersion = "ES2020")
    {
        SupportedPlatforms.Add(TypeScriptPlatformConfig.Browser(esVersion));
        EnableGRPCWeb = true;
        return this;
    }

    public TypeScriptPackageConfig WithNode(string nodeVersion = "18")
    {
        SupportedPlatforms.Add(TypeScriptPlatformConfig.Node(nodeVersion));
        EnableNodeGRPC = true;
        return this;
    }

    public TypeScriptPackageConfig WithReactNative(string rnVersion = "0.72")
    {
        SupportedPlatforms.Add(TypeScriptPlatformConfig.ReactNative(rnVersion));
        EnableGRPCWeb = true;
        return this;
    }

    public TypeScriptPackageConfig WithDeclarations(bool enabled = true)
    {
        GenerateDeclarations = enabled;
        return this;
    }

    public TypeScriptPackageConfig WithSourceMaps(bool enabled = true)
    {
        GenerateSourceMaps = enabled;
        return this;
    }

    public TypeScriptPackageConfig WithStrictMode(bool enabled = true)
    {
        Features.NullabilityAnnotations = enabled;
        CompilerOptions.Add(TypeScriptCompilerOption.Strict(enabled));
        return this;
    }
}

/// <summary>
/// TypeScript compilation targets
/// </summary>
public enum TypeScriptTarget
{
    ES5,
    ES2015,
    ES2016,
    ES2017,
    ES2018,
    ES2019,
    ES2020,
    ES2021,
    ES2022,
    ESNext
}

/// <summary>
/// TypeScript module systems
/// </summary>
public enum TypeScriptModule
{
    None,
    CommonJS,
    AMD,
    UMD,
    System,
    ES6,
    ES2015,
    ES2020,
    ESNext,
    Node16,
    NodeNext
}

/// <summary>
/// TypeScript compiler options
/// </summary>
public class TypeScriptCompilerOption
{
    public string Option { get; set; } = string.Empty;
    public object? Value { get; set; }

    public static TypeScriptCompilerOption Strict(bool enabled) => new() { Option = "strict", Value = enabled };
    public static TypeScriptCompilerOption ExactOptionalPropertyTypes() => new() { Option = "exactOptionalPropertyTypes", Value = true };
    public static TypeScriptCompilerOption NoImplicitReturns() => new() { Option = "noImplicitReturns", Value = true };
    public static TypeScriptCompilerOption NoFallthroughCasesInSwitch() => new() { Option = "noFallthroughCasesInSwitch", Value = true };
    public static TypeScriptCompilerOption NoUncheckedIndexedAccess() => new() { Option = "noUncheckedIndexedAccess", Value = true };
}