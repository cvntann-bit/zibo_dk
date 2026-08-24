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
import '../providers/costume_provider.dart';
import '../providers/dream_journal_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/speech_bubble.dart';
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
      appBar: AppBar(title: Text(l10n.dreamJournalTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                const SizedBox(height: 8),
                SpeechBubble(message: quote),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.dreamAddButton),
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
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(
                        dream.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(formatLongDate(dream.date, locale)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openForm(context, existing: dream),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
