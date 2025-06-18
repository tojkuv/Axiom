namespace AxiomEndpoints.Aspire.PackageGeneration;

/// <summary>
/// Supported package generation languages
/// </summary>
public enum PackageLanguage
{
    /// <summary>
    /// Swift Package Manager package for iOS/macOS/tvOS/watchOS
    /// </summary>
    Swift,

    /// <summary>
    /// Kotlin/Java package with Gradle build configuration
    /// </summary>
    Kotlin,

    /// <summary>
    /// C# .NET project/NuGet package
    /// </summary>
    CSharp,

    /// <summary>
    /// TypeScript package for web/Node.js applications with gRPC-Web support
    /// </summary>
    TypeScript
}

/// <summary>
/// Extension methods for PackageLanguage enum
/// </summary>
public static class PackageLanguageExtensions
{
    /// <summary>
    /// Get the string representation used by the ProtoGen CLI
    /// </summary>
    public static string ToProtoGenString(this PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => "Swift",
            PackageLanguage.Kotlin => "Kotlin", 
            PackageLanguage.CSharp => "CSharp",
            PackageLanguage.TypeScript => "TypeScript",
            _ => throw new ArgumentOutOfRangeException(nameof(language), language, null)
        };
    }

    /// <summary>
    /// Get the default file extension for the language
    /// </summary>
    public static string GetDefaultExtension(this PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => ".swift",
            PackageLanguage.Kotlin => ".kt",
            PackageLanguage.CSharp => ".cs",
            PackageLanguage.TypeScript => ".ts",
            _ => throw new ArgumentOutOfRangeException(nameof(language), language, null)
        };
    }

    /// <summary>
    /// Get the default package manager for the language
    /// </summary>
    public static string GetPackageManager(this PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => "Swift Package Manager",
            PackageLanguage.Kotlin => "Gradle",
            PackageLanguage.CSharp => "NuGet",
            PackageLanguage.TypeScript => "npm",
            _ => throw new ArgumentOutOfRangeException(nameof(language), language, null)
        };
    }

    /// <summary>
    /// Get the default output directory name for the language
    /// </summary>
    public static string GetDefaultDirectoryName(this PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => "swift",
            PackageLanguage.Kotlin => "kotlin",
            PackageLanguage.CSharp => "csharp",
            PackageLanguage.TypeScript => "typescript",
            _ => throw new ArgumentOutOfRangeException(nameof(language), language, null)
        };
    }
}