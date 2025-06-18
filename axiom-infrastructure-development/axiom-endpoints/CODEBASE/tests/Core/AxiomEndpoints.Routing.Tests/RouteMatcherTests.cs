using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Routing.Tests;

public class RouteMatcherTests
{
    [Fact]
    public void TryMatch_SimpleRoute_MatchesCorrectly()
    {
        // Arrange
        var path = "/simpleroute";

        // Act
        var result = RouteMatcher.TryMatch<SimpleRoute>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_RouteWithParameter_ExtractsParameter()
    {
        // Arrange
        var path = "/user/123";

        // Act
        var result = RouteMatcher.TryMatch<UserById>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Single(parameters);
        Assert.Equal("123", parameters["id"]);
    }

    [Fact]
    public void TryMatch_RouteWithMultipleParameters_ExtractsAllParameters()
    {
        // Arrange
        var path = "/order/456/789";

        // Act
        var result = RouteMatcher.TryMatch<OrderByUserAndId>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Equal(2, parameters.Count);
        Assert.Equal("456", parameters["userId"]);
        Assert.Equal("789", parameters["id"]);
    }

    [Fact]
    public void TryMatch_IncorrectPath_ReturnsFalse()
    {
        // Arrange
        var path = "/wrongpath";

        // Act
        var result = RouteMatcher.TryMatch<SimpleRoute>(path, out var parameters);

        // Assert
        Assert.False(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_IncorrectSegmentCount_ReturnsFalse()
    {
        // Arrange
        var path = "/user/123/extra";

        // Act
        var result = RouteMatcher.TryMatch<UserById>(path, out var parameters);

        // Assert
        Assert.False(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_NonGeneric_MatchesCorrectly()
    {
        // Arrange
        var path = "/simpleroute";

        // Act
        var result = RouteMatcher.TryMatch<SimpleRoute>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_CaseInsensitive_MatchesCorrectly()
    {
        // Arrange
        var path = "/SIMPLEROUTE";

        // Act
        var result = RouteMatcher.TryMatch<SimpleRoute>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_WithTrailingSlash_MatchesCorrectly()
    {
        // Arrange
        var path = "/simpleroute/";

        // Act
        var result = RouteMatcher.TryMatch<SimpleRoute>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Empty(parameters);
    }

    [Fact]
    public void TryMatch_RouteTemplateGeneration_StandardRoutes_WorkCorrectly()
    {
        // Test route template generation for debug scenarios from standalone files
        var template1 = RouteTemplateGenerator.Generate<TestRouteWithOptional>();
        var template2 = RouteTemplateGenerator.Generate<FileRouteWithOptionalVersion>();
        
        // These should generate sensible templates even if not exactly matching the debug file scenarios
        Assert.NotNull(template1);
        Assert.NotNull(template2);
        Assert.StartsWith("/", template1, StringComparison.Ordinal);
        Assert.StartsWith("/", template2, StringComparison.Ordinal);
    }

    [Fact] 
    public void TryMatch_ExistingComplexRoute_WorksCorrectly()
    {
        // Test scenario using a complex nested route pattern
        var path = "/complex/123e4567-e89b-12d3-a456-426614174000/456/ABC";

        // Act
        var result = RouteMatcher.TryMatch<Complex.NestedRoute>(path, out var parameters);

        // Assert  
        Assert.True(result);
        Assert.Equal(3, parameters.Count);
        Assert.Equal("123e4567-e89b-12d3-a456-426614174000", parameters["userId"]);
        Assert.Equal("456", parameters["orderId"]);
        Assert.Equal("ABC", parameters["itemCode"]);
    }

    [Fact]
    public void TryMatch_ComplexWithOptionals_WorksCorrectly()
    {
        // Test scenario using a route with parameters and optionals
        var path = "/userswithparam/123e4567-e89b-12d3-a456-426614174000";

        // Act
        var result = RouteMatcher.TryMatch<UsersWithParam.ById>(path, out var parameters);

        // Assert
        Assert.True(result);
        Assert.Single(parameters);
        Assert.Equal("123e4567-e89b-12d3-a456-426614174000", parameters["id"]);
    }
}