import 'package:shared_preferences/shared_preferences.dart';

/// "Çıkış Yap" akışında (bkz. `services/google_auth_service.dart`'taki
/// `FirebaseGoogleAuthService.signOut()`) temizlenen, HESABA ÖZGÜ yerel
/// `SharedPreferences` anahtarları — bkz. CLAUDE.md "Google Hesap Bağlama"
/// bölümündeki "Çıkış Yap sonrası eski hesabın verisi sızıyordu" bug notu.
///
/// **Neden gerekli — `CloudStateStore`'un KENDİ göç mantığındaki bir
/// açık.** [CloudStateStore.load], bir `uid`'nin Firestore'da HENÜZ hiç
/// verisi YOKSA (`snap.exists == false` — TAZE bir anonim kullanıcı için
/// HER ZAMAN doğru), yerel `SharedPreferences`'taki (varsa) eski veriyi bu
/// YENİ kullanıcının Firestore belgesine "göç ettiriyor" (bkz. o sınıfın
/// "Migrasyon otomatik" dokümantasyonu) — bu mekanizma TEK bir cihazın
/// "yerel-yalnızca dönem"den Firestore'a GEÇTİĞİ bir kerelik senaryo için
/// doğru tasarlanmıştı. Ama yerel anahtarlar `uid`'ye göre AYRIŞTIRILMADIĞI
/// için (aynı cihazdaki TÜM kullanıcılar/hesaplar AYNI `SharedPreferences`
/// anahtarlarını PAYLAŞIYOR), "Çıkış Yap" ile oluşturulan YENİ anonim
/// kullanıcı da BU AYNI göç yolundan geçip ÖNCEKİ hesabın yerel önbelleğini
/// SESSİZCE devralıyordu — coin/kostüm/tema/modül verileri "sıfırlanmış"
/// GÖRÜNMÜYORDU (kullanıcı raporu). Bu liste, yeni bir anonim kimliğin
/// GERÇEKTEN boş başlaması için "Çıkış Yap" anında (yeni anonim oturum
/// açıldıktan hemen sonra) temizleniyor — `switchToUid` sinyali TÜM
/// provider ağacını (bkz. `main.dart`'taki `_AppRoot`) yeniden kurmadan
/// ÖNCE bu temizliğin bitmiş olması yeterli, ne kadar erken/geç
/// çalıştığı önemli değil çünkü hiçbir provider henüz bu anahtarları
/// OKUMUYOR.
///
/// **"Hesap Değiştir" akışını BOZMUYOR:** o akışta hedef `uid` ZATEN VAR
/// olan (Firestore'da GERÇEK verisi bulunan) bir hesaba ait olduğu için
/// `CloudStateStore.load()` `snap.exists == true` dalına girip doğrudan
/// Firestore verisini döner — göç yolu (dolayısıyla yerel önbellek) hiç
/// devreye GİRMEZ, bu yüzden bu temizlik "Hesap Değiştir"in de her zaman
/// GÜVENLİ.
///
/// **Bilinçli olarak DIŞARIDA bırakılanlar — hesaba DEĞİL, CİHAZA ait
/// tercihler:** `isDarkMode`/`languageCode`/`soundEffectsState`/
/// `notificationFrequency`/`notificationTimes` (koyu tema, dil, ses
/// efektleri, yerel hatırlatma tercihi) — bunlar teknik olarak
/// `CloudStateStore` üzerinden `uid`'ye göre de senkronize olabiliyor
/// olsa da, kullanıcının "Çıkış Yap"tan HEMEN sonra beklediği şey
/// uygulamanın aniden farklı bir dile/temaya SIÇRAMASI DEĞİL (çoğu
/// uygulamanın standart davranışı — Instagram/Google hesabından çıkış
/// yapmak cihazın dilini/temasını DEĞİŞTİRMEZ). `trustedTimeLastVerifiedUtc`
/// (`TrustedTimeProvider`) VE `adFreePromoLastShownAtMillis`
/// (`AdFreePromoTrigger`) zaten hesap verisi DEĞİL — güvenlik/throttle
/// amaçlı cihaz-seviyesi önbellekler, dokunulMUYOR.
const localAccountDataKeys = <String>[
  // Zibo Coin ekonomisi
  'coinState',
  // Kostümler / Temalar — mağazadan satın alınan/hedefle açılan öğeler
  // ('isDarkMode' ile KARIŞTIRILMAMALI, o bir CİHAZ tercihi).
  'costumeState',
  'ownedCostumeIds',
  'equippedCostumeId',
  'appThemeState',
  'ownedAppThemeIds',
  'equippedAppThemeId',
  // Hedef Takibi / Su Takibi / Ruh Hali / Şükran / Manifest / Rüya / Para
  'goals',
  'waterState',
  'moodEntries',
  'gratitudeEntries',
  'manifestEntries',
  'manifestDecorState',
  'dreamEntries',
  'moneyEntries',
  'currencyState',
  // Günlük Giriş Ödülleri / Uygulamayı Her Gün Açma Serisi
  'dailyRewards',
  'appStreakState',
  // Rozet Sistemi
  'badgeState',
  'hiddenBadgeState',
  // Profil / Favori Sözler / Özel Mesajlar / Geçmiş Ay İstatistikleri
  'profileState',
  'profileStatsArchive',
  'favoriteQuotes',
  'customMessagesState',
  // Davet Et (Referral) / Google Bağlama teşvik durumu / Onboarding
  'referralState',
  'googleLinkPromptState',
  'onboardingState',
  // Push bildirim tercihleri — sunucu tarafı, hesaba (uid'e) özgü.
  'pushNotificationState',
];

/// [localAccountDataKeys]'in HEPSİNİ yerel `SharedPreferences`'tan siler.
/// Firestore'a HİÇ dokunmaz (o zaten `uid`'ye göre doğal olarak izole) —
/// yalnızca bu cihazdaki, `uid`'den BAĞIMSIZ paylaşılan yerel önbelleği
/// temizleyip [CloudStateStore]'un göç mantığının bir SONRAKİ hesap için
/// yanlışlıkla tetiklenmesini önlüyor.
Future<void> clearLocalAccountData() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in localAccountDataKeys) {
    await prefs.remove(key);
  }
}
