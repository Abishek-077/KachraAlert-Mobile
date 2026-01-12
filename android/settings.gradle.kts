pluginManagement {
    val flutterSdkPath: String =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            require(localProperties.exists()) { "local.properties not found in android/." }
            localProperties.inputStream().use { properties.load(it) }
            val path = properties.getProperty("flutter.sdk")
            require(path != null) { "flutter.sdk not set in local.properties" }
            path
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}

include(":app")
