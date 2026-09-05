import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/localized_calendar_names.dart';
import '../data/mood_quotes.dart';
import '../l10n/app_localizations.dart';
import '../models/mood.dart';
import '../providers/costume_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/xp_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/zibo_animated_image.dart';

String _moodLabel(AppLocalizations l10n, Mood mood) => switch (mood) {
  Mood.veryUnhappy => l10n.moodLabelVeryUnhappy,
  Mood.unhappy => l10n.moodLabelUnhappy,
  Mood.neutral => l10n.moodLabelNeutral,
  Mood.happy => l10n.moodLabelHappy,
  Mood.veryHappy => l10n.moodLabelVeryHappy,
};

/// Günlük Ruh Hali Takibi sayfası: 5 emoji'lik günlük seçim (dokununca
/// otomatik kaydedilir) + son 7 günün renkli özeti + tam geçmiş listesi.
/// Şimdilik sekme değil, Ayarlar sayfasındaki bir satırdan push ediliyor
/// (bkz. CLAUDE.md "Günlük Ruh Hali Takibi" bölümü).
class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen> {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _timer;

  // 2026 yeni özellik — bugünün ruh haline eşlik eden serbest not/günlük
  // alanı. `ProfileProvider`'ın isim alanındaki "onSubmitted/odak kaybında
  // kaydet" deseniyle AYNI — HER tuş vuruşunda DEĞİL, yalnızca gönderilince/
  // odak kaybedilince `MoodProvider.setTodayMood(...)` çağrılıyor.
  late final _noteController = TextEditingController(
    text: context.read<MoodProvider>().entryForDate(DateTime.now())?.note ?? '',
  );
  final _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showNewQuote(),
    );
    _noteFocusNode.addListener(_onNoteFocusChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteFocusNode.removeListener(_onNoteFocusChange);
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteFocusChange() {
    if (!_noteFocusNode.hasFocus) _saveNote();
  }

  void _saveNote() {
    final provider = context.read<MoodProvider>();
    final mood = provider.todayMood;
    // Henüz bir ruh hali seçilmediyse kaydedecek bir gün kaydı yok — alan
    // zaten UI'da devre dışı/gizli oluyor (bkz. build()), bu ekstra bir
    // güvenlik.
    if (mood == null) return;
    provider.setTodayMood(mood, note: _noteController.text);
  }

  /// 2026 yeni özellik — Level/XP Sistemi. `MoodProvider.setTodayMood()`
  /// coin VERMEDİĞİ için (bkz. CLAUDE.md "Günlük Ruh Hali Takibi" bölümü —
  /// `CoinProvider`'ı hiç bilmiyor) buradaki XP, `CoinProvider._earn()`'ün
  /// merkezi kancasından GEÇMİYOR — doğrudan burada, günün İLK seçimi
  /// olduğunda (`todayMood == null`, seçimden ÖNCE kontrol edilmeli)
  /// veriliyor. Aynı gün ruh halini DEĞİŞTİRMEK (üzerine yazma) ikinci bir
  /// XP tetiklemiyor.
  void _selectMood(Mood mood) {
    final provider = context.read<MoodProvider>();
    final isFirstToday = provider.todayMood == null;
    provider.setTodayMood(mood);
    if (isFirstToday) {
      context.read<XpProvider>().addXp(5);
    }
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = moodQuotesForLocale(Localizations.localeOf(context));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<MoodProvider>();
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final locale = Localizations.localeOf(context);
    final quotes = moodQuotesForLocale(locale);
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
      appBar: AppBar(title: Text(l10n.moodScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Column(
              children: [
                ZiboAnimatedImage(
                  imageKey: const Key('ziboMoodImage'),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final mood in Mood.values)
                      _MoodEmojiButton(
                        mood: mood,
                        isSelected: provider.todayMood == mood,
                        label: _moodLabel(l10n, mood),
                        onTap: () => _selectMood(mood),
                      ),
                  ],
                ),
              ),
            ),
            // 2026 yeni özellik — bugünün ruh haline eşlik eden serbest not.
            // Bir ruh hali seçilmeden önce anlamsız (hangi güne ait olacağı
            // belirsiz) olduğu için `todayMood == null`'ken GÖSTERİLMİYOR.
            if (provider.todayMood != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _noteController,
                    focusNode: _noteFocusNode,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.moodNoteHint,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _saveNote(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.moodWeekSummaryTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 6; i >= 0; i--)
                      _WeekDayDot(
                        date: todayDateOnly.subtract(Duration(days: i)),
                        entry: provider.entryForDate(
                          todayDateOnly.subtract(Duration(days: i)),
                        ),
                        locale: locale,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.moodHistoryTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (provider.entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.moodHistoryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final entry in provider.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: entry.mood.color.withValues(alpha: 0.25),
                        child: Text(entry.mood.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(formatLongDate(entry.date, locale)),
                      // 2026 yeni özellik — o güne yazılmış not varsa ruh
                      // hali etiketinin ALTINA ikinci bir satır olarak
                      // ekleniyor; yoksa (eski kayıtlar dahil, `note` zaten
                      // nullable) yalnızca ruh hali etiketi görünür.
                      subtitle: entry.note == null
                          ? Text(_moodLabel(l10n, entry.mood))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_moodLabel(l10n, entry.mood)),
                                Text(
                                  entry.note!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                      isThreeLine: entry.note != null,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Emoji seçim butonlarından biri — seçiliyken büyür ve rengiyle vurgulanır.
class _MoodEmojiButton extends StatelessWidget {
  const _MoodEmojiButton({
    required this.mood,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  final Mood mood;
  final bool isSelected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isSelected ? 1.25 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? mood.color.withValues(alpha: 0.25) : Colors.transparent,
              border: Border.all(
                color: isSelected ? mood.color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: mood.color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}

/// "Son 7 Gün" şeridindeki tek bir gün — `GoalCard`'daki `_DayBox`'la aynı
/// görsel dil (daire, kenarlık, dolu/boş durum), ama renk duruma göre değil
/// o günün ruh haline göre belirleniyor.
class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot({required this.date, required this.entry, required this.locale});

  final DateTime date;
  final MoodEntry? entry;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mood = entry?.mood;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weekdayShortName(date, locale),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mood?.color ?? Colors.transparent,
            border: Border.all(
              color: mood?.color ?? colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
