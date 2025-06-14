using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Tests;

public class AdvancedRoutingTests
{
    [Fact]
    public void Should_Generate_Correct_Template_With_Constraints()
    {
        var template = RouteTemplateGenerator.Generate<TestRoutes.Organizations.ById>();
        template.Should().Be("/organizations/{orgId:guid}");
    }

    [Fact]
    public void Should_Generate_Versioned_Routes()
    {
        var v1Template = RouteTemplateGenerator.Generate<TestRoutes.V1.Todos>();
        var v2Template = RouteTemplateGenerator.Generate<TestRoutes.V2.Todos>();

        v1Template.Should().Be("/v1/todos");
        v2Template.Should().Be("/v2/todos");
    }

    [Fact]
    public void Should_Build_Url_From_Route()
    {
        var route = new TestRoutes.Organizations.ById.Projects.ById(
            OrgId: Guid.Parse("123e4567-e89b-12d3-a456-426614174000"),
            ProjectId: Guid.Parse("987e6543-e21b-12d3-a456-426614174000")
        );

        var url = route.ToUrl();

        url.Should().Be("/organizations/123e4567-e89b-12d3-a456-426614174000/projects/987e6543-e21b-12d3-a456-426614174000");
    }

    [Fact]
    public void Should_Build_Url_With_Query_Parameters()
    {
        var route = new TestRoutes.V2.Todos();
        var query = new SearchQuery
        {
            Query = "important",
            Page = 2,
            PageSize = 50,
            Categories = ["work", "urgent"]
        };

        var url = route.ToUrl(query);

        url.Should().Contain("query=important");
        url.Should().Contain("p=2");
        url.Should().Contain("size=50");
        url.Should().Contain("categories=work");
        url.Should().Contain("categories=urgent");
    }

    [Fact]
    public void Should_Handle_Optional_Route_Parameters()
    {
        var route = new TestRoutes.Files.ByPath("documents/report.pdf");
        var routeWithVersion = new TestRoutes.Files.ByPath("documents/report.pdf", "v2");

        var url1 = route.ToUrl();
        var url2 = routeWithVersion.ToUrl();

        url1.Should().Be("/files/documents/report.pdf");
        url2.Should().Be("/files/documents/report.pdf/v2");
    }

    [Fact]
    public void Should_Support_Alternative_Route_Templates()
    {
        var route = new TestRoutes.LegacyApi();

        TestRoutes.LegacyApi.AlternativeTemplates.Should().Contain("/api/old");
        TestRoutes.LegacyApi.AlternativeTemplates.Should().Contain("/legacy/api");
        TestRoutes.LegacyApi.AlternativeTemplates.Should().Contain("/v0/api");
    }

    [Fact]
    public void Should_Validate_Route_Constraints()
    {
        var validGuid = Guid.NewGuid();
        var route = new TestRoutes.Organizations.ById(validGuid);

        // This would be validated by the route constraint system
        var constraint = new TypeConstraint<Guid>();
        constraint.IsValid(validGuid.ToString()).Should().BeTrue();
        constraint.IsValid("not-a-guid").Should().BeFalse();
    }

    [Fact]
    public void Should_Support_Hierarchical_Routes()
    {
        var orgId = Guid.NewGuid();
        var projectId = Guid.NewGuid();
        
        var route = new TestRoutes.Organizations.ById.Projects.ById(orgId, projectId);
        var parent = route.Parent;

        parent.OrgId.Should().Be(orgId);
        route.ProjectId.Should().Be(projectId);
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
    public void Should_Support_Api_Versioning()
    {
        var v1 = new ApiVersion(1, 0);
        var v2Beta = new ApiVersion(2, 1, "beta");

        v1.ToString().Should().Be("v1.0");
        v2Beta.ToString().Should().Be("v2.1-beta");
    }
}

// Test route definitions
public static class TestRoutes
{
    public static class V1
    {
        public record Todos : IVersionedRoute<Todos>
        {
            public static ApiVersion Version => new(1, 0);
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public record ById(
                [property: RouteConstraintAttribute<Guid>] Guid Id
            ) : IRoute<ById>
            {
                public static FrozenDictionary<string, object> Metadata { get; } =
                    FrozenDictionary<string, object>.Empty;
            }
        }
    }

    public static class V2
    {
        public record Todos : IVersionedRoute<Todos>
        {
            public static ApiVersion Version => new(2, 0);
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public record ById(Guid Id) : IRoute<ById>
            {
                public static FrozenDictionary<string, object> Metadata { get; } =
                    FrozenDictionary<string, object>.Empty;
            }

            public record BySlug(
                [property: RegexAttribute(@"^[a-z0-9-]+$")] string Slug
            ) : IRoute<BySlug>
            {
                public static FrozenDictionary<string, object> Metadata { get; } =
                    FrozenDictionary<string, object>.Empty;
            }
        }
    }

    public record Organizations : IRoute<Organizations>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public record ById(
            [property: RouteConstraintAttribute<Guid>] Guid OrgId
        ) : IRoute<ById>
        {
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public record Projects : IRoute<Projects>
            {
                public static FrozenDictionary<string, object> Metadata { get; } =
                    FrozenDictionary<string, object>.Empty;

                public record ById(
                    Guid OrgId,
                    [property: RouteConstraintAttribute<Guid>] Guid ProjectId
                ) : IHierarchicalRoute<ById, Organizations.ById>
                {
                    public Organizations.ById Parent => new(OrgId);

                    public static FrozenDictionary<string, object> Metadata { get; } =
                        FrozenDictionary<string, object>.Empty;

                    public record Tasks(
                        Guid OrgId,
                        Guid ProjectId,
                        [property: QueryParam] TaskQuery? Query = null
                    ) : IRouteWithQuery<Tasks, TaskQuery>
                    {
                        public static FrozenDictionary<string, object> Metadata { get; } =
                            FrozenDictionary<string, object>.Empty;
                    }
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

    public record LegacyApi : IAlternativeRoute<LegacyApi>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public static FrozenSet<string> AlternativeTemplates { get; } =
            ["/api/old", "/legacy/api", "/v0/api"].ToFrozenSet();
    }
}

public record SearchQuery : QueryParameters
{
    [QueryParam(Description = "Search text")]
    public string? Query { get; init; }

    [QueryParam(Name = "p")]
    [RangeAttribute<int>(1, 100)]
    public int Page { get; init; } = 1;

    [QueryParam(Name = "size")]
    [RangeAttribute<int>(10, 100)]
    public int PageSize { get; init; } = 20;

    [QueryParam]
    public SortOrder Sort { get; init; } = SortOrder.Relevance;

    [QueryParam]
    public DateTime? Since { get; init; }

    [QueryParam(Description = "Filter by categories")]
    public IReadOnlyList<string> Categories { get; init; } = Array.Empty<string>();

    public static QueryParameterMetadata GetMetadata() => new()
    {
        Parameters = new Dictionary<string, QueryParameterInfo>
        {
            ["query"] = new() { Name = "query", Type = typeof(string), IsRequired = false, DefaultValue = null, Constraint = null, Description = "Search text" },
            ["p"] = new() { Name = "p", Type = typeof(int), IsRequired = false, DefaultValue = 1, Constraint = new RangeConstraint<int> { Min = 1, Max = 100 }, Description = null },
            ["size"] = new() { Name = "size", Type = typeof(int), IsRequired = false, DefaultValue = 20, Constraint = new RangeConstraint<int> { Min = 10, Max = 100 }, Description = null },
            ["sort"] = new() { Name = "sort", Type = typeof(SortOrder), IsRequired = false, DefaultValue = SortOrder.Relevance, Constraint = new EnumConstraint<SortOrder>(), Description = null },
            ["since"] = new() { Name = "since", Type = typeof(DateTime?), IsRequired = false, DefaultValue = null, Constraint = null, Description = null },
            ["categories"] = new() { Name = "categories", Type = typeof(IReadOnlyList<string>), IsRequired = false, DefaultValue = Array.Empty<string>(), Constraint = null, Description = "Filter by categories" }
        }.ToFrozenDictionary(),
        RequiredParameters = FrozenSet<string>.Empty
    };
}

public record TaskQuery : QueryParameters
{
    [QueryParam]
    public TaskStatus? Status { get; init; }

    [QueryParam]
    public string? AssignedTo { get; init; }

    [QueryParam]
    [RangeAttribute<int>(0, 1000)]
    public int Limit { get; init; } = 50;

    [QueryParam]
    public bool IncludeCompleted { get; init; } = false;

    public static new QueryParameterMetadata GetMetadata() =>
        QueryParameterMetadataGenerator.Generate<TaskQuery>();
}

public enum SortOrder
{
    Relevance,
    Date,
    Title,
    Popular
}

