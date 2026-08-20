import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (google-services.json'ı okuyup gerekli kaynak/manifest
    // girdilerini üretir) — en sonda uygulanmalı.
    id("com.google.gms.google-services")
}

// Release imzalama — bkz. CLAUDE.md "Release İmzalama" bölümü. `key.
// properties` (android/key.properties, KESİNLİKLE .gitignore'da) gerçek
// upload keystore'un yolunu/şifrelerini taşıyor; bu dosya yoksa (ör. CI'da
// henüz kurulmamışsa) release build'i SESSİZCE debug imzasına düşer —
// build'i hemen kırmak yerine, en azından `flutter build`'in çalışmaya
// devam etmesi tercih edildi (aşağıdaki signingConfig seçimine bakın).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dijitalkanka.dijital_kanka"
    // permission_handler_android 37'yi gerektiriyor — flutter.compileSdkVersion
    // (36) burada yetersiz kalıyor, elle yükseltildi.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications bunu gerektiriyor (Java 8+ API'lerini
        // eski Android sürümlerine geri taşıyor).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dijitalkanka.dijital_kanka"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // `android/key.properties` (gerçek upload keystore) varsa onu
            // kullan — YOKSA (ör. bu dosyayı hiç almamış bir CI/klon)
            // debug imzasına DÜŞ, build en azından ÇALIŞMAYA devam etsin
            // (Play Store'a debug-imzalı bir paket YÜKLENEMEZ — bu yalnızca
            // build'in kırılmaması için bir güvenlik ağı, gerçek yayın
            // ASLA bu dalı kullanmamalı).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 kod küçültme + kaynak küçültme — bkz. CLAUDE.md "Release
            // İmzalama" bölümü VE proguard-rules.pro'nun başındaki
            // dokümantasyon (R8'in yalnızca native plugin katmanını
            // etkilediği, Dart/Flutter iş mantığına DOKUNMADIĞI notu).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
