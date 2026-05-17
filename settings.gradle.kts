rootProject.name = "coefficiency"

pluginManagement {
    repositories {
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenCentral()
    }
}

// Services
include(":services:coeff")
project(":services:coeff").projectDir = file("services/coeff")
