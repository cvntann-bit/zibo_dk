import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/gratitude_quotes.dart';
import '../l10n/app_localizations.dart';
import '../models/gratitude_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/zibo_animated_image.dart';

const _gratitudeGreen = Color(0xFF4CAF50);

const _turkishMonths = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_turkishMonths[date.month - 1]} ${date.year}';

/// Şükran Günlüğü sayfası: bugünün 3 şükran cümlesi formu (henüz
/// tamamlanmadıysa) veya "tamamlandı" özeti (tamamlandıysa) + geçmiş
/// kayıtların listesi. Şimdilik sekme değil, Ayarlar sayfasındaki bir
/// satırdan push ediliyor (bkz. CLAUDE.md "Şükran Günlüğü" bölümü).
class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() =>
      _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _timer;

  final _controllers = List.generate(3, (_) => TextEditingController());
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showNewQuote(),
    );
    for (final controller in _controllers) {
      controller.addListener(_onFieldsChanged);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = gratitudeQuotesForLocale(Localizations.localeOf(context));
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

  void _onFieldsChanged() {
    final canSave = _controllers.every((c) => c.text.trim().isNotEmpty);
    if (canSave != _canSave) setState(() => _canSave = canSave);
  }

  void _save() {
    if (!_canSave) return;
    final saved = context.read<GratitudeProvider>().saveToday(
      text1: _controllers[0].text,
      text2: _controllers[1].text,
      text3: _controllers[2].text,
    );
    if (saved) {
      // Koordinasyon GoalCard._onTodayTap'teki desenle AYNI: iki provider
      // birbirine bağımlı değil, bunu bağlayan burası (widget) — bkz.
      // GratitudeProvider.saveToday dokümantasyonu.
      context.read<CoinProvider>().earnGratitudeJournal();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.gratitudeCoinRewardMessage)));
    }
  }

  /// Geçmiş (veya bugünün) bir kaydını görüntüleyip DÜZENLEMEYE açan
  /// diyalog — üç metin de `GratitudeEntry`'nin mevcut değerleriyle
  /// önceden doldurulmuş `TextField`'lar, "Kaydet" `GratitudeProvider.
  /// updateEntry()`'yi çağırır (bkz. dokümantasyonu: `saveToday`'in aksine
  /// kilit kontrolü YOK, var olan bir kaydı her zaman düzenleyebilir).
  /// İçerik ayrı bir `StatefulWidget`'ta (`_GratitudeEditDialogContent`) —
  /// controller'ların dispose'u dialog'un KENDİ `State.dispose()`'una
  /// bağlı, `showDialog`'un döndürdüğü Future'a değil; aksi halde çıkış
  /// animasyonu tamamlanmadan elle dispose etmek "TextEditingController
  /// used after being disposed" hatasına yol açıyordu (bkz. CLAUDE.md
  /// "Şükran Günlüğü" 2026 güncellemesi).
  void _showEntryDetail(GratitudeEntry entry) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _GratitudeEditDialogContent(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<GratitudeProvider>();
    final isTodayComplete = provider.isTodayComplete;
    // Geçmiş listesi artık bugünü de İÇERİYOR — kullanıcı yukarıdaki özet
    // karttan sonra kendi şükranlarını burada da görüp düzenleyebilsin diye
    // (bkz. CLAUDE.md "Şükran Günlüğü" 2026 güncellemesi).
    final allEntries = provider.entries;
    final quotes = gratitudeQuotesForLocale(Localizations.localeOf(context));
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final quote = applyAddressTerm(
      quotes[_quoteIndex % quotes.length],
      addressTerm,
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
      appBar: AppBar(title: Text(l10n.gratitudeScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Column(
              children: [
                ZiboAnimatedImage(
                  imageKey: const Key('ziboGratitudeImage'),
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
            if (isTodayComplete)
              _TodayDoneCard(
                entry: provider.todayEntry!,
                onEdit: () => _showEntryDetail(provider.todayEntry!),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        TextField(
                          controller: _controllers[i],
                          minLines: 1,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: l10n.gratitudeFieldLabel(i + 1),
                          ),
                        ),
                        if (i < 2) const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _canSave ? _save : null,
                        child: Text(l10n.gratitudeSaveButton),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(l10n.gratitudeHistoryTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (allEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.gratitudeHistoryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final entry in allEntries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: _gratitudeGreen),
                      title: Text(_formatDate(entry.date)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showEntryDetail(entry),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Bugünün kaydı tamamlandığında formun yerine gösterilen kart — yeşil tik +
/// kısa bir kutlama metni + kullanıcının bugün yazdığı üç şükranın kendisi
/// (eskiden yalnızca kutlama metni gösterilip yazılan metinler bir daha
/// hiç görünmüyordu — bkz. CLAUDE.md "Şükran Günlüğü" 2026 güncellemesi) +
/// bir düzenleme ikonu (`onEdit`, `_showEntryDetail`'i açar).
class _TodayDoneCard extends StatelessWidget {
  const _TodayDoneCard({required this.entry, required this.onEdit});

  final GratitudeEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final texts = [entry.text1, entry.text2, entry.text3];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: _gratitudeGreen, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gratitudeTodayDoneTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.gratitudeTodayDoneBody,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.gratitudeEditTooltip,
                  onPressed: onEdit,
                ),
              ],
            ),
            const Divider(height: 24),
            for (var i = 0; i < 3; i++) ...[
              Text(
                l10n.gratitudeFieldLabel(i + 1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(texts[i]),
              if (i < 2) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// `_showEntryDetail`'in diyalog içeriği — kendi `TextEditingController`larını
/// `initState`'te oluşturup `dispose`'ta serbest bırakır, böylece dialog'un
/// çıkış animasyonu bitmeden controller'lar elle (ve erken) dispose
/// edilmez (bkz. `_showEntryDetail` dokümantasyonu).
class _GratitudeEditDialogContent extends StatefulWidget {
  const _GratitudeEditDialogContent({required this.entry});

  final GratitudeEntry entry;

  @override
  State<_GratitudeEditDialogContent> createState() => _GratitudeEditDialogContentState();
}

class _GratitudeEditDialogContentState extends State<_GratitudeEditDialogContent> {
  late final _controllers = [
    TextEditingController(text: widget.entry.text1),
    TextEditingController(text: widget.entry.text2),
    TextEditingController(text: widget.entry.text3),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(_formatDate(widget.entry.date)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              TextField(
                controller: _controllers[i],
                minLines: 1,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.gratitudeFieldLabel(i + 1)),
              ),
              if (i < 2) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.gratitudeEntryDetailCloseButton),
        ),
        FilledButton(
          onPressed: () {
            final updated = context.read<GratitudeProvider>().updateEntry(
              widget.entry.date,
              text1: _controllers[0].text,
              text2: _controllers[1].text,
              text3: _controllers[2].text,
            );
            if (updated) Navigator.of(context).pop();
          },
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
        ),
      ],
    );
  }
}
