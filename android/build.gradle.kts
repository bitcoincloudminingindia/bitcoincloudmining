// File: android/build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// ✅ Repositories
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Custom build output directory (optional but clean)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app") // Ensure `:app` evaluated first
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ Plugins block (new Gradle style)
plugins {
    id("com.google.gms.google-services") version "4.4.3" apply false
    id("com.google.firebase.crashlytics") version "3.0.4" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// ✅ Legacy buildscript (still required for some classpath tools)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.gms:google-services:4.4.3")
        classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.4")
    }
}
