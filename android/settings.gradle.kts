pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    // 8.13: flutter_secure_storage 11 compileSdk 37 istiyor ve SDK'da o
    // platform "android-37.0" adıyla geliyor; 8.11 bu adı tanımıyordu.
    id("com.android.application") version "8.13.2" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // Firebase: yalnızca app/google-services.json varken uygulanıyor.
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")
