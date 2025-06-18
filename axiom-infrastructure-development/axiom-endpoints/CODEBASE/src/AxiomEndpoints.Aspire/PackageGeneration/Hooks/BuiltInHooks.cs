using Microsoft.Extensions.Logging;

namespace AxiomEndpoints.Aspire.PackageGeneration.Hooks;

/// <summary>
/// Hook that validates output directories exist and are writable
/// </summary>
public class OutputDirectoryValidationHook : IPreGenerationHook
{
    private readonly ILogger<OutputDirectoryValidationHook> _logger;

    public OutputDirectoryValidationHook(ILogger<OutputDirectoryValidationHook> logger)
    {
        _logger = logger;
    }

    public string Name => "OutputDirectoryValidation";
    public int Priority => 10;
    public GenerationPhase SupportedPhases => GenerationPhase.PreGeneration;

    public async Task<HookResult> ExecuteAsync(PreGenerationContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var baseOutputDir = Path.GetFullPath(context.Options.BaseOutputPath);
            
            // Create base directory if it doesn't exist
            if (!Directory.Exists(baseOutputDir))
            {
                Directory.CreateDirectory(baseOutputDir);
                _logger.LogInformation("Created base output directory: {Directory}", baseOutputDir);
            }

            // Test write access
            var testFile = Path.Combine(baseOutputDir, $".write_test_{Guid.NewGuid()}");
            try
            {
                await File.WriteAllTextAsync(testFile, "test", cancellationToken);
                File.Delete(testFile);
            }
            catch (Exception ex)
            {
                return HookResult.Failed($"Cannot write to output directory '{baseOutputDir}': {ex.Message}");
            }

            // Check and create language-specific directories
            foreach (var (language, config) in context.Options.Languages)
            {
                var languageDir = Path.GetFullPath(config.OutputPath);
                
                if (!Directory.Exists(languageDir))
                {
                    Directory.CreateDirectory(languageDir);
                    _logger.LogInformation("Created {Language} output directory: {Directory}", language, languageDir);
                }
            }

            return HookResult.Successful("Output directories validated and prepared");
        }
        catch (Exception ex)
        {
            return HookResult.Failed($"Failed to validate output directories: {ex.Message}");
        }
    }
}

/// <summary>
/// Hook that cleans output directories before generation
/// </summary>
public class CleanOutputHook : IPreLanguageGenerationHook
{
    private readonly ILogger<CleanOutputHook> _logger;

    public CleanOutputHook(ILogger<CleanOutputHook> logger)
    {
        _logger = logger;
    }

    public string Name => "CleanOutput";
    public int Priority => 5;
    public GenerationPhase SupportedPhases => GenerationPhase.PreLanguageGeneration;

    public async Task<HookResult> ExecuteAsync(PreLanguageGenerationContext context, CancellationToken cancellationToken = default)
    {
        if (!context.LanguageConfig.CleanOutput)
        {
            return HookResult.Successful("Clean output disabled for this language");
        }

        try
        {
            var outputDir = Path.GetFullPath(context.LanguageConfig.OutputPath);
            
            if (Directory.Exists(outputDir))
            {
                var files = Directory.GetFiles(outputDir, "*", SearchOption.AllDirectories);
                var filesToDelete = files.Where(f => ShouldDeleteFile(f)).ToList();

                foreach (var file in filesToDelete)
                {
                    File.Delete(file);
                }

                // Remove empty directories
                var directories = Directory.GetDirectories(outputDir, "*", SearchOption.AllDirectories)
                    .OrderByDescending(d => d.Length); // Delete deepest first

                foreach (var dir in directories)
                {
                    if (!Directory.EnumerateFileSystemEntries(dir).Any())
                    {
                        Directory.Delete(dir);
                    }
                }

                _logger.LogInformation("Cleaned {FileCount} files from {Language} output directory", 
                    filesToDelete.Count, context.Language);
            }

            return HookResult.Successful($"Cleaned output directory for {context.Language}");
        }
        catch (Exception ex)
        {
            return HookResult.Failed($"Failed to clean output directory: {ex.Message}");
        }
    }

    private static bool ShouldDeleteFile(string filePath)
    {
        var fileName = Path.GetFileName(filePath);
        var extension = Path.GetExtension(filePath).ToLowerInvariant();

        // Don't delete user-created files
        var preservedFiles = new[] { "readme.md", ".gitignore", "license", "changelog.md" };
        if (preservedFiles.Contains(fileName.ToLowerInvariant()))
            return false;

        // Delete generated code files
        var generatedExtensions = new[] { ".swift", ".kt", ".cs", ".ts", ".proto", ".json", ".xml", ".yaml" };
        return generatedExtensions.Contains(extension);
    }
}

/// <summary>
/// Hook that generates package metadata files
/// </summary>
public class PackageMetadataHook : IPostLanguageGenerationHook
{
    private readonly ILogger<PackageMetadataHook> _logger;

    public PackageMetadataHook(ILogger<PackageMetadataHook> logger)
    {
        _logger = logger;
    }

    public string Name => "PackageMetadata";
    public int Priority => 20;
    public GenerationPhase SupportedPhases => GenerationPhase.PostLanguageGeneration;

    public async Task<HookResult> ExecuteAsync(PostLanguageGenerationContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var outputDir = Path.GetFullPath(context.LanguageConfig.OutputPath);
            
            switch (context.Language)
            {
                case PackageLanguage.Swift:
                    await GenerateSwiftPackageManifestAsync(outputDir, context, cancellationToken);
                    break;
                case PackageLanguage.Kotlin:
                    await GenerateKotlinBuildFileAsync(outputDir, context, cancellationToken);
                    break;
                case PackageLanguage.CSharp:
                    await GenerateCSharpProjectFileAsync(outputDir, context, cancellationToken);
                    break;
                case PackageLanguage.TypeScript:
                    await GenerateTypeScriptPackageFilesAsync(outputDir, context, cancellationToken);
                    break;
            }

            // Generate common files
            if (context.LanguageConfig.IncludeDocumentation)
            {
                await GenerateReadmeAsync(outputDir, context, cancellationToken);
            }

            return HookResult.Successful($"Generated metadata files for {context.Language}");
        }
        catch (Exception ex)
        {
            return HookResult.Failed($"Failed to generate metadata files: {ex.Message}");
        }
    }

    private async Task GenerateSwiftPackageManifestAsync(string outputDir, PostLanguageGenerationContext context, CancellationToken cancellationToken)
    {
        var manifest = $@"// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: ""{context.LanguageConfig.PackageName}"",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: ""{context.LanguageConfig.PackageName}"",
            targets: [""{context.LanguageConfig.PackageName}""]
        )
    ],
    dependencies: [
        .package(url: ""https://github.com/apple/swift-protobuf.git"", from: ""1.25.0""),
        .package(url: ""https://github.com/grpc/grpc-swift.git"", from: ""1.8.0"")
    ],
    targets: [
        .target(
            name: ""{context.LanguageConfig.PackageName}"",
            dependencies: [
                .product(name: ""SwiftProtobuf"", package: ""swift-protobuf""),
                .product(name: ""GRPC"", package: ""grpc-swift"")
            ]
        )
    ]
)
";

        var manifestPath = Path.Combine(outputDir, "Package.swift");
        await File.WriteAllTextAsync(manifestPath, manifest, cancellationToken);
        _logger.LogInformation("Generated Swift Package.swift manifest");
    }

    private async Task GenerateKotlinBuildFileAsync(string outputDir, PostLanguageGenerationContext context, CancellationToken cancellationToken)
    {
        var buildFile = $@"plugins {{{{
    kotlin(""jvm"") version ""1.9.20""
    `maven-publish`
}}}}

group = ""{GetKotlinGroupId(context.LanguageConfig.PackageName)}""
version = ""{context.LanguageConfig.Version}""

repositories {{{{
    mavenCentral()
}}}}

dependencies {{{{
    implementation(""com.google.protobuf:protobuf-kotlin:3.25.0"")
    implementation(""io.grpc:grpc-kotlin-stub:1.4.0"")
    implementation(""io.grpc:grpc-protobuf:1.59.0"")
    implementation(""org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3"")
}}}}

kotlin {{{{
    jvmToolchain(17)
}}}}
";

        var buildPath = Path.Combine(outputDir, "build.gradle.kts");
        await File.WriteAllTextAsync(buildPath, buildFile, cancellationToken);
        _logger.LogInformation("Generated Kotlin build.gradle.kts file");
    }

    private async Task GenerateCSharpProjectFileAsync(string outputDir, PostLanguageGenerationContext context, CancellationToken cancellationToken)
    {
        var projectFile = $@"<Project Sdk=""Microsoft.NET.Sdk"">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>12</LangVersion>
    <Nullable>enable</Nullable>
    <GeneratePackageOnBuild>true</GeneratePackageOnBuild>
    <PackageId>{context.LanguageConfig.PackageName}</PackageId>
    <PackageVersion>{context.LanguageConfig.Version}</PackageVersion>
    <Description>Generated gRPC client for {context.LanguageConfig.PackageName}</Description>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include=""Google.Protobuf"" Version=""3.25.0"" />
    <PackageReference Include=""Grpc.Net.Client"" Version=""2.59.0"" />
    <PackageReference Include=""Grpc.Tools"" Version=""2.59.0"" PrivateAssets=""All"" />
  </ItemGroup>

</Project>
";

        var projectPath = Path.Combine(outputDir, $"{context.LanguageConfig.PackageName}.csproj");
        await File.WriteAllTextAsync(projectPath, projectFile, cancellationToken);
        _logger.LogInformation("Generated C# project file");
    }

    private async Task GenerateTypeScriptPackageFilesAsync(string outputDir, PostLanguageGenerationContext context, CancellationToken cancellationToken)
    {
        // Generate package.json
        var packageJson = $@"{{
  ""name"": ""{context.LanguageConfig.PackageName}"",
  ""version"": ""{context.LanguageConfig.Version}"",
  ""description"": ""Generated TypeScript gRPC client for {context.LanguageConfig.PackageName}"",
  ""main"": ""dist/index.js"",
  ""types"": ""dist/index.d.ts"",
  ""files"": [
    ""dist/**/*"",
    ""src/**/*"",
    ""*.md""
  ],
  ""scripts"": {{
    ""build"": ""tsc"",
    ""build:watch"": ""tsc --watch"",
    ""clean"": ""rimraf dist"",
    ""prepublishOnly"": ""npm run clean && npm run build"",
    ""lint"": ""eslint src --ext .ts"",
    ""type-check"": ""tsc --noEmit""
  }},
  ""keywords"": [
    ""grpc"",
    ""grpc-web"",
    ""typescript"",
    ""protobuf"",
    ""api-client""
  ],
  ""author"": ""Generated by Axiom Endpoints"",
  ""license"": ""MIT"",
  ""dependencies"": {{
    ""@grpc/grpc-js"": ""^1.9.0"",
    ""grpc-web"": ""^1.4.2"",
    ""google-protobuf"": ""^3.25.0""
  }},
  ""devDependencies"": {{
    ""@types/google-protobuf"": ""^3.15.0"",
    ""@types/node"": ""^20.0.0"",
    ""@typescript-eslint/eslint-plugin"": ""^6.0.0"",
    ""@typescript-eslint/parser"": ""^6.0.0"",
    ""eslint"": ""^8.0.0"",
    ""rimraf"": ""^5.0.0"",
    ""typescript"": ""^5.3.0""
  }},
  ""peerDependencies"": {{
    ""typescript"": "">=4.7.0""
  }},
  ""engines"": {{
    ""node"": "">=16.0.0""
  }},
  ""repository"": {{
    ""type"": ""git"",
    ""url"": ""<repository-url>""
  }},
  ""bugs"": {{
    ""url"": ""<repository-url>/issues""
  }},
  ""homepage"": ""<repository-url>#readme""
}}
";

        var packageJsonPath = Path.Combine(outputDir, "package.json");
        await File.WriteAllTextAsync(packageJsonPath, packageJson, cancellationToken);
        _logger.LogInformation("Generated TypeScript package.json");

        // Generate tsconfig.json
        var tsconfigJson = $@"{{
  ""compilerOptions"": {{
    ""target"": ""ES2020"",
    ""lib"": [""ES2020"", ""DOM""],
    ""module"": ""commonjs"",
    ""moduleResolution"": ""node"",
    ""declaration"": true,
    ""declarationMap"": true,
    ""sourceMap"": true,
    ""outDir"": ""./dist"",
    ""rootDir"": ""./src"",
    ""strict"": true,
    ""noImplicitAny"": true,
    ""strictNullChecks"": true,
    ""strictFunctionTypes"": true,
    ""noImplicitReturns"": true,
    ""noFallthroughCasesInSwitch"": true,
    ""noUncheckedIndexedAccess"": true,
    ""exactOptionalPropertyTypes"": true,
    ""esModuleInterop"": true,
    ""skipLibCheck"": true,
    ""forceConsistentCasingInFileNames"": true,
    ""resolveJsonModule"": true,
    ""isolatedModules"": true,
    ""incremental"": true,
    ""noEmitOnError"": true
  }},
  ""include"": [
    ""src/**/*""
  ],
  ""exclude"": [
    ""node_modules"",
    ""dist"",
    ""**/*.test.ts"",
    ""**/*.spec.ts""
  ]
}}
";

        var tsconfigPath = Path.Combine(outputDir, "tsconfig.json");
        await File.WriteAllTextAsync(tsconfigPath, tsconfigJson, cancellationToken);
        _logger.LogInformation("Generated TypeScript tsconfig.json");

        // Generate .eslintrc.json
        var eslintConfig = $@"{{
  ""root"": true,
  ""parser"": ""@typescript-eslint/parser"",
  ""plugins"": [
    ""@typescript-eslint""
  ],
  ""extends"": [
    ""eslint:recommended"",
    ""@typescript-eslint/recommended"",
    ""@typescript-eslint/recommended-requiring-type-checking""
  ],
  ""parserOptions"": {{
    ""ecmaVersion"": 2020,
    ""sourceType"": ""module"",
    ""project"": ""./tsconfig.json""
  }},
  ""rules"": {{
    ""@typescript-eslint/no-unused-vars"": ""error"",
    ""@typescript-eslint/explicit-function-return-type"": ""warn"",
    ""@typescript-eslint/no-explicit-any"": ""warn"",
    ""@typescript-eslint/prefer-readonly"": ""error"",
    ""prefer-const"": ""error""
  }},
  ""env"": {{
    ""node"": true,
    ""browser"": true,
    ""es6"": true
  }}
}}
";

        var eslintPath = Path.Combine(outputDir, ".eslintrc.json");
        await File.WriteAllTextAsync(eslintPath, eslintConfig, cancellationToken);
        _logger.LogInformation("Generated TypeScript .eslintrc.json");

        // Generate .gitignore
        var gitignore = @"# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs
*.log

# Environment files
.env
.env.local
.env.*.local

# Coverage
coverage/
.nyc_output/
";

        var gitignorePath = Path.Combine(outputDir, ".gitignore");
        await File.WriteAllTextAsync(gitignorePath, gitignore, cancellationToken);
        _logger.LogInformation("Generated TypeScript .gitignore");
    }

    private async Task GenerateReadmeAsync(string outputDir, PostLanguageGenerationContext context, CancellationToken cancellationToken)
    {
        var readme = $@"# {context.LanguageConfig.PackageName}

Generated {context.Language} client package for gRPC services.

## Installation

{GetInstallationInstructions(context.Language, context.LanguageConfig)}

## Usage

```{GetLanguageCodeBlock(context.Language)}
// Example usage will be added here
```

## Generated Files

This package contains the following generated files:
{string.Join("\n", context.GenerationResult.GeneratedFiles.Select(f => $"- {f.RelativePath}"))}

## Version

Package version: {context.LanguageConfig.Version}
Generated on: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC

---
Generated by Axiom Endpoints Package Generator
";

        var readmePath = Path.Combine(outputDir, "README.md");
        await File.WriteAllTextAsync(readmePath, readme, cancellationToken);
        _logger.LogInformation("Generated README.md file");
    }

    private static string GetKotlinGroupId(string packageName)
    {
        if (packageName.Contains('.'))
            return string.Join(".", packageName.Split('.').Take(packageName.Split('.').Length - 1));
        return "com.example";
    }

    private static string GetInstallationInstructions(PackageLanguage language, LanguagePackageConfig config)
    {
        return language switch
        {
            PackageLanguage.Swift => $"Add this package to your Package.swift dependencies:\n\n```swift\n.package(url: \"<repository-url>\", from: \"{config.Version}\")\n```",
            PackageLanguage.Kotlin => $"Add to your build.gradle.kts:\n\n```kotlin\nimplementation(\"{config.PackageName}:{config.Version}\")\n```",
            PackageLanguage.CSharp => $"Install via NuGet:\n\n```bash\ndotnet add package {config.PackageName} --version {config.Version}\n```",
            PackageLanguage.TypeScript => $"Install via npm:\n\n```bash\nnpm install {config.PackageName}@{config.Version}\n```\n\nOr with yarn:\n\n```bash\nyarn add {config.PackageName}@{config.Version}\n```",
            _ => "Installation instructions not available."
        };
    }

    private static string GetLanguageCodeBlock(PackageLanguage language)
    {
        return language switch
        {
            PackageLanguage.Swift => "swift",
            PackageLanguage.Kotlin => "kotlin",
            PackageLanguage.CSharp => "csharp",
            PackageLanguage.TypeScript => "typescript",
            _ => "text"
        };
    }
}

/// <summary>
/// Hook that sends notifications about generation completion
/// </summary>
public class NotificationHook : IPostGenerationHook
{
    private readonly ILogger<NotificationHook> _logger;

    public NotificationHook(ILogger<NotificationHook> logger)
    {
        _logger = logger;
    }

    public string Name => "Notification";
    public int Priority => 100;
    public GenerationPhase SupportedPhases => GenerationPhase.PostGeneration;

    public async Task<HookResult> ExecuteAsync(PostGenerationContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = context.FinalResult;
            var message = $"Package generation completed successfully. Generated {result.GeneratedPackages.Count} packages in {result.Duration.TotalSeconds:F1} seconds.";
            
            _logger.LogInformation(message);

            // Here you could add integration with notification systems:
            // - Slack notifications
            // - Email notifications  
            // - Teams notifications
            // - Custom webhooks
            
            return HookResult.Successful(message);
        }
        catch (Exception ex)
        {
            return HookResult.Failed($"Failed to send notifications: {ex.Message}");
        }
    }
}