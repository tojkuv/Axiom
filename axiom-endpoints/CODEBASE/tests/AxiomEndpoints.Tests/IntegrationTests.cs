using System.Collections.Frozen;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.Tests;

/// <summary>
/// Integration tests that demonstrate the complete advanced routing workflow
/// </summary>
public class IntegrationTests
{
    [Fact]
    public void Complete_Advanced_Routing_Workflow_Should_Work()
    {
        // 1. Define advanced routes with all features
        var searchRoute = new AdvancedTestRoutes.V2.Products();
        var productRoute = new AdvancedTestRoutes.V2.Products.ById(Guid.NewGuid());
        var searchQuery = new ProductSearchQuery
        {
            Query = "laptop",
            Category = ProductCategory.Electronics,
            MinPrice = 100,
            MaxPrice = 2000,
            InStock = true,
            Tags = ["gaming", "portable"]
        };

        // 2. Generate URLs with type safety
        var searchUrl = searchRoute.ToUrl(searchQuery);
        var productUrl = productRoute.ToUrl();

        // 3. Verify URL generation
        searchUrl.Should().Contain("/v2/products");
        searchUrl.Should().Contain("query=laptop");
        searchUrl.Should().Contain("category=electronics");
        searchUrl.Should().Contain("minprice=100");
        searchUrl.Should().Contain("maxprice=2000");
        searchUrl.Should().Contain("instock=true");
        searchUrl.Should().Contain("tags=gaming");
        searchUrl.Should().Contain("tags=portable");

        productUrl.Should().StartWith("/v2/products/");
        productUrl.Should().MatchRegex(@"/v2/products/[0-9a-f-]{36}");

        // 4. Test route matching
        var endpoints = CreateAdvancedEndpoints();
        var matcher = new FastRouteMatcher(endpoints);

        var searchMatch = matcher.Match("/v2/products");
        var productMatch = matcher.Match($"/v2/products/{productRoute.Id}");

        searchMatch.Should().NotBeNull();
        searchMatch!.Endpoint.Template.Should().Be("/v2/products");

        productMatch.Should().NotBeNull();
        productMatch!.Endpoint.Template.Should().Be("/v2/products/{id:guid}");
        productMatch.Parameters.Should().ContainKey("id");
        productMatch.Parameters["id"].Should().Be(productRoute.Id.ToString());

        // 5. Test constraint validation
        var invalidProductMatch = matcher.Match("/v2/products/not-a-guid");
        invalidProductMatch.Should().BeNull(); // Should fail GUID constraint

        // 6. Test versioning
        var v1Match = matcher.Match("/v1/products");
        var v2Match = matcher.Match("/v2/products");

        v1Match.Should().NotBeNull();
        v1Match!.Endpoint.Version.Should().NotBeNull();
        v1Match.Endpoint.Version!.Major.Should().Be(1);

        v2Match.Should().NotBeNull();
        v2Match!.Endpoint.Version.Should().NotBeNull();
        v2Match.Endpoint.Version!.Major.Should().Be(2);
    }

    [Fact]
    public void Hierarchical_Routes_Should_Work_End_To_End()
    {
        var orgId = Guid.NewGuid();
        var projectId = Guid.NewGuid();
        var taskId = Guid.NewGuid();

        // Create hierarchical route
        var taskRoute = new AdvancedTestRoutes.Organizations.ById.Projects.ById.Tasks.ById(
            orgId, projectId, taskId);

        // Test parent relationships
        taskRoute.OrgId.Should().Be(orgId);
        taskRoute.ProjectId.Should().Be(projectId);
        taskRoute.TaskId.Should().Be(taskId);

        var projectParent = taskRoute.ProjectParent;
        projectParent.OrgId.Should().Be(orgId);
        projectParent.ProjectId.Should().Be(projectId);

        var orgParent = projectParent.Parent;
        orgParent.OrgId.Should().Be(orgId);

        // Test URL generation
        var taskUrl = taskRoute.ToUrl();
        var expectedUrl = $"/organizations/{orgId}/projects/{projectId}/tasks/{taskId}";
        taskUrl.Should().Be(expectedUrl);

        // Test route matching
        var endpoints = CreateHierarchicalEndpoints();
        var matcher = new FastRouteMatcher(endpoints);

        var match = matcher.Match(expectedUrl);
        match.Should().NotBeNull();
        match!.Parameters.Should().ContainKey("orgId");
        match.Parameters.Should().ContainKey("projectId");
        match.Parameters.Should().ContainKey("taskId");
        match.Parameters["orgId"].Should().Be(orgId.ToString());
        match.Parameters["projectId"].Should().Be(projectId.ToString());
        match.Parameters["taskId"].Should().Be(taskId.ToString());
    }

    [Fact]
    public void Query_Parameter_Validation_Should_Work_End_To_End()
    {
        // Test valid query parameters
        var validQuery = new ProductSearchQuery
        {
            Query = "laptop",
            MinPrice = 100,
            MaxPrice = 2000,
            Category = ProductCategory.Electronics
        };

        var route = new AdvancedTestRoutes.V2.Products();
        var url = route.ToUrl(validQuery);

        // URL should be generated correctly
        url.Should().Contain("query=laptop");
        url.Should().Contain("minprice=100");
        url.Should().Contain("maxprice=2000");
        url.Should().Contain("category=electronics");

        // Test constraint validation
        var priceConstraint = new RangeConstraint<decimal> { Min = 0, Max = 10000 };
        priceConstraint.IsValid("100").Should().BeTrue();
        priceConstraint.IsValid("2000").Should().BeTrue();
        priceConstraint.IsValid("-10").Should().BeFalse();
        priceConstraint.IsValid("20000").Should().BeFalse();

        var categoryConstraint = new EnumConstraint<ProductCategory>();
        categoryConstraint.IsValid("Electronics").Should().BeTrue();
        categoryConstraint.IsValid("electronics").Should().BeTrue(); // Case insensitive
        categoryConstraint.IsValid("InvalidCategory").Should().BeFalse();
    }

    [Fact]
    public void Alternative_Routes_Should_Support_Migration_Scenarios()
    {
        var route = new AdvancedTestRoutes.LegacyProducts();

        // Test that alternative templates are defined
        AdvancedTestRoutes.LegacyProducts.AlternativeTemplates.Should().Contain("/api/products");
        AdvancedTestRoutes.LegacyProducts.AlternativeTemplates.Should().Contain("/legacy/products");
        AdvancedTestRoutes.LegacyProducts.AlternativeTemplates.Should().Contain("/v0/products");

        // In a real implementation, the route matcher would handle all alternative templates
        var endpoints = new[]
        {
            new RouteEndpoint(
                "/products",
                typeof(GetProducts),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/api/products",
                typeof(GetProducts),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/legacy/products",
                typeof(GetProducts),
                HttpMethod.Get,
                null,
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            )
        };

        var matcher = new FastRouteMatcher(endpoints);

        // All alternative paths should match
        matcher.Match("/products").Should().NotBeNull();
        matcher.Match("/api/products").Should().NotBeNull();
        matcher.Match("/legacy/products").Should().NotBeNull();
    }

    private static List<RouteEndpoint> CreateAdvancedEndpoints()
    {
        return new List<RouteEndpoint>
        {
            new RouteEndpoint(
                "/v1/products",
                typeof(GetProductsV1),
                HttpMethod.Get,
                new ApiVersion(1, 0),
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/v2/products",
                typeof(GetProductsV2),
                HttpMethod.Get,
                new ApiVersion(2, 0),
                FrozenDictionary<string, IRouteConstraint>.Empty,
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/v2/products/{id:guid}",
                typeof(GetProductV2),
                HttpMethod.Get,
                new ApiVersion(2, 0),
                new Dictionary<string, IRouteConstraint>
                {
                    ["id"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            )
        };
    }

    private static List<RouteEndpoint> CreateHierarchicalEndpoints()
    {
        return new List<RouteEndpoint>
        {
            new RouteEndpoint(
                "/organizations/{orgId:guid}",
                typeof(GetOrganization),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["orgId"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/organizations/{orgId:guid}/projects/{projectId:guid}",
                typeof(GetProject),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["orgId"] = new TypeConstraint<Guid>(),
                    ["projectId"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            ),
            new RouteEndpoint(
                "/organizations/{orgId:guid}/projects/{projectId:guid}/tasks/{taskId:guid}",
                typeof(GetTask),
                HttpMethod.Get,
                null,
                new Dictionary<string, IRouteConstraint>
                {
                    ["orgId"] = new TypeConstraint<Guid>(),
                    ["projectId"] = new TypeConstraint<Guid>(),
                    ["taskId"] = new TypeConstraint<Guid>()
                }.ToFrozenDictionary(),
                FrozenDictionary<string, object>.Empty
            )
        };
    }
}

// Advanced test route definitions
public static class AdvancedTestRoutes
{
    public static class V1
    {
        public record Products : IVersionedRoute<Products>
        {
            public static ApiVersion Version => new(1, 0);
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;
        }
    }

    public static class V2
    {
        public record Products : IVersionedRoute<Products>
        {
            public static ApiVersion Version => new(2, 0);
            public static FrozenDictionary<string, object> Metadata { get; } =
                FrozenDictionary<string, object>.Empty;

            public record ById(Guid Id) : IRoute<ById>
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

                    public record Tasks : IRoute<Tasks>
                    {
                        public static FrozenDictionary<string, object> Metadata { get; } =
                            FrozenDictionary<string, object>.Empty;

                        public record ById(
                            Guid OrgId,
                            Guid ProjectId,
                            Guid TaskId
                        ) : IRoute<ById>
                        {
                            public Projects.ById ProjectParent => new(OrgId, ProjectId);

                            public static FrozenDictionary<string, object> Metadata { get; } =
                                FrozenDictionary<string, object>.Empty;
                        }
                    }
                }
            }
        }
    }

    public record LegacyProducts : IAlternativeRoute<LegacyProducts>
    {
        public static FrozenDictionary<string, object> Metadata { get; } =
            FrozenDictionary<string, object>.Empty;

        public static FrozenSet<string> AlternativeTemplates { get; } =
            new[] {"/api/products", "/legacy/products", "/v0/products"}.ToFrozenSet();
    }
}

public record ProductSearchQuery : QueryParameters, IQueryParameters
{
    [QueryParam]
    public string? Query { get; init; }

    [QueryParam]
    public ProductCategory? Category { get; init; }

    [QueryParam]
    [RangeAttribute<double>(0.0, 10000.0)]
    public decimal? MinPrice { get; init; }

    [QueryParam]
    [RangeAttribute<double>(0.0, 10000.0)]
    public decimal? MaxPrice { get; init; }

    [QueryParam]
    public bool InStock { get; init; } = false;

    [QueryParam]
    public IReadOnlyList<string> Tags { get; init; } = Array.Empty<string>();

    public static new QueryParameterMetadata GetMetadata() =>
        QueryParameterMetadataGenerator.Generate<ProductSearchQuery>();
}

public enum ProductCategory
{
    Electronics,
    Clothing,
    Books,
    Home,
    Sports
}

// Mock endpoint types
public class GetProductsV1 { }
public class GetProductsV2 { }
public class GetProductV2 { }
public class GetProducts { }
public class GetOrganization { }
