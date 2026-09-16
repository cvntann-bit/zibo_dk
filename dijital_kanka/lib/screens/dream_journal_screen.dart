import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/dream_quotes.dart';
import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/dream_entry.dart';
import '../models/mood.dart';
import '../providers/costume_provider.dart';
import '../providers/dream_journal_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../utils/dream_sentiment.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';
import 'dream_entry_form_screen.dart';

/// Rüya Günlüğü sayfası: kaydedilen rüyaların (en yeni en üstte) listesi +
/// yeni rüya ekleme girişi. Sekmelerden biri değil, ana başlık çubuğundaki
/// ay ikonundan push edilen ayrı bir sayfa (bkz. RootScreen ve CLAUDE.md
/// "Rüya Günlüğü" bölümündeki yerleşim gerekçesi — SettingsScreen ile aynı
/// desen).
class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Bu sayfa (Ayarlar gibi) push edilen ayrı bir rota olduğu için —
    // MoneyScreen/GoalTrackingScreen'in aksine bir IndexedStack içinde
    // gizli kalmıyor — zamanlayıcıyı doğrudan initState/dispose ile
    // yönetmek yeterli, ayrı bir `isActive` akışına gerek yok.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _showNewQuote());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = dreamQuotesForLocale(Localizations.localeOf(context));
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

  void _openForm(BuildContext context, {DreamEntry? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DreamEntryFormScreen(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dreams = context.watch<DreamJournalProvider>().dreams;
    final moodProvider = context.watch<MoodProvider>();
    final locale = Localizations.localeOf(context);
    final quotes = dreamQuotesForLocale(locale);
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

    return Scaffold(
      appBar: plainStickerAppBar(context, title: l10n.dreamJournalTitle),
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
                      imageKey: const Key('ziboDreamJournalImage'),
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
                DashedStickerButton(
                  onPressed: () => _openForm(context),
                  label: l10n.dreamAddButton,
                ),
                const SizedBox(height: 16),
                if (dreams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.dreamEmptyState,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final dream in dreams)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StickerRowCard(
                        emoji: '🌙',
                        title: dream.title,
                        subtitleWidget: _buildDreamSubtitle(
                          context,
                          locale,
                          dream,
                          moodProvider,
                        ),
                        onTap: () => _openForm(context, existing: dream),
                      ),
                    ),
                const SizedBox(height: 20),
                const BannerAdSlot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rüya Günlüğü listesindeki bir kaydın alt metni — normalde yalnızca
/// tarih, ama AYNI tarihte olumsuz bir rüya (bkz. `isNegativeDream`) VE
/// düşük bir ruh hali kaydı (bkz. `Mood.isLow`) varsa ikinci bir satırla
/// hafifçe bunu belirtir (2026 yeni özellik — bkz. CLAUDE.md "Rüya
/// Günlüğü" bölümündeki korelasyon notu). Liste yapısı/form/navigasyon
/// HİÇ değişmedi, yalnızca bu TEK koşullu satır eklendi.
Widget _buildDreamSubtitle(
  BuildContext context,
  Locale locale,
  DreamEntry dream,
  MoodProvider moodProvider,
) {
  final colorScheme = Theme.of(context).colorScheme;
  // `StickerRowCard`'ın kendi tek-satırlık `subtitle` stiliyle AYNI (bkz.
  // sticker_style.dart) — burada elle tekrarlanıyor çünkü ikinci (koşullu)
  // satır için [subtitleWidget] kullanılıyor, düz `subtitle` DEĞİL.
  final dateText = Text(
    formatLongDate(dream.date, locale),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 11.5,
      color: colorScheme.onSurfaceVariant,
    ),
  );
  final moodEntry = moodProvider.entryForDate(dream.date);
  final correlated =
      moodEntry != null && moodEntry.mood.isLow && isNegativeDream(dream);
  if (!correlated) return dateText;

  final l10n = AppLocalizations.of(context)!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      dateText,
      const SizedBox(height: 2),
      Text(
        l10n.dreamMoodCorrelationNote,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
