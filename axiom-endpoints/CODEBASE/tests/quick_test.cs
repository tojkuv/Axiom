using System;
using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

// Test route types - copy from test project
internal sealed record SimpleRoute : IRoute<SimpleRoute>
{
    public static FrozenDictionary<string, object> Metadata { get; } = 
        FrozenDictionary<string, object>.Empty;
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

// Test the route generation
var simple = RouteTemplateGenerator.Generate<SimpleRoute>();
Console.WriteLine($"SimpleRoute: {simple}");

var userWithParam = RouteTemplateGenerator.Generate<UsersWithParam.ById>();
Console.WriteLine($"UsersWithParam.ById: {userWithParam} (expected: /userswithparam/{{id}})");

var orders = RouteTemplateGenerator.Generate<Orders.ByUserAndId>();
Console.WriteLine($"Orders.ByUserAndId: {orders} (expected: /orders/{{userid}}/{{id}})");

var userById = RouteTemplateGenerator.Generate<UserById>();
Console.WriteLine($"UserById: {userById} (expected: /user/{{id}})");