# Release küçültme (R8) kuralları — bkz. CLAUDE.md "Release İmzalama /
# Play Store Yayın Hazırlığı" bölümü.
#
# ÖNEMLİ BAĞLAM: R8 yalnızca bu projenin Android/Kotlin/Java tarafını
# (plugin'lerin native platform-channel kodu + Firebase/Google Play
# Services/AdMob gibi bağımlılıklar) işliyor — uygulamanın GERÇEK iş
# mantığı (CoinProvider, AuthLinkProvider, vb.) Dart'ta, ayrı bir AOT
# derleyiciyle (libapp.so) derleniyor ve R8'in HİÇ görmediği bir katman.
# Yani buradaki risk yalnızca "native plugin köprüsü" içindir, uygulamanın
# kendi Dart mantığı için DEĞİL.
#
# Firebase/Google Play Services/AdMob/google_sign_in gibi çoğu modern,
# bakımı iyi yapılan kütüphane kendi "consumer proguard rules"ını AAR'ının
# içinde taşıyor (AGP bunları minifyEnabled açıkken OTOMATİK birleştiriyor)
# — bu yüzden burada YALNIZCA bilinen, sık karşılaşılan boşlukları
# kapatan, minimal bir ek küme var. Gerçek doğrulama derleme başarısı
# DEĞİL, gerçek cihazda ana akışları (Google ile Bağlama, reklam,
# bildirim, coin akışları) gezmek.

# Flutter'ın kendi embedding sınıfları.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Flutter'ın "deferred components" desteği bu sınıflara
# derleme zamanında referans veriyor; kullanılmasalar bile eksik olmaları
# bazı Flutter sürümlerinde R8'in "missing classes" hatasıyla build'i
# durdurmasına yol açabiliyor).
-dontwarn com.google.android.play.core.**

# google_sign_in / Credential Manager — Android 14+ Credential Manager
# API'si reflection'a dayanan bazı sınıflar içeriyor.
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# AndroidX WorkManager + Room — GERÇEK CİHAZDA yakalanan bir çökmenin
# düzeltmesi (bkz. CLAUDE.md "Release İmzalama" bölümü): R8, WorkManager'ın
# Room tabanlı `WorkDatabase`sinin ÜRETİLMİŞ (generated) `_Impl`
# sınıflarını (yalnızca reflection/SPI ile referans edildikleri için R8'in
# statik analizinin GÖREMEDİĞİ sınıflar) silip "Failed to create an
# instance of androidx.work.impl.WorkDatabase" ile `androidx.startup.
# InitializationProvider` aşamasında (uygulama AÇILIRKEN, `main()`'e hiç
# ulaşmadan) çökmesine yol açtı. WorkManager'ı DOĞRUDAN kullanan bir kod
# YAZMADIK — bu, bir plugin'in (Firebase Messaging arka plan işleme veya
# benzeri) TRANSİTİF bağımlılığı; bu yüzden HANGİ plugin'in tetiklediğini
# izole etmek yerine WorkManager/Room'un TAMAMINI korumak en güvenli/kalıcı
# çözüm.
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-dontwarn androidx.work.**
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Database class * { *; }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.**

# Genel güvenlik ağı — reflection/serialization için sık gereken
# meta-veriyi koru (Firebase'in kendi Firestore/Auth model dönüşümleri
# bunlara bağımlı olabiliyor).
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod
