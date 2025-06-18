using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Running;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;
using System.Collections.Frozen;

namespace AxiomEndpoints.Performance.Tests;

/// <summary>
/// Performance benchmarks for routing operations
/// </summary>
[MemoryDiagnoser]
[SimpleJob]
public class RoutingBenchmarks
{
    private RouteEndpoint[] _endpoints = [];
    private FastRouteMatcher _matcher = null!;
    private readonly string[] _testUrls = 
    [
        "/user/123e4567-e89b-12d3-a456-426614174000",
        "/user/test@example.com", 
        "/order/123e4567-e89b-12d3-a456-426614174000/42",
        "/product/12345",
        "/category/electronics",
        "/api/v1/users",
        "/api/v2/users",
        "/search?query=test&page=1"
    ];

    [GlobalSetup]
    public void Setup()
    {
        _endpoints = CreateTestEndpoints();
        _matcher = new FastRouteMatcher(_endpoints);
    }

    [Benchmark]
    public object? SingleRouteMatch()
    {
        return _matcher.Match("/user/123e4567-e89b-12d3-a456-426614174000");
    }

    [Benchmark]
    public void MultipleRouteMatches()
    {
        foreach (var url in _testUrls)
        {
            _matcher.Match(url);
        }
    }

    [Benchmark]
    public bool TryMatchGeneric()
    {
        return RouteMatcher.TryMatch<UserById>("/user/123e4567-e89b-12d3-a456-426614174000", out _);
    }

    [Benchmark]
    public string GenerateRouteTemplate()
    {
        return RouteTemplateGenerator.Generate<UserById>();
    }

    [Benchmark]
    public string GenerateRouteUrl()
    {
        var route = new UserById(Guid.Parse("123e4567-e89b-12d3-a456-426614174000"));
        return RouteUrlGenerator.GenerateUrl(route);
    }

    [Benchmark]
    public void RouteConstraintValidation()
    {
        var guidConstraint = new TypeConstraint<Guid>();
        var rangeConstraint = new RangeConstraint<int> { Min = 1, Max = 100 };
        var lengthConstraint = new LengthConstraint { MinLength = 2, MaxLength = 50 };
        
        guidConstraint.IsValid("123e4567-e89b-12d3-a456-426614174000");
        rangeConstraint.IsValid("50");
        lengthConstraint.IsValid("test");
    }

    [Benchmark]
    public void CachedRouteMatching()
    {
        // Test cached performance by repeating same URLs
        for (int i = 0; i < 100; i++)
        {
            _matcher.Match("/user/123e4567-e89b-12d3-a456-426614174000");
        }
    }

    [Benchmark]
    public void RouteParameterExtraction()
    {
        var match = _matcher.Match("/user/123e4567-e89b-12d3-a456-426614174000");
        // Simulate parameter extraction without specific type dependencies
        if (match != null)
        {
            _ = match.ToString();
        }
    }

    private static RouteEndpoint[] CreateTestEndpoints()
    {
        return new[]
        {
            new RouteEndpoint(
                "/user/{id:guid}",
                typeof(UserById),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["id"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/user/{email}",
                typeof(UserByName),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/order/{userId:guid}/{id:int}",
                typeof(OrderByUserAndId),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["userId"] = new TypeConstraint<Guid>(),
                    ["id"] = new TypeConstraint<int>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/product/{id:int}",
                typeof(ProductById),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["id"] = new TypeConstraint<int>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/category/{slug}",
                typeof(CategoryBySlug),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };
    }
}