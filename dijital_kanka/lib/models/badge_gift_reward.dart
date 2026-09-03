/// Bir rozetin ZC ödülüne EK OLARAK verdiği kostüm/tema hediyesinin TÜRÜ —
/// bkz. `data/badge_gift_rewards.dart`'taki `badgeGiftRewards` eşlemesi ve
/// CLAUDE.md "Rozet Sistemi" > "Rozet Hediyeleri" bölümü.
enum BadgeGiftType {
  /// Sabit/deterministik bir kostüm — HANGİ kostüm olduğu ÖNCEDEN bilinir,
  /// rastgelelik YOK (bkz. [BadgeGiftReward.costumeId]). Kazanma anındaki
  /// popup bu yüzden "Ödülü Al"a basılmadan ÖNCE bile kostümün adını/
  /// görselini gösterebilir.
  costume,

  /// Sahip OLUNMAYAN STANDART (premium/animasyonlu OLMAYAN) temalardan
  /// rastgele biri — HANGİSİ olduğu yalnızca "Ödülü Al"a basılıp ödül
  /// GERÇEKTEN talep edilince belli olur (bkz. `utils/
  /// badge_special_reward.dart`'taki `pickRandomUnownedStandardTheme`).
  theme,
}

/// Bir rozetin taşıdığı kostüm/tema hediyesi — bkz. `data/
/// badge_gift_rewards.dart`'taki `badgeGiftRewards` eşlemesi.
class BadgeGiftReward {
  const BadgeGiftReward.costume(this.costumeId)
    : type = BadgeGiftType.costume;

  const BadgeGiftReward.theme() : type = BadgeGiftType.theme, costumeId = null;

  final BadgeGiftType type;

  /// Yalnızca [type] `costume` iken dolu (hangi kostümün hediye edileceği
  /// SABİT/önceden bilinen).
  final String? costumeId;
}

/// "Ödülü Al"a basılınca GERÇEKTEN verilen bir kostüm/tema hediyesi —
/// `BadgeCelebrationOverlay`'in `_BadgeClaimCard`'ından `BadgesGalleryScreen`'e
/// (doğru SnackBar metnini seçebilmesi için) taşınır. Bu tipin BURADA
/// (widget dosyalarının İKİSİNİN de bağımsız olarak import edebileceği,
/// NÖTR bir model dosyasında) tanımlanması BİLEREK — `BadgeCelebrationOverlay`
/// zaten `BadgesGalleryScreen`'i import ediyor, tersi yönde bir import
/// (`BadgesGalleryScreen` → `BadgeCelebrationOverlay`) DAİRESEL bir
/// bağımlılık yaratırdı.
typedef GrantedBadgeGift = ({BadgeGiftType type, String name});
