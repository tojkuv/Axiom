using System.CommandLine;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.ProtoGen.Core;
using AxiomEndpoints.ProtoGen.Writers;
using AxiomEndpoints.ProtoGen.Compilation;
using AxiomEndpoints.ProtoGen.Packaging;
using AxiomEndpoints.ProtoGen.Publishing;

var rootCommand = new RootCommand("Axiom Endpoints Proto Generator - Generate gRPC types from C# endpoints");

// Generate command
var generateCommand = new Command("generate", "Generate proto files and packages from assemblies");

var assemblyOption = new Option<FileInfo>("--assembly", "Path to the assembly containing Axiom endpoints") { IsRequired = true };
var outputOption = new Option<DirectoryInfo>("--output", "Output directory") { IsRequired = true };
var languagesOption = new Option<string[]>("--languages", "Target languages (swift, kotlin, csharp, java, typescript)") { IsRequired = true };
var packageNameOption = new Option<string>("--package-name", "Package name (defaults to assembly name)");
var versionOption = new Option<string>("--version", "Package version (defaults to assembly version or 1.0.0)");
var organizationOption = new Option<string>("--organization", "Organization/company name");
var authorsOption = new Option<string>("--authors", "Package authors");
var descriptionOption = new Option<string>("--description", "Package description");
var repositoryOption = new Option<string>("--repository", "Repository URL");
var verboseOption = new Option<bool>("--verbose", "Enable verbose logging");

generateCommand.AddOption(assemblyOption);
generateCommand.AddOption(outputOption);
generateCommand.AddOption(languagesOption);
generateCommand.AddOption(packageNameOption);
generateCommand.AddOption(versionOption);
generateCommand.AddOption(organizationOption);
generateCommand.AddOption(authorsOption);
generateCommand.AddOption(descriptionOption);
generateCommand.AddOption(repositoryOption);
generateCommand.AddOption(verboseOption);

generateCommand.SetHandler(async (context) =>
{
    var assemblyFile = context.ParseResult.GetValueForOption(assemblyOption)!;
    var outputDir = context.ParseResult.GetValueForOption(outputOption)!;
    var languages = context.ParseResult.GetValueForOption(languagesOption)!;
    var packageName = context.ParseResult.GetValueForOption(packageNameOption);
    var version = context.ParseResult.GetValueForOption(versionOption);
    var organization = context.ParseResult.GetValueForOption(organizationOption);
    var authors = context.ParseResult.GetValueForOption(authorsOption);
    var description = context.ParseResult.GetValueForOption(descriptionOption);
    var repository = context.ParseResult.GetValueForOption(repositoryOption);
    var verbose = context.ParseResult.GetValueForOption(verboseOption);
    
    var host = CreateHost(verbose);
    var logger = host.Services.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("Starting proto generation for assembly: {Assembly}", assemblyFile.FullName);
        
        var generator = host.Services.GetRequiredService<ProtoPackageService>();
        
        var options = new GenerateOptions
        {
            AssemblyPath = assemblyFile.FullName,
            OutputPath = outputDir.FullName,
            Languages = languages.Select(l => Enum.Parse<Language>(l, true)).ToList(),
            PackageName = packageName,
            Version = version,
            Organization = organization,
            Authors = authors ?? "",
            Description = description ?? "",
            RepositoryUrl = repository ?? ""
        };

        var result = await generator.GenerateAsync(options);
        
        if (result.Success)
        {
            logger.LogInformation("Proto generation completed successfully");
            logger.LogInformation("Generated packages:");
            foreach (var package in result.GeneratedPackages)
            {
                logger.LogInformation("  {Language}: {Path}", package.Language, package.PackagePath);
            }
        }
        else
        {
            logger.LogError("Proto generation failed: {Error}", result.Error);
            Environment.Exit(1);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred during proto generation");
        Environment.Exit(1);
    }
});

// Compile command
var compileCommand = new Command("compile", "Compile proto files to language-specific types");

var protoOption = new Option<DirectoryInfo>("--proto", "Path to proto files directory") { IsRequired = true };
var languageOption = new Option<string>("--language", "Target language") { IsRequired = true };
var compileOutputOption = new Option<DirectoryInfo>("--output", "Output directory for compiled types") { IsRequired = true };

compileCommand.AddOption(protoOption);
compileCommand.AddOption(languageOption);
compileCommand.AddOption(compileOutputOption);
compileCommand.AddOption(verboseOption);

compileCommand.SetHandler(async (protoDir, language, outputDir, verbose) =>
{
    var host = CreateHost(verbose);
    var logger = host.Services.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("Compiling proto files from: {ProtoDir}", protoDir.FullName);
        
        var compiler = host.Services.GetRequiredService<ProtocCompiler>();
        var targetLanguage = Enum.Parse<Language>(language, true);
        
        var protoFiles = Directory.GetFiles(protoDir.FullName, "*.proto", SearchOption.AllDirectories);
        var results = new List<CompilationResult>();
        
        foreach (var protoFile in protoFiles)
        {
            logger.LogInformation("Compiling {ProtoFile} for {Language}", Path.GetFileName(protoFile), targetLanguage);
            var result = await compiler.CompileAsync(protoFile, targetLanguage, outputDir.FullName);
            results.Add(result);
            
            if (!result.Success)
            {
                logger.LogError("Compilation failed for {ProtoFile}: {Error}", protoFile, result.Error);
            }
        }
        
        var successful = results.Count(r => r.Success);
        var total = results.Count;
        
        logger.LogInformation("Compilation completed: {Successful}/{Total} files compiled successfully", successful, total);
        
        if (successful < total)
        {
            Environment.Exit(1);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred during compilation");
        Environment.Exit(1);
    }
}, protoOption, languageOption, compileOutputOption, verboseOption);

// Publish command
var publishCommand = new Command("publish", "Publish generated packages to registries");

var packagePathOption = new Option<DirectoryInfo>("--path", "Path to package directory") { IsRequired = true };
var targetOption = new Option<string>("--target", "Publish target (github, nuget, maven, private)") { IsRequired = true };
var apiKeyOption = new Option<string>("--api-key", "API key for publishing");
var registryUrlOption = new Option<string>("--registry", "Registry URL for private publishing");

publishCommand.AddOption(packagePathOption);
publishCommand.AddOption(targetOption);
publishCommand.AddOption(apiKeyOption);
publishCommand.AddOption(registryUrlOption);
publishCommand.AddOption(verboseOption);

publishCommand.SetHandler(async (packagePath, target, apiKey, registryUrl, verbose) =>
{
    var host = CreateHost(verbose);
    var logger = host.Services.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("Publishing package from: {PackagePath}", packagePath.FullName);
        
        var publisher = host.Services.GetRequiredService<PackagePublishingService>();
        
        var publishOptions = new PublishOptions
        {
            PackagePath = packagePath.FullName,
            Target = Enum.Parse<PublishTarget>(target, true),
            ApiKey = apiKey,
            RegistryUrl = registryUrl
        };
        
        var result = await publisher.PublishAsync(publishOptions);
        
        if (result.Success)
        {
            logger.LogInformation("Package published successfully");
        }
        else
        {
            logger.LogError("Publishing failed: {Error}", result.Error);
            Environment.Exit(1);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred during publishing");
        Environment.Exit(1);
    }
}, packagePathOption, targetOption, apiKeyOption, registryUrlOption, verboseOption);

// Version command
var versionCommand = new Command("version", "Show version information");
versionCommand.SetHandler(() =>
{
    var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "1.0.0";
    Console.WriteLine($"Axiom Endpoints Proto Generator v{version}");
    Console.WriteLine("Generate gRPC types from C# endpoints for multiple languages");
});

// Add commands to root
rootCommand.AddCommand(generateCommand);
rootCommand.AddCommand(compileCommand);
rootCommand.AddCommand(publishCommand);
rootCommand.AddCommand(versionCommand);

// Run the CLI
return await rootCommand.InvokeAsync(args);

static IHost CreateHost(bool verbose)
{
    return Host.CreateDefaultBuilder()
        .ConfigureLogging(logging =>
        {
            logging.ClearProviders();
            logging.AddConsole();
            logging.SetMinimumLevel(verbose ? LogLevel.Debug : LogLevel.Information);
        })
        .ConfigureServices(services =>
        {
            // Register core services
            services.AddSingleton<ProtoTypeGenerator>(provider =>
            {
                var options = new ProtoGeneratorOptions
                {
                    IncludeValidation = true,
                    IncludeDocumentation = true,
                    GenerateServices = true
                };
                return new ProtoTypeGenerator(options);
            });
            
            services.AddSingleton<ProtoFileWriter>(provider =>
            {
                var options = new ProtoWriterOptions
                {
                    SplitLargeFiles = false,
                    IncludeDocumentation = true,
                    GenerateBufConfigs = true
                };
                return new ProtoFileWriter(options);
            });
            
            services.AddSingleton<ProtocCompiler>(provider =>
            {
                var logger = provider.GetRequiredService<ILogger<ProtocCompiler>>();
                var options = new ProtocOptions();
                return new ProtocCompiler(options, logger);
            });
            
            // Register package generators
            services.AddSingleton<IPackageGenerator, SwiftPackageGenerator>();
            services.AddSingleton<IPackageGenerator, KotlinPackageGenerator>();
            services.AddSingleton<IPackageGenerator, NuGetPackageGenerator>();
            
            // Register services
            services.AddSingleton<ProtoPackageService>();
            services.AddSingleton<PackagePublishingService>();
        })
        .Build();
}