using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Tests;

public class UrlBuilderTests
{
    [Fact]
    public void Should_Build_Simple_Route_Url()
    {
        var route = new TestUrlRoutes.Users();
        var url = route.ToUrl();
        
        url.Should().Be("/users");
    }

    [Fact]
    public void Should_Build_Route_With_Single_Parameter()
    {
        var userId = Guid.NewGuid();
        var route = new TestUrlRoutes.Users.ById(userId);
        var url = route.ToUrl();
        
        url.Should().Be($"/users/{userId}");
    }

    [Fact]
    public void Should_Build_Route_With_Multiple_Parameters()
    {
        var orgId = Guid.NewGuid();
        var projectId = Guid.NewGuid();
        var route = new TestUrlRoutes.Organizations.ById.Projects.ById(orgId, projectId);
        var url = route.ToUrl();
        
        url.Should().Be($"/organizations/{orgId}/projects/{projectId}");
    }

    [Fact]
    public void Should_Url_Encode_Parameters()
    {
        var route = new TestUrlRoutes.Files.ByPath("folder with spaces/file.txt");
        var url = route.ToUrl();
        
        url.Should().Contain("folder%20with%20spaces");
        url.Should().Contain("file.txt");
    }

    [Fact]
    public void Should_Handle_Special_Characters_In_Parameters()
    {
        var route = new TestUrlRoutes.Search.ByQuery("hello&world");
        var url = route.ToUrl();
        
        url.Should().Contain("hello%26world");
    }

    [Fact]
    public void Should_Build_Url_With_Query_Parameters()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            Name = "john",
            Age = 25,
            IsActive = true,
            Tags = ["admin", "user"]
        };
        
        var url = route.ToUrl(query);
        
        url.Should().Contain("name=john");
        url.Should().Contain("age=25");
        url.Should().Contain("isactive=true");
        url.Should().Contain("tags=admin");
        url.Should().Contain("tags=user");
    }

    [Fact]
    public void Should_Skip_Default_Values_In_Query_Parameters()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            Name = "john",
            Page = 1, // Default value, should be skipped
            PageSize = 20 // Default value, should be skipped
        };
        
        var url = route.ToUrl(query);
        
        url.Should().Contain("name=john");
        url.Should().NotContain("page=1");
        url.Should().NotContain("pagesize=20");
    }

    [Fact]
    public void Should_Handle_DateTime_Query_Parameters()
    {
        var route = new TestUrlRoutes.Users();
        var date = new DateTime(2023, 12, 25, 10, 30, 0, DateTimeKind.Utc);
        var query = new UserSearchQuery
        {
            CreatedAfter = date
        };
        
        var url = route.ToUrl(query);
        
        url.Should().Contain("createdafter=");
        url.Should().Contain("2023-12-25T10%3A30%3A00.0000000Z"); // ISO format, URL encoded
    }

    [Fact]
    public void Should_Handle_Boolean_Query_Parameters()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            IsActive = true,
            IsDeleted = false
        };
        
        var url = route.ToUrl(query);
        
        url.Should().Contain("isactive=true");
        url.Should().Contain("isdeleted=false");
    }

    [Fact]
    public void Should_Handle_Null_Query_Parameters()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            Name = null, // Should be skipped
            Age = 25
        };
        
        var url = route.ToUrl(query);
        
        url.Should().NotContain("name=");
        url.Should().Contain("age=25");
    }

    [Fact]
    public void Should_Generate_Uri_From_Route()
    {
        var route = new TestUrlRoutes.Users.ById(Guid.NewGuid());
        var uri = route.ToUri();
        
        uri.Should().NotBeNull();
        uri.IsAbsoluteUri.Should().BeFalse();
        uri.ToString().Should().StartWith("/users/");
    }

    [Fact]
    public void Should_Generate_Absolute_Uri_With_Base_Url()
    {
        var route = new TestUrlRoutes.Users.ById(Guid.NewGuid());
        var uri = route.ToUri("https://api.example.com");
        
        uri.Should().NotBeNull();
        uri.IsAbsoluteUri.Should().BeTrue();
        uri.ToString().Should().StartWith("https://api.example.com/users/");
    }

    [Fact]
    public void Should_Handle_Route_With_Constraints()
    {
        var route = new TestUrlRoutes.Users.ById(Guid.NewGuid());
        var url = route.ToUrl();
        
        // The constraint information is used during route matching, not URL generation
        url.Should().StartWith("/users/");
        url.Should().MatchRegex(@"/users/[0-9a-f-]{36}"); // GUID pattern
    }

    [Fact]
    public void Should_Handle_Optional_Parameters()
    {
        var routeWithoutVersion = new TestUrlRoutes.Files.ByPath("document.pdf");
        var routeWithVersion = new TestUrlRoutes.Files.ByPath("document.pdf", "v2");
        
        var url1 = routeWithoutVersion.ToUrl();
        var url2 = routeWithVersion.ToUrl();
        
        url1.Should().Be("/files/document.pdf");
        url2.Should().Be("/files/document.pdf/v2");
    }

    [Fact]
    public void Should_Handle_Hierarchical_Routes()
    {
        var orgId = Guid.NewGuid();
        var projectId = Guid.NewGuid();
        
        var route = new TestUrlRoutes.Organizations.ById.Projects.ById(orgId, projectId);
        var parentUrl = route.Parent.ToUrl();
        var fullUrl = route.ToUrl();
        
        parentUrl.Should().Be($"/organizations/{orgId}");
        fullUrl.Should().Be($"/organizations/{orgId}/projects/{projectId}");
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
        var route = new TestUrlRoutes.Search.ByQuery(input);
        var url = route.ToUrl();
        
        if (string.IsNullOrEmpty(expected))
        {
            url.Should().Be("/search/");
        }
        else
        {
            url.Should().Be($"/search/{expected}");
        }
    }

    [Fact]
    public void Should_Handle_Complex_Query_Parameter_Collections()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            Tags = ["tag with spaces", "tag&with&ampersands", "tag+with+plus"]
        };
        
        var url = route.ToUrl(query);
        
        url.Should().Contain("tags=tag%20with%20spaces");
        url.Should().Contain("tags=tag%26with%26ampersands");
        url.Should().Contain("tags=tag%2Bwith%2Bplus");
    }

    [Fact]
    public void Should_Handle_Empty_Collections()
    {
        var route = new TestUrlRoutes.Users();
        var query = new UserSearchQuery
        {
            Tags = [] // Empty collection should not appear in URL
        };
        
        var url = route.ToUrl(query);
        
        url.Should().NotContain("tags=");
    }
}

// Test route definitions for URL building
public static class TestUrlRoutes
{
    public record Users : IRoute<Users>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public record ById(Guid Id) : IRoute<ById>
        {
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;
        }
    }

    public record Search : IRoute<Search>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public record ByQuery(string Query) : IRoute<ByQuery>
        {
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;
        }
    }

    public record Organizations : IRoute<Organizations>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public record ById(Guid OrgId) : IRoute<ById>
        {
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public record Projects : IRoute<Projects>
            {
                public static FrozenDictionary<string, object> Metadata { get; } =
                    FrozenDictionary<string, object>.Empty;

                public record ById(
                    Guid OrgId,
                    Guid ProjectId
                ) : IHierarchicalRoute<ById, Organizations.ById>
                {
                    public Organizations.ById Parent => new(OrgId);

                    public static FrozenDictionary<string, object> Metadata { get; } =
                        FrozenDictionary<string, object>.Empty;
                }
            }
        }
    }

    public record Files : IRoute<Files>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public record ByPath(
            string Path,
            string? Version = null
        ) : IOptionalRoute<ByPath>
        {
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public static OptionalRouteParameters GetOptionalParameters() => new()
            {
                OptionalSegments = ["version"].ToFrozenSet(),
                DefaultValues = new Dictionary<string, object>
                {
                    ["version"] = "latest"
                }.ToFrozenDictionary()
            };
        }
    }
}

public record UserSearchQuery : QueryParameters
{
    [QueryParam]
    public string? Name { get; init; }

    [QueryParam]
    public int? Age { get; init; }

    [QueryParam]
    public bool IsActive { get; init; } = false;

    [QueryParam]
    public bool IsDeleted { get; init; } = false;

    [QueryParam]
    public DateTime? CreatedAfter { get; init; }

    [QueryParam]
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();

    [QueryParam]
    public int Page { get; init; } = 1;

    [QueryParam]
    public int PageSize { get; init; } = 20;

    public static QueryParameterMetadata GetMetadata() => new()
    {
        Parameters = new Dictionary<string, QueryParameterInfo>
        {
            ["name"] = new() { Name = "name", Type = typeof(string), IsRequired = false, DefaultValue = null, Constraint = null, Description = null },
            ["age"] = new() { Name = "age", Type = typeof(int?), IsRequired = false, DefaultValue = null, Constraint = null, Description = null },
            ["isactive"] = new() { Name = "isactive", Type = typeof(bool), IsRequired = false, DefaultValue = false, Constraint = null, Description = null },
            ["isdeleted"] = new() { Name = "isdeleted", Type = typeof(bool), IsRequired = false, DefaultValue = false, Constraint = null, Description = null },
            ["createdafter"] = new() { Name = "createdafter", Type = typeof(DateTime?), IsRequired = false, DefaultValue = null, Constraint = null, Description = null },
            ["tags"] = new() { Name = "tags", Type = typeof(IReadOnlyList<string>), IsRequired = false, DefaultValue = Array.Empty<string>(), Constraint = null, Description = null },
            ["page"] = new() { Name = "page", Type = typeof(int), IsRequired = false, DefaultValue = 1, Constraint = null, Description = null },
            ["pagesize"] = new() { Name = "pagesize", Type = typeof(int), IsRequired = false, DefaultValue = 20, Constraint = null, Description = null }
        }.ToFrozenDictionary(),
        RequiredParameters = FrozenSet<string>.Empty
    };
}