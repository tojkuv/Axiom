using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Core.Tests;

public class AdvancedRoutingTests
{
    [Fact]
    public void Should_Generate_Correct_Template_For_Nested_Routes()
    {
        var template = RouteTemplateGenerator.Generate<Users.ById>();
        template.Should().Be("/users/byid");
    }

    [Fact]
    public void Should_Handle_Routes_With_Multiple_Parameters()
    {
        var template = RouteTemplateGenerator.Generate<Orders.ByUserAndId>();
        template.Should().Be("/orders/{userId}/{id}");
    }

    [Fact]
    public void Should_Build_Url_From_Route_With_Parameters()
    {
        var userId = Guid.Parse("123e4567-e89b-12d3-a456-426614174000");
        var orderId = 42;
        var route = new OrderByUserAndId(userId, orderId);

        var url = RouteUrlGenerator.GenerateUrl(route);

        url.Should().Be($"/order/{userId}/{orderId}");
    }

    [Fact]
    public void Should_Build_Url_With_Query_Parameters()
    {
        var route = new SimpleRoute();
        var queryParams = new { search = "important", page = 2, limit = 50 };

        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);

        url.Should().Contain("search=important");
        url.Should().Contain("page=2");
        url.Should().Contain("limit=50");
    }

    [Fact]
    public void Should_Validate_Route_Constraints()
    {
        var validGuid = Guid.NewGuid();

        // Test GUID constraint
        var guidConstraint = new TypeConstraint<Guid>();
        guidConstraint.IsValid(validGuid.ToString()).Should().BeTrue();
        guidConstraint.IsValid("not-a-guid").Should().BeFalse();

        // Test range constraint
        var rangeConstraint = new RangeConstraint<int> { Min = 1, Max = 100 };
        rangeConstraint.IsValid("50").Should().BeTrue();
        rangeConstraint.IsValid("150").Should().BeFalse();
    }

    [Fact]
    public void Should_Generate_Correct_Constraint_String()
    {
        var rangeConstraint = new RangeConstraint<int> { Min = 1, Max = 100 };
        var regexConstraint = new RegexConstraint(@"^[a-z0-9-]+$");
        var lengthConstraint = new LengthConstraint { MinLength = 1, MaxLength = 50 };

        rangeConstraint.ConstraintString.Should().Be("range(1,100)");
        regexConstraint.ConstraintString.Should().Be(@"regex(^[a-z0-9-]+$)");
        lengthConstraint.ConstraintString.Should().Be("length(1,50)");
    }

    [Fact]
    public void Should_Support_Complex_Route_Matching()
    {
        var path = "/user/123e4567-e89b-12d3-a456-426614174000";
        var matches = RouteMatcher.TryMatch<UserById>(path, out var parameters);

        matches.Should().BeTrue();
        parameters.Should().ContainKey("id");
        parameters["id"].Should().Be("123e4567-e89b-12d3-a456-426614174000");
    }

    [Fact]
    public void Should_Handle_Special_Characters_In_Urls()
    {
        var route = new UserByName("John Doe & Associates");
        var url = RouteUrlGenerator.GenerateUrl(route);

        url.Should().Contain("John%20Doe%20%26%20Associates");
    }

    [Fact]
    public void Should_Support_Category_Based_Routes()
    {
        var route = new CategoryBySlug("technology");
        var template = RouteTemplateGenerator.Generate<CategoryBySlug>();

        template.Should().Be("/category/{slug}");
        
        var url = RouteUrlGenerator.GenerateUrl(route);
        url.Should().Be("/category/technology");
    }

    [Fact]
    public void Should_Support_Numeric_Route_Parameters()
    {
        var route = new ProductById(12345);
        var template = RouteTemplateGenerator.Generate<ProductById>();

        template.Should().Be("/product/{id}");
        
        var url = RouteUrlGenerator.GenerateUrl(route);
        url.Should().Be("/product/12345");
    }

    [Theory]
    [InlineData("pending", true)]
    [InlineData("inprogress", true)]
    [InlineData("completed", true)]
    [InlineData("invalid-status", false)]
    public void Should_Validate_Enum_Constraints(string value, bool expectedValid)
    {
        var constraint = new EnumConstraint<TaskStatus>();
        constraint.IsValid(value).Should().Be(expectedValid);
    }

    [Theory]
    [InlineData("red", true)]
    [InlineData("green", true)]
    [InlineData("blue", true)]
    [InlineData("yellow", false)]
    public void Should_Validate_Allowed_Values_Constraints(string value, bool expectedValid)
    {
        var constraint = new AllowedValuesConstraint("red", "green", "blue");
        constraint.IsValid(value).Should().Be(expectedValid);
    }

    [Fact]
    public void Should_Handle_Complex_Nested_Route_Structures()
    {
        // Test with the most complex route we have available
        var userId = Guid.NewGuid();
        var orderId = 123;
        var route = new OrderByUserAndId(userId, orderId);

        var template = RouteTemplateGenerator.Generate<OrderByUserAndId>();
        template.Should().Be("/order/{userId}/{id}");

        var url = RouteUrlGenerator.GenerateUrl(route);
        url.Should().Be($"/order/{userId}/{orderId}");

        var matches = RouteMatcher.TryMatch<OrderByUserAndId>(url, out var parameters);
        matches.Should().BeTrue();
        parameters.Should().ContainKey("userId");
        parameters.Should().ContainKey("id");
    }

    [Fact]
    public void Should_Support_Query_Parameter_Collections()
    {
        var route = new SimpleRoute();
        var queryParams = new { tags = new[] { "work", "urgent", "high-priority" } };

        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);

        url.Should().Contain("tags=work");
        url.Should().Contain("tags=urgent");
        url.Should().Contain("tags=high-priority");
    }
}

