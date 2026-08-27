import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/bond_level.dart';
import '../providers/auth_link_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/favorite_quotes_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/money_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_archive_provider.dart';
import '../providers/referral_provider.dart';
import '../providers/trusted_time_provider.dart';
import '../providers/water_provider.dart';
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
import '../widgets/profile_stat_card.dart';
import '../widgets/zibo_share_sheet.dart';

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
    final water = context.watch<WaterProvider>();
    final coin = context.watch<CoinProvider>();
    final favoriteQuotes = context.watch<FavoriteQuotesProvider>();
    final authLink = context.watch<AuthLinkProvider>();
    final referral = context.watch<ReferralProvider>();
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
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: colorScheme.surfaceContainerHigh,
                          backgroundImage: profile.photoPath != null
                              ? FileImage(File(profile.photoPath!))
                              : null,
                          child: profile.photoPath == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: colorScheme.primary,
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
                                    size: 18,
                                    color: colorScheme.onPrimary,
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
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: l10n.profileNameHint,
                border: InputBorder.none,
                isCollapsed: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => context.read<ProfileProvider>().setName(value),
            ),
            const SizedBox(height: 32),
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
            _ProfileLinkRow(
              icon: Icons.calendar_month_rounded,
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
            _ProfileLinkRow(
              icon: Icons.favorite_rounded,
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
            _ProfileLinkRow(
              icon: Icons.local_fire_department_rounded,
              title: l10n.longestStreakScreenTitle,
              subtitle: l10n.profileStreakRowSubtitle(goals.longestStreak),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LongestStreakScreen()),
              ),
            ),
            const SizedBox(height: 12),
            const CostumeClosetPreview(),
            const SizedBox(height: 12),
            _ProfileLinkRow(
              icon: Icons.savings_outlined,
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
            _ProfileLinkRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.addressTermScreenTitle,
              subtitle: l10n.profileAddressTermRowSubtitle(profile.addressTerm),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressTermScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileLinkRow(
              icon: Icons.favorite_border_rounded,
              title: l10n.favoriteQuotesScreenTitle,
              subtitle: l10n.profileFavoriteQuotesRowSubtitle(
                favoriteQuotes.quotes.length,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoriteQuotesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileLinkRow(
              icon: Icons.ios_share_rounded,
              title: l10n.profileShareCardRowTitle,
              subtitle: l10n.profileShareCardRowSubtitle,
              onTap: () => _openShareCard(context, l10n, profile, stats),
            ),
            const SizedBox(height: 12),
            _ProfileLinkRow(
              icon: Icons.person_add_alt_1_rounded,
              title: l10n.referralRowTitle,
              subtitle: referral.hasRedeemed
                  ? l10n.referralAlreadyRedeemedStatus
                  : l10n.referralRowSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReferralScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileLinkRow(
              icon: authLink.isLinked
                  ? Icons.verified_user_rounded
                  : Icons.link_rounded,
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

/// "Zibo ile Bağın" bölümündeki standart satır — ikon + başlık + canlı alt
/// metin + sağ ok, dokununca `onTap` çağrılır (çoğunlukla yeni bir sayfa
/// push eder). `modules_menu_sheet.dart`'taki `_ModuleCard`'la aynı görsel
/// dil (Card + ListTile), burada ayrı bir private widget olarak tutuldu
/// çünkü bu dosyaya özel (dışa aktarılmaya gerek yok).
class _ProfileLinkRow extends StatelessWidget {
  const _ProfileLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
