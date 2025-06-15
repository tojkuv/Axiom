namespace AxiomEndpoints.Aspire.PackageGeneration.Validation;

/// <summary>
/// Validates basic configuration properties
/// </summary>
public class BasicConfigurationValidator : BaseConfigurationValidator
{
    public override string ValidatorName => "BasicConfiguration";
    public override int Priority => 10; // Run early

    public override Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default)
    {
        var result = new ValidationResult();

        ValidateBaseOutputPath(options, result);
        ValidateDefaultSettings(options, result);
        ValidateLanguageConfigurations(options, result);
        ValidateGlobalOptions(options, result);

        return Task.FromResult(result);
    }

    private void ValidateBaseOutputPath(PackageGenerationOptions options, ValidationResult result)
    {
        if (string.IsNullOrWhiteSpace(options.BaseOutputPath))
        {
            result.AddError(
                "EMPTY_OUTPUT_PATH",
                "Base output path cannot be empty",
                "BaseOutputPath",
                "Specify a valid output directory path");
            return;
        }

        if (!IsValidPath(options.BaseOutputPath))
        {
            result.AddError(
                "INVALID_OUTPUT_PATH",
                $"Base output path '{options.BaseOutputPath}' is not a valid path",
                "BaseOutputPath",
                "Use a valid directory path (relative or absolute)");
            return;
        }

        // Check for potentially problematic paths
        var normalizedPath = Path.GetFullPath(options.BaseOutputPath);
        if (normalizedPath.Contains(".."))
        {
            result.AddWarning(
                "RELATIVE_PATH_TRAVERSAL",
                "Output path contains '..' which may cause issues",
                "BaseOutputPath",
                "Consider using absolute paths or simpler relative paths");
        }

        // Check if path is inside system directories
        var systemPaths = new[] { 
            Environment.GetFolderPath(Environment.SpecialFolder.System),
            Environment.GetFolderPath(Environment.SpecialFolder.Windows),
            "/System", "/usr/bin", "/bin" 
        };

        if (systemPaths.Any(sp => !string.IsNullOrEmpty(sp) && normalizedPath.StartsWith(sp)))
        {
            result.AddError(
                "SYSTEM_PATH_OUTPUT",
                "Cannot generate packages in system directories",
                "BaseOutputPath",
                "Choose a user-accessible directory");
        }
    }

    private void ValidateDefaultSettings(PackageGenerationOptions options, ValidationResult result)
    {
        if (!string.IsNullOrEmpty(options.DefaultVersion) && !IsValidVersion(options.DefaultVersion))
        {
            result.AddError(
                "INVALID_DEFAULT_VERSION",
                $"Default version '{options.DefaultVersion}' is not a valid semantic version",
                "DefaultVersion",
                "Use semantic versioning format (e.g., '1.0.0', '2.1.0-beta')");
        }

        if (options.MaxConcurrency <= 0)
        {
            result.AddError(
                "INVALID_MAX_CONCURRENCY",
                "MaxConcurrency must be greater than 0",
                "MaxConcurrency",
                "Set to a positive number (typically 1-8)");
        }
        else if (options.MaxConcurrency > Environment.ProcessorCount * 2)
        {
            result.AddWarning(
                "HIGH_CONCURRENCY",
                $"MaxConcurrency ({options.MaxConcurrency}) is higher than 2x processor count ({Environment.ProcessorCount})",
                "MaxConcurrency",
                "Consider reducing to avoid resource contention");
        }
    }

    private void ValidateLanguageConfigurations(PackageGenerationOptions options, ValidationResult result)
    {
        if (!options.Languages.Any())
        {
            result.AddError(
                "NO_LANGUAGES_CONFIGURED",
                "No target languages configured",
                "Languages",
                "Add at least one language configuration");
            return;
        }

        foreach (var (language, config) in options.Languages)
        {
            var languagePath = $"Languages[{language}]";

            if (string.IsNullOrWhiteSpace(config.PackageName))
            {
                result.AddError(
                    "EMPTY_PACKAGE_NAME",
                    $"Package name for {language} cannot be empty",
                    $"{languagePath}.PackageName",
                    "Specify a valid package name");
                continue;
            }

            if (!IsValidPackageName(config.PackageName, language))
            {
                result.AddError(
                    "INVALID_PACKAGE_NAME",
                    $"Package name '{config.PackageName}' is not valid for {language}",
                    $"{languagePath}.PackageName",
                    GetPackageNameGuidance(language));
            }

            if (string.IsNullOrWhiteSpace(config.OutputPath))
            {
                result.AddError(
                    "EMPTY_LANGUAGE_OUTPUT_PATH",
                    $"Output path for {language} cannot be empty",
                    $"{languagePath}.OutputPath",
                    "Specify a valid output directory");
            }
            else if (!IsValidPath(config.OutputPath))
            {
                result.AddError(
                    "INVALID_LANGUAGE_OUTPUT_PATH",
                    $"Output path '{config.OutputPath}' for {language} is not valid",
                    $"{languagePath}.OutputPath",
                    "Use a valid directory path");
            }

            if (!string.IsNullOrEmpty(config.Version) && !IsValidVersion(config.Version))
            {
                result.AddError(
                    "INVALID_LANGUAGE_VERSION",
                    $"Version '{config.Version}' for {language} is not valid",
                    $"{languagePath}.Version",
                    "Use semantic versioning format");
            }
        }
    }

    private void ValidateGlobalOptions(PackageGenerationOptions options, ValidationResult result)
    {
        foreach (var (key, value) in options.GlobalOptions)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                result.AddWarning(
                    "EMPTY_GLOBAL_OPTION_KEY",
                    "Global option has empty key",
                    "GlobalOptions",
                    "Remove empty keys or provide valid names");
            }

            if (string.IsNullOrEmpty(value))
            {
                result.AddSuggestion(
                    "EMPTY_GLOBAL_OPTION_VALUE",
                    $"Global option '{key}' has empty value",
                    $"GlobalOptions[{key}]",
                    "Consider removing unused options");
            }
        }
    }

    private static string GetPackageNameGuidance(PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => "Use PascalCase (e.g., 'MyAwesomeSDK')",
            PackageLanguage.Kotlin => "Use reverse domain notation (e.g., 'com.company.sdk')",
            PackageLanguage.CSharp => "Use PascalCase with dots (e.g., 'Company.Product.Client')",
            PackageLanguage.TypeScript => "Use lowercase with hyphens (e.g., '@company/api-client' or 'my-grpc-client')",
            _ => "Follow language-specific naming conventions"
        };
    }
}