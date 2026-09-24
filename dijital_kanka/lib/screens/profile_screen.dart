import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/founder_badge.dart';
import '../l10n/app_localizations.dart';
import '../models/bond_level.dart';
import '../models/xp_level.dart';
import '../providers/app_streak_provider.dart';
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
    final gratitude = context.watch<GratitudeProvider>();
    final manifest = context.watch<ManifestProvider>();
    final goals = context.watch<GoalsProvider>();
    final appStreak = context.watch<AppStreakProvider>();
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

    // Faz 6 düzeltmesi — Pro/Pro+ halka çerçevesi eskiden 112x112 avatar
    // kutusunun 41px DIŞINA taşıyordu (`Positioned(left:-41,...)` +
    // `Clip.none`). Artık dış kutu, çerçeveyi TAM içine alacak büyüklükte
    // (`_frameDiameter`) hesaplanıyor — hiçbir şey kendi kutusunun dışına
    // taşmıyor, `Clip.none` gerekmiyor. Avatar çapı da (112 → 96) biraz
    // küçültüldü.
    const avatarDiameter = 96.0;
    const frameDiameter = 168.0;
    final hasFrame = subscription.isPro;
    final avatarOuterSize = hasFrame ? frameDiameter : avatarDiameter;

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
                    width: avatarOuterSize,
                    height: avatarOuterSize,
                    child: Stack(
                      children: [
                        // Faz 5 (C2) — Zibo Pro/Pro+ çerçevesi: avatarın
                        // TAMAMINI saran bir halka (`pro_profile_frame.webp`/
                        // `proplus_profile_frame.webp`, Zibo Pro(+)
                        // materyalleri). `Positioned.fill` ile dış kutuyu
                        // (`frameDiameter`) TAM dolduruyor — kutu halkayı
                        // içerecek büyüklükte hesaplandığı için taşma YOK.
                        // `IgnorePointer` — halka fotoğraf değiştirme dokunma
                        // alanını ENGELLEMESİN.
                        if (subscription.isProPlus)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Image.asset(
                                'assets/images/proplus_profile_frame.webp',
                                semanticLabel: l10n.subscriptionBadgeProPlusTooltip,
                              ),
                            ),
                          )
                        else if (subscription.isPro)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Image.asset(
                                'assets/images/pro_profile_frame.webp',
                                semanticLabel: l10n.subscriptionBadgeProTooltip,
                              ),
                            ),
                          ),
                        Center(
                          child: DecoratedBox(
                            // Faz 6 düzeltmesi — Pro/Pro+ halkası zaten
                            // kendi kalın konturunu taşıyor; avatarın KENDİ
                            // ofsetli sticker gölgesi (varsayılan sağ-alta
                            // kaymış düz silüet) dar halka boşluğunun İÇİNDE
                            // asimetrik bir siyah hilal olarak taşıp
                            // dairenin "yamuk" görünmesine sebep oluyordu —
                            // çerçeve VARKEN gölge kaldırılıyor.
                            decoration: stickerCircleDecoration(
                              fill: colorScheme.surfaceContainerLowest,
                              borderWidth: 3,
                              shadowOffset: hasFrame ? Offset.zero : const Offset(4, 4),
                            ),
                            child: CircleAvatar(
                              radius: avatarDiameter / 2,
                              backgroundColor: Colors.transparent,
                              // **2026 bug düzeltmesi — Crashlytics'teki EN
                              // BÜYÜK tekrarlayan hata (bkz.
                              // `manifest_journal_screen.dart`'taki
                              // `_SafeFileImage` dokümantasyonu — AYNI kök
                              // neden, AYNI çözüm). Burada `errorBuilder`
                              // BİLE YOKTU (`backgroundImage` bir
                              // `ImageProvider`, `Image.file` widget'ı
                              // DEĞİL) — dosya var mı diye ÖNCEDEN
                              // `existsSync()` ile kontrol edip yoksa "+"
                              // ikonuna düşüyoruz, hiç `FileImage`
                              // OLUŞTURMUYORUZ.
                              backgroundImage: _hasReadablePhoto(profile.photoPath)
                                  ? FileImage(File(profile.photoPath!))
                                  : null,
                              // Faz 6 düzeltmesi — ayrı bir köşe
                              // kamera-rozeti YERİNE: fotoğraf yoksa
                              // avatarın TAM ortasında büyük bir "+"
                              // ikonu (kullanıcının isteği), fotoğraf
                              // eklenince o alan fotoğrafla değişir.
                              // Yükleniyor durumu AYNI merkezi konumda
                              // küçük bir döner gösterge.
                              child: _isPicking
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  : (_hasReadablePhoto(profile.photoPath)
                                        ? null
                                        : Icon(
                                            Icons.add_rounded,
                                            size: 40,
                                            color: colorScheme.onSurfaceVariant,
                                          )),
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
            if (isFounder) ...[
              const _FounderBadgeBanner(),
              const SizedBox(height: 12),
            ],
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
              subtitle: l10n.profileStreakRowSubtitle(appStreak.longestStreakEver),
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

/// Faz 6 düzeltmesi — "Kurucu Üye" rozeti eskiden avatarın sol-üst köşesinde
/// küçük bir simgeydi (kullanıcı bu konumdan memnun değildi). Profil
/// başlığının hemen altına, ayrı bir vurgu şeridi olarak taşındı. Kurucu Üye
/// BİLEREK `consistency_badges.dart`/Rozetler Galerisi'nin DIŞINDA (satılamaz
/// bir pseudo-kostüm, bkz. `founder_badge.dart`) — bu yüzden Galeri'nin
/// `ZiboBadgeDefinition` tabanlı kart sistemini kullanmak yerine kendi basit
/// şeridini alıyor. Yalnızca `isFounder` iken görünür.
class _FounderBadgeBanner extends StatelessWidget {
  const _FounderBadgeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: stickerDecoration(
        fill: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Image.asset(
            founderBadgeImageAsset,
            width: 32,
            height: 32,
            semanticLabel: l10n.founderBadgeTooltip,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.founderBadgeTooltip,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 14,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.founderBadgeEarnedSubtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colorScheme.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
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

