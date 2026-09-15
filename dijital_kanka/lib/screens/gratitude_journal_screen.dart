import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/gratitude_prompts.dart';
import '../data/gratitude_quotes.dart';
import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/gratitude_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/gratitude_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

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
      showInfoDialog(context, l10n.gratitudeCoinRewardMessage);
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
    final locale = Localizations.localeOf(context);
    final quotes = gratitudeQuotesForLocale(locale);
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
      appBar: plainStickerAppBar(context, title: l10n.gratitudeScreenTitle),
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
                      imageKey: const Key('ziboGratitudeImage'),
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
                if (isTodayComplete)
                  _TodayDoneCard(
                    entry: provider.todayEntry!,
                    onEdit: () => _showEntryDetail(provider.todayEntry!),
                  )
                else
                  _GratitudeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          _GratitudeFieldBox(
                            label: l10n.gratitudeFieldLabel(i + 1),
                            controller: _controllers[i],
                            // 2026 yeni özellik — kullanıcı yazmaya
                            // başlamadan önce gösterilen, her gün değişen
                            // ilham verici öneri (bkz.
                            // gratitude_prompts.dart). Kullanıcı yazmaya
                            // başlayınca normal placeholder davranışıyla
                            // kaybolur, ekstra bir kod GEREKMEZ.
                            hint: gratitudePromptForField(
                              DateTime.now(),
                              i,
                              locale,
                            ),
                          ),
                          if (i < 2) const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 16),
                        stickerButtonShadow(
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: stickerFilledButtonStyle(context),
                              onPressed: _canSave ? _save : null,
                              child: Text(l10n.gratitudeSaveButton),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  l10n.gratitudeHistoryTitle,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: [FontVariation('wght', 800)],
                    fontSize: 16,
                  ),
                ),
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
                      child: StickerRowCard(
                        emoji: '✓',
                        title: formatLongDate(entry.date, locale),
                        onTap: () => _showEntryDetail(entry),
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

/// Şükran Günlüğü'nün "genel" sticker kartı — mockup'ın `.card` (bkz.
/// `docs/theme_new.md`). Form VE "bugün tamamlandı" özeti AYNI bu dış
/// sarmalayıcıyı paylaşır, yalnızca içi değişir (mockup notu: "Bu kart,
/// form YERİNE geçiyor").
class _GratitudeCard extends StatelessWidget {
  const _GratitudeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(
        fill: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Formun (henüz tamamlanmadıysa görünen) tek bir "N. Şükran cümlen" alanı —
/// mockup'ın `.dd-field` (küçük büyük-harf etiket + ince konturlu giriş
/// kutusu). [controller] gerçek bir [TextField]'a bağlı KALIYOR — yalnızca
/// görünümü sıfırlanıp bu kutunun kendi ince konturu devralıyor (bkz.
/// `docs/theme_new.md`'deki alan ipucu notu — hint günlük söz havuzundan
/// gelir, normal placeholder davranışı korunuyor).
class _GratitudeFieldBox extends StatelessWidget {
  const _GratitudeFieldBox({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.4,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: kStickerOutline, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              hintText: hint,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bugünün kaydı tamamlandığında formun yerine gösterilen kart — büyük tik +
/// kısa bir kutlama metni + kullanıcının bugün yazdığı üç şükranın kendisi
/// (eskiden yalnızca kutlama metni gösterilip yazılan metinler bir daha
/// hiç görünmüyordu — bkz. CLAUDE.md "Şükran Günlüğü" 2026 güncellemesi) +
/// bir düzenleme ikonu (`onEdit`, `_showEntryDetail`'i açar).
///
/// **Renk istisnası** (bkz. `docs/theme_new.md` "Onaylanan: Şükran
/// Günlüğü"): gerçek kodda bu tik eskiden SABİT bir yeşildi (`#4CAF50`,
/// temaya bağlı değil) — tek-vurgu kuralımız gereği bilinçli olarak altına
/// (`colorScheme.primary`) çevrildi, mockup'taki gerçek kod rengi KOPYALANMADI.
class _TodayDoneCard extends StatelessWidget {
  const _TodayDoneCard({required this.entry, required this.onEdit});

  final GratitudeEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final texts = [entry.text1, entry.text2, entry.text3];
    return _GratitudeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: stickerCircleDecoration(
                  fill: colorScheme.primary,
                  borderWidth: 2.5,
                ),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.gratitudeTodayDoneTitle,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: [FontVariation('wght', 800)],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.gratitudeTodayDoneBody,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StickerIconButton(
                icon: Icons.edit_outlined,
                onPressed: onEdit,
                tooltip: l10n.gratitudeEditTooltip,
                backgroundColor: colorScheme.surfaceContainerLowest,
                iconColor: kStickerOutline,
                size: 30,
                iconSize: 14,
                borderRadius: null,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: DashedUnderline(
              color: colorScheme.outlineVariant,
              child: const SizedBox(width: double.infinity, height: 1),
            ),
          ),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.gratitudeFieldLabel(i + 1),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      letterSpacing: 0.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    texts[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: colorScheme.onSurface,
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
      title: Text(formatLongDate(widget.entry.date, Localizations.localeOf(context))),
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
