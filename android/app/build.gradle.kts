plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.bitcoincloudmining.newapp"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    signingConfigs {
        getByName("debug") {
            storePassword = "Shyam@1999"
            keyPassword = "Shyam@1999"
            storeFile = file("C:\\bitcoin_cloud_mining\\android\\keystore\\my-release-key.jks")
            keyAlias = "my-key-alias"
        }
        create("release") {
            storeFile = file("C:\\bitcoin_cloud_mining\\android\\keystore\\my-release-key.jks")
            storePassword = "Shyam@1999"
            keyPassword = "Shyam@1999"
            keyAlias = "my-key-alias"
            if (project.hasProperty("storePassword")) {
                storeFile = file(project.property("storeFile") as String)
                storePassword = project.property("storePassword") as String
                keyAlias = project.property("keyAlias") as String
                keyPassword = project.property("keyPassword") as String
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            freeCompilerArgs += listOf("-Xsuppress-version-warnings")
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf("-Xlint:none"))
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bitcoincloudmining.newapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.android.gms:play-services-ads:24.4.0") // AdMob SDK (latest)
    implementation("com.unity3d.ads:unity-ads:4.15.1") // Unity Ads SDK (latest)
    implementation("com.google.ads.mediation:unity:4.15.1.0") // Unity adapter for AdMob (latest)
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-crashlytics")
}

