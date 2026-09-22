import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/localized_calendar_names.dart';
import '../data/water_quotes.dart';
import '../l10n/app_localizations.dart';
import '../models/water_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/water_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../services/sound_effects_service.dart';
import '../utils/address_term.dart';
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

String _unitLabel(AppLocalizations l10n, WaterUnit unit) =>
    unit == WaterUnit.glass ? l10n.waterUnitGlass : l10n.waterUnitBottle;

/// Su Takibi sayfası: bugünün ilerlemesi (bardak/şişe ikonları, dokunarak
/// doldurulur/geri alınır) + günlük hedef özeti + geçmiş kayıtlar listesi.
/// AppBar'daki ayar ikonu (`Icons.tune_rounded`) günlük hedefi düzenleme
/// diyaloğunu açar — bu ayar bilerek Ayarlar sayfasında DEĞİL, doğrudan
/// burada (bkz. CLAUDE.md "Su Takibi" bölümü). Diğer yeni modüller
/// (Rüya/Şükran/Ruh Hali) gibi sekme değil, Z butonunun açtığı modül
/// menüsünden push ediliyor.
class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key, this.soundEffectsService});

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `AudioPlayersSoundEffectsService()` (`GoalTrackingScreen`/`HomeScreen`
  /// ile AYNI desen).
  final SoundEffectsService? soundEffectsService;

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _timer;

  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();

  @override
  void initState() {
    super.initState();
    // Bu sayfa (Rüya Günlüğü gibi) push edilen ayrı bir rota olduğu için
    // zamanlayıcıyı doğrudan initState/dispose ile yönetmek yeterli.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _showNewQuote());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = waterQuotesForLocale(Localizations.localeOf(context));
      if (quotes.length <= 1) {
        _quoteIndex = 0;
        return;
      }
      int next;
      do {
        next = _random.nextInt(quotes.length);
      } while (next == _quoteIndex);
      _quoteIndex = next;
    });
  }

  Future<void> _showGoalDialog(WaterProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    var unit = provider.unit;
    var mlPerUnit = provider.mlPerUnit;
    var goalUnitCount = provider.goalUnitCount;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void syncMlPerUnitFromUnit(WaterUnit newUnit) {
            mlPerUnit = newUnit == WaterUnit.glass ? provider.glassMl : provider.bottleMl;
          }

          return AlertDialog(
            title: Text(l10n.waterGoalDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.waterUnitSectionLabel, style: Theme.of(dialogContext).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<WaterUnit>(
                    segments: [
                      ButtonSegment(value: WaterUnit.glass, label: Text(l10n.waterUnitGlass)),
                      ButtonSegment(value: WaterUnit.bottle, label: Text(l10n.waterUnitBottle)),
                    ],
                    selected: {unit},
                    onSelectionChanged: (selection) => setDialogState(() {
                      unit = selection.first;
                      syncMlPerUnitFromUnit(unit);
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.waterMlPerUnitLabel(_unitLabel(l10n, unit)),
                    style: Theme.of(dialogContext).textTheme.labelLarge,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: mlPerUnit > 50
                            ? () => setDialogState(() => mlPerUnit -= 25)
                            : null,
                      ),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '$mlPerUnit ml',
                          textAlign: TextAlign.center,
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: mlPerUnit < 2000
                            ? () => setDialogState(() => mlPerUnit += 25)
                            : null,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: goalUnitCount > 1
                            ? () => setDialogState(() => goalUnitCount--)
                            : null,
                      ),
                      SizedBox(
                        width: 96,
                        child: Text(
                          l10n.waterGoalDialogUnitCount(goalUnitCount, _unitLabel(l10n, unit)),
                          textAlign: TextAlign.center,
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: goalUnitCount < 40
                            ? () => setDialogState(() => goalUnitCount++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () async {
                  if (unit == WaterUnit.glass) {
                    await provider.setGlassMl(mlPerUnit);
                  } else {
                    await provider.setBottleMl(mlPerUnit);
                  }
                  await provider.setUnit(unit);
                  await provider.setGoalUnitCount(goalUnitCount);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                child: Text(MaterialLocalizations.of(dialogContext).saveButtonLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _tapGlass(int index, WaterProvider provider) {
    // Zaten dolu bir birime dokununca en son işaretlenen birimi geri alır
    // (basit "geri al"); boş bir birime dokununca bir sonrakini işaretler —
    // bkz. WaterProvider.incrementUnit/decrementUnit.
    if (index < provider.todayCount) {
      provider.decrementUnit();
      return;
    }
    // "Su içtim" işaretlemesi — dolma animasyonuyla (bkz. `_WaterGlass`'ın
    // `AnimatedContainer` geçişi) TAM EŞ ZAMANLI, geri alma (yukarıdaki dal)
    // İÇİN ÇALINMAZ.
    if (context.read<SoundEffectsProvider>().enabled) {
      _soundEffectsService.playWaterDrop();
    }
    final justCompleted = provider.incrementUnit();
    if (justCompleted) {
      final l10n = AppLocalizations.of(context)!;
      context.read<CoinProvider>().earnWaterGoal();
      showInfoDialog(context, l10n.waterGoalCompletedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<WaterProvider>();
    final goal = provider.goalUnitCount;
    final count = provider.todayCount;
    final unit = provider.unit;
    final unitLabel = _unitLabel(l10n, unit);
    final history = provider.history;
    final locale = Localizations.localeOf(context);
    final quotes = waterQuotesForLocale(locale);
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final quote = applyAddressTerm(
      quotes[_quoteIndex % quotes.length],
      addressTerm,
      locale,
    );

    // Mağaza > Kostümler'den giyilen bir kostüm varsa Zibo'nun görseli onunla
    // değişir; yoksa (veya kostüm listeden kaldırılmışsa) varsayılan görsele
    // düşülür (bkz. HomeScreen'deki aynı desen).
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final equippedImageAsset = equippedId == null
        ? defaultZiboImage
        : (findCostumeById(equippedId)?.imageAsset ?? defaultZiboImage);
    final poseStep = context.watch<ZiboPoseProvider>().poseStep;

    final chipGrid = Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < goal; i++)
          _WaterGlass(
            filled: i < count,
            unit: unit,
            label: i < count
                ? l10n.waterGlassFilledLabel(i + 1, unitLabel)
                : l10n.waterGlassEmptyLabel(i + 1, unitLabel),
            onTap: () => _tapGlass(i, provider),
          ),
      ],
    );

    return Scaffold(
      appBar: plainStickerAppBar(
        context,
        title: l10n.waterScreenTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StickerIconButton(
              // Mockup'ta 🎛️ emoji öneriliyor, ama bu glif test cihazında
              // (ve muhtemelen birçok Android cihazda/OEM emoji fontunda)
              // tofu/boş kutucuk olarak render oluyor — bu yüzden gerçek
              // cihaz uyumluluğu için güvenilir bir Material ikonuna
              // düşülüyor (mockup'ın literal glifinden BİLİNÇLİ sapma).
              icon: Icons.tune_rounded,
              onPressed: () => _showGoalDialog(provider),
              tooltip: l10n.waterGoalSettingsTitle,
              backgroundColor: colorScheme.surfaceContainerLowest,
              iconColor: colorScheme.onSurface,
              size: 34,
              iconSize: 16,
              borderRadius: null,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Column(
                  children: [
                    ZiboAnimatedImage(
                      imageKey: const Key('ziboWaterImage'),
                      costumeId: equippedId,
                      poseStep: poseStep,
                      fallbackImage: equippedImageAsset,
                      height: 200,
                      semanticLabel: l10n.ziboImagePlaceholder,
                    ),
                    const SizedBox(height: 14),
                    SpeechBubble(message: quote),
                  ],
                ),
                const SizedBox(height: 20),
                StickerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.waterProgressLabel(count, goal, unitLabel),
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontVariations: [FontVariation('wght', 800)],
                              fontSize: 16,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              l10n.waterProgressMl(
                                count * provider.mlPerUnit,
                                goal * provider.mlPerUnit,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      chipGrid,
                      if (provider.isTodayComplete) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text('✅', style: TextStyle(fontSize: 18, height: 1)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.waterTodayCompleteBody,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.waterHistoryTitle,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: [FontVariation('wght', 800)],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.waterHistoryEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  StickerCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < history.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _WaterHistoryRow(
                            isCompleted: history[i].isCompleted,
                            text: history[i].isCompleted
                                ? l10n.waterHistoryCompletedEntry(
                                    formatLongDate(history[i].date, locale),
                                  )
                                : l10n.waterHistoryPartialEntry(
                                    formatLongDate(history[i].date, locale),
                                    history[i].unitCount,
                                    history[i].goalUnitCount,
                                  ),
                          ),
                        ],
                      ],
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

/// "Geçmiş" listesindeki tek bir satır — mockup'ın `.hist-row` (bkz.
/// `docs/theme_new.md`). Satırlar bilerek tıklanamaz/silinemez (docs notu),
/// bu yüzden `StickerRowCard`'ın onTap/chevron mantığı YERİNE burada daha
/// basit, salt-okunur bir satır kullanılıyor.
class _WaterHistoryRow extends StatelessWidget {
  const _WaterHistoryRow({required this.isCompleted, required this.text});

  final bool isCompleted;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: stickerCircleDecoration(
            fill: isCompleted ? colorScheme.primary : colorScheme.surfaceContainerLowest,
            borderWidth: 2,
          ),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: isCompleted
                  ? Text(
                      '✓',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Text('💧', style: TextStyle(fontSize: 13, height: 1)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tek bir su birimi ikonu — mockup'ın `.chip`/`.chip.filled`/`.chip.empty`
/// (bkz. `docs/theme_new.md`): boşken soluk beyaz zemin, dolunca altın
/// zemin — SÜREKLİ bir çubuk/halka DEĞİL, dokunulabilir ayrı daireler.
/// Bardak/şişe birimine göre farklı ikon kullanır. Gerçek [Icon] türü
/// BİLEREK korunuyor (emoji'ye ÇEVRİLMEDİ) — `water_tracking_sound_test.dart`
/// bu daireleri `find.byIcon(Icons.water_drop_outlined/water_drop)` ile
/// tür üzerinden buluyor. Dokunma davranışı (doldur/geri al)
/// `_WaterTrackingScreenState._tapGlass`'ta.
class _WaterGlass extends StatelessWidget {
  const _WaterGlass({
    required this.filled,
    required this.unit,
    required this.label,
    required this.onTap,
  });

  final bool filled;
  final WaterUnit unit;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filledIcon = unit == WaterUnit.glass ? Icons.water_drop : Icons.local_drink;
    final emptyIcon = unit == WaterUnit.glass
        ? Icons.water_drop_outlined
        : Icons.local_drink_outlined;
    return Semantics(
      label: label,
      button: true,
      child: Opacity(
        opacity: filled ? 1 : 0.55,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? colorScheme.primary : colorScheme.surfaceContainerLowest,
              border: Border.all(color: kStickerOutline, width: 2.5),
            ),
            child: Icon(
              filled ? filledIcon : emptyIcon,
              size: 20,
              color: filled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
