using System.Reflection;

namespace AxiomEndpoints.Aspire.PackageGeneration.Hooks;

/// <summary>
/// Interface for generation workflow hooks
/// </summary>
public interface IGenerationHook
{
    /// <summary>
    /// Hook name for identification and ordering
    /// </summary>
    string Name { get; }

    /// <summary>
    /// Execution priority (lower numbers execute first)
    /// </summary>
    int Priority { get; }

    /// <summary>
    /// Which generation phases this hook should run during
    /// </summary>
    GenerationPhase SupportedPhases { get; }
}

/// <summary>
/// Hook that executes before generation starts
/// </summary>
public interface IPreGenerationHook : IGenerationHook
{
    /// <summary>
    /// Execute before generation begins
    /// </summary>
    Task<HookResult> ExecuteAsync(
        PreGenerationContext context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Hook that executes after configuration validation
/// </summary>
public interface IPostValidationHook : IGenerationHook
{
    /// <summary>
    /// Execute after configuration validation
    /// </summary>
    Task<HookResult> ExecuteAsync(
        PostValidationContext context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Hook that executes before code generation for each language
/// </summary>
public interface IPreLanguageGenerationHook : IGenerationHook
{
    /// <summary>
    /// Execute before generating code for a specific language
    /// </summary>
    Task<HookResult> ExecuteAsync(
        PreLanguageGenerationContext context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Hook that executes after code generation for each language
/// </summary>
public interface IPostLanguageGenerationHook : IGenerationHook
{
    /// <summary>
    /// Execute after generating code for a specific language
    /// </summary>
    Task<HookResult> ExecuteAsync(
        PostLanguageGenerationContext context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Hook that executes after all generation is complete
/// </summary>
public interface IPostGenerationHook : IGenerationHook
{
    /// <summary>
    /// Execute after all generation is complete
    /// </summary>
    Task<HookResult> ExecuteAsync(
        PostGenerationContext context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Generation phases
/// </summary>
[Flags]
public enum GenerationPhase
{
    PreGeneration = 1,
    PostValidation = 2,
    PreLanguageGeneration = 4,
    PostLanguageGeneration = 8,
    PostGeneration = 16,
    All = PreGeneration | PostValidation | PreLanguageGeneration | PostLanguageGeneration | PostGeneration
}

/// <summary>
/// Result of hook execution
/// </summary>
public class HookResult
{
    public bool Success { get; set; } = true;
    public string? Error { get; set; }
    public List<string> Messages { get; set; } = new();
    public bool ContinueGeneration { get; set; } = true;
    public Dictionary<string, object> Data { get; set; } = new();

    public static HookResult Successful(string? message = null)
    {
        var result = new HookResult();
        if (!string.IsNullOrEmpty(message))
            result.Messages.Add(message);
        return result;
    }

    public static HookResult Failed(string error, bool continueGeneration = false)
    {
        return new HookResult
        {
            Success = false,
            Error = error,
            ContinueGeneration = continueGeneration
        };
    }

    public static HookResult Warning(string message)
    {
        return new HookResult
        {
            Success = true,
            Messages = { message }
        };
    }
}

/// <summary>
/// Base context for all hooks
/// </summary>
public abstract class HookContext
{
    protected HookContext(PackageGenerationOptions options)
    {
        Options = options;
        Timestamp = DateTime.UtcNow;
        CorrelationId = Guid.NewGuid();
    }

    public PackageGenerationOptions Options { get; }
    public DateTime Timestamp { get; }
    public Guid CorrelationId { get; }
    public Dictionary<string, object> SharedData { get; set; } = new();
}

/// <summary>
/// Context for pre-generation hooks
/// </summary>
public class PreGenerationContext : HookContext
{
    public PreGenerationContext(Assembly assembly, PackageGenerationOptions options) : base(options)
    {
        Assembly = assembly;
    }

    public Assembly Assembly { get; }
}

/// <summary>
/// Context for post-validation hooks
/// </summary>
public class PostValidationContext : HookContext
{
    public PostValidationContext(Assembly assembly, PackageGenerationOptions options, Validation.ValidationResult validationResult) 
        : base(options)
    {
        Assembly = assembly;
        ValidationResult = validationResult;
    }

    public Assembly Assembly { get; }
    public Validation.ValidationResult ValidationResult { get; }
}

/// <summary>
/// Context for language-specific generation hooks
/// </summary>
public class PreLanguageGenerationContext : HookContext
{
    public PreLanguageGenerationContext(
        Assembly assembly, 
        PackageGenerationOptions options, 
        PackageLanguage language, 
        LanguagePackageConfig languageConfig) : base(options)
    {
        Assembly = assembly;
        Language = language;
        LanguageConfig = languageConfig;
    }

    public Assembly Assembly { get; }
    public PackageLanguage Language { get; }
    public LanguagePackageConfig LanguageConfig { get; }
}

/// <summary>
/// Context for post language generation hooks
/// </summary>
public class PostLanguageGenerationContext : HookContext
{
    public PostLanguageGenerationContext(
        Assembly assembly,
        PackageGenerationOptions options,
        PackageLanguage language,
        LanguagePackageConfig languageConfig,
        CodeGeneration.CodeGenerationResult generationResult) : base(options)
    {
        Assembly = assembly;
        Language = language;
        LanguageConfig = languageConfig;
        GenerationResult = generationResult;
    }

    public Assembly Assembly { get; }
    public PackageLanguage Language { get; }
    public LanguagePackageConfig LanguageConfig { get; }
    public CodeGeneration.CodeGenerationResult GenerationResult { get; }
}

/// <summary>
/// Context for post-generation hooks
/// </summary>
public class PostGenerationContext : HookContext
{
    public PostGenerationContext(
        Assembly assembly,
        PackageGenerationOptions options,
        PackageGenerationResult finalResult) : base(options)
    {
        Assembly = assembly;
        FinalResult = finalResult;
    }

    public Assembly Assembly { get; }
    public PackageGenerationResult FinalResult { get; }
}