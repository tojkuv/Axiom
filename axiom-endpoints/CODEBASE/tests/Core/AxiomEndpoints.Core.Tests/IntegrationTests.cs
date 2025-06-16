using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Core.Streaming;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Core.Tests;

/// <summary>
/// Integration tests that demonstrate the complete routing workflow
/// </summary>
public class IntegrationTests
{
    [Fact]
    public void Complete_Routing_Workflow_Should_Work()
    {
        // 1. Define routes
        var userRoute = new UserById(Guid.NewGuid());
        var orderRoute = new OrderByUserAndId(Guid.NewGuid(), 42);

        // 2. Generate URLs
        var userUrl = RouteUrlGenerator.GenerateUrl(userRoute);
        var orderUrl = RouteUrlGenerator.GenerateUrl(orderRoute);

        userUrl.Should().StartWith("/user/");
        orderUrl.Should().StartWith("/order/");

        // 3. Generate templates  
        var userTemplate = RouteTemplateGenerator.Generate<UserById>();
        var orderTemplate = RouteTemplateGenerator.Generate<OrderByUserAndId>();

        userTemplate.Should().Be("/user/{id}");
        orderTemplate.Should().Be("/order/{userId}/{id}");

        // 4. Test route matching
        var userMatches = RouteMatcher.TryMatch<UserById>(userUrl, out var userParams);
        var orderMatches = RouteMatcher.TryMatch<OrderByUserAndId>(orderUrl, out var orderParams);

        userMatches.Should().BeTrue();
        orderMatches.Should().BeTrue();

        userParams.Should().ContainKey("id");
        orderParams.Should().ContainKey("userId");
        orderParams.Should().ContainKey("id");
    }

    [Fact]
    public void End_To_End_Route_Validation_Should_Work()
    {
        // 1. Test constraint validation
        var guidConstraint = new TypeConstraint<Guid>();
        var validGuid = Guid.NewGuid().ToString();
        var invalidGuid = "not-a-guid";

        guidConstraint.IsValid(validGuid).Should().BeTrue();
        guidConstraint.IsValid(invalidGuid).Should().BeFalse();

        // 2. Test range constraints
        var rangeConstraint = new RangeConstraint<int> { Min = 1, Max = 100 };
        rangeConstraint.IsValid("50").Should().BeTrue();
        rangeConstraint.IsValid("150").Should().BeFalse();

        // 3. Test length constraints
        var lengthConstraint = new LengthConstraint { MinLength = 2, MaxLength = 10 };
        lengthConstraint.IsValid("hello").Should().BeTrue();
        lengthConstraint.IsValid("a").Should().BeFalse();
        lengthConstraint.IsValid("this is too long").Should().BeFalse();
    }

    [Fact]
    public void Complex_Query_Parameters_Should_Work()
    {
        // 1. Create route with query parameters
        var route = new SimpleRoute();
        var queryParams = new 
        { 
            search = "test query",
            page = 2,
            tags = new[] { "important", "urgent" },
            active = true
        };

        // 2. Generate URL with query string
        var url = RouteUrlGenerator.GenerateUrlWithQuery(route, queryParams);

        // 3. Verify all parameters are included
        url.Should().Contain("search=test%20query");
        url.Should().Contain("page=2");
        url.Should().Contain("tags=important");
        url.Should().Contain("tags=urgent");
        url.Should().Contain("active=True");
    }

    [Fact]
    public void Result_Type_Integration_Should_Work()
    {
        // 1. Test successful result
        var successResult = ResultFactory.Success("test value");
        successResult.IsSuccess.Should().BeTrue();
        successResult.Value.Should().Be("test value");

        // 2. Test failed result
        var error = AxiomError.Validation("Test error");
        var failureResult = ResultFactory.Failure<string>(error);
        failureResult.IsFailure.Should().BeTrue();
        failureResult.Error.Should().Be(error);

        // 3. Test result matching
        var output = successResult.Match(
            success: value => $"Success: {value}",
            failure: err => $"Error: {err.Message}"
        );
        output.Should().Be("Success: test value");
    }

    [Fact]
    public void Multiple_Route_Types_Should_Coexist()
    {
        // Test that different route types work together
        var routes = new object[]
        {
            new SimpleRoute(),
            new UserById(Guid.NewGuid()),
            new UserByName("john-doe"),
            new OrderByUserAndId(Guid.NewGuid(), 123),
            new ProductById(456),
            new CategoryBySlug("electronics")
        };

        foreach (var route in routes)
        {
            var routeType = route.GetType();
            string template = RouteTemplateGenerator.Generate(routeType);
            string url = RouteUrlGenerator.GenerateUrl((dynamic)route);

            template.Should().NotBeNullOrEmpty();
            url.Should().NotBeNullOrEmpty();
            url.Should().StartWith("/");

            // Test that we can match the generated URL back to parameters
            var matches = RouteMatcher.TryMatch(routeType, url, out Dictionary<string, object> parameters);
            matches.Should().BeTrue();
        }
    }

    [Fact]
    public void Streaming_Endpoints_Integration_Should_Work()
    {
        // Test that streaming endpoints work with the Result type system
        var serverEndpoint = TestEndpointFactory.CreateServerStreamEndpoint();
        var clientEndpoint = TestEndpointFactory.CreateClientStreamEndpoint();

        serverEndpoint.Should().BeAssignableTo<IServerStreamAxiom<TestRequest, TestResponse>>();
        clientEndpoint.Should().BeAssignableTo<IClientStreamAxiom<TestRequest, TestResponse>>();
    }

    [Fact]
    public void Constraint_Error_Messages_Should_Be_Descriptive()
    {
        var constraints = new IRouteConstraint[]
        {
            new TypeConstraint<Guid>(),
            new RangeConstraint<int> { Min = 1, Max = 100 },
            new LengthConstraint { MinLength = 2, MaxLength = 50 },
            new RegexConstraint(@"^[a-z0-9-]+$"),
            new RequiredConstraint(),
            new AllowedValuesConstraint("red", "green", "blue")
        };

        foreach (var constraint in constraints)
        {
            constraint.ErrorMessage.Should().NotBeNullOrEmpty();
            constraint.ConstraintString.Should().NotBeNullOrEmpty();
        }
    }
}