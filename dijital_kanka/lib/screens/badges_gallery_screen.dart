import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/badge_gift_rewards.dart';
import '../data/consistency_badges.dart';
import '../data/costumes.dart';
import '../data/hidden_badges.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_definition.dart';
import '../models/badge_gift_reward.dart';
import '../providers/badge_provider.dart';
import '../utils/info_dialog.dart';

/// Rozetler Galerisi — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Kazanılan
/// rozetler net/renkli, kazanılmamış rozetler gri tonlu/soluk görünür ama
/// adı ve kazanma koşulu HER ZAMAN görünür kalır — **TEK istisna Gizli/
/// Eğlenceli Rozetler kategorisi** (bkz. `_BadgeGalleryCard`'daki
/// `hiddenLocked` kontrolü ve `ZiboBadgeDefinition.isHidden` dokümantasyonu):
/// isim VE koşul KAZANILMADAN önce "???" — **ama ZC ödül miktarı/ikonu HER
/// ZAMAN görünür** (2026 İKİNCİ güncelleme — kullanıcının netleştirmesi,
/// ilk sürümde ödül de gizliydi).
///
/// **2026 güncellemesi — altı kategori: İstikrar + Modül Ustalığı +
/// Koleksiyon + Sadakat + Sosyal/Paylaşım + Gizli/Eğlenceli.** `allBadges`
/// kategoriye göre gruplanıp `BadgeCategory.values` SIRASIYLA render
/// ediliyor, her bölüm kendi başlığı ile geliyor ve (ilk hariç) HER
/// bölümün ÜSTÜNE ince bir `Divider` ile diğerinden görsel olarak
/// ayrılıyor (kullanıcının açık isteği). Yeni bir kategori eklendiğinde
/// yalnızca `allBadges`'e (bkz. `consistency_badges.dart`) ve buradaki
/// `_categoryTitle` switch'ine bir `case` eklemek yeterli.
class BadgesGalleryScreen extends StatefulWidget {
  const BadgesGalleryScreen({super.key, this.grantedGift});

  /// `badgeGiftRewards`'ta bir hediyesi olan bir rozet AZ ÖNCE kazanılıp
  /// "Ödülü Al"a basılınca hediye GERÇEKTEN verildiyse (bkz.
  /// `BadgeCelebrationOverlay`), türü + yerelleştirilmiş adı — ilk karede
  /// bir SnackBar ile duyurulur. `null` ise (hediye yoksa VEYA — yalnızca
  /// tema tipinde, teorik olarak nadir — sahip olunmayan standart tema
  /// kalmadıysa) hiçbir şey gösterilmez, normal galeri açılışı.
  final GrantedBadgeGift? grantedGift;

  @override
  State<BadgesGalleryScreen> createState() => _BadgesGalleryScreenState();
}

class _BadgesGalleryScreenState extends State<BadgesGalleryScreen> {
  @override
  void initState() {
    super.initState();
    final granted = widget.grantedGift;
    if (granted == null) return;
    // `showModulesMenuSheet`/`_maybeShowAdFreePromo` ile AYNI "build
    // tamamlanmadan bir SnackBar/dialog göstermek güvenli değil" gerekçesi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = granted.type == BadgeGiftType.costume
          ? l10n.badgeGiftCostumeMessage(granted.name)
          : l10n.badgeSpecialRewardThemeGrantedMessage(granted.name);
      showInfoDialog(context, message);
    });
  }

  String _categoryTitle(AppLocalizations l10n, BadgeCategory category) {
    switch (category) {
      case BadgeCategory.consistency:
        return l10n.badgeCategoryConsistency;
      case BadgeCategory.moduleMastery:
        return l10n.badgeCategoryModuleMastery;
      case BadgeCategory.collection:
        return l10n.badgeCategoryCollection;
      case BadgeCategory.loyalty:
        return l10n.badgeCategoryLoyalty;
      case BadgeCategory.social:
        return l10n.badgeCategorySocial;
      case BadgeCategory.hidden:
        return l10n.badgeCategoryHidden;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byCategory = <BadgeCategory, List<ZiboBadgeDefinition>>{};
    for (final badge in allBadges) {
      byCategory.putIfAbsent(badge.category, () => []).add(badge);
    }
    // `BadgeCategory.values`'ın kendi sırasını koruyor (İstikrar → Modül
    // Ustalığı) — bu, kullanıcının "Modül Ustalığı, İstikrar'ın ALTINDA"
    // isteğiyle birebir (enum'da bu sırayla tanımlı).
    final sections = BadgeCategory.values
        .where((category) => byCategory[category]?.isNotEmpty ?? false)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.badgesGalleryTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in sections) ...[
              if (category != sections.first) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
              ],
              Text(
                _categoryTitle(l10n, category),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // 2026 güncellemesi — kullanıcı "genel olarak çerçeve
                // dikdörtgen şeklinde uzun, biraz kısaltalım" dedi: kartın
                // FİKSE yüksekliği (aspect ratio'dan gelen) kısa metinli
                // rozetlerde altta boşluk bırakıyordu. Görsel/metin/ödül
                // satırı BİR ÖNCEKİ turda büyütüldüğü için 0.5'ten biraz
                // DAHA BÜYÜK (0.62) bir orana çıkarılıp hem kart kısaltıldı
                // hem büyümüş içerik için yeterli pay bırakıldı —
                // `badges_gallery_screen_test.dart` overflow olmadığını
                // doğruluyor.
                childAspectRatio: 0.62,
                children: [
                  for (final badge in byCategory[category]!)
                    _BadgeGalleryCard(badge: badge),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const _greyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _BadgeGalleryCard extends StatelessWidget {
  const _BadgeGalleryCard({required this.badge});

  final ZiboBadgeDefinition badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earned = context.watch<BadgeProvider>().isEarned(badge.id);

    // Gizli/Eğlenceli Rozetler — KAZANILMADAN önce hiçbir şey (görsel/isim/
    // koşul/ödül) ifşa edilmez, bkz. `ZiboBadgeDefinition.isHidden`
    // dokümantasyonu. Kazanıldıktan SONRA `hiddenLocked` `false` olur ve
    // kart TÜM diğer rozetlerle BİREBİR aynı şekilde render edilir.
    final hiddenLocked = badge.isHidden && !earned;

    // Kostüm/tema hediyesi taşıyan DOKUZ rozetten biri mi — bkz.
    // `data/badge_gift_rewards.dart`. Gizli/Eğlenceli Rozetler kategorisi
    // BİLEREK İSTİSNA (kullanıcının isteği: "Gizli Rozetler kategorisi
    // hariç — onlarda bu bilgi de gizli kalmaya devam etsin") — bu yüzden
    // `hiddenLocked` iken satır hiç GÖSTERİLMİYOR, tıpkı isim/koşul gibi.
    final gift = badgeGiftRewards[badge.id];
    final giftCostume = gift?.type == BadgeGiftType.costume
        ? findCostumeById(gift!.costumeId!)
        : null;

    // Kullanıcı isteği: rozet görseli biraz DAHA büyütülsün, çok değil
    // (88 → 108 → 118).
    final image = Image.asset(
      hiddenLocked ? hiddenBadgeMysteryImageAsset : badge.imageAsset,
      width: 118,
      height: 118,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gizem görseli KENDİSİ zaten "bilinmiyor" hissini taşıyan bir
            // tasarım (`gizli_rozet.png`) — normal kazanılmamış rozetlerdeki
            // gibi AYRICA gri tonlamaya/soluklaştırmaya TABİ TUTULMUYOR, tam
            // renkli gösteriliyor.
            earned || hiddenLocked
                ? image
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
                    child: Opacity(opacity: 0.5, child: image),
                  ),
            const SizedBox(height: 10),
            // Kullanıcı isteği: "alttaki yazıların boyutunu büyüt" —
            // ad titleSmall → titleMedium'a, açıklama bodySmall →
            // bodyMedium'a büyütüldü.
            Text(
              hiddenLocked ? l10n.badgeHiddenPlaceholder : badge.localizedName(l10n),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: earned ? null : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                hiddenLocked
                    ? l10n.badgeHiddenPlaceholder
                    : badge.localizedRequirement(l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Kullanıcı isteği: en altta kaç Zibo Coin ödülü olduğu, Zibo
            // Coin ikonu PNG'siyle birlikte gösterilsin — `CoinBalanceWidget`/
            // `CostumeCard`'daki AYNI `assets/images/zibo_coin.webp` kullanımı.
            // 2026 güncellemesi: hem ikon hem metin büyütüldü ("10zc/30zc
            // ve zc ikonunun boyutunu büyüt"). **2026 İKİNCİ güncelleme —
            // Gizli/Eğlenceli Rozetler'de bu satır KAZANILMADAN önce de
            // GÖRÜNÜR** (kullanıcının netleştirmesi: yalnızca isim/koşul
            // "???" kalsın, ödül miktarı/ikonu HER ZAMAN görünsün) — ilk
            // yazımda `hiddenLocked` iken TAMAMEN gizlenmişti, bu satır
            // gizlemeyi KALDIRIP koşulsuz render etmeye çevrildi.
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/zibo_coin.webp', width: 20, height: 20),
                const SizedBox(width: 5),
                Text(
                  l10n.storeCoinAmount(badge.zcReward),
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: earned
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Kostüm/tema hediyesi önizlemesi — kullanıcı isteği: "rozet
            // kartında ZC ödül yazısının HEMEN ALTINA 🎁 emojisi + hediye
            // edilen kostümün/temanın küçük bir önizleme görseli." Kostüm
            // tipi SABİT olduğu için gerçek görseli gösteriyoruz; tema tipi
            // rastgele (yalnızca claim anında belli olduğu) için genel bir
            // palet ikonu gösteriyoruz.
            if (!hiddenLocked && gift != null) ...[
              const SizedBox(height: 4),
              Semantics(
                label: l10n.badgeGiftPreviewLabel(
                  giftCostume?.localizedName(l10n) ??
                      l10n.badgeSpecialRewardThemeNote,
                ),
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    if (giftCostume != null)
                      Image.asset(
                        giftCostume.imageAsset,
                        width: 24,
                        height: 24,
                      )
                    else
                      Icon(
                        Icons.palette_rounded,
                        size: 18,
                        color: colorScheme.tertiary,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
