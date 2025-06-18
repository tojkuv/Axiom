using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Routing.Tests;

public class UrlBuilderTests
{
    [Fact]
    public void Should_Build_Simple_Route_Url()
    {
        var route = new SimpleRoute();
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        url.Should().Be("/simpleroute");
    }

    [Fact]
    public void Should_Build_Route_With_Single_Parameter()
    {
        var userId = Guid.NewGuid();
        var route = new UserById(userId);
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        url.Should().Be($"/user/{userId}");
    }

    [Fact]
    public void Should_Build_Route_With_Multiple_Parameters()
    {
        var userId = Guid.NewGuid();
        var orderId = 123;
        var route = new OrderByUserAndId(userId, orderId);
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        url.Should().Be($"/order/{userId}/{orderId}");
    }

    [Fact]
    public void Should_Url_Encode_Parameters()
    {
        var route = new UserByName("John Doe & Jane");
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        url.Should().Contain("John%20Doe%20%26%20Jane");
    }

    [Fact]
    public void Should_Handle_Special_Characters_In_Parameters()
    {
        var route = new UserByName("hello&world");
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        url.Should().Contain("hello%26world");
    }

    [Fact]
    public void Should_Build_Url_With_Query_Parameters()
    {
        var route = new SimpleRoute();
        var queryParams = new { page = 2, size = 10, active = true };
        
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);
        
        url.Should().Contain("page=2");
        url.Should().Contain("size=10");
        url.Should().Contain("active=True");
    }

    [Fact]
    public void Should_Handle_Null_Query_Parameters()
    {
        var route = new SimpleRoute();
        
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, null);
        
        url.Should().Be("/simpleroute");
    }

    [Theory]
    [InlineData("", "")]
    [InlineData("simple", "simple")]
    [InlineData("hello world", "hello%20world")]
    [InlineData("hello&world", "hello%26world")]
    [InlineData("hello+world", "hello%2Bworld")]
    [InlineData("hello/world", "hello%2Fworld")]
    [InlineData("hello?world", "hello%3Fworld")]
    [InlineData("hello#world", "hello%23world")]
    public void Should_Properly_Encode_Route_Parameters(string input, string expected)
    {
        var route = new UserByName(input);
        var url = RouteUrlGenerator.GenerateUrl(route);
        
        if (string.IsNullOrEmpty(expected))
        {
            url.Should().Be("/user/");
        }
        else
        {
            url.Should().Be($"/user/{expected}");
        }
    }

    [Fact]
    public void Should_Handle_Complex_Query_Parameter_Collections()
    {
        var route = new SimpleRoute();
        var queryParams = new { tags = new[] { "tag with spaces", "tag&with&ampersands" } };
        
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);
        
        url.Should().Contain("tags=tag%20with%20spaces");
        url.Should().Contain("tags=tag%26with%26ampersands");
    }

    [Fact]
    public void Should_Handle_Boolean_Query_Parameters()
    {
        var route = new SimpleRoute();
        var queryParams = new { isActive = true, isDeleted = false };
        
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);
        
        url.Should().Contain("isactive=True");
        url.Should().Contain("isdeleted=False");
    }

    [Fact]
    public void Should_Handle_Nested_Route_Types()
    {
        var route = new Users.ById();
        var template = RouteTemplateGenerator.Generate<Users.ById>();
        
        template.Should().Be("/users/byid");
    }

    [Fact]
    public void Should_Handle_Route_With_Parameters_From_Nested_Types()
    {
        var route = new UsersWithParam.ById(Guid.NewGuid());
        var template = RouteTemplateGenerator.Generate<UsersWithParam.ById>();
        
        template.Should().Be("/userswithparam/{id}");
    }

    [Fact]
    public void Should_Handle_Route_Matching_For_Url_Generation()
    {
        var userId = Guid.NewGuid();
        var orderId = 42;
        var route = new OrderByUserAndId(userId, orderId);
        
        // Test that we can generate a URL and then match it back
        var url = RouteUrlGenerator.GenerateUrl(route);
        var matches = RouteMatcher.TryMatch<OrderByUserAndId>(url, out var parameters);
        
        matches.Should().BeTrue();
        parameters.Should().ContainKey("userId");
        parameters.Should().ContainKey("id");
        parameters["userId"].Should().Be(userId.ToString());
        parameters["id"].Should().Be(orderId.ToString());
    }
}