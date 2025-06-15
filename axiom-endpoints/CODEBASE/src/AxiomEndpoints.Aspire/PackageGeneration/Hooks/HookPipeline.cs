using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Aspire.PackageGeneration.Hooks;

/// <summary>
/// Pipeline for executing generation hooks
/// </summary>
public interface IHookPipeline
{
    /// <summary>
    /// Register a hook
    /// </summary>
    IHookPipeline RegisterHook(IGenerationHook hook);

    /// <summary>
    /// Execute pre-generation hooks
    /// </summary>
    Task<HookExecutionResult> ExecutePreGenerationAsync(PreGenerationContext context, CancellationToken cancellationToken = default);

    /// <summary>
    /// Execute post-validation hooks
    /// </summary>
    Task<HookExecutionResult> ExecutePostValidationAsync(PostValidationContext context, CancellationToken cancellationToken = default);

    /// <summary>
    /// Execute pre-language generation hooks
    /// </summary>
    Task<HookExecutionResult> ExecutePreLanguageGenerationAsync(PreLanguageGenerationContext context, CancellationToken cancellationToken = default);

    /// <summary>
    /// Execute post-language generation hooks
    /// </summary>
    Task<HookExecutionResult> ExecutePostLanguageGenerationAsync(PostLanguageGenerationContext context, CancellationToken cancellationToken = default);

    /// <summary>
    /// Execute post-generation hooks
    /// </summary>
    Task<HookExecutionResult> ExecutePostGenerationAsync(PostGenerationContext context, CancellationToken cancellationToken = default);
}

/// <summary>
/// Default hook pipeline implementation
/// </summary>
public class HookPipeline : IHookPipeline
{
    private readonly List<IGenerationHook> _hooks = new();
    private readonly ILogger<HookPipeline> _logger;

    public HookPipeline(ILogger<HookPipeline> logger)
    {
        _logger = logger;
    }

    public IHookPipeline RegisterHook(IGenerationHook hook)
    {
        _hooks.Add(hook);
        _logger.LogDebug("Registered hook: {HookName} for phases: {Phases}", hook.Name, hook.SupportedPhases);
        return this;
    }

    public async Task<HookExecutionResult> ExecutePreGenerationAsync(PreGenerationContext context, CancellationToken cancellationToken = default)
    {
        var hooks = GetHooksForPhase<IPreGenerationHook>(GenerationPhase.PreGeneration);
        var result = new HookExecutionResult();

        foreach (var hook in hooks)
        {
            var hookResult = await ExecuteHookSafelyAsync(
                () => hook.ExecuteAsync(context, cancellationToken),
                hook.Name,
                cancellationToken);

            result.AddResult(hook.Name, hookResult);
            
            if (!hookResult.ContinueGeneration)
            {
                _logger.LogWarning("Hook {HookName} requested to stop generation", hook.Name);
                result.ShouldContinue = false;
                break;
            }
        }

        return result;
    }

    public async Task<HookExecutionResult> ExecutePostValidationAsync(PostValidationContext context, CancellationToken cancellationToken = default)
    {
        var hooks = GetHooksForPhase<IPostValidationHook>(GenerationPhase.PostValidation);
        var result = new HookExecutionResult();

        foreach (var hook in hooks)
        {
            var hookResult = await ExecuteHookSafelyAsync(
                () => hook.ExecuteAsync(context, cancellationToken),
                hook.Name,
                cancellationToken);

            result.AddResult(hook.Name, hookResult);
            
            if (!hookResult.ContinueGeneration)
            {
                result.ShouldContinue = false;
                break;
            }
        }

        return result;
    }

    public async Task<HookExecutionResult> ExecutePreLanguageGenerationAsync(PreLanguageGenerationContext context, CancellationToken cancellationToken = default)
    {
        var hooks = GetHooksForPhase<IPreLanguageGenerationHook>(GenerationPhase.PreLanguageGeneration);
        var result = new HookExecutionResult();

        foreach (var hook in hooks)
        {
            var hookResult = await ExecuteHookSafelyAsync(
                () => hook.ExecuteAsync(context, cancellationToken),
                hook.Name,
                cancellationToken);

            result.AddResult(hook.Name, hookResult);
            
            if (!hookResult.ContinueGeneration)
            {
                result.ShouldContinue = false;
                break;
            }
        }

        return result;
    }

    public async Task<HookExecutionResult> ExecutePostLanguageGenerationAsync(PostLanguageGenerationContext context, CancellationToken cancellationToken = default)
    {
        var hooks = GetHooksForPhase<IPostLanguageGenerationHook>(GenerationPhase.PostLanguageGeneration);
        var result = new HookExecutionResult();

        foreach (var hook in hooks)
        {
            var hookResult = await ExecuteHookSafelyAsync(
                () => hook.ExecuteAsync(context, cancellationToken),
                hook.Name,
                cancellationToken);

            result.AddResult(hook.Name, hookResult);
            
            if (!hookResult.ContinueGeneration)
            {
                result.ShouldContinue = false;
                break;
            }
        }

        return result;
    }

    public async Task<HookExecutionResult> ExecutePostGenerationAsync(PostGenerationContext context, CancellationToken cancellationToken = default)
    {
        var hooks = GetHooksForPhase<IPostGenerationHook>(GenerationPhase.PostGeneration);
        var result = new HookExecutionResult();

        foreach (var hook in hooks)
        {
            var hookResult = await ExecuteHookSafelyAsync(
                () => hook.ExecuteAsync(context, cancellationToken),
                hook.Name,
                cancellationToken);

            result.AddResult(hook.Name, hookResult);
            
            if (!hookResult.ContinueGeneration)
            {
                result.ShouldContinue = false;
                break;
            }
        }

        return result;
    }

    private List<T> GetHooksForPhase<T>(GenerationPhase phase) where T : class, IGenerationHook
    {
        return _hooks
            .Where(h => h.SupportedPhases.HasFlag(phase))
            .OfType<T>()
            .OrderBy(h => h.Priority)
            .ToList();
    }

    private async Task<HookResult> ExecuteHookSafelyAsync(
        Func<Task<HookResult>> hookExecution,
        string hookName,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogDebug("Executing hook: {HookName}", hookName);
            var result = await hookExecution();
            
            if (result.Success)
            {
                _logger.LogDebug("Hook {HookName} completed successfully", hookName);
                foreach (var message in result.Messages)
                {
                    _logger.LogInformation("Hook {HookName}: {Message}", hookName, message);
                }
            }
            else
            {
                _logger.LogWarning("Hook {HookName} failed: {Error}", hookName, result.Error);
            }

            return result;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            _logger.LogInformation("Hook {HookName} was cancelled", hookName);
            return HookResult.Failed("Hook execution was cancelled", false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Hook {HookName} threw an exception", hookName);
            return HookResult.Failed($"Hook threw exception: {ex.Message}", true);
        }
    }
}

/// <summary>
/// Result of executing multiple hooks
/// </summary>
public class HookExecutionResult
{
    public bool ShouldContinue { get; set; } = true;
    public Dictionary<string, HookResult> HookResults { get; set; } = new();
    public List<string> AllMessages { get; set; } = new();
    public List<string> Errors { get; set; } = new();

    public void AddResult(string hookName, HookResult result)
    {
        HookResults[hookName] = result;
        AllMessages.AddRange(result.Messages);
        
        if (!result.Success && !string.IsNullOrEmpty(result.Error))
        {
            Errors.Add($"[{hookName}] {result.Error}");
        }
    }

    public bool HasErrors => Errors.Any();
    public bool AllSucceeded => HookResults.Values.All(r => r.Success);
}