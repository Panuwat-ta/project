plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Production identity and signing come from the environment, never source.
val releaseApplicationId = providers.environmentVariable("SCAMGUARD_APPLICATION_ID").orNull
val keyStorePath = providers.environmentVariable("SCAMGUARD_KEYSTORE_PATH").orNull
val keyAliasValue = providers.environmentVariable("SCAMGUARD_KEY_ALIAS").orNull
val storePasswordValue = providers.environmentVariable("SCAMGUARD_STORE_PASSWORD").orNull
val keyPasswordValue = providers.environmentVariable("SCAMGUARD_KEY_PASSWORD").orNull
val hasReleaseSigning = listOf(keyStorePath, keyAliasValue, storePasswordValue, keyPasswordValue).all { !it.isNullOrBlank() }
val unsignedQualityBuild = providers.environmentVariable("SCAMGUARD_ALLOW_UNSIGNED_QUALITY_BUILD").orNull == "true"
gradle.taskGraph.whenReady {
    val packagesRelease = allTasks.any {
        Regex("(?i)^(assemble|bundle|package|install|validateSigning).*release.*$").matches(it.name)
    }
    if (packagesRelease && !unsignedQualityBuild) {
    require(!releaseApplicationId.isNullOrBlank() && !releaseApplicationId.startsWith("com.example.")) {
        "Release requires a confirmed SCAMGUARD_APPLICATION_ID"
    }
    require(hasReleaseSigning) { "Release signing configuration is missing" }
    require(file(keyStorePath!!).isFile) { "Release keystore file is unavailable" }
    }
}

android {
    namespace = "com.example.scam_image_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = releaseApplicationId ?: "com.example.scam_image_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("production") {
                storeFile = file(keyStorePath!!)
                keyAlias = keyAliasValue
                storePassword = storePasswordValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            // The explicit quality build is unsigned and cannot be distributed.
            signingConfig = if (!unsignedQualityBuild && hasReleaseSigning) signingConfigs.getByName("production") else null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
