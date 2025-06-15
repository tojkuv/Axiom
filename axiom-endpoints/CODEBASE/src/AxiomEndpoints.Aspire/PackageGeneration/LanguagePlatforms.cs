namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Swift platform targets
/// </summary>
public enum SwiftPlatform
{
    iOS,
    macOS,
    tvOS,
    watchOS,
    visionOS,
    Linux
}

/// <summary>
/// Kotlin platform targets
/// </summary>
public enum KotlinPlatform
{
    JVM,
    Android,
    Native,
    JS,
    Wasm
}

/// <summary>
/// C# platform targets
/// </summary>
public enum CSharpPlatform
{
    NetCore,
    NetFramework,
    NetStandard,
    Xamarin,
    Blazor,
    Unity
}

/// <summary>
/// TypeScript platform targets
/// </summary>
public enum TypeScriptPlatform
{
    Browser,
    Node,
    ReactNative,
    Electron,
    WebWorker
}

/// <summary>
/// Platform-specific configuration for Swift
/// </summary>
public class SwiftPlatformConfig
{
    public SwiftPlatform Platform { get; set; }
    public string MinimumVersion { get; set; } = string.Empty;
    public bool IsEnabled { get; set; } = true;
    public Dictionary<string, string> PlatformSpecificOptions { get; set; } = new();

    public static SwiftPlatformConfig iOS(string minimumVersion = "15.0") => new()
    {
        Platform = SwiftPlatform.iOS,
        MinimumVersion = minimumVersion
    };

    public static SwiftPlatformConfig macOS(string minimumVersion = "12.0") => new()
    {
        Platform = SwiftPlatform.macOS,
        MinimumVersion = minimumVersion
    };

    public static SwiftPlatformConfig tvOS(string minimumVersion = "15.0") => new()
    {
        Platform = SwiftPlatform.tvOS,
        MinimumVersion = minimumVersion
    };

    public static SwiftPlatformConfig watchOS(string minimumVersion = "8.0") => new()
    {
        Platform = SwiftPlatform.watchOS,
        MinimumVersion = minimumVersion
    };
}

/// <summary>
/// Platform-specific configuration for Kotlin
/// </summary>
public class KotlinPlatformConfig
{
    public KotlinPlatform Platform { get; set; }
    public string TargetVersion { get; set; } = string.Empty;
    public bool IsEnabled { get; set; } = true;
    public Dictionary<string, string> PlatformSpecificOptions { get; set; } = new();

    public static KotlinPlatformConfig JVM(string targetVersion = "17") => new()
    {
        Platform = KotlinPlatform.JVM,
        TargetVersion = targetVersion
    };

    public static KotlinPlatformConfig Android(string apiLevel = "24") => new()
    {
        Platform = KotlinPlatform.Android,
        TargetVersion = apiLevel,
        PlatformSpecificOptions = { ["compileSdk"] = "34", ["minSdk"] = apiLevel }
    };
}

/// <summary>
/// Platform-specific configuration for C#
/// </summary>
public class CSharpPlatformConfig
{
    public CSharpPlatform Platform { get; set; }
    public string TargetFramework { get; set; } = string.Empty;
    public bool IsEnabled { get; set; } = true;
    public Dictionary<string, string> PlatformSpecificOptions { get; set; } = new();

    public static CSharpPlatformConfig NetCore(string version = "net8.0") => new()
    {
        Platform = CSharpPlatform.NetCore,
        TargetFramework = version
    };

    public static CSharpPlatformConfig NetStandard(string version = "netstandard2.1") => new()
    {
        Platform = CSharpPlatform.NetStandard,
        TargetFramework = version
    };

    public static CSharpPlatformConfig NetFramework(string version = "net48") => new()
    {
        Platform = CSharpPlatform.NetFramework,
        TargetFramework = version
    };
}

/// <summary>
/// Platform-specific configuration for TypeScript
/// </summary>
public class TypeScriptPlatformConfig
{
    public TypeScriptPlatform Platform { get; set; }
    public string TargetVersion { get; set; } = string.Empty;
    public bool IsEnabled { get; set; } = true;
    public Dictionary<string, string> PlatformSpecificOptions { get; set; } = new();

    public static TypeScriptPlatformConfig Browser(string esVersion = "ES2020") => new()
    {
        Platform = TypeScriptPlatform.Browser,
        TargetVersion = esVersion,
        PlatformSpecificOptions = 
        { 
            ["module"] = "esnext",
            ["moduleResolution"] = "bundler",
            ["lib"] = "DOM,ES2020"
        }
    };

    public static TypeScriptPlatformConfig Node(string nodeVersion = "18") => new()
    {
        Platform = TypeScriptPlatform.Node,
        TargetVersion = nodeVersion,
        PlatformSpecificOptions = 
        { 
            ["module"] = "commonjs",
            ["moduleResolution"] = "node",
            ["lib"] = "ES2020"
        }
    };

    public static TypeScriptPlatformConfig ReactNative(string rnVersion = "0.72") => new()
    {
        Platform = TypeScriptPlatform.ReactNative,
        TargetVersion = rnVersion,
        PlatformSpecificOptions = 
        { 
            ["module"] = "esnext",
            ["moduleResolution"] = "node",
            ["jsx"] = "react-native"
        }
    };

    public static TypeScriptPlatformConfig Electron(string electronVersion = "latest") => new()
    {
        Platform = TypeScriptPlatform.Electron,
        TargetVersion = electronVersion,
        PlatformSpecificOptions = 
        { 
            ["module"] = "commonjs",
            ["moduleResolution"] = "node",
            ["lib"] = "DOM,ES2020"
        }
    };
}