/// "Kurucu Üye" rozeti. **2026 güncellemesi — artık "ilk 500 KAYIT OLAN"
/// kullanıcıya DEĞİL, Google hesabına BAĞLANAN ilk 500 kullanıcıya, canlı
/// bir uygulama-içi sayaçla veriliyor** (bkz.
/// `providers/founder_badge_provider.dart` — TAM mimari orada belgeli;
/// eski, bir kerelik `grantFounderBadges.js` Admin SDK betiği bu geçişle
/// birlikte TAMAMEN kaldırıldı).
///
/// **`costumes.dart`'taki `costumes` listesine BİLEREK EKLENMEDİ** —
/// satın alınamasın diye (Mağaza'nın Kostümler ızgarası yalnızca o listeyi
/// dolaşır). `CostumeProvider.markOwned('founder_badge')`/`isOwned(...)`
/// gene de SORUNSUZ çalışır çünkü o provider zaten satın alma-agnostik
/// (bkz. `CostumeProvider` dokümantasyonu) — yalnızca bu id'nin "sahiplik"
/// kaydını tutuyor, listede olup olmadığını hiç umursamıyor.
const founderBadgeCostumeId = 'founder_badge';

/// Placeholder görsel — `tool/generate_founder_badge_placeholder.dart` ile
/// üretildi (basit, altın/hardal renkli bir daire+yıldız rozeti). Kullanıcı
/// kendi tasarımını hazırladığında yalnızca bu YOLDAKİ dosyayı (aynı adla)
/// DEĞİŞTİRMESİ yeterli — kodda başka HİÇBİR değişiklik gerekmez.
const founderBadgeImageAsset = 'assets/images/founder_badge.png';
