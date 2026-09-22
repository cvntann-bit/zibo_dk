import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/founder_badge.dart';
import '../l10n/app_localizations.dart';
import '../models/bond_level.dart';
import '../models/xp_level.dart';
import '../providers/auth_link_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/favorite_quotes_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/instagram_follow_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_archive_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
import '../providers/xp_provider.dart';
import '../screens/address_term_screen.dart';
import '../screens/bond_level_screen.dart';
import '../screens/coin_summary_screen.dart';
import '../screens/favorite_quotes_screen.dart';
import '../screens/longest_streak_screen.dart';
import '../screens/monthly_stats_history_screen.dart';
import '../screens/referral_screen.dart';
import '../services/photo_picker_service.dart';
import '../utils/google_link_action.dart';
import '../utils/profile_stats.dart';
import '../widgets/costume_closet_preview.dart';
import '../widgets/founder_badge_promo_card.dart';
import '../widgets/instagram_follow_card.dart';
import '../widgets/mood_trend_detail_chart.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_share_sheet.dart';

/// **2026 bug düzeltmesi — Crashlytics'teki EN BÜYÜK tekrarlayan hata**
/// (`_File.length` → `PathNotFoundException`, `FileImage._loadAsync`
/// üzerinden — bkz. `manifest_journal_screen.dart`'taki `_SafeFileImage`
/// dokümantasyonu, AYNI kök neden: "cihazlar arası fotoğraf taşınmaz"
/// sınırlaması yüzünden `photoPath` cihazda artık var olmayan bir dosyaya
/// işaret edebiliyor). Profil fotoğrafı BİR TANE olduğu ve `CircleAvatar.
/// backgroundImage` bir `ImageProvider` (widget DEĞİL, `Image.file`'ın
/// `errorBuilder`'ı gibi bir savunma mekanizması hiç YOK) beklediği için,
/// dosyanın gerçekten OKUNABİLİR olup olmadığını `build()` sırasında
/// senkron kontrol eden küçük bir yardımcı.
bool _hasReadablePhoto(String? photoPath) {
  if (photoPath == null) return false;
  try {
    return File(photoPath).existsSync();
  } catch (_) {
    return false;
  }
}

/// Profil sayfası: üstte kullanıcının fotoğrafı + ismi (ikisi de kalıcı,
/// `ProfileProvider` üzerinden Firestore'a senkronize), altında
/// "İstatistiklerim" — dört sabit kategorinin (bkz. `ProfileStats`) her biri
/// kendi kartında bir trend grafiği + 0-10 dairesel puan göstergesi.
/// **Alt gezinme çubuğunun ÜÇÜNCÜ sekmesi** (eskiden Birikim'in yeri —
/// kullanıcı isteğiyle yer değiştirdiler, bkz. CLAUDE.md "Alt Gezinme
/// Çubuğu" bölümü) — bu yüzden diğer sekmeler (Ana Sayfa/Hedefler/Mağaza)
/// gibi kendi Scaffold/AppBar'ı YOK, RootScreen'in ortak AppBar'ını
/// paylaşıyor.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.photoService = const ImagePickerPhotoService(),
    this.isActive = true,
  });

  /// Galeri seçimi + kalıcı depolama — testte sahte bir implementasyon
  /// enjekte edilebilir (bkz. `PhotoPickerService` dokümantasyonu).
  final PhotoPickerService photoService;

  /// `GoalTrackingScreen`/`StoreScreen` ile AYNI desen (bkz. `RootScreen`'in
  /// `IndexedStack`'i, sekmeler hiç unmount edilmiyor) — 2026 güncellemesi:
  /// "İstatistiklerim" bölümündeki dairesel puan göstergelerinin (bkz.
  /// `CircularScoreGauge`) sekmeye HER girişte 0'dan tekrar dolma
  /// animasyonu oynaması için gerekli, `IndexedStack` sekmeyi hiç
  /// unmount etmediğinden bu sinyal olmadan animasyon yalnızca İLK
  /// ziyarette çalışırdı.
  final bool isActive;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isPicking = false;

  /// Her artışında "İstatistiklerim" alt ağacına YENİ bir `Key` verilip
  /// (bkz. `build()`) o alt ağaç TAMAMEN yeniden kurdurulur — içindeki her
  /// `CircularScoreGauge`'un `initState()`'i baştan çalışır, dolma+sayaç
  /// animasyonu sıfırdan tekrar oynar. İlk yüklemede de (varsayılan `0`)
  /// bir kez oynaması için ayrıca bir tetikleme GEREKMEZ.
  int _statsReplayKey = 0;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        context.read<ProfileProvider>().setName(_nameController.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(() => _statsReplayKey++);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _openShareCard(
    BuildContext context,
    AppLocalizations l10n,
    ProfileProvider profile,
    List<CategoryStat> stats,
  ) {
    final days = profile.daysSinceFirstUsed();
    final level = bondLevelForDays(days);
    final buffer = StringBuffer()
      ..writeln(l10n.profileShareCardTitle)
      ..writeln()
      ..writeln(
        // Hitap tercihi BİLEREK uygulanmıyor (bkz. bond_level_screen.dart
        // içindeki aynı gerekçe) — "kankasın" eki kullanıcının kendi
        // adıyla anlamsızlaşıyordu.
        '${level.localizedName(l10n)} · '
        '${l10n.profileBondLevelRowSubtitle(days)}',
      )
      ..writeln();
    for (final stat in stats) {
      final score = stat.hasData ? stat.score.toStringAsFixed(1) : '–';
      buffer.writeln('${_statTitle(l10n, stat.category)}: $score/10');
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ZiboShareSheet(message: buffer.toString().trim()),
    );
  }

  String _statTitle(AppLocalizations l10n, ProfileStatCategory category) {
    switch (category) {
      case ProfileStatCategory.money:
        return l10n.profileStatMoneyTitle;
      case ProfileStatCategory.gratitudeManifest:
        return l10n.profileStatGratitudeManifestTitle;
      case ProfileStatCategory.consistency:
        return l10n.profileStatConsistencyTitle;
      case ProfileStatCategory.selfCareHealth:
        return l10n.profileStatSelfCareTitle;
    }
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPicking = true);
    try {
      final picked = await widget.photoService.pickFromGallery();
      if (picked == null || !mounted) return;
      final permanentPath = await widget.photoService.saveToPermanentStorage(picked);
      if (!mounted) return;
      final profile = context.read<ProfileProvider>();
      final oldPath = profile.photoPath;
      await profile.setPhotoPath(permanentPath);
      // Profilde her zaman TEK bir aktif fotoğraf var (Manifest Günlüğü'nün
      // aksine — orada aynı gün birden fazla fotoğraf birikip hepsi
      // saklanıyor) — eskisinin yerini yenisi aldığı için öksüz dosya
      // kalmasın diye best-effort silinir.
      if (oldPath != null) unawaited(widget.photoService.deletePhoto(oldPath));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileProvider>();
    if (!_nameFocusNode.hasFocus && _nameController.text != profile.name) {
      _nameController.text = profile.name;
    }

    final money = context.watch<MoneyProvider>();
    // Faz 5 (D2) — Zibo Pro+'a özel detaylı Ruh Hali trend grafiği.
    final mood = context.watch<MoodProvider>();
    final gratitude = context.watch<GratitudeProvider>();
    final manifest = context.watch<ManifestProvider>();
    final goals = context.watch<GoalsProvider>();
    final water = context.watch<WaterProvider>();
    final coin = context.watch<CoinProvider>();
    // 2026 yeni özellik — Level/XP Sistemi + Odak Sayacı (bkz. CLAUDE.md).
    final xpProgress = context.watch<XpProvider>().progress;
    final focus = context.watch<FocusProvider>();
    final favoriteQuotes = context.watch<FavoriteQuotesProvider>();
    final authLink = context.watch<AuthLinkProvider>();
    final referral = context.watch<ReferralProvider>();
    final isFounder = context
        .watch<CostumeProvider>()
        .isOwned(founderBadgeCostumeId);
    // Faz 5 (C2) — Zibo Pro/Pro+ rozeti, avatarın boş kalan tek köşesinde
    // (sol-üst Kurucu Üye'de, sağ-alt kamera/düzenle ikonunda dolu).
    final subscription = context.watch<SubscriptionProvider>();
    final statsArchive = context.watch<ProfileStatsArchiveProvider>();
    final now = context.watch<TrustedTimeProvider>().now();

    final stats = ProfileStats.compute(
      money: money,
      gratitude: gratitude,
      manifest: manifest,
      goals: goals,
      water: water,
      now: now,
    );

    // Takvim ayı değiştiyse (bkz. `ProfileStatsArchiveProvider` dokümantasyonu)
    // az önce hesaplanan `stats`'ı önceki ayın arşiv kaydı olarak sakla — aynı
    // ay içindeki tekrar çağrılar ucuz bir no-op, `build()` sırasında
    // `notifyListeners()` tetiklenmesin diye bir sonraki kareye erteleniyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      statsArchive.archiveIfMonthChanged(stats, now);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
            Center(
              child: GestureDetector(
                onTap: _isPicking ? null : _pickPhoto,
                child: Semantics(
                  label: l10n.profilePhotoSemanticLabel,
                  button: true,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      children: [
                        DecoratedBox(
                          decoration: stickerCircleDecoration(
                            fill: colorScheme.surfaceContainerLowest,
                            borderWidth: 3,
                            shadowOffset: const Offset(4, 4),
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.transparent,
                            // **2026 bug düzeltmesi — Crashlytics'teki EN
                            // BÜYÜK tekrarlayan hata (bkz.
                            // `manifest_journal_screen.dart`'taki
                            // `_SafeFileImage` dokümantasyonu — AYNI kök
                            // neden, AYNI çözüm). Burada `errorBuilder` BİLE
                            // YOKTU (`backgroundImage` bir `ImageProvider`,
                            // `Image.file` widget'ı DEĞİL) — dosya var mı
                            // diye ÖNCEDEN `existsSync()` ile kontrol edip
                            // yoksa `person_rounded` ikonuna düşüyoruz, hiç
                            // `FileImage` OLUŞTURMUYORUZ.
                            backgroundImage: _hasReadablePhoto(profile.photoPath)
                                ? FileImage(File(profile.photoPath!))
                                : null,
                            child: _hasReadablePhoto(profile.photoPath)
                                ? null
                                : Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: stickerCircleDecoration(
                              fill: colorScheme.primary,
                              borderWidth: 2.5,
                              shadowOffset: Offset.zero,
                            ),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: _isPicking
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onPrimary,
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: colorScheme.onPrimary,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        // 2026 yeni özellik — "Kurucu Üye" rozeti (bkz.
                        // CLAUDE.md "Kurucu Üye" bölümü). Kullanıcının
                        // "profilde bu rozeti gösteren küçük bir simge
                        // olsun" isteği — tam bir `_ProfileLinkRow` DEĞİL,
                        // fotoğrafın karşı köşesinde küçük bir rozet.
                        // Sahiplik `CostumeProvider.isOwned` üzerinden
                        // (bkz. yukarıdaki `isFounder`) TAMAMEN
                        // istemci-dışı bir yoldan geliyor — yalnızca
                        // `notification-scripts/src/grantFounderBadges.js`
                        // (bir kerelik bakım betiği) tarafından
                        // Firestore'a yazılabilir.
                        if (isFounder)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Tooltip(
                              message: l10n.founderBadgeTooltip,
                              child: Image.asset(
                                founderBadgeImageAsset,
                                width: 28,
                                height: 28,
                                semanticLabel: l10n.founderBadgeTooltip,
                              ),
                            ),
                          ),
                        // Faz 5 (C2) — Kurucu Üye rozetiyle AYNI desen,
                        // boş kalan tek köşede (sol-alt). Free kullanıcıda
                        // HİÇBİR şey eklenmez.
                        if (subscription.isProPlus)
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: Tooltip(
                              message: l10n.subscriptionBadgeProPlusTooltip,
                              child: Image.asset(
                                'assets/images/proplus_badge.png',
                                width: 28,
                                height: 28,
                                semanticLabel: l10n.subscriptionBadgeProPlusTooltip,
                              ),
                            ),
                          )
                        else if (subscription.isPro)
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: Tooltip(
                              message: l10n.subscriptionBadgeProTooltip,
                              child: Image.asset(
                                'assets/images/pro_badge.png',
                                width: 28,
                                height: 28,
                                semanticLabel: l10n.subscriptionBadgeProTooltip,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DashedUnderline(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 19,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.profileNameHint,
                    border: InputBorder.none,
                    // Global `InputDecorationTheme` (bkz. main.dart)
                    // `filled:true, fillColor: colorScheme.surfaceContainer`
                    // veriyor — dashed alt çizginin İÇİNDE sarımsı bir dolgu
                    // olarak göründüğü için burada AÇIKÇA kapatılıyor.
                    filled: false,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(bottom: 8),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => context.read<ProfileProvider>().setName(value),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 2026 yeni özellik — Level/XP Sistemi. Mevcut seviye + bir
            // sonraki seviyeye ne kadar kaldığını gösteren bir ilerleme
            // çubuğu (bkz. CLAUDE.md "Level/XP Sistemi" bölümü).
            _LevelProgressCard(progress: xpProgress),
            const SizedBox(height: 12),
            // 2026 yeni özellik — Instagram Takip Kartı ve Ödülü. Zaten
            // takip ödülü alınmışsa kart kendini gizler (bkz. widget'ın
            // kendi dokümantasyonu) — bu yüzden koşulsuz her build'de eklenir.
            const InstagramFollowCard(),
            const SizedBox(height: 20),
            Text(
              l10n.profileStatsSectionTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: ValueKey(_statsReplayKey),
              child: Column(
                children: [
                  for (final stat in stats) ...[
                    ProfileStatCard(stat: stat),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            // Faz 5 (D2) — Zibo Pro+'a özel, EK bir kart (mevcut 4
            // `ProfileStatCard`'a Ruh Hali hiç dahil değildi, HİÇBİRİNE
            // dokunulmuyor). Pro/free hiçbir şey görmez.
            if (subscription.isProPlus) ...[
              StickerCard(
                child: MoodTrendDetailChart(entries: mood.entries),
              ),
              const SizedBox(height: 12),
            ],
            StickerRowCard(
              emoji: '📅',
              title: l10n.monthlyStatsRowTitle,
              subtitle: l10n.monthlyStatsRowSubtitle(statsArchive.snapshots.length),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MonthlyStatsHistoryScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.profileBondSectionTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            StickerRowCard(
              emoji: '💗',
              title: l10n.bondLevelScreenTitle,
              // Hitap tercihi BİLEREK uygulanmıyor (bkz. bond_level_screen.dart).
              subtitle: l10n.profileBondLevelRowSubtitle(
                profile.daysSinceFirstUsed(),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BondLevelScreen()),
              ),
            ),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '🔥',
              title: l10n.longestStreakScreenTitle,
              subtitle: l10n.profileStreakRowSubtitle(goals.longestStreak),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LongestStreakScreen()),
              ),
            ),
            const SizedBox(height: 12),
            // 2026 yeni özellik — Odak Sayacı modülü. Mevcut 4 kategorili
            // İstatistiklerim sistemine DAHİL EDİLMEDİ (bkz. CLAUDE.md
            // "Odak Sayacı" bölümündeki kapsam kararı) — bunun yerine
            // diğer basit istatistik satırlarıyla (Bağ Seviyesi/En Uzun
            // Seri) AYNI görsel dilde, ayrı bir bilgi satırı. Bir sayfaya
            // NAVİGE ETMİYOR (Odak Sayacı zaten Z-menüsünden erişiliyor),
            // bu yüzden [StickerRowCard.onTap] BİLEREK `null` bırakılıyor —
            // `onTap == null` iken sağdaki köşeli ok da otomatik gizleniyor.
            StickerRowCard(
              emoji: '⏱️',
              title: l10n.profileFocusRowTitle,
              subtitle: l10n.profileFocusRowSubtitle(
                _formatFocusDuration(focus.totalFocusSeconds),
              ),
            ),
            const SizedBox(height: 12),
            const CostumeClosetPreview(),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '🐖',
              title: l10n.coinSummaryScreenTitle,
              subtitle: l10n.profileCoinSummaryRowSubtitle(
                coin.totalEarned,
                coin.totalSpent,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CoinSummaryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '💬',
              title: l10n.addressTermScreenTitle,
              subtitle: l10n.profileAddressTermRowSubtitle(profile.addressTerm),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressTermScreen()),
              ),
            ),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '🤍',
              title: l10n.favoriteQuotesScreenTitle,
              subtitle: l10n.profileFavoriteQuotesRowSubtitle(
                favoriteQuotes.quotes.length,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoriteQuotesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '📤',
              title: l10n.profileShareCardRowTitle,
              subtitle: l10n.profileShareCardRowSubtitle,
              onTap: () => _openShareCard(context, l10n, profile, stats),
            ),
            const SizedBox(height: 12),
            StickerRowCard(
              emoji: '➕',
              title: l10n.referralRowTitle,
              subtitle: referral.hasRedeemed
                  ? l10n.referralAlreadyRedeemedStatus
                  : l10n.referralRowSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReferralScreen()),
              ),
            ),
            const SizedBox(height: 12),
            const FounderBadgePromoCard(),
            StickerRowCard(
              emoji: authLink.isLinked ? '✅' : '🔗',
              // Mockup'ta bu satırın ikon dairesi TEK istisna — diğer tüm
              // satırlar altın dolgu, bu beyaz zemin (`.row-icon{background:
              // #fff}`).
              iconBackground: colorScheme.surfaceContainerLowest,
              title: authLink.isLinked
                  ? l10n.googleLinkRowTitleLinked
                  : l10n.googleLinkRowTitleUnlinked,
              subtitle: authLink.isLinked
                  ? (authLink.linkedEmail ?? '')
                  : l10n.googleLinkRowSubtitle,
              onTap: () => handleGoogleLinkTap(context),
            ),
      ],
    );
  }
}

/// 2026 yeni özellik — Level/XP Sistemi. Mevcut seviye + bir sonraki
/// seviyeye ne kadar kaldığını gösteren küçük bir kart (bkz. CLAUDE.md
/// "Level/XP Sistemi" bölümü) — sticker kart + "Lv. N" altın hap rozeti +
/// ilerleme çubuğu + XP metni (bkz. `docs/theme_new.md` "Onaylanan: Profil
/// sekmesi").
class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profileLevelRowTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  border: Border.all(color: kStickerOutline, width: 2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Lv. ${progress.level}',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 13,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(color: kStickerOutline, width: 2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.fraction.clamp(0.0, 1.0),
                child: ColoredBox(color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.profileLevelProgressLabel(
                progress.xpIntoLevel,
                progress.xpForNextLevel,
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Basit saniye toplamını "{saat} sa {dakika} dk" / "{dakika} dk" biçiminde
/// insan-okunur bir metne çevirir — `profileFocusRowSubtitle`'ın
/// `{durationText}` parametresi için.
String _formatFocusDuration(int totalSeconds) {
  final totalMinutes = totalSeconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0) return '$hours sa $minutes dk';
  return '$minutes dk';
}

