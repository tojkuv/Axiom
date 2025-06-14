using System.Collections.Frozen;
using System.Buffers;
using System.Text.RegularExpressions;
using System.Numerics;

namespace AxiomEndpoints.Core;

/// <summary>
/// Generic constraint for types that implement IParsable
/// </summary>
public record TypeConstraint<T> : IRouteConstraint where T : IParsable<T>
{
    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && T.TryParse(value, null, out _);

    public string ErrorMessage => $"Value must be a valid {typeof(T).Name}";

    public string ConstraintString => typeof(T).Name.ToLowerInvariant() switch
    {
        "guid" => "guid",
        "int32" => "int",
        "int64" => "long",
        "decimal" => "decimal",
        "double" => "double",
        "single" => "float",
        "boolean" => "bool",
        "datetime" => "datetime",
        "datetimeoffset" => "datetimeoffset",
        _ => "string"
    };
}

/// <summary>
/// Range constraint for numeric types
/// </summary>
public record RangeConstraint<T> : IRouteConstraint
    where T : INumber<T>, IParsable<T>
{
    public required T Min { get; init; }
    public required T Max { get; init; }

    public bool IsValid(string? value)
    {
        if (string.IsNullOrEmpty(value) || !T.TryParse(value, null, out var parsed))
            return false;

        return parsed >= Min && parsed <= Max;
    }

    public string ErrorMessage => $"Value must be between {Min} and {Max}";
    public string ConstraintString => $"range({Min},{Max})";
}

/// <summary>
/// Regular expression constraint
/// </summary>
public record RegexConstraint : IRouteConstraint
{
    private readonly Regex _regex;

    public RegexConstraint(string pattern, RegexOptions options = RegexOptions.Compiled)
    {
        _regex = new Regex(pattern, options | RegexOptions.Compiled);
        Pattern = pattern;
    }

    public string Pattern { get; }

    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && _regex.IsMatch(value);

    public string ErrorMessage => $"Value must match pattern: {Pattern}";
    public string ConstraintString => $"regex({Pattern})";
}

/// <summary>
/// Length constraint for strings
/// </summary>
public record LengthConstraint : IRouteConstraint
{
    public int? MinLength { get; init; }
    public int? MaxLength { get; init; }

    public bool IsValid(string? value)
    {
        if (value is null) return MinLength is null or 0;

        return (MinLength is null || value.Length >= MinLength) &&
               (MaxLength is null || value.Length <= MaxLength);
    }

    public string ErrorMessage => (MinLength, MaxLength) switch
    {
        (not null, not null) => $"Length must be between {MinLength} and {MaxLength}",
        (not null, null) => $"Minimum length is {MinLength}",
        (null, not null) => $"Maximum length is {MaxLength}",
        _ => "Invalid length"
    };

    public string ConstraintString => (MinLength, MaxLength) switch
    {
        (not null, not null) => $"length({MinLength},{MaxLength})",
        (not null, null) => $"minlength({MinLength})",
        (null, not null) => $"maxlength({MaxLength})",
        _ => ""
    };
}

/// <summary>
/// Enum constraint
/// </summary>
public record EnumConstraint<TEnum> : IRouteConstraint where TEnum : struct, Enum
{
    private static readonly FrozenSet<string> ValidValues =
        Enum.GetNames<TEnum>().Select(name => name.ToLowerInvariant()).ToFrozenSet();

    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && ValidValues.Contains(value.ToLowerInvariant());

    public string ErrorMessage =>
        $"Value must be one of: {string.Join(", ", ValidValues)}";

    public string ConstraintString =>
        $"enum({string.Join("|", ValidValues)})";
}

/// <summary>
/// Constraint for specific allowed values
/// </summary>
public record AllowedValuesConstraint : IRouteConstraint
{
    private readonly SearchValues<string> _allowedValues;

    public AllowedValuesConstraint(params string[] values)
    {
        AllowedValues = values.Select(v => v.ToLowerInvariant()).ToFrozenSet();
        _allowedValues = SearchValues.Create(AllowedValues.ToArray(), StringComparison.OrdinalIgnoreCase);
    }

    public FrozenSet<string> AllowedValues { get; }

    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && _allowedValues.Contains(value.ToLowerInvariant());

    public string ErrorMessage =>
        $"Value must be one of: {string.Join(", ", AllowedValues)}";

    public string ConstraintString =>
        $"values({string.Join("|", AllowedValues)})";
}

/// <summary>
/// Required constraint - ensures value is not null or empty
/// </summary>
public record RequiredConstraint : IRouteConstraint
{
    public bool IsValid(string? value) => 
        !string.IsNullOrWhiteSpace(value);

    public string ErrorMessage => "Value is required";
    public string ConstraintString => "required";
}

/// <summary>
/// Alpha constraint - allows only letters
/// </summary>
public record AlphaConstraint : IRouteConstraint
{
    private static readonly Regex AlphaRegex = new(@"^[a-zA-Z]+$", RegexOptions.Compiled);

    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && AlphaRegex.IsMatch(value);

    public string ErrorMessage => "Value must contain only letters";
    public string ConstraintString => "alpha";
}

/// <summary>
/// Alphanumeric constraint - allows letters and numbers
/// </summary>
public record AlphanumericConstraint : IRouteConstraint
{
    private static readonly Regex AlphanumericRegex = new(@"^[a-zA-Z0-9]+$", RegexOptions.Compiled);

    public bool IsValid(string? value) =>
        !string.IsNullOrEmpty(value) && AlphanumericRegex.IsMatch(value);

    public string ErrorMessage => "Value must contain only letters and numbers";
    public string ConstraintString => "alphanumeric";
}