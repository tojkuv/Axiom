using FluentAssertions;
using FluentAssertions.Execution;
using FluentAssertions.Primitives;
using AxiomEndpoints.Core;
using AxiomEndpoints.Routing;

namespace AxiomEndpoints.Testing.Common.Assertions;

public static class RouteAssertionExtensions
{
    public static RouteAssertions Should(this Type routeType) => new(routeType);
    public static RouteTemplateAssertions Should(this string template) => new(template);
    public static RouteMatchAssertions Should(this bool matchResult) => new(matchResult);
}

public class RouteAssertions : ReferenceTypeAssertions<Type, RouteAssertions>
{
    public RouteAssertions(Type instance) : base(instance) { }

    protected override string Identifier => "route type";

    public AndConstraint<RouteAssertions> ImplementIRoute(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .Given(() => Subject)
            .ForCondition(type => type != null)
            .FailWith("Expected route type to implement IRoute, but found <null>.")
            .Then
            .ForCondition(type => type!.GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IRoute<>)))
            .FailWith("Expected {0} to implement IRoute<T>, but it does not.", Subject);

        return new AndConstraint<RouteAssertions>(this);
    }

    public AndConstraint<RouteAssertions> HaveTemplate(string expectedTemplate, string because = "", params object[] becauseArgs)
    {
        var actualTemplate = RouteTemplateGenerator.Generate(Subject!);

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(actualTemplate == expectedTemplate)
            .FailWith("Expected route {0} to have template {1}, but found {2}.", 
                Subject, expectedTemplate, actualTemplate);

        return new AndConstraint<RouteAssertions>(this);
    }

    public AndConstraint<RouteAssertions> MatchPath(string path, string because = "", params object[] becauseArgs)
    {
        var matches = RouteMatcher.TryMatch(Subject!, path, out _);

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(matches)
            .FailWith("Expected route {0} to match path {1}, but it does not.", Subject, path);

        return new AndConstraint<RouteAssertions>(this);
    }

    public AndConstraint<RouteAssertions> NotMatchPath(string path, string because = "", params object[] becauseArgs)
    {
        var matches = RouteMatcher.TryMatch(Subject!, path, out _);

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(!matches)
            .FailWith("Expected route {0} to not match path {1}, but it does.", Subject, path);

        return new AndConstraint<RouteAssertions>(this);
    }

    public AndConstraint<RouteAssertions> HaveMetadata(string because = "", params object[] becauseArgs)
    {
        var metadataProperty = Subject!.GetProperty("Metadata");

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(metadataProperty != null)
            .FailWith("Expected route {0} to have Metadata property, but it does not.", Subject)
            .Then
            .ForCondition(metadataProperty!.PropertyType == typeof(FrozenDictionary<string, object>))
            .FailWith("Expected route {0} Metadata to be FrozenDictionary<string, object>, but found {1}.", 
                Subject, metadataProperty.PropertyType);

        return new AndConstraint<RouteAssertions>(this);
    }
}

public class RouteTemplateAssertions : StringAssertions
{
    public RouteTemplateAssertions(string instance) : base(instance) { }

    public AndConstraint<RouteTemplateAssertions> BeValidTemplate(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(!string.IsNullOrEmpty(Subject))
            .FailWith("Expected template to be valid, but found null or empty.")
            .Then
            .ForCondition(Subject!.StartsWith('/'))
            .FailWith("Expected template {0} to start with '/', but it does not.", Subject);

        return new AndConstraint<RouteTemplateAssertions>(this);
    }

    public AndConstraint<RouteTemplateAssertions> HaveParameter(string parameterName, string because = "", params object[] becauseArgs)
    {
        var expectedPattern = $"{{{parameterName}}}";

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject?.Contains(expectedPattern) == true)
            .FailWith("Expected template {0} to contain parameter {1}, but it does not.", Subject, parameterName);

        return new AndConstraint<RouteTemplateAssertions>(this);
    }

    public AndConstraint<RouteTemplateAssertions> NotHaveParameter(string parameterName, string because = "", params object[] becauseArgs)
    {
        var expectedPattern = $"{{{parameterName}}}";

        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject?.Contains(expectedPattern) != true)
            .FailWith("Expected template {0} to not contain parameter {1}, but it does.", Subject, parameterName);

        return new AndConstraint<RouteTemplateAssertions>(this);
    }
}

public class RouteMatchAssertions : BooleanAssertions
{
    public RouteMatchAssertions(bool instance) : base(instance) { }

    public new AndConstraint<RouteMatchAssertions> BeTrue(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject == true)
            .FailWith("Expected route to match, but it does not.");

        return new AndConstraint<RouteMatchAssertions>(this);
    }

    public new AndConstraint<RouteMatchAssertions> BeFalse(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject == false)
            .FailWith("Expected route to not match, but it does.");

        return new AndConstraint<RouteMatchAssertions>(this);
    }
}