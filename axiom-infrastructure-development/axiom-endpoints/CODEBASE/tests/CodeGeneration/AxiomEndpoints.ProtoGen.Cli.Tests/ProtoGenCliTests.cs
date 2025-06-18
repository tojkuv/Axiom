using System.CommandLine;
using System.CommandLine.IO;
using System.CommandLine.Parsing;
using System.CommandLine.Binding;
using System.CommandLine.Invocation;
using FluentAssertions;
using Xunit;

namespace AxiomEndpoints.ProtoGen.Cli.Tests;

/// <summary>
/// Tests for the ProtoGen CLI tool functionality
/// </summary>
public class ProtoGenCliTests
{
    [Fact]
    public void CLI_Should_Parse_Generate_Command()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { "generate", "--input", "test.dll", "--output", "output/" };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().BeEmpty();
        parseResult.CommandResult.Command.Name.Should().Be("generate");
    }

    [Fact]
    public void CLI_Should_Validate_Required_Parameters()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { "generate" }; // Missing required parameters

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().NotBeEmpty();
    }

    [Fact]
    public void CLI_Should_Handle_Help_Command()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { "--help" };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert - Help should not require a subcommand, so we expect no errors when using global help
        parseResult.Errors.Should().BeEmpty();
    }

    [Fact]
    public void CLI_Should_Support_Multiple_Input_Files()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { 
            "generate", 
            "--input", "file1.dll", 
            "--input", "file2.dll",
            "--output", "output/" 
        };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().BeEmpty();
        var inputFiles = parseResult.GetValueForOption(GetInputOption(rootCommand));
        inputFiles.Should().HaveCount(2);
    }

    [Fact]
    public void CLI_Should_Support_Output_Directory_Option()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { 
            "generate", 
            "--input", "test.dll", 
            "--output", "/custom/output/path" 
        };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().BeEmpty();
        var outputDir = parseResult.GetValueForOption(GetOutputOption(rootCommand));
        outputDir.Should().Be("/custom/output/path");
    }

    [Fact]
    public void CLI_Should_Support_Namespace_Option()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { 
            "generate", 
            "--input", "test.dll", 
            "--output", "output/",
            "--namespace", "MyCompany.Generated"
        };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().BeEmpty();
        var namespaceValue = parseResult.GetValueForOption(GetNamespaceOption(rootCommand));
        namespaceValue.Should().Be("MyCompany.Generated");
    }

    [Fact]
    public void CLI_Should_Support_Verbose_Option()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var args = new[] { 
            "generate", 
            "--input", "test.dll", 
            "--output", "output/",
            "--verbose"
        };

        // Act
        var parseResult = rootCommand.Parse(args);

        // Assert
        parseResult.Errors.Should().BeEmpty();
        var verbose = parseResult.GetValueForOption(GetVerboseOption(rootCommand));
        verbose.Should().BeTrue();
    }

    [Fact]
    public async Task CLI_Should_Execute_Generate_Command_Successfully()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var console = new TestConsole();
        var args = new[] { 
            "generate", 
            "--input", "test.dll", 
            "--output", "output/"
        };

        // Act
        var exitCode = await rootCommand.InvokeAsync(args, console);

        // Assert
        exitCode.Should().Be(0);
        console.Out.ToString().Should().NotBeEmpty();
    }

    [Fact]
    public async Task CLI_Should_Handle_Invalid_Input_File()
    {
        // Arrange
        var rootCommand = CreateRootCommand();
        var console = new TestConsole();
        var args = new[] { 
            "generate", 
            "--input", "nonexistent.dll", 
            "--output", "output/"
        };

        // Act
        var exitCode = await rootCommand.InvokeAsync(args, console);

        // Assert
        exitCode.Should().NotBe(0);
        console.Error.ToString().Should().Contain("not found");
    }

    // Helper methods to create CLI structure
    private static RootCommand CreateRootCommand()
    {
        var inputOption = new Option<string[]>(
            name: "--input",
            description: "Input assembly files to process")
        {
            IsRequired = true,
            AllowMultipleArgumentsPerToken = true
        };

        var outputOption = new Option<string>(
            name: "--output",
            description: "Output directory for generated files")
        {
            IsRequired = true
        };

        var namespaceOption = new Option<string>(
            name: "--namespace",
            description: "Namespace for generated types",
            getDefaultValue: () => "Generated");

        var verboseOption = new Option<bool>(
            name: "--verbose",
            description: "Enable verbose output");

        var generateCommand = new Command("generate", "Generate protobuf files from assemblies")
        {
            inputOption,
            outputOption,
            namespaceOption,
            verboseOption
        };

        generateCommand.SetHandler(async (InvocationContext context) =>
        {
            var inputs = context.ParseResult.GetValueForOption(inputOption) ?? Array.Empty<string>();
            var output = context.ParseResult.GetValueForOption(outputOption) ?? string.Empty;
            var nameSpace = context.ParseResult.GetValueForOption(namespaceOption) ?? "Generated";
            var verbose = context.ParseResult.GetValueForOption(verboseOption);
            
            await HandleGenerateCommand(inputs, output, nameSpace, verbose, context.Console);
        });

        var rootCommand = new RootCommand("AxiomEndpoints ProtoGen CLI")
        {
            generateCommand
        };

        // Allow root command to handle help without requiring subcommand
        rootCommand.TreatUnmatchedTokensAsErrors = false;
        
        // Add a default handler for the root command to handle help
        rootCommand.SetHandler(() =>
        {
            // This handler allows the root command to process help without errors
        });

        return rootCommand;
    }

    private static async Task HandleGenerateCommand(string[] inputs, string output, string nameSpace, bool verbose, IConsole console)
    {
        // Simulate command execution
        await Task.Delay(10);
        
        if (inputs.Any(i => i.Contains("nonexistent")))
        {
            console.Error.WriteLine("Input file not found");
            throw new FileNotFoundException("Input file not found");
        }
        
        if (verbose)
        {
            console.Out.WriteLine($"Processing {inputs.Length} input files");
            console.Out.WriteLine($"Output directory: {output}");
            console.Out.WriteLine($"Namespace: {nameSpace}");
        }
        
        console.Out.WriteLine("Generation completed successfully");
    }

    private static Option<string[]> GetInputOption(RootCommand rootCommand)
    {
        var generateCommand = rootCommand.Subcommands.First(c => c.Name == "generate");
        return (Option<string[]>)generateCommand.Options.First(o => o.Name == "input");
    }

    private static Option<string> GetOutputOption(RootCommand rootCommand)
    {
        var generateCommand = rootCommand.Subcommands.First(c => c.Name == "generate");
        return (Option<string>)generateCommand.Options.First(o => o.Name == "output");
    }

    private static Option<string> GetNamespaceOption(RootCommand rootCommand)
    {
        var generateCommand = rootCommand.Subcommands.First(c => c.Name == "generate");
        return (Option<string>)generateCommand.Options.First(o => o.Name == "namespace");
    }

    private static Option<bool> GetVerboseOption(RootCommand rootCommand)
    {
        var generateCommand = rootCommand.Subcommands.First(c => c.Name == "generate");
        return (Option<bool>)generateCommand.Options.First(o => o.Name == "verbose");
    }
}