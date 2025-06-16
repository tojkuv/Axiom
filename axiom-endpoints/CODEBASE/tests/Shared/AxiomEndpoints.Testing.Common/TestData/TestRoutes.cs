using AxiomEndpoints.Core;

#pragma warning disable CA1812 // Avoid uninstantiated internal classes - test route types used in reflection

namespace AxiomEndpoints.Testing.Common.TestData;

public sealed record SimpleRoute : IRoute<SimpleRoute>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public static class Users
{
    public sealed record ById : IRoute<ById>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record ByEmail(string Email) : IRoute<ByEmail>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record Create : IRoute<Create>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record Update(Guid Id) : IRoute<Update>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record Delete(Guid Id) : IRoute<Delete>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

public static class UsersWithParam
{
    public sealed record ById(Guid Id) : IRoute<ById>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

public static class Orders
{
    public sealed record ByUserAndId(Guid UserId, int Id) : IRoute<ByUserAndId>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record ByStatus(string Status) : IRoute<ByStatus>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record Create : IRoute<Create>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}

public sealed record UserById(Guid Id) : IRoute<UserById>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public sealed record UserByName(string Name) : IRoute<UserByName>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public sealed record OrderByUserAndId(Guid UserId, int Id) : IRoute<OrderByUserAndId>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public sealed record ProductById(int Id) : IRoute<ProductById>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public sealed record CategoryBySlug(string Slug) : IRoute<CategoryBySlug>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
}

public static class Complex
{
    public sealed record NestedRoute(Guid UserId, int OrderId, string ItemCode) : IRoute<NestedRoute>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }

    public sealed record WithOptionals(int Id, string? Category = null, bool? Active = null) : IRoute<WithOptionals>
    {
        public static FrozenDictionary<string, object> Metadata { get; } = 
            FrozenDictionary<string, object>.Empty;
    }
}