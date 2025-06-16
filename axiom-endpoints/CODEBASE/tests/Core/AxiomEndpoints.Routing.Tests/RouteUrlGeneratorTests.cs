using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Routing.Tests;

public class RouteUrlGeneratorTests
{
    [Fact]
    public void GenerateUrl_SimpleRoute_ReturnsCorrectUrl()
    {
        // Arrange
        var route = new SimpleRoute();

        // Act
        var url = RouteUrlGenerator.GenerateUrl(route);

        // Assert
        Assert.Equal("/simpleroute", url);
    }

    [Fact]
    public void GenerateUrl_RouteWithParameter_ReturnsUrlWithValue()
    {
        // Arrange
        var route = new UserById(Guid.Parse("12345678-1234-5678-9abc-123456789012"));

        // Act
        var url = RouteUrlGenerator.GenerateUrl(route);

        // Assert
        Assert.Equal("/user/12345678-1234-5678-9abc-123456789012", url);
    }

    [Fact]
    public void GenerateUrl_RouteWithMultipleParameters_ReturnsUrlWithAllValues()
    {
        // Arrange
        var route = new OrderByUserAndId(Guid.Parse("12345678-1234-5678-9abc-123456789012"), 42);

        // Act
        var url = RouteUrlGenerator.GenerateUrl(route);

        // Assert
        Assert.Equal("/order/12345678-1234-5678-9abc-123456789012/42", url);
    }

    [Fact]
    public void GenerateUrlWithQuery_WithQueryParameters_ReturnsUrlWithQueryString()
    {
        // Arrange
        var route = new SimpleRoute();
        var queryParams = new { page = 2, size = 10, active = true };

        // Act
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);

        // Assert
        Assert.Equal("/simpleroute?page=2&size=10&active=True", url);
    }

    [Fact]
    public void GenerateUrlWithQuery_WithNullQueryParameters_ReturnsBaseUrl()
    {
        // Arrange
        var route = new SimpleRoute();

        // Act
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, null);

        // Assert
        Assert.Equal("/simpleroute", url);
    }

    [Fact]
    public void GenerateUrlWithQuery_WithCollectionParameters_ReturnsUrlWithRepeatedParams()
    {
        // Arrange
        var route = new SimpleRoute();
        var queryParams = new { tags = new[] { "tag1", "tag2", "tag3" } };

        // Act
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);

        // Assert
        Assert.Equal("/simpleroute?tags=tag1&tags=tag2&tags=tag3", url);
    }

    [Fact]
    public void GenerateUrl_WithSpecialCharacters_ReturnsEscapedUrl()
    {
        // Arrange
        var route = new UserByName("John Doe & Jane");

        // Act
        var url = RouteUrlGenerator.GenerateUrl(route);

        // Assert
        Assert.Equal("/user/John%20Doe%20%26%20Jane", url);
    }
}