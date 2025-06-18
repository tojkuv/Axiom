using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;
using System.Collections.Frozen;

namespace AxiomEndpointsExample.Api;

public static class Routes
{
    // Health check route
    public record Health() : IRoute<Health>
    {
        public static string Pattern => "/health";
        public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
    }

    // V1 API routes
    public static class V1
    {
        public static class Users
        {
            // Simple routes
            public record Index() : IRoute<Index>
            {
                public static string Pattern => "/v1/users";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            public record ById(
                Guid Id
            ) : IRoute<ById>
            {
                public static string Pattern => "/v1/users/{Id}";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            public record ByEmail(
                string Email
            ) : IRoute<ByEmail>
            {
                public static string Pattern => "/v1/users/email/{Email}";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            // Query parameter routes
            public record Search(UserSearchQuery Query) : IRoute<Search>
            {
                public static string Pattern => "/v1/users/search";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            // Performance demonstration routes - Caching
            public record Stats(Guid UserId) : IRoute<Stats>
            {
                public static string Pattern => "/v1/users/{UserId}/stats";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["cache"] = "5min",
                    ["description"] = "User statistics with caching"
                }.ToFrozenDictionary();
            }

            public record Active() : IRoute<Active>
            {
                public static string Pattern => "/v1/users/active";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["cache"] = "10min",
                    ["description"] = "Active users list with caching"
                }.ToFrozenDictionary();
            }
        }

        public static class Posts
        {
            public record Index() : IRoute<Index>
            {
                public static string Pattern => "/v1/posts";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            public record ById(int Id) : IRoute<ById>
            {
                public static string Pattern => "/v1/posts/{Id}";
                public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
            }

            // Performance demonstration - Caching
            public record Recent(int? Limit = null) : IRoute<Recent>
            {
                public static string Pattern => "/v1/posts/recent";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["cache"] = "3min",
                    ["description"] = "Recent posts with caching"
                }.ToFrozenDictionary();
            }
        }

        // Performance demonstration - Expensive operations with caching
        public static class Data
        {
            public record Expensive(string Key) : IRoute<Expensive>
            {
                public static string Pattern => "/v1/data/expensive/{Key}";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["cache"] = "30min",
                    ["description"] = "Expensive computation with long-term caching"
                }.ToFrozenDictionary();
            }
        }

        // Performance demonstration - Object pooling with report generation
        public static class Reports
        {
            public record User(Guid UserId) : IRoute<User>
            {
                public static string Pattern => "/v1/reports/user/{UserId}";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["objectPooling"] = "true",
                    ["description"] = "User report generation with object pooling"
                }.ToFrozenDictionary();
            }

            public record Large(string? Type = null) : IRoute<Large>
            {
                public static string Pattern => "/v1/reports/large";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["objectPooling"] = "true",
                    ["compression"] = "true",
                    ["description"] = "Large report generation with object pooling and compression"
                }.ToFrozenDictionary();
            }
        }

        // Performance demonstration - Metrics and monitoring
        public static class Metrics
        {
            public record Performance() : IRoute<Performance>
            {
                public static string Pattern => "/v1/metrics/performance";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["monitoring"] = "true",
                    ["description"] = "Performance metrics collected by monitoring middleware"
                }.ToFrozenDictionary();
            }
        }

        // Performance demonstration - Test endpoints
        public static class Test
        {
            public record Slow(int? DelayMs = null) : IRoute<Slow>
            {
                public static string Pattern => "/v1/test/slow";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["monitoring"] = "true",
                    ["description"] = "Intentionally slow endpoint for performance monitoring demonstration"
                }.ToFrozenDictionary();
            }

            public record CacheStress(int? Iterations = null) : IRoute<CacheStress>
            {
                public static string Pattern => "/v1/test/cache-stress";
                public static FrozenDictionary<string, object> Metadata => new Dictionary<string, object>
                {
                    ["cache"] = "true",
                    ["stress"] = "true",
                    ["description"] = "Cache stress test endpoint"
                }.ToFrozenDictionary();
            }
        }
    }

    // V2 API routes with hierarchical structure
    public static class V2
    {
        public static class Users
        {
            public static class ById
            {
                // User posts (hierarchical route)
                public record Posts(Guid UserId) : IRoute<Posts>
                {
                    public static string Pattern => "/v2/users/{UserId}/posts";
                    public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
                }

                public static class Post
                {
                    public static class ById
                    {
                        // Post comments (deep hierarchical route)
                        public record Comments(Guid UserId, int PostId) : IRoute<Comments>
                        {
                            public static string Pattern => "/v2/users/{UserId}/posts/{PostId}/comments";
                            public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
                        }
                    }
                }
            }
        }

        public static class Organizations
        {
            public static class ById
            {
                // Organization projects
                public record Projects : IRoute<Projects>
                {
                    public Guid OrgId { get; init; }
                    public static string Pattern => "/v2/organizations/{OrgId}/projects";
                    public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
                }
            }
        }
    }

    // File routes with optional parameters
    public static class Files
    {
        public record ByPath(
            string Path,
            string? Version = null
        ) : IRoute<ByPath>
        {
            public static string Pattern => "/files/{Path}/{Version?}";
            public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
        }
    }

    // Legacy API support (alternative routes)
    public record LegacyApi() : IRoute<LegacyApi>
    {
        public static string Pattern => "/legacy-api";
        public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
    }

    // Streaming routes
    public static class Stream
    {
        public record Events() : IRoute<Events>
        {
            public static string Pattern => "/stream/events";
            public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
        }

        public record Chat() : IRoute<Chat>
        {
            public static string Pattern => "/stream/chat";
            public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
        }

        public record Metrics() : IRoute<Metrics>
        {
            public static string Pattern => "/stream/metrics";
            public static FrozenDictionary<string, object> Metadata => FrozenDictionary<string, object>.Empty;
        }
    }
}