import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (google-services.json'ı okuyup gerekli kaynak/manifest
    // girdilerini üretir) — en sonda uygulanmalı.
    id("com.google.gms.google-services")
    // Çökme/hata izleme (Crashlytics) — bkz. CLAUDE.md "Crashlytics"
    // bölümü. R8 ile küçültülmüş (bkz. "Release İmzalama" bölümü) release
    // build'lerin gerçek stack trace'lerini Firebase Console'da OKUNABİLİR
    // göstermek için her `assembleRelease`/`bundleRelease` SONRASI mapping
    // dosyasını (obfuscated → gerçek isim eşlemesi) OTOMATİK Firebase'e
    // yüklüyor — elle bir adım GEREKMİYOR.
    id("com.google.firebase.crashlytics")
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
            // (2026 — bir turluk tanı amaçlı KAPATILMIŞTI: Google Sign-In
            // "[16] Account reauth failed" için R8 hipotezi test edildi ve
            // ELENDİ — sorun R8 kapalıyken de AYNEN devam etti. Gerçek kök
            // neden `google-services.json`'daki App Signing Key SHA-1'in
            // YANLIŞ olmasıydı (bkz. CLAUDE.md "Google Hesap Bağlama"
            // bölümü) — R8 ile ilgisi YOKTU, bu yüzden tekrar açıldı.)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // NOT: `firebaseCrashlytics { mappingFileUploadEnabled = true }`
            // DSL uzantısı bu AGP 9.0 "yeni DSL" + Crashlytics 3.0.8
            // kombinasyonunda "Unresolved reference" hatasıyla derlenmiyordu
            // (bkz. CLAUDE.md "Crashlytics" bölümü) — KALDIRILDI, çünkü
            // Crashlytics Gradle plugin'i `isMinifyEnabled = true` iken
            // mapping dosyası yüklemeyi zaten VARSAYILAN olarak yapıyor,
            // bu bloğa hiç gerek YOKTU.
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
    // --- Appodeal mediation ağ adaptörleri ---------------------------------
    // `stack_appodeal_flutter`'ın kendi build.gradle'ı yalnızca Appodeal'in
    // `core` + `iab` (bidding) adaptörünü getiriyor; GERÇEK bir ağdan reklam
    // alabilmek için o ağın adaptörünü BURADA elle eklemek gerekiyor (bkz.
    // CLAUDE.md "AdMob → Appodeal geçişi").
    //
    // **Bu liste Appodeal Console'da uygulama için AÇIK olan ağlarla BİREBİR
    // eşleşmeli.** Console'da açık ama burada adaptörü YOKSA o ağ HİÇ fill
    // vermez (SDK o ağın kodunu içermiyor) — "reklam gelmiyor"un baş sebebi
    // buydu: Console'da AppLovin/BidMachine/Vungle/Unity açıktı ama APK yalnızca
    // Unity adaptörünü taşıyordu. Console'da bir ağı açıp/kapatınca bu listeyi
    // de güncelle + yeni AAB al.
    //
    // Sürümler Appodeal SDK 4.2.0'ın resmî adaptör setinden (bkz. Appodeal
    // Flutter Plugin demo `build.gradle`). Yeni ağ eklerken aynı setten al —
    // uyumsuz sürüm derleme/çalışma-zamanı hatası verir.
    implementation("com.appodeal.ads.sdk.adapters:unity_ads:4.17.0.0")
    implementation("com.appodeal.ads.sdk.adapters:applovin:13.5.1.0")
    implementation("com.appodeal.ads.sdk.adapters:bidmachine:3.7.1.0")
    implementation("com.appodeal.ads.sdk.adapters:vungle:7.6.1.0")
}
