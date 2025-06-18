using System.CommandLine;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using AxiomEndpoints.ProtoGen.Core;
using AxiomEndpoints.ProtoGen.Writers;
using AxiomEndpoints.ProtoGen.Compilation;

var rootCommand = new RootCommand("Axiom Endpoints Proto Generator - Generate gRPC types from C# endpoints");

// Generate command
var generateCommand = new Command("generate", "Generate proto files from assemblies");

var assemblyOption = new Option<FileInfo>("--assembly", "Path to the assembly containing Axiom endpoints") { IsRequired = true };
var outputOption = new Option<DirectoryInfo>("--output", "Output directory") { IsRequired = true };
var verboseOption = new Option<bool>("--verbose", "Enable verbose logging");

generateCommand.AddOption(assemblyOption);
generateCommand.AddOption(outputOption);
generateCommand.AddOption(verboseOption);

generateCommand.SetHandler(async (context) =>
{
    var assemblyFile = context.ParseResult.GetValueForOption(assemblyOption)!;
    var outputDir = context.ParseResult.GetValueForOption(outputOption)!;
    var verbose = context.ParseResult.GetValueForOption(verboseOption);
    
    var host = CreateHost(verbose);
    var logger = host.Services.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("Starting proto generation for assembly: {Assembly}", assemblyFile.FullName);
        
        var generator = host.Services.GetRequiredService<ProtoTypeGenerator>();
        
        // Load assembly
        var assembly = Assembly.LoadFrom(assemblyFile.FullName);
        
        // Generate proto content
        var protoContent = await generator.GenerateProtoFromAssemblyAsync(assembly);
        
        // Write to output directory
        var outputFile = Path.Combine(outputDir.FullName, "generated.proto");
        await File.WriteAllTextAsync(outputFile, protoContent);
        
        logger.LogInformation("Proto generation completed successfully");
        logger.LogInformation("Generated file: {OutputFile}", outputFile);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred during proto generation");
        Environment.Exit(1);
    }
});

// Version command
var versionCommand = new Command("version", "Show version information");
versionCommand.SetHandler(() =>
{
    var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "1.0.0";
    Console.WriteLine($"Axiom Endpoints Proto Generator v{version}");
    Console.WriteLine("Generate gRPC types from C# endpoints");
});

// Add commands to root
rootCommand.AddCommand(generateCommand);
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
            services.AddSingleton<ProtoGeneratorOptions>(provider => new ProtoGeneratorOptions
            {
                PackageName = "axiom_generated",
                Organization = "axiom",
                IncludeValidation = true,
                IncludeDocumentation = true,
                GenerateServices = true
            });
            services.AddSingleton<ProtoTypeGenerator>();
            services.AddSingleton<ProtoFileWriter>();
            services.AddSingleton<ProtocCompiler>();
        })
        .Build();
}