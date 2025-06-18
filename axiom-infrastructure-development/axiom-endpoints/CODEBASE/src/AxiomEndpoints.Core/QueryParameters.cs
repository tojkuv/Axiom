using System;
using System.Collections.Frozen;
using System.Numerics;
using System.Reflection;

namespace AxiomEndpoints.Core;

/// <summary>
/// Base record for query parameters with metadata
/// </summary>
public abstract record QueryParameters
{
    public virtual QueryParameterMetadata GetMetadata() => throw new NotImplementedException();
}

/// <summary>
/// Attributes for query parameter configuration
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public class QueryParamAttribute : Attribute
{
    public string? Name { get; set; }
    public bool Required { get; set; }
    public string? Description { get; set; }
}

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public class QueryConstraintAttribute : Attribute
{
    public IRouteConstraint Constraint { get; }

    protected QueryConstraintAttribute(IRouteConstraint constraint)
    {
        Constraint = constraint;
    }
}

public class RangeAttribute<T> : QueryConstraintAttribute
    where T : INumber<T>, IParsable<T>
{
    public RangeAttribute(T min, T max)
        : base(new RangeConstraint<T> { Min = min, Max = max })
    {
    }
}

public class RegexAttribute : QueryConstraintAttribute
{
    public RegexAttribute(string pattern)
        : base(new RegexConstraint(pattern))
    {
    }
}

public class LengthAttribute : QueryConstraintAttribute
{
    public LengthAttribute(int minLength = 0, int maxLength = int.MaxValue)
        : base(new LengthConstraint { MinLength = minLength == 0 ? null : minLength, MaxLength = maxLength == int.MaxValue ? null : maxLength })
    {
    }
}

public class EnumAttribute<TEnum> : QueryConstraintAttribute
    where TEnum : struct, Enum
{
    public EnumAttribute()
        : base(new EnumConstraint<TEnum>())
    {
    }
}

public class AllowedValuesAttribute : QueryConstraintAttribute
{
    public AllowedValuesAttribute(params string[] values)
        : base(new AllowedValuesConstraint(values))
    {
    }
}

public class RequiredAttribute : QueryConstraintAttribute
{
    public RequiredAttribute()
        : base(new RequiredConstraint())
    {
    }
}

/// <summary>
/// Convenience attributes for route constraints
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public class RouteConstraintAttribute<T> : Attribute where T : IParsable<T>
{
    public IRouteConstraint Constraint { get; } = new TypeConstraint<T>();
}

/// <summary>
/// Utility class for generating query parameter metadata
/// </summary>
public static class QueryParameterMetadataGenerator
{
    public static QueryParameterMetadata Generate<T>() where T : IQueryParameters
    {
        var type = typeof(T);
        var properties = type.GetProperties();
        var parameters = new Dictionary<string, QueryParameterInfo>();
        var requiredParams = new HashSet<string>();

        foreach (var property in properties)
        {
            var queryParamAttr = property.GetCustomAttribute<QueryParamAttribute>();
            var constraintAttr = property.GetCustomAttribute<QueryConstraintAttribute>();
            var requiredAttr = property.GetCustomAttribute<RequiredAttribute>();

            var paramName = queryParamAttr?.Name ?? property.Name.ToLowerInvariant();
            var isRequired = queryParamAttr?.Required ?? requiredAttr != null;
            var description = queryParamAttr?.Description;

            if (isRequired)
            {
                requiredParams.Add(paramName);
            }

            parameters[paramName] = new QueryParameterInfo
            {
                Name = paramName,
                Type = property.PropertyType,
                IsRequired = isRequired,
                DefaultValue = GetPropertyDefaultValue(property),
                Constraint = constraintAttr?.Constraint,
                Description = description
            };
        }

        return new QueryParameterMetadata
        {
            Parameters = parameters.ToFrozenDictionary(),
            RequiredParameters = requiredParams.ToFrozenSet()
        };
    }

    private static object? GetPropertyDefaultValue(PropertyInfo property)
    {
        // For record properties with default values, we need to create an instance
        // and get the actual property value to determine the real default
        try
        {
            var declaringType = property.DeclaringType;
            if (declaringType != null)
            {
                // Create an instance using the parameterless constructor (if available)
                var constructor = declaringType.GetConstructor(Type.EmptyTypes);
                if (constructor != null)
                {
                    var instance = Activator.CreateInstance(declaringType);
                    return property.GetValue(instance);
                }
                
                // For record types, try to create using default constructor
                try
                {
                    var instance = Activator.CreateInstance(declaringType);
                    return property.GetValue(instance);
                }
                catch
                {
                    // If we can't create an instance, fall back to type default
                }
            }
        }
        catch
        {
            // If reflection fails, fall back to type default
        }
        
        // Fallback to .NET type default
        if (property.PropertyType.IsValueType)
        {
            return Activator.CreateInstance(property.PropertyType);
        }

        return null;
    }
}