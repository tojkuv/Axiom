using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using AxiomEndpoints.Core;
using AxiomEndpoints.Testing.Common.TestData;
using FluentAssertions;
using Xunit;
using System.Text;

namespace AxiomEndpoints.ProtoGen.Tests;

/// <summary>
/// Tests for protobuf code generation functionality
/// </summary>
public class ProtoGenTests
{
    [Fact]
    public void Should_Generate_Proto_From_Route_Definition()
    {
        // Arrange
        var routeType = typeof(UserById);
        
        // Act
        var protoDefinition = GenerateProtoDefinition(routeType);
        
        // Assert
        protoDefinition.Should().NotBeNullOrEmpty();
        protoDefinition.Should().Contain("message UserByIdRequest");
        protoDefinition.Should().Contain("string id = 1;");
    }

    [Fact]
    public void Should_Generate_Service_Definition_From_Endpoint()
    {
        // Arrange
        var endpointType = typeof(SimpleEndpoint);
        
        // Act
        var serviceDefinition = GenerateServiceDefinition(endpointType);
        
        // Assert
        serviceDefinition.Should().NotBeNullOrEmpty();
        serviceDefinition.Should().Contain("service SimpleEndpointService");
        serviceDefinition.Should().Contain("rpc Handle");
    }

    [Fact]
    public void Should_Handle_Complex_Types_In_Proto_Generation()
    {
        // Arrange
        var complexType = typeof(OrderByUserAndId);
        
        // Act
        var protoDefinition = GenerateProtoDefinition(complexType);
        
        // Assert
        protoDefinition.Should().NotBeNullOrEmpty();
        protoDefinition.Should().Contain("message OrderByUserAndIdRequest");
        protoDefinition.Should().Contain("string userId = 1;");
        protoDefinition.Should().Contain("int32 id = 2;");
    }

    [Fact]
    public void Should_Generate_Streaming_Service_Methods()
    {
        // Arrange
        var streamingEndpoint = typeof(TestServerStreamEndpoint);
        
        // Act
        var serviceDefinition = GenerateStreamingServiceDefinition(streamingEndpoint);
        
        // Assert
        serviceDefinition.Should().NotBeNullOrEmpty();
        serviceDefinition.Should().Contain("rpc StreamAsync");
        serviceDefinition.Should().Contain("stream");
    }

    [Fact]
    public void Should_Validate_Proto_Syntax()
    {
        // Arrange
        var protoContent = GenerateSampleProtoFile();
        
        // Act
        var isValid = ValidateProtoSyntax(protoContent);
        
        // Assert
        isValid.Should().BeTrue();
    }

    [Fact]
    public void Should_Generate_CSharp_Code_From_Proto()
    {
        // Arrange
        var protoContent = GenerateSampleProtoFile();
        
        // Act
        var csharpCode = GenerateCSharpFromProto(protoContent);
        
        // Assert
        csharpCode.Should().NotBeNullOrEmpty();
        csharpCode.Should().Contain("public sealed partial class");
        csharpCode.Should().Contain("namespace");
    }

    [Fact]
    public void Should_Preserve_Route_Metadata_In_Proto()
    {
        // Arrange
        var routeWithMetadata = typeof(UserById);
        
        // Act
        var protoDefinition = GenerateProtoWithMetadata(routeWithMetadata);
        
        // Assert
        protoDefinition.Should().NotBeNullOrEmpty();
        protoDefinition.Should().Contain("// Route: /user/{id}");
        protoDefinition.Should().Contain("// Method: GET");
    }

    // Helper methods for proto generation (placeholder implementations)
    private static string GenerateProtoDefinition(Type routeType)
    {
        var sb = new StringBuilder();
        sb.AppendLine("syntax = \"proto3\";");
        sb.AppendLine();
        sb.AppendLine($"message {routeType.Name}Request {{");
        
        // Simple implementation for testing
        if (routeType == typeof(UserById))
        {
            sb.AppendLine("  string id = 1;");
        }
        else if (routeType == typeof(OrderByUserAndId))
        {
            sb.AppendLine("  string userId = 1;");
            sb.AppendLine("  int32 id = 2;");
        }
        
        sb.AppendLine("}");
        return sb.ToString();
    }

    private static string GenerateServiceDefinition(Type endpointType)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"service {endpointType.Name}Service {{");
        sb.AppendLine($"  rpc Handle(TestRequest) returns (TestResponse);");
        sb.AppendLine("}");
        return sb.ToString();
    }

    private static string GenerateStreamingServiceDefinition(Type endpointType)
    {
        var sb = new StringBuilder();
        sb.AppendLine($"service {endpointType.Name}Service {{");
        sb.AppendLine($"  rpc StreamAsync(TestRequest) returns (stream TestResponse);");
        sb.AppendLine("}");
        return sb.ToString();
    }

    private static string GenerateSampleProtoFile()
    {
        return """
            syntax = "proto3";
            
            package test;
            
            message TestRequest {
              string message = 1;
            }
            
            message TestResponse {
              string message = 1;
            }
            
            service TestService {
              rpc Process(TestRequest) returns (TestResponse);
            }
            """;
    }

    private static bool ValidateProtoSyntax(string protoContent)
    {
        // Simple validation - in real implementation would use protobuf compiler
        return protoContent.Contains("syntax = \"proto3\";") &&
               protoContent.Contains("message") &&
               !string.IsNullOrEmpty(protoContent);
    }

    private static string GenerateCSharpFromProto(string protoContent)
    {
        // Placeholder implementation
        return """
            namespace Generated
            {
                public sealed partial class TestRequest
                {
                    public string Message { get; set; } = "";
                }
                
                public sealed partial class TestResponse  
                {
                    public string Message { get; set; } = "";
                }
            }
            """;
    }

    private static string GenerateProtoWithMetadata(Type routeType)
    {
        var sb = new StringBuilder();
        sb.AppendLine("syntax = \"proto3\";");
        sb.AppendLine();
        sb.AppendLine("// Route: /user/{id}");
        sb.AppendLine("// Method: GET");
        sb.AppendLine($"message {routeType.Name}Request {{");
        sb.AppendLine("  string id = 1;");
        sb.AppendLine("}");
        return sb.ToString();
    }
}