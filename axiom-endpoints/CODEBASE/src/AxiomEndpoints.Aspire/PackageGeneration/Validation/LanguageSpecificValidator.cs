using System.Text.RegularExpressions;

namespace AxiomEndpoints.Aspire.PackageGeneration.Validation;

/// <summary>
/// Validates language-specific configurations and best practices
/// </summary>
public class LanguageSpecificValidator : BaseConfigurationValidator
{
    public override string ValidatorName => "LanguageSpecific";
    public override int Priority => 20;

    public override Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default)
    {
        var result = new ValidationResult();

        foreach (var (language, config) in options.Languages)
        {
            switch (language)
            {
                case PackageLanguage.Swift:
                    ValidateSwiftConfiguration(config, result);
                    break;
                case PackageLanguage.Kotlin:
                    ValidateKotlinConfiguration(config, result);
                    break;
                case PackageLanguage.CSharp:
                    ValidateCSharpConfiguration(config, result);
                    break;
                case PackageLanguage.TypeScript:
                    ValidateTypeScriptConfiguration(config, result);
                    break;
            }
        }

        return Task.FromResult(result);
    }

    private void ValidateSwiftConfiguration(LanguagePackageConfig config, ValidationResult result)
    {
        var path = $"Languages[Swift]";

        // Check for Swift-specific best practices
        if (config.PackageName.Contains("Swift") || config.PackageName.Contains("SDK"))
        {
            result.AddSuggestion(
                "SWIFT_REDUNDANT_NAMING",
                $"Swift package name '{config.PackageName}' contains 'Swift' or 'SDK' which may be redundant",
                $"{path}.PackageName",
                "Consider a more concise name (users know it's a Swift SDK)");
        }

        // Check version format for Swift conventions
        if (!string.IsNullOrEmpty(config.Version))
        {
            if (!Regex.IsMatch(config.Version, @"^\d+\.\d+\.\d+$"))
            {
                result.AddWarning(
                    "SWIFT_VERSION_FORMAT",
                    "Swift packages typically use simple semantic versioning (x.y.z)",
                    $"{path}.Version",
                    "Consider using format like '1.0.0' without pre-release suffixes");
            }
        }

        // Check for documentation generation
        if (!config.IncludeDocumentation)
        {
            result.AddSuggestion(
                "SWIFT_MISSING_DOCS",
                "Swift packages benefit greatly from DocC documentation",
                $"{path}.IncludeDocumentation",
                "Enable documentation generation for better developer experience");
        }

        ValidateSwiftDependencies(config, result, path);
    }

    private void ValidateKotlinConfiguration(LanguagePackageConfig config, ValidationResult result)
    {
        var path = $"Languages[Kotlin]";

        // Check package name format
        if (!config.PackageName.Contains('.'))
        {
            result.AddWarning(
                "KOTLIN_PACKAGE_NAMING",
                "Kotlin packages should typically use reverse domain notation",
                $"{path}.PackageName",
                "Consider format like 'com.company.product' or 'org.project.module'");
        }

        // Check for lowercase in package name
        if (config.PackageName.Any(char.IsUpper))
        {
            result.AddWarning(
                "KOTLIN_PACKAGE_CASE",
                "Kotlin package names should be lowercase",
                $"{path}.PackageName",
                "Use lowercase letters separated by dots");
        }

        ValidateKotlinDependencies(config, result, path);
    }

    private void ValidateCSharpConfiguration(LanguagePackageConfig config, ValidationResult result)
    {
        var path = $"Languages[CSharp]";

        // Check for .NET naming conventions
        if (!char.IsUpper(config.PackageName[0]))
        {
            result.AddWarning(
                "CSHARP_PACKAGE_NAMING",
                "C# package names should start with uppercase letter",
                $"{path}.PackageName",
                "Use PascalCase naming (e.g., 'Company.Product.Client')");
        }

        // Check for appropriate suffixes
        var appropriateSuffixes = new[] { "Client", "SDK", "Api", "Core", "Common" };
        var lastPart = config.PackageName.Split('.').LastOrDefault() ?? "";
        
        if (!appropriateSuffixes.Any(suffix => lastPart.EndsWith(suffix, StringComparison.OrdinalIgnoreCase)))
        {
            result.AddSuggestion(
                "CSHARP_PACKAGE_SUFFIX",
                $"C# packages often benefit from descriptive suffixes",
                $"{path}.PackageName",
                $"Consider adding suffix like {string.Join(", ", appropriateSuffixes)}");
        }

        ValidateCSharpDependencies(config, result, path);
    }

    private void ValidateTypeScriptConfiguration(LanguagePackageConfig config, ValidationResult result)
    {
        var path = $"Languages[TypeScript]";

        // Check package name format for npm
        if (!IsValidNpmPackageName(config.PackageName))
        {
            result.AddError(
                "TYPESCRIPT_INVALID_PACKAGE_NAME",
                $"TypeScript package name '{config.PackageName}' is not valid for npm",
                $"{path}.PackageName",
                "Use lowercase letters, numbers, hyphens, and dots (e.g., '@company/api-client' or 'my-grpc-client')");
        }

        // Check for scoped package recommendation
        if (!config.PackageName.StartsWith('@') && !config.PackageName.Contains('-'))
        {
            result.AddSuggestion(
                "TYPESCRIPT_RECOMMEND_SCOPED_PACKAGE",
                "Consider using a scoped package name for better namespace management",
                $"{path}.PackageName",
                "Use format like '@company/package-name' to avoid naming conflicts");
        }

        // Check for gRPC-Web dependencies
        ValidateTypeScriptDependencies(config, result, path);
    }

    private void ValidateSwiftDependencies(LanguagePackageConfig config, ValidationResult result, string path)
    {
        var requiredDependencies = new[] { "SwiftProtobuf" };
        var recommendedDependencies = new[] { "GRPC-Swift" };

        foreach (var required in requiredDependencies)
        {
            if (!config.Dependencies.ContainsKey(required))
            {
                result.AddWarning(
                    "SWIFT_MISSING_REQUIRED_DEPENDENCY",
                    $"Swift gRPC packages typically require '{required}' dependency",
                    $"{path}.Dependencies",
                    $"Add dependency: {required}");
            }
        }

        foreach (var recommended in recommendedDependencies)
        {
            if (!config.Dependencies.ContainsKey(recommended))
            {
                result.AddSuggestion(
                    "SWIFT_MISSING_RECOMMENDED_DEPENDENCY",
                    $"Consider adding '{recommended}' for full gRPC support",
                    $"{path}.Dependencies",
                    $"Add dependency: {recommended}");
            }
        }

        // Check dependency versions
        foreach (var (name, version) in config.Dependencies)
        {
            if (name == "SwiftProtobuf" && !string.IsNullOrEmpty(version))
            {
                if (Version.TryParse(version, out var v) && v < new Version(1, 20, 0))
                {
                    result.AddWarning(
                        "SWIFT_OLD_PROTOBUF_VERSION",
                        $"SwiftProtobuf version {version} is quite old",
                        $"{path}.Dependencies[{name}]",
                        "Consider updating to 1.25.0 or later");
                }
            }
        }
    }

    private void ValidateKotlinDependencies(LanguagePackageConfig config, ValidationResult result, string path)
    {
        var requiredDependencies = new[] { "com.google.protobuf:protobuf-kotlin" };
        var recommendedDependencies = new[] { "io.grpc:grpc-kotlin-stub", "org.jetbrains.kotlinx:kotlinx-coroutines-core" };

        foreach (var required in requiredDependencies)
        {
            if (!config.Dependencies.ContainsKey(required))
            {
                result.AddWarning(
                    "KOTLIN_MISSING_REQUIRED_DEPENDENCY",
                    $"Kotlin gRPC packages typically require '{required}' dependency",
                    $"{path}.Dependencies",
                    $"Add dependency: {required}");
            }
        }

        foreach (var recommended in recommendedDependencies)
        {
            if (!config.Dependencies.ContainsKey(recommended))
            {
                result.AddSuggestion(
                    "KOTLIN_MISSING_RECOMMENDED_DEPENDENCY",
                    $"Consider adding '{recommended}' for better gRPC support",
                    $"{path}.Dependencies",
                    $"Add dependency: {recommended}");
            }
        }
    }

    private void ValidateCSharpDependencies(LanguagePackageConfig config, ValidationResult result, string path)
    {
        var requiredDependencies = new[] { "Google.Protobuf" };
        var recommendedDependencies = new[] { "Grpc.Net.Client", "Grpc.AspNetCore" };

        foreach (var required in requiredDependencies)
        {
            if (!config.Dependencies.ContainsKey(required))
            {
                result.AddWarning(
                    "CSHARP_MISSING_REQUIRED_DEPENDENCY",
                    $"C# gRPC packages typically require '{required}' dependency",
                    $"{path}.Dependencies",
                    $"Add dependency: {required}");
            }
        }

        foreach (var recommended in recommendedDependencies)
        {
            if (!config.Dependencies.ContainsKey(recommended))
            {
                result.AddSuggestion(
                    "CSHARP_MISSING_RECOMMENDED_DEPENDENCY",
                    $"Consider adding '{recommended}' for full gRPC support",
                    $"{path}.Dependencies",
                    $"Add dependency: {recommended}");
            }
        }

        // Check for .NET version compatibility
        foreach (var (name, version) in config.Dependencies)
        {
            if (name == "Google.Protobuf" && !string.IsNullOrEmpty(version))
            {
                if (Version.TryParse(version, out var v) && v < new Version(3, 21, 0))
                {
                    result.AddWarning(
                        "CSHARP_OLD_PROTOBUF_VERSION",
                        $"Google.Protobuf version {version} may have compatibility issues",
                        $"{path}.Dependencies[{name}]",
                        "Consider updating to 3.25.0 or later");
                }
            }
        }
    }

    private void ValidateTypeScriptDependencies(LanguagePackageConfig config, ValidationResult result, string path)
    {
        var requiredDependencies = new[] { "@grpc/grpc-js", "google-protobuf" };
        var recommendedDependencies = new[] { "grpc-web", "@types/google-protobuf" };

        foreach (var required in requiredDependencies)
        {
            if (!config.Dependencies.Any(dep => dep.Name == required))
            {
                result.AddWarning(
                    "TYPESCRIPT_MISSING_REQUIRED_DEPENDENCY",
                    $"TypeScript gRPC packages typically require '{required}' dependency",
                    $"{path}.Dependencies",
                    $"Add dependency: {required}");
            }
        }

        foreach (var recommended in recommendedDependencies)
        {
            if (!config.Dependencies.Any(dep => dep.Name == recommended))
            {
                result.AddSuggestion(
                    "TYPESCRIPT_MISSING_RECOMMENDED_DEPENDENCY",
                    $"Consider adding '{recommended}' for better TypeScript support",
                    $"{path}.Dependencies",
                    $"Add dependency: {recommended}");
            }
        }

        // Check for conflicting gRPC libraries
        var hasGrpcJs = config.Dependencies.Any(dep => dep.Name == "@grpc/grpc-js");
        var hasGrpcWeb = config.Dependencies.Any(dep => dep.Name == "grpc-web");

        if (hasGrpcJs && hasGrpcWeb)
        {
            result.AddWarning(
                "TYPESCRIPT_GRPC_LIBRARY_CONFLICT",
                "Both @grpc/grpc-js and grpc-web are present - ensure they're used for different platforms",
                $"{path}.Dependencies",
                "Use @grpc/grpc-js for Node.js and grpc-web for browsers");
        }
    }

    private static bool IsValidNpmPackageName(string name)
    {
        // NPM package name validation rules
        if (string.IsNullOrWhiteSpace(name) || name.Length > 214)
            return false;

        // Must be lowercase
        if (name != name.ToLowerInvariant())
            return false;

        // Scoped packages
        if (name.StartsWith('@'))
        {
            var parts = name.Split('/');
            if (parts.Length != 2)
                return false;
            
            var scope = parts[0];
            var packageName = parts[1];

            // Validate scope (without @)
            if (!Regex.IsMatch(scope[1..], @"^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$"))
                return false;

            // Validate package name
            return Regex.IsMatch(packageName, @"^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$");
        }

        // Regular packages
        return Regex.IsMatch(name, @"^[a-z0-9]([a-z0-9._-]*[a-z0-9])?$");
    }
}