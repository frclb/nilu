import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase yapılandırması hesap bağlanınca gelecek (SETUP_KEYS.md). Dosya
// yokken eklenti derlemeyi düşürürdü; uygulama ise Firebase'siz yerel modda
// çalışabiliyor (FirebaseConfig), o yüzden eklenti yalnızca dosya varsa.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Yayın imzası: android/key.properties (git dışında; örneği
// key.properties.example). Yokken release derleme debug anahtarıyla
// imzalanıyor — yerelde `flutter run --release` çalışsın diye. Play'e
// yüklenecek derlemede check_release bunu yakalıyor.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.furkan.rcperiodtracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications zamanlanmış bildirimlerde java.time
        // kullanıyor; eski API düzeylerinde desugaring şart.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // iOS paket kimliğiyle aynı: Firebase, RevenueCat ve mağaza
        // kayıtları tek kimlikle eşleşsin.
        applicationId = "com.furkan.rcperiodtracker"
        // health eklentisi (Health Connect) 26 istiyor; Android 8.0+.
        minSdk = 26
        // Flutter'ın varsayılanı 36 (Android 16). Google Play 31 Ağustos
        // 2026'dan beri yeni uygulama ve güncellemelerde en az 36 istiyor.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
