import '../l10n/app_localizations.dart';

/// Kostümün nadirlik kademesi — Mağaza > Kostümler bölümü bu sırayla gruplanır
/// (Yaygın → Nadir → Epik → Efsanevi → Mitik) ve kart çerçevesinin rengi bundan
/// gelir (bkz. `data/rarity_colors.dart`, `RarityStyle`). Sıralama = enum sırası.
enum CostumeRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  /// Mağaza grup başlığı ve kart etiketi için o anki dildeki (TR/EN/ES) ad.
  String localizedName(AppLocalizations l10n) => switch (this) {
    CostumeRarity.common => l10n.rarityCommon,
    CostumeRarity.rare => l10n.rarityRare,
    CostumeRarity.epic => l10n.rarityEpic,
    CostumeRarity.legendary => l10n.rarityLegendary,
    CostumeRarity.mythic => l10n.rarityMythic,
  };
}

/// Kostümün nasıl elde edildiği. Yalnızca [store] kostümler Zibo Coin ile
/// satın alınabilir; diğerlerinde kartta satın alma butonu/fiyat ÇIKMAZ, bunun
/// yerine ilgili etiket gösterilir ("Rozetle kazan", "Pro", "Sınırlı süre").
///
/// 2026-10: şu an HİÇBİR kostüm [store] dışında değil (rozetle hediye edilenler
/// de ayrıca Mağaza'dan satın alınabiliyor); bu alan, ileride rozete/üyeliğe/
/// etkinliğe özel kostümler eklenirse arayüzün hazır olması için var.
enum CostumeAcquisition {
  store,
  badge,
  pro,
  limited;

  bool get isPurchasable => this == CostumeAcquisition.store;

  String? localizedLabel(AppLocalizations l10n) => switch (this) {
    CostumeAcquisition.store => null,
    CostumeAcquisition.badge => l10n.costumeAcquireBadge,
    CostumeAcquisition.pro => l10n.costumeAcquirePro,
    CostumeAcquisition.limited => l10n.costumeAcquireLimited,
  };
}
