using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.CompilerServices;

namespace AxiomEndpoints.Core;

/// <summary>
/// Result type for functional error handling
/// </summary>
public readonly record struct Result<T>
{
    private readonly ResultState _state;
    private readonly T? _value;
    private readonly AxiomError? _error;

    private Result(ResultState state, T? value, AxiomError? error)
    {
        _state = state;
        _value = value;
        _error = error;
    }

    public bool IsSuccess => _state == ResultState.Success;
    public bool IsFailure => _state == ResultState.Failure;

    public T Value => _state == ResultState.Success
        ? _value!
        : throw new InvalidOperationException($"Cannot access value when result is {_state}");

    public AxiomError Error => _state == ResultState.Failure
        ? _error!
        : throw new InvalidOperationException($"Cannot access error when result is {_state}");

    // Pattern matching support
    public TResult Match<TResult>(
        Func<T, TResult> success,
        Func<AxiomError, TResult> failure)
    {
        ArgumentNullException.ThrowIfNull(success);
        ArgumentNullException.ThrowIfNull(failure);
        
        return _state switch
        {
            ResultState.Success => success(_value!),
            ResultState.Failure => failure(_error!),
            _ => throw new UnreachableException()
        };
    }

    // Internal factory methods for use by ResultFactory
    internal static Result<T> CreateSuccess(T value) => new(ResultState.Success, value, null);
    internal static Result<T> CreateFailure(AxiomError error) => new(ResultState.Failure, default, error);

    private enum ResultState : byte
    {
        Success,
        Failure
    }
}

/// <summary>
/// Factory methods for creating Result instances
/// </summary>
public static class ResultFactory
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Result<T> Success<T>(T value) => Result<T>.CreateSuccess(value);

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Result<T> Failure<T>(AxiomError error) => Result<T>.CreateFailure(error);

    public static Result<T> NotFound<T>(string? message = null) =>
        Failure<T>(AxiomError.NotFound(message));
}

/// <summary>
/// Extension methods for Result to provide convenient factory methods
/// </summary>
public static class ResultExtensions
{
    public static Result<T> Success<T>(this T value) => ResultFactory.Success(value);
    
    public static Result<T> ToResult<T>(this T value) => ResultFactory.Success(value);
}

public record AxiomError(string Code, string Message, ErrorType Type = ErrorType.Validation)
{
    public IReadOnlyDictionary<string, object>? Details { get; init; }
    public IReadOnlyDictionary<string, string>? Fields { get; init; }
    public string? CorrelationId { get; init; }

    public static AxiomError NotFound(string? message = null) =>
        new("NOT_FOUND", message ?? "Resource not found", ErrorType.NotFound);

    public static AxiomError Validation(string message) =>
        new("VALIDATION_ERROR", message, ErrorType.Validation);

    public static AxiomError Validation(string message, IReadOnlyDictionary<string, string> fields) =>
        new("VALIDATION_ERROR", message, ErrorType.Validation) { Fields = fields };

    public AxiomError WithDetails(IReadOnlyDictionary<string, object> details) => 
        this with { Details = details };

    public AxiomError WithFields(IReadOnlyDictionary<string, string> fields) => 
        this with { Fields = fields };

    public AxiomError WithCorrelationId(string correlationId) => 
        this with { CorrelationId = correlationId };
}

public enum ErrorType
{
    Validation,
    NotFound,
    Unauthorized,
    Forbidden,
    Conflict,
    TooManyRequests,
    Internal,
    NotImplemented,
    Timeout,
    Unavailable
}