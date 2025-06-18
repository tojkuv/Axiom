using System.ComponentModel.DataAnnotations;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace AxiomEndpoints.Core.Middleware;

/// <summary>
/// Automatic request validation
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class ValidateAttribute : EndpointFilterAttribute
{
    public bool ThrowOnFailure { get; set; } = false;

    public override int Order => -800; // Run after auth and rate limiting

    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        var requestType = context.Request.GetType();
        var validator = context.Context.HttpContext.RequestServices
            .GetService(typeof(IValidator<>).MakeGenericType(requestType)) as IValidator;

        if (validator == null)
        {
            // Fallback to data annotations validation
            return ValidateWithDataAnnotations(context);
        }

        var validationContext = new ValidationContext<object>(context.Request);
        var validationResult = await validator.ValidateAsync(
            validationContext,
            context.Context.CancellationToken);

        if (!validationResult.IsValid)
        {
            var errors = validationResult.Errors
                .GroupBy(e => e.PropertyName)
                .Select(g => new ValidationFieldError(
                    g.Key,
                    g.Select(e => e.ErrorMessage).ToArray()))
                .ToList();

            return ResultFactory.Failure<Unit>(new ValidationError(
                "VALIDATION_FAILED",
                "One or more validation errors occurred",
                errors));
        }

        return ResultFactory.Success(Unit.Value);
    }

    private Result<Unit> ValidateWithDataAnnotations(EndpointFilterContext context)
    {
        var validationResults = new List<System.ComponentModel.DataAnnotations.ValidationResult>();
        var validationContext = new System.ComponentModel.DataAnnotations.ValidationContext(context.Request);
        
        bool isValid = Validator.TryValidateObject(
            context.Request, 
            validationContext, 
            validationResults, 
            validateAllProperties: true);

        if (!isValid)
        {
            var errors = validationResults
                .GroupBy(r => r.MemberNames.FirstOrDefault() ?? "")
                .Select(g => new ValidationFieldError(
                    g.Key,
                    g.Select(r => r.ErrorMessage ?? "Validation failed").ToArray()))
                .ToList();

            return ResultFactory.Failure<Unit>(new ValidationError(
                "VALIDATION_FAILED",
                "One or more validation errors occurred",
                errors));
        }

        return ResultFactory.Success(Unit.Value);
    }
}

/// <summary>
/// Custom validation rule
/// </summary>
public abstract class ValidationRule<TRequest> : EndpointFilterAttribute
{
    public override async ValueTask<Result<Unit>> OnExecutingAsync(EndpointFilterContext context)
    {
        if (context.Request is not TRequest request)
        {
            return ResultFactory.Success(Unit.Value);
        }

        var errors = await ValidateAsync(request, context.Context);

        if (errors.Any())
        {
            return ResultFactory.Failure<Unit>(new ValidationError(
                "VALIDATION_FAILED",
                "Validation failed",
                errors));
        }

        return ResultFactory.Success(Unit.Value);
    }

    protected abstract ValueTask<IReadOnlyList<ValidationFieldError>> ValidateAsync(
        TRequest request,
        IContext context);
}

/// <summary>
/// Validation error types
/// </summary>
public record ValidationError : AxiomError
{
    public IReadOnlyList<ValidationFieldError> ValidationFields { get; }

    public ValidationError(string code, string message, IReadOnlyList<ValidationFieldError> fields)
        : base(code, message, ErrorType.Validation)
    {
        ValidationFields = fields;
    }
}

public record ValidationFieldError(string Name, string[] Errors);

/// <summary>
/// Simple validation result
/// </summary>
public class ValidationResult
{
    public bool IsValid => !Errors.Any();
    public List<ValidationError> Errors { get; } = new();

    public void AddError(string propertyName, string errorMessage)
    {
        Errors.Add(new ValidationError(propertyName, errorMessage));
    }

    public record ValidationError(string PropertyName, string ErrorMessage);
}

/// <summary>
/// Validation context
/// </summary>
public class ValidationContext<T>
{
    public T Instance { get; }
    public Dictionary<string, object> Properties { get; } = new();

    public ValidationContext(T instance)
    {
        Instance = instance;
    }
}

/// <summary>
/// Validator interface
/// </summary>
public interface IValidator
{
    ValueTask<ValidationResult> ValidateAsync(
        ValidationContext<object> context,
        CancellationToken cancellationToken = default);
}

public interface IValidator<T> : IValidator
{
    ValueTask<ValidationResult> ValidateAsync(
        ValidationContext<T> context,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Simple validator base class
/// </summary>
public abstract class AbstractValidator<T> : IValidator<T>
{
    public virtual ValueTask<ValidationResult> ValidateAsync(
        ValidationContext<T> context,
        CancellationToken cancellationToken = default)
    {
        var result = new ValidationResult();
        
        // Override this method in derived classes to implement validation logic
        ValidateInstance(context.Instance, result);

        return ValueTask.FromResult(result);
    }

    protected abstract void ValidateInstance(T instance, ValidationResult result);

    async ValueTask<ValidationResult> IValidator.ValidateAsync(
        ValidationContext<object> context,
        CancellationToken cancellationToken)
    {
        if (context.Instance is T typedInstance)
        {
            return await ValidateAsync(new ValidationContext<T>(typedInstance), cancellationToken);
        }

        var result = new ValidationResult();
        result.AddError("", $"Expected type {typeof(T).Name} but got {context.Instance?.GetType().Name ?? "null"}");
        return result;
    }
}

