import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_themes.dart';
import '../data/coin_packages.dart';
import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/app_theme_option.dart';
import '../models/coin_economy.dart';
import '../models/coin_package.dart';
import '../providers/ad_free_provider.dart';
import '../providers/app_streak_provider.dart';
import '../providers/auth_link_provider.dart';
import '../providers/coin_provider.dart';
import '../screens/paywall_screen.dart';
import '../utils/ad_free_promo_trigger.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import '../widgets/costume_card.dart';
import '../widgets/google_link_promo_sheet.dart';
import '../widgets/sticker_style.dart';
import '../widgets/streak_freeze_balance_card.dart' show streakFreezeIconAsset;
import '../widgets/theme_option_card.dart';

/// Mağaza'nın dört segmenti — dışarıdan (ör. Profil > Kostüm Dolabı
/// önizlemesi) doğrudan bir segmentle açılabilmesi için public. `pro`
/// (2026 güncellemesi) — eskiden Ayarlar'ın en üstünde duran paywall giriş
/// noktası, kullanıcı isteğiyle buraya taşındı (bkz. `_ZiboProSection`).
enum StoreSection { coins, costumes, themes, pro }

/// Zibo Coin satın alma ve kostüm mağazası. Alt gezinme çubuğundaki
/// "Mağaza" sekmesi ve başlık çubuğundaki '+' ikonu (aynı sekmeye geçer)
/// buraya götürür; diğer sekmeler gibi RootScreen'in ortak başlık çubuğunu
/// paylaşır, kendi Scaffold/AppBar'ı yoktur.
///
/// İki segment tek sayfada birleşiyor (ayrı bir alt gezinme sekmesi/sayfa
/// yerine): "coin satın alma" ve "coin harcama" akışları aynı girişten
/// (Mağaza) doğal olarak ulaşılabilir kalsın, alt gezinme çubuğu da 4 öğede
/// sabit kalsın diye.
class StoreScreen extends StatefulWidget {
  const StoreScreen({
    super.key,
    this.initialSection = StoreSection.coins,
    this.isActive = true,
  });

  /// Profil > Kostüm Dolabı önizlemesi gibi yerlerden doğrudan "Kostümler"
  /// segmentiyle açılabilmesi için — varsayılan davranış (Mağaza sekmesi/'+'
  /// ikonu) DEĞİŞMEDİ, hep "Coin Al" ile açılır.
  final StoreSection initialSection;

  /// Bu sekmenin şu anda görünen sekme olup olmadığı — `GoalTrackingScreen`
  /// ile AYNI desen (bkz. `RootScreen`'in `IndexedStack`'i, sekmeler hiç
  /// unmount edilmiyor). Paywall tanıtımının (bkz. `paywall_screen.dart`)
  /// HER Mağaza ziyaretinde (ilk mount'ta değil, her sekmeye GEÇİŞTE)
  /// tetiklenebilmesi için gerekli. `costume_closet_
  /// preview.dart` gibi Mağaza'yı push edilen AYRI bir sayfa olarak açan
  /// yerlerde varsayılan `true` yeterli (o bağlamda zaten tek başına
  /// görünüyor).
  final bool isActive;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late StoreSection _section = widget.initialSection;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _maybeShowAdFreePromo();
    }
  }

  @override
  void didUpdateWidget(covariant StoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _maybeShowAdFreePromo();
    }
  }

  /// Tanıtım popup'ı (bkz. CLAUDE.md "Zibo ADS" bölümü) — her Mağaza
  /// ziyaretinde DEĞİL, `AdFreePromoTrigger`'ın basit sayacına göre ARA SIRA
  /// gösterilir. `addPostFrameCallback` ile ertelendi çünkü `initState`/
  /// `didUpdateWidget` sırasında henüz build tamamlanmadan `showModalBottomSheet`
  /// çağırmak (özellikle `didUpdateWidget`'ta, bir üst widget'ın kendi
  /// build'i sürerken) güvenli değil. Kullanıcı ZATEN satın aldıysa hiç
  /// tetiklenmiyor — zaten sahip olduğu bir şeyi tekrar tekrar satmaya
  /// çalışmak can sıkıcı olurdu.
  void _maybeShowAdFreePromo() {
    if (context.read<AdFreeProvider>().isAdFree) return;
    if (!AdFreePromoTrigger.shouldShowOnStoreVisit()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const PaywallScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          l10n.storeTitle,
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontVariations: const [FontVariation('wght', 700)],
            fontSize: 21,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _StoreSegmentedControl(
          selected: _section,
          onChanged: (value) => setState(() => _section = value),
        ),
        const SizedBox(height: 20),
        switch (_section) {
          StoreSection.coins => const _BuyCoinsSection(),
          StoreSection.costumes => const _CostumesSection(),
          StoreSection.themes => const _ThemesSection(),
          StoreSection.pro => const _ZiboProSection(),
        },
      ],
    );
  }
}

/// Mockup'ın `.segmented`/`.seg` — gerçek `SegmentedButton`'ın sticker
/// karşılığı. Hiçbir test bu kontrolü WIDGET TİPİYLE aramıyor (yalnızca
/// `find.text('Kostümler')` gibi etiket metniyle dokunuyor, bkz.
/// `widget_test.dart`), bu yüzden `FilledButton` gibi bir tür kısıtı YOK —
/// tamamen özel bir `Material`/`InkWell` üçlüsü.
class _StoreSegmentedControl extends StatelessWidget {
  const _StoreSegmentedControl({required this.selected, required this.onChanged});

  final StoreSection selected;
  final ValueChanged<StoreSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _segment(context, StoreSection.coins, l10n.storeCoinsTabLabel),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _segment(context, StoreSection.costumes, l10n.storeCostumesTabLabel),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _segment(context, StoreSection.themes, l10n.storeThemesTabLabel),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _segment(context, StoreSection.pro, l10n.storeProTabLabel),
        ),
      ],
    );
  }

  Widget _segment(BuildContext context, StoreSection value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = value == selected;
    final radius = BorderRadius.circular(12);
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          alignment: Alignment.center,
          // Dolgu + kontur + gölge AYNI `BoxDecoration`'da olmalı — ayrı bir
          // `Material` katmanına bölünürse gölge (düz, bulanıksız kopya)
          // kendi dolgusunun ÜSTÜNE değil ALTINDA kalması gereken yerde
          // ÜSTÜNDE boyanıp segmenti tamamen koyu gösteriyordu (gerçekten
          // yaşandı — bkz. git geçmişi).
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : colorScheme.surfaceContainerLowest,
            border: Border.all(color: kStickerOutline, width: 2.5),
            borderRadius: radius,
            boxShadow: active
                ? const [BoxShadow(color: kStickerOutline, offset: Offset(2, 2))]
                : null,
          ),
          // 4. segment (Zibo Pro) eklenince hücreler daraldı — `FittedBox`
          // ile metin gerekirse küçülüyor, `maxLines`/`ellipsis`'in
          // "Zibo Pro" gibi KISALTILMASI anlamsız bir marka adını yarım
          // kesmesindense tam okunur kalması tercih edildi.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: const [FontVariation('wght', 700)],
                fontSize: 12.5,
                color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(borderRadius: radius, onTap: () => onChanged(value)),
          ),
        ),
      ],
    );
  }
}

/// Mockup'ın `.section-title` — küçük, kalın Baloo2 alt başlık.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Baloo2',
        fontVariations: const [FontVariation('wght', 700)],
        fontSize: 14.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _BuyCoinsSection extends StatelessWidget {
  const _BuyCoinsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2026 güncellemesi — kullanıcı isteği: "Zibo ADS" (reklamsız
        // deneyim) yalnızca ARA SIRA çıkan bir tanıtım popup'ı (bkz.
        // `AdFreePromoTrigger`/`StoreScreen._maybeShowAdFreePromo`) değil,
        // kullanıcının istediği ZAMAN satın alabileceği KALICI bir giriş
        // noktası da olsun. **2026-09-22 güncellemesi** — bu kart artık eski
        // dar sheet yerine kapsamlı `PaywallScreen`'i açıyor (bkz.
        // `docs/subscribe_model.md`) — periyodik tetikleyicinin sayaç/
        // cooldown mantığı burada ATLANIYOR (kullanıcı kendi isteğiyle
        // geldiği için bekletmenin anlamı yok).
        _SectionTitle(l10n.storeAdFreeSectionTitle),
        const SizedBox(height: 8),
        const _AdFreeCard(),
        const SizedBox(height: 24),
        _SectionTitle(l10n.streakFreezeStoreSectionTitle),
        const SizedBox(height: 8),
        const _StreakFreezeCard(),
        const SizedBox(height: 24),
        _SectionTitle(l10n.storeFreeSectionTitle),
        const SizedBox(height: 8),
        const _WatchAdCard(),
        const SizedBox(height: 24),
        _SectionTitle(l10n.storePackagesSectionTitle),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // 2026: kartlara "+N bonus" satırı eklendi (bkz. `_PackageCard`) —
          // oran 0.8'den 0.72'ye düşürüldü ki ekstra satır taşmasın (bkz.
          // CLAUDE.md'deki tekrarlayan "yeni içerik → childAspectRatio
          // overflow" dersi; Mağaza widget testi doğruluyor).
          childAspectRatio: 0.72,
          children: [
            for (final package in coinPackages) _PackageCard(package: package),
          ],
        ),
      ],
    );
  }
}

class _CostumesSection extends StatelessWidget {
  const _CostumesSection();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Kilitli kartlar (görsel + isim + fiyat + "Satın Al" butonu) sahip
      // olunan kartlardan (görsel + isim + rozet) daha uzun — en uzun durumu
      // taşırmayacak kadar düşük bir oran seçildi. "Çizgi Roman Çıkartması"
      // restyle'ında kart içeriği (görsel yüksekliği, dolgu, yazı boyutları)
      // küçüldüğü için oran 0.56'dan 0.8'e ÇIKARILMIŞTI, ama gerçek cihazda
      // (384dp genişlik, 2 sütun → ~166dp hücre) kilitli kart içeriği bu
      // oranda ~14px taşıyordu (`_ThemesGrid`'in AYNI gerekçeyle 0.72'ye
      // düşürülmesiyle AYNI kalıp) — 0.7'ye düşürüldü.
      childAspectRatio: 0.7,
      children: [
        for (final costume in costumes) CostumeCard(costume: costume),
      ],
    );
  }
}

class _ThemesSection extends StatelessWidget {
  const _ThemesSection();

  @override
  Widget build(BuildContext context) {
    // 2026 güncellemesi — kullanıcı isteğiyle Standart/Premium ayrımı
    // (ayrı başlıklı iki `GridView`) KALDIRILDI: artık TÜM temalar (statik +
    // premium/animasyonlu) kategori ayrımı olmadan TEK bir listede, ucuzdan
    // pahalıya sıralı gösteriliyor. Her kartın kendi üstündeki "Premium"
    // rozeti (bkz. ThemeOptionCard, `theme.isPremiumAnimated`) hangi
    // temaların animasyonlu olduğunu KART SEVİYESİNDE göstermeye devam
    // ediyor — yalnızca üst düzey grup başlığı kayboldu.
    final sortedThemes = [...appThemes]
      ..sort((a, b) => a.price.compareTo(b.price));

    return _ThemesGrid(themes: sortedThemes);
  }
}

/// Mağaza'nın "Zibo Pro" sekmesi — eskiden Ayarlar'ın en üstünde duran
/// paywall giriş noktasının YERİNE geçti (kullanıcı isteği, 2026-09-23:
/// "artık ayarlar kısmında durmasın"). `PaywallContent(embedded: true)`
/// DOĞRUDAN gömülüyor — ayrı bir sayfaya `Navigator.push` YOK, kullanıcı
/// diğer sekmeler gibi bu sekmeye geçip/çıkabiliyor (bkz. o widget'ın
/// `embedded` dokümantasyonu: kapatma X'i yok, kendi kaydırması yok, satın
/// alma sonrası sekmeden ayrılmıyor).
class _ZiboProSection extends StatelessWidget {
  const _ZiboProSection();

  @override
  Widget build(BuildContext context) {
    return const PaywallContent(embedded: true);
  }
}

class _ThemesGrid extends StatelessWidget {
  const _ThemesGrid({required this.themes});

  final List<AppThemeOption> themes;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      // Kilitli/sahip olunan kartların en uzun içeriği (isim + fiyat/rozet
      // satırı + buton) taşırmayacak kadar düşük bir oran — `CostumeCard`
      // ile AYNI gerekçeyle YÜKSELTİLDİ, ama kostümden biraz daha DÜŞÜK
      // tutuldu (0.72): Premium rozetli kilitli kartlar (kilit + ✨ rozeti
      // + önizleme + isim + fiyat + buton) 0.8'de 4px taşıyordu (widget
      // testiyle yakalandı).
      childAspectRatio: 0.72,
      children: [for (final theme in themes) ThemeOptionCard(theme: theme)],
    );
  }
}

/// Mağaza'nın "Reklamsız Zibo" bölümündeki kalıcı satın alma girişi —
/// `_WatchAdCard` ile AYNI görsel dil (Card + ikon + başlık/alt metin +
/// buton), ama "izleyip kazan" yerine "satın al" akışına bağlı. Basınca
/// `PaywallScreen`'i açar (bkz. `docs/subscribe_model.md`) — periyodik
/// tanıtımın kullandığı AYNI ekran, ikinci bir kopya YAZILMADI. Kullanıcı
/// ZATEN satın aldıysa (bkz. `AdFreeProvider.isAdFree`) buton yerine "Satın
/// Alındı" rozeti gösterilir.
class _AdFreeCard extends StatefulWidget {
  const _AdFreeCard();

  @override
  State<_AdFreeCard> createState() => _AdFreeCardState();
}

class _AdFreeCardState extends State<_AdFreeCard> {
  /// Play Store'dan sorgulanan canlı fiyat — `_PackageCardState._livePrice`
  /// ile AYNI desen (bkz. `AdFreeProvider.queryLocalizedPrice`
  /// dokümantasyonu: sabit `adFreeFallbackPrice` KDV/vergi yüzünden gerçek
  /// fiyattan farklı çıkabiliyor).
  String? _livePrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrice());
  }

  Future<void> _loadLivePrice() async {
    final price = await context.read<AdFreeProvider>().queryLocalizedPrice();
    if (mounted && price != null) setState(() => _livePrice = price);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // `context.watch` — kullanıcı SHEET İÇİNDEN satın alma tamamlayınca bu
    // kart, sekmeden hiç çıkmadan/rebuild TETİKLEMEDEN otomatik "Satın
    // Alındı" durumuna geçmeli (IndexedStack'te sürekli monte kalıyor).
    final isAdFree = context.watch<AdFreeProvider>().isAdFree;
    final priceLabel =
        _livePrice ??
        adFreeFallbackPrice.formattedForLocale(
          Localizations.localeOf(context).languageCode,
        );

    return _StorePromoCard(
      emoji: '👑',
      title: l10n.storeAdFreeCardTitle,
      subtitle: l10n.storeAdFreeCardSubtitle,
      trailing: isAdFree
          ? IntrinsicWidth(
              child: StickerStatusPill(
                label: l10n.storeAdFreeCardPurchasedLabel,
                filled: true,
              ),
            )
          : _StorePromoCta(
              label: priceLabel,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              ),
            ),
    );
  }
}

/// Zibo Coin ile alınan, stoğa eklenen Streak Freeze. Seri kırılmak
/// üzereyken `StreakFreezeOfferDialog` önce bu stoğu kullanır.
class _StreakFreezeCard extends StatelessWidget {
  const _StreakFreezeCard();

  Future<void> _buy(BuildContext context) async {
    final coins = context.read<CoinProvider>();
    if (coins.balance < CoinEconomy.streakFreezeStorePrice ||
        !coins.spendStreakFreezeStorePurchase()) {
      showInsufficientCoinsWarning(context);
      return;
    }
    final streak = context.read<AppStreakProvider>()..addOwnedStreakFreeze();
    final l10n = AppLocalizations.of(context)!;
    await showInfoDialog(
      context,
      l10n.streakFreezePurchasedMessage(streak.ownedStreakFreezes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final owned = context.watch<AppStreakProvider>().ownedStreakFreezes;
    return _StorePromoCard(
      leading: Image.asset(streakFreezeIconAsset, width: 38, height: 38),
      title: l10n.streakFreezeStoreCardTitle,
      subtitle: l10n.streakFreezeStoreCardSubtitle(owned),
      trailing: _StorePromoCta(
        key: const Key('streakFreezeStoreBuyButton'),
        label: '${CoinEconomy.streakFreezeStorePrice} ZC',
        onTap: () => _buy(context),
      ),
    );
  }
}

/// Mockup'ın `.promo-card` — "Reklamsız Zibo"/"Ücretsiz" bölümlerindeki iki
/// kart (bkz. `_AdFreeCard`/`_WatchAdCard`) AYNI ikon dairesi + başlık/alt
/// metin + sağdaki CTA yerleşimini paylaşıyor. [leading] verilirse emoji
/// dairesinin yerine geçer.
class _StorePromoCard extends StatelessWidget {
  const _StorePromoCard({
    this.emoji = '',
    this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String emoji;
  final Widget? leading;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          leading ??
              DecoratedBox(
                decoration: stickerCircleDecoration(
                  fill: colorScheme.primary,
                  borderWidth: 2.5,
                  shadowOffset: Offset.zero,
                ),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17, height: 1))),
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 13.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

/// Mockup'ın `.promo-card .cta` — altın dolgulu, köşeli sticker düğme.
/// `_StorePromoCard`'ın CTA'sı `FilledButton` OLMAK ZORUNDA DEĞİL (hiçbir
/// test bu iki kartı widget tipiyle aramıyor, yalnızca fiyat/"İzle"
/// METNİYLE dokunuyor — bkz. `widget_test.dart`), bu yüzden düz bir
/// `GestureDetector` yeterli.
class _StorePromoCta extends StatelessWidget {
  const _StorePromoCta({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(10);
    return stickerButtonShadow(
      child: Material(
        color: onTap == null ? colorScheme.primary.withValues(alpha: 0.5) : colorScheme.primary,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: kStickerOutline, width: 2.5),
              borderRadius: radius,
            ),
            child: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontSize: 12,
                      color: colorScheme.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

void _showCoinsAddedSnackBar(BuildContext context, int amount) {
  final l10n = AppLocalizations.of(context)!;
  showInfoDialog(context, l10n.storeCoinsAdded(amount));
}

class _WatchAdCard extends StatefulWidget {
  const _WatchAdCard();

  @override
  State<_WatchAdCard> createState() => _WatchAdCardState();
}

class _WatchAdCardState extends State<_WatchAdCard> {
  bool _loading = false;

  Future<void> _watchAd(BuildContext context) async {
    setState(() => _loading = true);
    final rewarded = await context.read<CoinProvider>().earnAdWatch();
    if (!mounted) return;
    setState(() => _loading = false);
    if (rewarded && context.mounted) {
      _showCoinsAddedSnackBar(context, CoinEconomy.adWatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Günlük hak tükendiyse (bkz. CoinProvider.maxDailyAdWatches) kart
    // "pasif" görünür: alt metin uyarı mesajına döner, buton devre dışı
    // kalır — kullanıcı `_WatchAdCardState` bunu her `build()`'de canlı
    // izlediği için (context.watch) reklam izleyip hakkı tükettiği ANDA
    // (ayrı bir sayfa yenilemeye gerek kalmadan) kart otomatik güncellenir.
    final canWatch = context.watch<CoinProvider>().canWatchAdForCoinsToday;

    return _StorePromoCard(
      emoji: '📺',
      title: l10n.storeWatchAdTitle,
      subtitle: canWatch
          ? l10n.storeWatchAdSubtitle(CoinEconomy.adWatch)
          : l10n.dailyAdLimitReachedMessage,
      trailing: _StorePromoCta(
        label: l10n.storeWatchAdButton,
        loading: _loading,
        onTap: (_loading || !canWatch) ? null : () => _watchAd(context),
      ),
    );
  }
}

class _PackageCard extends StatefulWidget {
  const _PackageCard({required this.package});

  final CoinPackage package;

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _loading = false;

  /// Play Store'dan sorgulanan canlı fiyat metni (bkz.
  /// `CoinProvider.queryLocalizedPrice`) — `null` kaldığı sürece (mağaza
  /// henüz yanıt vermedi, ürün Play Console'da aktif değil, testte
  /// `MockPurchaseService` her zaman `null` döner) [CoinPackage.price]'taki
  /// sabit fiyat gösterilmeye devam eder, ekranda hiçbir "yükleniyor"
  /// durumu YOK — bu tamamen sessiz bir arka plan iyileştirmesi.
  String? _livePrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLivePrice());
  }

  Future<void> _loadLivePrice() async {
    final price = await context.read<CoinProvider>().queryLocalizedPrice(
      widget.package,
    );
    if (mounted && price != null) setState(() => _livePrice = price);
  }

  Future<void> _buy(BuildContext context) async {
    // Kullanıcı isteği: İLK gerçek coin satın alma DENEMESİNDE, hesap
    // henüz Google'a bağlı değilse önce bir teşvik sheet'i göster (zorunlu
    // DEĞİL — "Şimdilik Atla" ile atlanabilir, ne yapılırsa yapılsın
    // aşağıdaki satın alma normal şekilde devam eder). `hasSeenLinkPrompt`
    // sayesinde bu YALNIZCA bir kez (ilk denemede) gösteriliyor — sonraki
    // satın almalarda tekrar sormuyor.
    final authLink = context.read<AuthLinkProvider>();
    if (!authLink.isLinked && !authLink.hasSeenLinkPrompt) {
      await authLink.markLinkPromptSeen();
      if (!context.mounted) return;
      await showGoogleLinkPromoSheet(context);
      if (!context.mounted) return;
    }

    setState(() => _loading = true);
    final success = await context.read<CoinProvider>().purchaseCoinPackage(
      widget.package,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!context.mounted) return;
    if (success) {
      // Bonus dahil GERÇEK eklenen tutar (bkz. CoinPackage.totalCoins).
      _showCoinsAddedSnackBar(context, widget.package.totalCoins);
    } else {
      final l10n = AppLocalizations.of(context)!;
      showInfoDialog(context, l10n.storePurchaseFailedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60 * widget.package.imageScale,
            height: 60 * widget.package.imageScale,
            child: Image.asset(
              widget.package.imageAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.storeCoinAmount(widget.package.coinAmount),
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
          if (widget.package.bonusCoins > 0) ...[
            const SizedBox(height: 1),
            Text(
              l10n.storeCoinBonus(widget.package.bonusCoins),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kGoldDeep,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
          const SizedBox(height: 7),
          stickerButtonShadow(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: stickerFilledButtonStyle(context, fontSize: 11.5),
                onPressed: _loading ? null : () => _buy(context),
                child: _loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        _livePrice ??
                            widget.package.price?.formatted ??
                            l10n.storeBuyButton,
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    // Dıştaki `Card` GÖRSEL OLARAK şeffaf — `widget_test.dart`'ın
    // `package100Card` gibi `find.byType(Card)` ile bulduğu ANCESTOR
    // hâlâ mevcut olsun diye korunuyor (bkz. `CostumeCard`'daki AYNI not).
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Container(
        decoration: stickerDecoration(
          fill: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      ),
    );
  }
}
