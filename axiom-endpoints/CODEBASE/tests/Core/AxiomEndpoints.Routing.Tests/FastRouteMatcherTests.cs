using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Routing.Tests;

public class FastRouteMatcherTests
{
    private readonly List<RouteEndpoint> _testEndpoints;
    private readonly FastRouteMatcher _matcher;

    public FastRouteMatcherTests()
    {
        _testEndpoints = CreateTestEndpoints();
        _matcher = new FastRouteMatcher(_testEndpoints);
    }

    [Theory]
    [InlineData("/users", "GetUsers")]
    [InlineData("/users/123", "GetUser")]
    [InlineData("/organizations/456/projects", "GetProjects")]
    [InlineData("/organizations/456/projects/789", "GetProject")]
    public void Should_Match_Exact_Routes(string path, string expectedEndpointName)
    {
        var result = _matcher.Match(path);

        result.Should().NotBeNull();
        result!.Endpoint.EndpointType.Name.Should().Be(expectedEndpointName);
    }

    [Theory]
    [InlineData("/users/123e4567-e89b-12d3-a456-426614174000", true)]  // Valid GUID
    [InlineData("/users/not-a-guid", false)]                            // Invalid GUID
    [InlineData("/users/123", false)]                                   // Not a GUID
    public void Should_Validate_Route_Constraints(string path, bool shouldMatch)
    {
        // Add endpoint with GUID constraint
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/users/{id:guid}",
                typeof(GetUserById),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["id"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);
        var result = matcher.Match(path);

        if (shouldMatch)
        {
            result.Should().NotBeNull();
            result!.Parameters.Should().ContainKey("id");
        }
        else
        {
            result.Should().BeNull();
        }
    }

    [Fact]
    public void Should_Extract_Route_Parameters()
    {
        var result = _matcher.Match("/users/123");

        result.Should().NotBeNull();
        result!.Parameters.Should().ContainKey("id");
        result.Parameters["id"].Should().Be("123");
    }

    [Fact]
    public void Should_Handle_Multiple_Parameters()
    {
        var result = _matcher.Match("/organizations/456/projects/789");

        result.Should().NotBeNull();
        result!.Parameters.Should().ContainKey("orgId");
        result.Parameters.Should().ContainKey("projectId");
        result.Parameters["orgId"].Should().Be("456");
        result.Parameters["projectId"].Should().Be("789");
    }

    [Fact]
    public void Should_Prioritize_Exact_Matches_Over_Parameters()
    {
        // Add both exact and parameterized routes
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/users/new",
                typeof(CreateUser),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/users/{id}",
                typeof(GetUser),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);
        var result = matcher.Match("/users/new");

        result.Should().NotBeNull();
        result!.Endpoint.EndpointType.Should().Be(typeof(CreateUser));
        result.Parameters.Should().BeEmpty(); // Should match exact route, not parameterized
    }

    [Fact]
    public void Should_Handle_Optional_Parameters()
    {
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/files/{path}/{version?}",
                typeof(GetFile),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);

        // Test with optional parameter
        var result1 = matcher.Match("/files/document.pdf/v2");
        result1.Should().NotBeNull();
        result1!.Parameters.Should().ContainKey("path");
        result1.Parameters.Should().ContainKey("version");
        result1.Parameters["path"].Should().Be("document.pdf");
        result1.Parameters["version"].Should().Be("v2");

        // Test without optional parameter
        var result2 = matcher.Match("/files/document.pdf");
        result2.Should().NotBeNull();
        result2!.Parameters.Should().ContainKey("path");
        result2.Parameters.Should().NotContainKey("version");
        result2.Parameters["path"].Should().Be("document.pdf");
    }

    [Fact]
    public void Should_Return_Null_For_Unmatched_Routes()
    {
        var result = _matcher.Match("/nonexistent/route");
        result.Should().BeNull();
    }

    [Fact]
    public void Should_Handle_Root_Path()
    {
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/",
                typeof(GetRoot),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);
        var result = matcher.Match("/");

        result.Should().NotBeNull();
        result!.Endpoint.EndpointType.Should().Be(typeof(GetRoot));
    }

    [Fact]
    public void Should_Handle_Empty_Path()
    {
        var result = _matcher.Match("");
        result.Should().BeNull(); // Empty path should not match anything
    }

    [Fact]
    public void Should_Cache_Results_For_Performance()
    {
        var initialCacheSize = _matcher.CacheSize;

        // Match the same route multiple times
        _matcher.Match("/users/123");
        _matcher.Match("/users/123");
        _matcher.Match("/users/123");

        var finalCacheSize = _matcher.CacheSize;
        finalCacheSize.Should().BeGreaterThan(initialCacheSize);
    }

    [Fact]
    public void Should_Clear_Cache()
    {
        _matcher.Match("/users/123");
        _matcher.CacheSize.Should().BeGreaterThan(0);

        _matcher.ClearCache();
        _matcher.CacheSize.Should().Be(0);
    }

    [Fact]
    public void Should_Handle_Complex_Nested_Routes()
    {
        var result = _matcher.Match("/organizations/org123/projects/proj456/tasks/task789");

        result.Should().NotBeNull();
        result!.Parameters.Should().ContainKey("orgId");
        result.Parameters.Should().ContainKey("projectId");
        result.Parameters.Should().ContainKey("taskId");
        result.Parameters["orgId"].Should().Be("org123");
        result.Parameters["projectId"].Should().Be("proj456");
        result.Parameters["taskId"].Should().Be("task789");
    }

    [Fact]
    public void Should_Match_Routes_With_Different_Http_Methods()
    {
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/users/{id}",
                typeof(GetUser),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/users/{id}",
                typeof(UpdateUser),
                HttpMethod.Put,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);

        var getResult = matcher.Match("/users/123");
        var putResult = matcher.Match("/users/123");

        // Both should match the same route pattern
        getResult.Should().NotBeNull();
        putResult.Should().NotBeNull();
        
        // The actual HTTP method filtering would be done at a higher level
        getResult!.Endpoint.Template.Should().Be("/users/{id}");
        putResult!.Endpoint.Template.Should().Be("/users/{id}");
    }

    [Theory]
    [InlineData("/api/v1/users", "1")]
    [InlineData("/api/v2/users", "2")]
    public void Should_Handle_Versioned_Routes(string path, string expectedVersion)
    {
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/api/v{version}/users",
                typeof(GetUsersV1),
                HttpMethod.Get,
                new ApiVersion(1, 0),
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);
        var result = matcher.Match(path);

        result.Should().NotBeNull();
        result!.Parameters.Should().ContainKey("version");
        result.Parameters["version"].Should().Be(expectedVersion);
    }

    private static List<RouteEndpoint> CreateTestEndpoints()
    {
        return new List<RouteEndpoint>
        {
            new("/users", typeof(GetUsers), HttpMethod.Get, null, FrozenDictionary<string, IRouteConstraint>.Empty, FrozenDictionary<string, object>.Empty),
            new("/users/{id}", typeof(GetUser), HttpMethod.Get, null, FrozenDictionary<string, IRouteConstraint>.Empty, FrozenDictionary<string, object>.Empty),
            new("/organizations/{orgId}/projects", typeof(GetProjects), HttpMethod.Get, null, FrozenDictionary<string, IRouteConstraint>.Empty, FrozenDictionary<string, object>.Empty),
            new("/organizations/{orgId}/projects/{projectId}", typeof(GetProject), HttpMethod.Get, null, FrozenDictionary<string, IRouteConstraint>.Empty, FrozenDictionary<string, object>.Empty),
            new("/organizations/{orgId}/projects/{projectId}/tasks/{taskId}", typeof(GetTask), HttpMethod.Get, null, FrozenDictionary<string, IRouteConstraint>.Empty, FrozenDictionary<string, object>.Empty)
        };
    }
}

// Mock endpoint types for testing
public class GetUsers { }
public class GetUser { }
public class GetUserById { }
public class CreateUser { }
public class UpdateUser { }
public class GetProjects { }
public class GetProject { }
public class GetTask { }
public class GetFile { }
public class GetRoot { }
public class GetUsersV1 { }