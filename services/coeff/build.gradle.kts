plugins {
    id("java")
    id("application")
    alias(libs.plugins.shadow)
    alias(libs.plugins.jooby.run)
}

group = "io.bitnomio"
version = "1.0.0-SNAPSHOT"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

application {
    mainClass = "io.bitnomio.coeff.CoeffApplication"
}

dependencies {
    annotationProcessor(libs.avaje.inject.generator)
    annotationProcessor(libs.jooby.apt)

    implementation(platform(libs.avaje.inject))

    implementation(libs.bundles.coeff.core)
    implementation(libs.bundles.coeff.openapi)
    implementation(libs.bundles.jackson)
    implementation(libs.jooby.flyway)
    runtimeOnly(libs.flyway.core)

    testImplementation(libs.bundles.coeff.testing)
}


tasks.register<Exec>("npmInstall") {
    workingDir = file("frontend")
    commandLine("npm", "install")
    isIgnoreExitValue = true
}

tasks.register<Exec>("buildFrontend") {
    dependsOn(tasks.named("npmInstall"))
    workingDir = file("frontend")
    commandLine("npm", "run", "build")
    isIgnoreExitValue = true
}

tasks.shadowJar {
    dependsOn(tasks.named("buildFrontend"))
    from("frontend/dist") {
        into("static")
    }
}

sourceSets {
    create("intTest") {
        compileClasspath += sourceSets.main.get().output + sourceSets.test.get().output
        runtimeClasspath += sourceSets.main.get().output + sourceSets.test.get().output
    }
}

configurations["intTestImplementation"].extendsFrom(configurations.testImplementation.get())
configurations["intTestRuntimeOnly"].extendsFrom(configurations.testRuntimeOnly.get())

tasks.register<Test>("intTest") {
    description = "Runs integration tests."
    group = "verification"
    testClassesDirs = sourceSets["intTest"].output.classesDirs
    classpath = sourceSets["intTest"].runtimeClasspath
    shouldRunAfter("test")
}

tasks.compileJava {
    options.compilerArgs.add("-parameters")
    options.compilerArgs.add("-Ajooby.incremental=true")
}

tasks.test {
    useJUnitPlatform()
}
