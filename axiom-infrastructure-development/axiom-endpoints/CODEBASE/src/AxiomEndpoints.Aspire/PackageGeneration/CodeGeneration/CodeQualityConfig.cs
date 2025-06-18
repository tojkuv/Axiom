namespace AxiomEndpoints.Aspire.PackageGeneration.CodeGeneration;

/// <summary>
/// Configuration for code quality and generation polish
/// </summary>
public class CodeQualityConfig
{
    /// <summary>
    /// Follow language-specific style guides
    /// </summary>
    public bool FollowStyleGuides { get; set; } = true;

    /// <summary>
    /// Generate comprehensive documentation
    /// </summary>
    public DocumentationConfig Documentation { get; set; } = new();

    /// <summary>
    /// Type safety configurations
    /// </summary>
    public TypeSafetyConfig TypeSafety { get; set; } = new();

    /// <summary>
    /// Performance optimization settings
    /// </summary>
    public PerformanceConfig Performance { get; set; } = new();

    /// <summary>
    /// Code organization and structure
    /// </summary>
    public CodeOrganizationConfig Organization { get; set; } = new();

    /// <summary>
    /// Testing and validation generation
    /// </summary>
    public TestingConfig Testing { get; set; } = new();
}

/// <summary>
/// Documentation generation configuration
/// </summary>
public class DocumentationConfig
{
    /// <summary>
    /// Generate inline code documentation
    /// </summary>
    public bool GenerateInlineComments { get; set; } = true;

    /// <summary>
    /// Generate API documentation files
    /// </summary>
    public bool GenerateApiDocs { get; set; } = true;

    /// <summary>
    /// Generate usage examples
    /// </summary>
    public bool GenerateExamples { get; set; } = true;

    /// <summary>
    /// Generate README files
    /// </summary>
    public bool GenerateReadme { get; set; } = true;

    /// <summary>
    /// Generate changelog
    /// </summary>
    public bool GenerateChangelog { get; set; } = false;

    /// <summary>
    /// Documentation style
    /// </summary>
    public DocumentationStyle Style { get; set; } = DocumentationStyle.Comprehensive;

    /// <summary>
    /// Include performance notes in documentation
    /// </summary>
    public bool IncludePerformanceNotes { get; set; } = false;
}

/// <summary>
/// Type safety configuration
/// </summary>
public class TypeSafetyConfig
{
    /// <summary>
    /// Generate nullability annotations
    /// </summary>
    public bool NullabilityAnnotations { get; set; } = true;

    /// <summary>
    /// Use immutable types where possible
    /// </summary>
    public bool PreferImmutableTypes { get; set; } = true;

    /// <summary>
    /// Generate strong typing for IDs and values
    /// </summary>
    public bool StronglyTypedIds { get; set; } = false;

    /// <summary>
    /// Generate validation attributes
    /// </summary>
    public bool ValidationAttributes { get; set; } = true;

    /// <summary>
    /// Use generic type constraints
    /// </summary>
    public bool GenericConstraints { get; set; } = true;
}

/// <summary>
/// Performance optimization configuration
/// </summary>
public class PerformanceConfig
{
    /// <summary>
    /// Enable lazy loading patterns
    /// </summary>
    public bool LazyLoading { get; set; } = false;

    /// <summary>
    /// Optimize for memory usage
    /// </summary>
    public bool MemoryOptimizations { get; set; } = false;

    /// <summary>
    /// Generate async/await patterns
    /// </summary>
    public bool AsyncPatterns { get; set; } = true;

    /// <summary>
    /// Use efficient serialization
    /// </summary>
    public bool OptimizedSerialization { get; set; } = true;

    /// <summary>
    /// Generate caching hints
    /// </summary>
    public bool CachingHints { get; set; } = false;
}

/// <summary>
/// Code organization configuration
/// </summary>
public class CodeOrganizationConfig
{
    /// <summary>
    /// Organize code by feature
    /// </summary>
    public bool OrganizeByFeature { get; set; } = true;

    /// <summary>
    /// Generate separate files for types
    /// </summary>
    public bool SeparateFilePerType { get; set; } = true;

    /// <summary>
    /// Use consistent naming conventions
    /// </summary>
    public bool ConsistentNaming { get; set; } = true;

    /// <summary>
    /// Group related functionality
    /// </summary>
    public bool GroupRelatedCode { get; set; } = true;

    /// <summary>
    /// Generate namespace/module structure
    /// </summary>
    public bool StructuredNamespaces { get; set; } = true;
}

/// <summary>
/// Testing configuration
/// </summary>
public class TestingConfig
{
    /// <summary>
    /// Generate unit tests
    /// </summary>
    public bool GenerateUnitTests { get; set; } = false;

    /// <summary>
    /// Generate mock objects
    /// </summary>
    public bool GenerateMocks { get; set; } = false;

    /// <summary>
    /// Generate test utilities
    /// </summary>
    public bool GenerateTestUtilities { get; set; } = false;

    /// <summary>
    /// Generate integration test examples
    /// </summary>
    public bool GenerateIntegrationExamples { get; set; } = false;
}

/// <summary>
/// Documentation styles
/// </summary>
public enum DocumentationStyle
{
    /// <summary>
    /// Minimal documentation
    /// </summary>
    Minimal,

    /// <summary>
    /// Standard documentation
    /// </summary>
    Standard,

    /// <summary>
    /// Comprehensive documentation with examples
    /// </summary>
    Comprehensive,

    /// <summary>
    /// Tutorial-style documentation
    /// </summary>
    Tutorial
}

/// <summary>
/// Code generation templates for different quality levels
/// </summary>
public static class CodeQualityTemplates
{
    public static CodeQualityConfig HighQuality => new()
    {
        FollowStyleGuides = true,
        Documentation = new DocumentationConfig
        {
            GenerateInlineComments = true,
            GenerateApiDocs = true,
            GenerateExamples = true,
            GenerateReadme = true,
            Style = DocumentationStyle.Comprehensive,
            IncludePerformanceNotes = true
        },
        TypeSafety = new TypeSafetyConfig
        {
            NullabilityAnnotations = true,
            PreferImmutableTypes = true,
            StronglyTypedIds = true,
            ValidationAttributes = true,
            GenericConstraints = true
        },
        Performance = new PerformanceConfig
        {
            LazyLoading = true,
            MemoryOptimizations = true,
            AsyncPatterns = true,
            OptimizedSerialization = true,
            CachingHints = true
        },
        Organization = new CodeOrganizationConfig
        {
            OrganizeByFeature = true,
            SeparateFilePerType = true,
            ConsistentNaming = true,
            GroupRelatedCode = true,
            StructuredNamespaces = true
        },
        Testing = new TestingConfig
        {
            GenerateUnitTests = true,
            GenerateMocks = true,
            GenerateTestUtilities = true,
            GenerateIntegrationExamples = true
        }
    };

    public static CodeQualityConfig Standard => new()
    {
        FollowStyleGuides = true,
        Documentation = new DocumentationConfig
        {
            GenerateInlineComments = true,
            GenerateApiDocs = true,
            GenerateExamples = true,
            GenerateReadme = true,
            Style = DocumentationStyle.Standard
        },
        TypeSafety = new TypeSafetyConfig
        {
            NullabilityAnnotations = true,
            PreferImmutableTypes = true,
            ValidationAttributes = true
        },
        Performance = new PerformanceConfig
        {
            AsyncPatterns = true,
            OptimizedSerialization = true
        },
        Organization = new CodeOrganizationConfig
        {
            OrganizeByFeature = true,
            SeparateFilePerType = true,
            ConsistentNaming = true,
            GroupRelatedCode = true
        }
    };

    public static CodeQualityConfig Minimal => new()
    {
        FollowStyleGuides = true,
        Documentation = new DocumentationConfig
        {
            GenerateInlineComments = true,
            Style = DocumentationStyle.Minimal
        },
        TypeSafety = new TypeSafetyConfig
        {
            NullabilityAnnotations = true
        },
        Performance = new PerformanceConfig
        {
            AsyncPatterns = true
        },
        Organization = new CodeOrganizationConfig
        {
            ConsistentNaming = true
        }
    };
}