namespace AxiomEndpoints.Aspire.PackageGeneration.Validation;

/// <summary>
/// Result of configuration validation
/// </summary>
public class ValidationResult
{
    public bool IsValid => !Errors.Any();
    public List<ValidationError> Errors { get; set; } = new();
    public List<ValidationWarning> Warnings { get; set; } = new();
    public List<ValidationSuggestion> Suggestions { get; set; } = new();

    public void AddError(string code, string message, string? path = null, string? fix = null)
    {
        Errors.Add(new ValidationError(code, message, path, fix));
    }

    public void AddWarning(string code, string message, string? path = null, string? suggestion = null)
    {
        Warnings.Add(new ValidationWarning(code, message, path, suggestion));
    }

    public void AddSuggestion(string code, string message, string? path = null, string? improvement = null)
    {
        Suggestions.Add(new ValidationSuggestion(code, message, path, improvement));
    }

    public ValidationResult Merge(ValidationResult other)
    {
        var merged = new ValidationResult();
        merged.Errors.AddRange(Errors);
        merged.Errors.AddRange(other.Errors);
        merged.Warnings.AddRange(Warnings);
        merged.Warnings.AddRange(other.Warnings);
        merged.Suggestions.AddRange(Suggestions);
        merged.Suggestions.AddRange(other.Suggestions);
        return merged;
    }
}

/// <summary>
/// Base validation issue
/// </summary>
public abstract class ValidationIssue
{
    protected ValidationIssue(string code, string message, string? path = null)
    {
        Code = code;
        Message = message;
        Path = path;
        Timestamp = DateTime.UtcNow;
    }

    public string Code { get; }
    public string Message { get; }
    public string? Path { get; }
    public DateTime Timestamp { get; }
}

/// <summary>
/// Validation error - blocks generation
/// </summary>
public class ValidationError : ValidationIssue
{
    public ValidationError(string code, string message, string? path = null, string? suggestedFix = null)
        : base(code, message, path)
    {
        SuggestedFix = suggestedFix;
    }

    public string? SuggestedFix { get; }
}

/// <summary>
/// Validation warning - allows generation but may cause issues
/// </summary>
public class ValidationWarning : ValidationIssue
{
    public ValidationWarning(string code, string message, string? path = null, string? suggestion = null)
        : base(code, message, path)
    {
        Suggestion = suggestion;
    }

    public string? Suggestion { get; }
}

/// <summary>
/// Validation suggestion - optimization or best practice recommendation
/// </summary>
public class ValidationSuggestion : ValidationIssue
{
    public ValidationSuggestion(string code, string message, string? path = null, string? improvement = null)
        : base(code, message, path)
    {
        Improvement = improvement;
    }

    public string? Improvement { get; }
}

/// <summary>
/// Validation severity levels
/// </summary>
public enum ValidationSeverity
{
    Error,
    Warning,
    Suggestion,
    Info
}