using AxiomEndpoints.ProtoGen.Compilation;

namespace AxiomEndpoints.ProtoGen.Packaging;

/// <summary>
/// Kotlin/Maven package generator
/// </summary>
public class KotlinPackageGenerator : IPackageGenerator
{
    public async Task<PackageResult> GeneratePackageAsync(
        CompilationResult compilation,
        PackageMetadata metadata)
    {
        var packageDir = Path.Combine(compilation.OutputPath, metadata.PackageName);
        Directory.CreateDirectory(packageDir);

        try
        {
            // Create Maven structure
            var srcDir = Path.Combine(packageDir, "src", "main", "kotlin",
                metadata.GroupId.Replace('.', Path.DirectorySeparatorChar));
            Directory.CreateDirectory(srcDir);

            // Copy generated files
            foreach (var file in compilation.GeneratedFiles)
            {
                var destPath = Path.Combine(srcDir, Path.GetFileName(file));
                File.Copy(file, destPath, overwrite: true);
            }

            // Create pom.xml
            await GeneratePomXmlAsync(packageDir, metadata);

            // Create Gradle alternative
            await GenerateBuildGradleAsync(packageDir, metadata);

            // Generate Kotlin extensions
            await GenerateKotlinExtensionsAsync(srcDir, metadata);

            // Create README
            await GenerateReadmeAsync(packageDir, metadata, "Kotlin");

            // Create .gitignore
            await GenerateGitIgnoreAsync(packageDir);

            // Create test structure
            await GenerateTestStructureAsync(packageDir, metadata);

            return new PackageResult
            {
                Success = true,
                PackagePath = packageDir,
                Language = Language.Kotlin,
                GeneratedFiles = Directory.GetFiles(packageDir, "*.*", SearchOption.AllDirectories).ToList()
            };
        }
        catch (Exception ex)
        {
            return new PackageResult
            {
                Success = false,
                Error = ex.Message,
                PackagePath = packageDir,
                Language = Language.Kotlin
            };
        }
    }

    private async Task GeneratePomXmlAsync(string packageDir, PackageMetadata metadata)
    {
        var pomXml = $@"<?xml version=""1.0"" encoding=""UTF-8""?>
<project xmlns=""http://maven.apache.org/POM/4.0.0""
         xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance""
         xsi:schemaLocation=""http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd"">
    <modelVersion>4.0.0</modelVersion>

    <groupId>{metadata.GroupId}</groupId>
    <artifactId>{metadata.PackageName}</artifactId>
    <version>{metadata.Version}</version>
    <packaging>jar</packaging>

    <name>{metadata.PackageName}</name>
    <description>gRPC types for {metadata.ServiceName}</description>
    <url>{metadata.RepositoryUrl}</url>

    <properties>
        <kotlin.version>1.9.22</kotlin.version>
        <grpc.version>1.61.0</grpc.version>
        <protobuf.version>3.25.2</protobuf.version>
        <grpc.kotlin.version>1.4.1</grpc.kotlin.version>
        <coroutines.version>1.7.3</coroutines.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
            <version>${{kotlin.version}}</version>
        </dependency>

        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-kotlin</artifactId>
            <version>${{protobuf.version}}</version>
        </dependency>

        <dependency>
            <groupId>io.grpc</groupId>
            <artifactId>grpc-kotlin-stub</artifactId>
            <version>${{grpc.kotlin.version}}</version>
        </dependency>

        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-coroutines-core</artifactId>
            <version>${{coroutines.version}}</version>
        </dependency>

        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-serialization-json</artifactId>
            <version>1.6.2</version>
        </dependency>

        <!-- Test dependencies -->
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-test-junit5</artifactId>
            <version>${{kotlin.version}}</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>5.10.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <sourceDirectory>src/main/kotlin</sourceDirectory>
        <testSourceDirectory>src/test/kotlin</testSourceDirectory>
        
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
                <version>${{kotlin.version}}</version>
                <executions>
                    <execution>
                        <id>compile</id>
                        <phase>compile</phase>
                        <goals>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>test-compile</id>
                        <phase>test-compile</phase>
                        <goals>
                            <goal>test-compile</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <jvmTarget>17</jvmTarget>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.3</version>
            </plugin>
        </plugins>
    </build>
</project>";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "pom.xml"),
            pomXml);
    }

    private async Task GenerateBuildGradleAsync(string packageDir, PackageMetadata metadata)
    {
        var buildGradle = $@"plugins {{
    id 'org.jetbrains.kotlin.jvm' version '1.9.22'
    id 'org.jetbrains.kotlin.plugin.serialization' version '1.9.22'
    id 'maven-publish'
    id 'signing'
}}

group = '{metadata.GroupId}'
version = '{metadata.Version}'

repositories {{
    mavenCentral()
}}

dependencies {{
    implementation 'org.jetbrains.kotlin:kotlin-stdlib'
    implementation 'com.google.protobuf:protobuf-kotlin:3.25.2'
    implementation 'io.grpc:grpc-kotlin-stub:1.4.1'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2'
    
    testImplementation 'org.jetbrains.kotlin:kotlin-test-junit5'
    testImplementation 'org.junit.jupiter:junit-jupiter-engine:5.10.1'
}}

java {{
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}}

kotlin {{
    jvmToolchain(17)
}}

test {{
    useJUnitPlatform()
}}

publishing {{
    publications {{
        maven(MavenPublication) {{
            groupId = '{metadata.GroupId}'
            artifactId = '{metadata.PackageName}'
            version = '{metadata.Version}'
            
            from components.java
            
            pom {{
                name = '{metadata.PackageName}'
                description = 'gRPC types for {metadata.ServiceName}'
                url = '{metadata.RepositoryUrl}'
                
                licenses {{
                    license {{
                        name = 'MIT License'
                        url = '{metadata.LicenseUrl}'
                    }}
                }}
                
                developers {{
                    developer {{
                        name = '{metadata.Authors}'
                        organization = '{metadata.Company}'
                    }}
                }}
                
                scm {{
                    url = '{metadata.RepositoryUrl}'
                }}
            }}
        }}
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "build.gradle.kts"),
            buildGradle);
    }

    private async Task GenerateKotlinExtensionsAsync(string srcDir, PackageMetadata metadata)
    {
        var extensions = $@"// Extensions for {metadata.PackageName}
package {metadata.GroupId}

import com.google.protobuf.Timestamp
import com.google.protobuf.kotlin.toByteString
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.time.Instant
import java.util.Date

// Timestamp conversions
fun Timestamp.toInstant(): Instant = Instant.ofEpochSecond(seconds, nanos.toLong())

fun Instant.toTimestamp(): Timestamp = Timestamp.newBuilder()
    .setSeconds(epochSecond)
    .setNanos(nano)
    .build()

fun Timestamp.toDate(): Date = Date(seconds * 1000 + nanos / 1_000_000)

fun Date.toTimestamp(): Timestamp = time.let {{ millis ->
    Timestamp.newBuilder()
        .setSeconds(millis / 1000)
        .setNanos(((millis % 1000) * 1_000_000).toInt())
        .build()
}}

// JSON serialization helpers
inline fun <reified T> T.toJson(): String = Json.encodeToString(this)
inline fun <reified T> String.fromJson(): T = Json.decodeFromString(this)

// Validation framework
interface Validatable {{
    fun validate(): ValidationResult
}}

data class ValidationResult(
    val isValid: Boolean,
    val errors: List<ValidationError> = emptyList()
) {{
    companion object {{
        fun success() = ValidationResult(true)
        fun failure(vararg errors: ValidationError) = ValidationResult(false, errors.toList())
        fun failure(errors: List<ValidationError>) = ValidationResult(false, errors)
    }}
}}

data class ValidationError(
    val field: String,
    val message: String,
    val code: String? = null
)

// Result handling extensions
sealed class ApiResult<out T> {{
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: String? = null) : ApiResult<Nothing>()
    
    inline fun <R> map(transform: (T) -> R): ApiResult<R> = when (this) {{
        is Success -> Success(transform(data))
        is Error -> this
    }}
    
    inline fun <R> flatMap(transform: (T) -> ApiResult<R>): ApiResult<R> = when (this) {{
        is Success -> transform(data)
        is Error -> this
    }}
    
    fun getOrNull(): T? = when (this) {{
        is Success -> data
        is Error -> null
    }}
    
    fun getOrThrow(): T = when (this) {{
        is Success -> data
        is Error -> throw Exception(message)
    }}
}}

// Extension functions for common operations
fun String?.isNotNullOrEmpty(): Boolean = this != null && this.isNotEmpty()

fun String?.isNotNullOrBlank(): Boolean = this != null && this.isNotBlank()

// Builder pattern helpers
inline fun <T> T.apply(block: T.() -> Unit): T {{
    block()
    return this
}}

// Coroutine extensions for gRPC
suspend fun <T> kotlinx.coroutines.flow.Flow<T>.collectToList(): List<T> {{
    val result = mutableListOf<T>()
    collect {{ result.add(it) }}
    return result
}}";

        await File.WriteAllTextAsync(
            Path.Combine(srcDir, "Extensions.kt"),
            extensions);
    }

    private async Task GenerateReadmeAsync(string packageDir, PackageMetadata metadata, string language)
    {
        var readme = $@"# {metadata.PackageName}

{metadata.Description}

## Installation

### Maven

Add this dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>{metadata.GroupId}</groupId>
    <artifactId>{metadata.PackageName}</artifactId>
    <version>{metadata.Version}</version>
</dependency>
```

### Gradle

Add this dependency to your `build.gradle.kts`:

```kotlin
dependencies {{
    implementation(""{metadata.GroupId}:{metadata.PackageName}:{metadata.Version}"")
}}
```

## Usage

```kotlin
import {metadata.GroupId}.*
import kotlinx.coroutines.flow.*

// Use as domain models
val request = createTodoRequest {{
    title = ""Build something awesome""
    description = ""Using gRPC types as domain models""
    priority = Priority.MEDIUM
}}

// Direct use with gRPC
val stub = TodoServiceGrpcKt.TodoServiceCoroutineStub(channel)
val response = stub.createTodo(request)

// Streaming
stub.streamTodos(Empty.getDefaultInstance())
    .collect {{ event ->
        println(""Received: $event"")
    }}
```

## Features

- ✅ Type-safe gRPC client generation
- ✅ Kotlin coroutines support
- ✅ kotlinx.serialization integration
- ✅ Convenient extension functions
- ✅ Validation framework
- ✅ Result handling utilities
- ✅ Android and JVM support

## Generated at

{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC

## Version

{metadata.Version}
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, "README.md"),
            readme);
    }

    private async Task GenerateGitIgnoreAsync(string packageDir)
    {
        var gitignore = @"target/
.gradle/
build/
.idea/
*.iml
*.ipr
*.iws
.vscode/
.DS_Store
*.log
dependency-reduced-pom.xml
";

        await File.WriteAllTextAsync(
            Path.Combine(packageDir, ".gitignore"),
            gitignore);
    }

    private async Task GenerateTestStructureAsync(string packageDir, PackageMetadata metadata)
    {
        var testDir = Path.Combine(packageDir, "src", "test", "kotlin",
            metadata.GroupId.Replace('.', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(testDir);

        var testFile = $@"package {metadata.GroupId}

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import java.time.Instant
import java.util.Date

class {metadata.PackageName.Replace("-", "")}Test {{
    
    @Test
    fun `test timestamp conversions`() {{
        val now = Instant.now()
        val timestamp = now.toTimestamp()
        val converted = timestamp.toInstant()
        
        assertEquals(now.epochSecond, converted.epochSecond)
        assertEquals(now.nano, converted.nano)
    }}
    
    @Test
    fun `test date conversions`() {{
        val now = Date()
        val timestamp = now.toTimestamp()
        val converted = timestamp.toDate()
        
        assertEquals(now.time / 1000, converted.time / 1000) // Allow for millisecond precision
    }}
    
    @Test
    fun `test validation framework`() {{
        val result = ValidationResult.success()
        assertTrue(result.isValid)
        assertTrue(result.errors.isEmpty())
        
        val errorResult = ValidationResult.failure(
            ValidationError(""field"", ""error message"")
        )
        assertFalse(errorResult.isValid)
        assertEquals(1, errorResult.errors.size)
    }}
    
    @Test
    fun `test api result handling`() {{
        val success = ApiResult.Success(""test"")
        assertEquals(""test"", success.getOrNull())
        assertEquals(""test"", success.getOrThrow())
        
        val error = ApiResult.Error(""error message"")
        assertNull(error.getOrNull())
        assertThrows(Exception::class.java) {{ error.getOrThrow() }}
    }}
    
    @Test
    fun `test string extensions`() {{
        assertTrue(""test"".isNotNullOrEmpty())
        assertTrue(""test"".isNotNullOrBlank())
        assertFalse("""".isNotNullOrEmpty())
        assertFalse("""".isNotNullOrBlank())
        assertFalse("" "".isNotNullOrBlank())
    }}
}}";

        await File.WriteAllTextAsync(
            Path.Combine(testDir, $"{metadata.PackageName.Replace("-", "")}Test.kt"),
            testFile);
    }
}