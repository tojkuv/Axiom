using AxiomEndpoints.Core;

#pragma warning disable CA1812 // Avoid uninstantiated internal classes - test route types used in reflection

namespace AxiomEndpoints.Tests;

// Test route types for unit tests
internal sealed record SimpleRoute : IRoute<SimpleRoute>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

internal static class Users
{
    internal sealed record ById : IRoute<ById>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

internal static class UsersWithParam
{
    internal sealed record ById(Guid Id) : IRoute<ById>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

internal static class Orders
{
    internal sealed record ByUserAndId(Guid UserId, int Id) : IRoute<ByUserAndId>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

internal sealed record UserById(Guid Id) : IRoute<UserById>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

internal sealed record UserByName(string Name) : IRoute<UserByName>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

internal sealed record OrderByUserAndId(Guid UserId, int Id) : IRoute<OrderByUserAndId>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}