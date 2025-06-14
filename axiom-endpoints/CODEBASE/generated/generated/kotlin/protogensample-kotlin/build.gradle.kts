plugins {
    id 'org.jetbrains.kotlin.jvm' version '1.9.22'
    id 'org.jetbrains.kotlin.plugin.serialization' version '1.9.22'
    id 'maven-publish'
    id 'signing'
}

group = 'com.company.protogensample'
version = '1.0.0'

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.jetbrains.kotlin:kotlin-stdlib'
    implementation 'com.google.protobuf:protobuf-kotlin:3.25.2'
    implementation 'io.grpc:grpc-kotlin-stub:1.4.1'
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3'
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2'
    
    testImplementation 'org.jetbrains.kotlin:kotlin-test-junit5'
    testImplementation 'org.junit.jupiter:junit-jupiter-engine:5.10.1'
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    jvmToolchain(17)
}

test {
    useJUnitPlatform()
}
