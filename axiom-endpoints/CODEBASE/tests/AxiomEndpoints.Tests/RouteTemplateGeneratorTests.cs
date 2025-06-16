using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

#pragma warning disable CA1707 // Identifiers should not contain underscores - test method naming convention

namespace AxiomEndpoints.Tests;

public class RouteTemplateGeneratorTests
{
    [Fact]
    public void Generate_SimpleRoute_ReturnsCorrectTemplate()
    {
        // Arrange & Act
        var template = RouteTemplateGenerator.Generate<SimpleRoute>();

        // Assert
        Assert.Equal("/simpleroute", template);
    }

    [Fact]
    public void Generate_NestedRoute_ReturnsCorrectTemplate()
    {
        // Arrange & Act
        var template = RouteTemplateGenerator.Generate<Users.ById>();

        // Assert
        Assert.Equal("/users/byid", template);
    }

    [Fact]
    public void Generate_RouteWithParameter_ReturnsTemplateWithPlaceholder()
    {
        // Arrange & Act
        var template = RouteTemplateGenerator.Generate<UsersWithParam.ById>();

        // Assert
        Assert.Equal("/userswithparam/{id}", template);
    }

    [Fact]
    public void Generate_RouteWithMultipleParameters_ReturnsTemplateWithPlaceholders()
    {
        // Arrange & Act
        var template = RouteTemplateGenerator.Generate<Orders.ByUserAndId>();

        // Assert
        Assert.Equal("/orders/{userId}/{id}", template);
    }

    [Fact]
    public void Generate_NonGeneric_ReturnsCorrectTemplate()
    {
        // Arrange & Act
        var template = RouteTemplateGenerator.Generate<SimpleRoute>();

        // Assert
        Assert.Equal("/simpleroute", template);
    }

}