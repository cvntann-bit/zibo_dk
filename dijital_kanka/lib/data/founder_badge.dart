/// 2026 yeni özellik — "Kurucu Üye" rozeti. Kullanıcı isteği: ilk 500
/// kayıt olan kullanıcıya özel, SATIN ALINAMAYAN bir rozet/kostüm ver.
///
/// **`costumes.dart`'taki `costumes` listesine BİLEREK EKLENMEDİ** —
/// satın alınamasın diye (Mağaza'nın Kostümler ızgarası yalnızca o listeyi
/// dolaşır). `CostumeProvider.markOwned('founder_badge')`/`isOwned(...)`
/// gene de SORUNSUZ çalışır çünkü o provider zaten satın alma-agnostik
/// (bkz. `CostumeProvider` dokümantasyonu) — yalnızca bu id'nin "sahiplik"
/// kaydını tutuyor, listede olup olmadığını hiç umursamıyor. Sahiplik,
/// `notification-scripts/src/grantFounderBadges.js` (bir kerelik, elle
/// tetiklenen bakım betiği) tarafından Firestore'a doğrudan (Admin SDK ile)
/// yazılıyor — istemci tarafında rozeti "kazanmanın" hiçbir yolu YOK.
const founderBadgeCostumeId = 'founder_badge';

/// Placeholder görsel — `tool/generate_founder_badge_placeholder.dart` ile
/// üretildi (basit, altın/hardal renkli bir daire+yıldız rozeti). Kullanıcı
/// kendi tasarımını hazırladığında yalnızca bu YOLDAKİ dosyayı (aynı adla)
/// DEĞİŞTİRMESİ yeterli — kodda başka HİÇBİR değişiklik gerekmez.
const founderBadgeImageAsset = 'assets/images/founder_badge.png';
