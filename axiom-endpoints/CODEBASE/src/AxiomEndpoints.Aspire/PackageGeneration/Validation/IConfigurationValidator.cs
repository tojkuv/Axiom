using System.Text.RegularExpressions;

namespace AxiomEndpoints.Aspire.PackageGeneration.Validation;

/// <summary>
/// Interface for configuration validators
/// </summary>
public interface IConfigurationValidator
{
    /// <summary>
    /// Validate the configuration
    /// </summary>
    Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default);

    /// <summary>
    /// Validator name for reporting
    /// </summary>
    string ValidatorName { get; }

    /// <summary>
    /// Validation order priority (lower numbers run first)
    /// </summary>
    int Priority { get; }
}

/// <summary>
/// Configuration validation pipeline
/// </summary>
public interface IValidationPipeline
{
    /// <summary>
    /// Add a validator to the pipeline
    /// </summary>
    IValidationPipeline AddValidator(IConfigurationValidator validator);

    /// <summary>
    /// Run all validators and return combined results
    /// </summary>
    Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default);

    /// <summary>
    /// Run validation with specific severity filter
    /// </summary>
    Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, ValidationSeverity minimumSeverity, CancellationToken cancellationToken = default);
}

/// <summary>
/// Default validation pipeline implementation
/// </summary>
public class ValidationPipeline : IValidationPipeline
{
    private readonly List<IConfigurationValidator> _validators = new();

    public IValidationPipeline AddValidator(IConfigurationValidator validator)
    {
        _validators.Add(validator);
        return this;
    }

    public async Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default)
    {
        return await ValidateAsync(options, ValidationSeverity.Info, cancellationToken);
    }

    public async Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, ValidationSeverity minimumSeverity, CancellationToken cancellationToken = default)
    {
        var result = new ValidationResult();
        var orderedValidators = _validators.OrderBy(v => v.Priority);

        foreach (var validator in orderedValidators)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                var validationResult = await validator.ValidateAsync(options, cancellationToken);
                result = result.Merge(validationResult);
            }
            catch (Exception ex)
            {
                result.AddError(
                    "VALIDATION_EXCEPTION", 
                    $"Validator '{validator.ValidatorName}' threw an exception: {ex.Message}",
                    validator.ValidatorName);
            }
        }

        return result;
    }
}

/// <summary>
/// Base validator with common functionality
/// </summary>
public abstract class BaseConfigurationValidator : IConfigurationValidator
{
    public abstract string ValidatorName { get; }
    public virtual int Priority => 100;

    public abstract Task<ValidationResult> ValidateAsync(PackageGenerationOptions options, CancellationToken cancellationToken = default);

    protected static bool IsValidPackageName(string name, PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => IsValidSwiftPackageName(name),
            PackageLanguage.Kotlin => IsValidKotlinPackageName(name),
            PackageLanguage.CSharp => IsValidCSharpPackageName(name),
            PackageLanguage.TypeScript => IsValidTypeScriptPackageName(name),
            _ => false
        };
    }

    protected static bool IsValidSwiftPackageName(string name)
    {
        // Swift package names should be PascalCase and contain only letters, numbers, and underscores
        return Regex.IsMatch(name, @"^[A-Z][a-zA-Z0-9_]*$");
    }

    protected static bool IsValidKotlinPackageName(string name)
    {
        // Kotlin package names should follow reverse domain notation
        return Regex.IsMatch(name, @"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$");
    }

    protected static bool IsValidCSharpPackageName(string name)
    {
        // C# package names should be PascalCase with dots allowed
        return Regex.IsMatch(name, @"^[A-Z][a-zA-Z0-9]*(\.[A-Z][a-zA-Z0-9]*)*$");
    }

    protected static bool IsValidTypeScriptPackageName(string name)
    {
        // TypeScript/npm package name validation
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

    protected static bool IsValidVersion(string version)
    {
        // Basic semantic version validation
        return Regex.IsMatch(version, @"^\d+\.\d+\.\d+(-[a-zA-Z0-9-]+)?(\+[a-zA-Z0-9-]+)?$");
    }

    protected static bool IsValidPath(string path)
    {
        try
        {
            Path.GetFullPath(path);
            return true;
        }
        catch
        {
            return false;
        }
    }
}