import '../data/founder_badge.dart';
import '../providers/auth_link_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/founder_badge_provider.dart';

/// **2026 bug düzeltmesi — gerçek kullanıcı raporu: Google hesabı bağlandı
/// ama Kurucu Üye rozeti hiç görünmedi.** Kök neden: bu hesap
/// (`credential-already-in-use`, bkz. `google_link_action.dart`) HER ZAMAN
/// "zaten BAŞKA bir hesaba bağlı, o hesaba GEÇMEK ister misin?" dalına
/// düşüyordu — `_offerSignInInstead`/`handleSwitchAccountTap`'in ikisi de
/// BİLEREK `FounderBadgeProvider.claimIfEligible()`'ı ÇAĞIRMIYOR ("o hesap
/// ya zaten rozete sahip ya da bağlandığı anda kontenjan doluydu, tekrar
/// denenecek bir şey yok" varsayımıyla) — ama bu varsayım, hesap
/// `founderBadgeStatus/status` sayacı HENÜZ SEED EDİLMEDEN ÖNCE bağlanmışsa
/// YANLIŞ: o andaki TEK claim denemesi (varsa) sessizce başarısız olmuştu
/// (`!statusSnap.exists`), ve bu hesap bir daha ASLA "yeni/ilk kez bağlama"
/// akışına düşmediği için tekrar deneme fırsatı hiç bulamıyordu.
///
/// **Düzeltme — `RootScreen`'in `AppStreakProvider`/`ReferralProvider` ile
/// AYNI "reconcile-on-resume" deseni.** Uygulama HER açılışta/öne gelişte,
/// Google'a bağlıysa VE rozet henüz sahip DEĞİLSE `claimIfEligible()`'ı
/// sessizce yeniden dener — bu, HANGİ yoldan bağlanmış/geçilmiş olursa
/// olsun (fresh link, "geç", "Hesap Değiştir", yeni cihazda giriş) çalışır,
/// üç ayrı çağrı sitesine yanlış `_uid`/`FounderBadgeProvider` örneği
/// kullanma riskiyle elle claim eklemekten çok daha güvenli — `RootScreen`
/// HER ZAMAN o anki (doğru) uid'e bağlı taze provider örnekleriyle çalışır
/// (bir uid değişimi `main.dart`'taki `_AppRoot`'un TÜM `RootScreen`
/// ağacını yeniden kurmasını gerektirir).
///
/// `claimIfEligible()` zaten idempotent/sessiz — bu fonksiyon da ek olarak
/// `isOwned` ön kontrolüyle GEREKSİZ bir Firestore transaction'ını önlüyor.
/// Saf/test edilebilir bir üst düzey fonksiyon olarak yazıldı ki
/// `RootScreen`'in tam widget ağacını kurmadan doğrudan test edilebilsin —
/// `HomeWidgetSyncCoordinator`/`BadgeCoordinator`'ın "provider'ları
/// parametre olarak al" felsefesiyle AYNI.
Future<void> maybeClaimFounderBadge({
  required AuthLinkProvider authLink,
  required CostumeProvider costume,
  required FounderBadgeProvider founderBadge,
}) async {
  if (!authLink.isLinked) return;
  if (costume.isOwned(founderBadgeCostumeId)) return;
  final won = await founderBadge.claimIfEligible();
  if (won) {
    await costume.markOwned(founderBadgeCostumeId);
  }
}
