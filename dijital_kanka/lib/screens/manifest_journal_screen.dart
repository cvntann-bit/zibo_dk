import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/manifest_quotes.dart';
import '../l10n/app_localizations.dart';
import '../models/manifest_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/manifest_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../services/photo_picker_service.dart';
import '../utils/address_term.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/zibo_animated_image.dart';

const _intentionMaxLength = 280;

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

/// Manifest Günlüğü sayfası: bugünün fotoğrafı + niyet metni formu (bugün
/// zaten bir kayıt varsa önceden doldurulur — üzerine yazma senaryosu) +
/// geçmiş günlerin 2 sütunlu bir "vizyon panosu" galerisi. Diğer yeni
/// modüller (Rüya/Şükran/Ruh Hali/Su Takibi) gibi sekme değil, Z butonunun
/// açtığı modül menüsünden push ediliyor (bkz. CLAUDE.md "Manifest
/// Günlüğü" bölümü).
class ManifestJournalScreen extends StatefulWidget {
  const ManifestJournalScreen({
    super.key,
    this.photoService = const ImagePickerPhotoService(),
  });

  /// Galeri seçimi + kalıcı depolama — testte sahte bir implementasyon
  /// enjekte edilebilir (bkz. `PhotoPickerService` dokümantasyonu).
  final PhotoPickerService photoService;

  @override
  State<ManifestJournalScreen> createState() => _ManifestJournalScreenState();
}

class _ManifestJournalScreenState extends State<ManifestJournalScreen> {
  final _random = Random();
  int _quoteIndex = 0;
  Timer? _timer;
  late final _textController = TextEditingController();

  /// Bugünün GÜNCEL fotoğrafı — kaydedilmiş olabilir ya da kullanıcının
  /// henüz kaydetmediği yeni bir seçim olabilir (bu durumda geçici bir
  /// önbellek yolu tutar, `_save()` onu kalıcı depoya kopyalar).
  String? _photoPath;
  bool _isPicking = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Bu sayfa (Su Takibi gibi) push edilen ayrı bir rota olduğu için
    // zamanlayıcıyı doğrudan initState/dispose ile yönetmek yeterli.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _showNewQuote());
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = manifestQuotesForLocale(Localizations.localeOf(context));
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

  bool get _canSave =>
      !_isSaving && _photoPath != null && _textController.text.trim().isNotEmpty;

  Future<void> _pickPhoto() async {
    setState(() => _isPicking = true);
    try {
      final picked = await widget.photoService.pickFromGallery();
      if (picked != null && mounted) setState(() => _photoPath = picked);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final provider = context.read<ManifestProvider>();
    final pickedPath = _photoPath!;

    setState(() => _isSaving = true);
    try {
      final permanentPath = await widget.photoService.saveToPermanentStorage(pickedPath);

      final justCompleted = provider.addEntry(
        photoPath: permanentPath,
        intentionText: _textController.text,
      );

      if (!mounted) return;
      // Kaydettikten sonra form BOŞ ve AÇIK kalır — kullanıcı isterse hemen
      // aynı gün içinde yeni bir giriş daha ekleyebilir (bkz. sınıf
      // dokümantasyonu, `ManifestProvider.addEntry` üzerine yazmaz).
      setState(() {
        _photoPath = null;
        _textController.clear();
      });

      // Coin ödülü GratitudeJournalScreen/_save() ile AYNI desen: yalnızca
      // provider `true` döndüğünde (bugünün İLK tamamlanan girişi)
      // CoinProvider tetiklenir.
      if (justCompleted) {
        context.read<CoinProvider>().earnManifestJournal();
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              justCompleted
                  ? l10n.manifestCoinRewardMessage
                  : l10n.manifestSavedMessage,
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEntryDetail(ManifestEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_formatDate(entry.date)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    File(entry.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _BrokenImagePlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(entry.intentionText),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.manifestDetailCloseButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<ManifestProvider>();
    final history = provider.history;
    final locale = Localizations.localeOf(context);
    final quotes = manifestQuotesForLocale(locale);
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
      appBar: AppBar(title: Text(l10n.manifestScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Column(
              children: [
                ZiboAnimatedImage(
                  imageKey: const Key('ziboManifestImage'),
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
            _PhotoPickerArea(
              photoPath: _photoPath,
              isLoading: _isPicking,
              hint: l10n.manifestPhotoPickerHint,
              semanticLabel: l10n.manifestPhotoSemanticLabel,
              onTap: _pickPhoto,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 6,
              maxLength: _intentionMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.manifestIntentionHint,
                alignLabelWithHint: true,
              ),
            ),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.manifestSaveButton),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.manifestHistoryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.manifestHistoryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  final entry = history[index];
                  return _HistoryCard(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onTap: () => _showEntryDetail(entry),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Fotoğraf seçim/önizleme alanı — büyük, kart şeklinde, yuvarlatılmış
/// köşeli bir çerçeve içinde. Boşken ipucu ikonu+metni gösterir, doluyken
/// fotoğrafı kaplar ve köşede küçük bir "düzenle" rozeti belirir.
class _PhotoPickerArea extends StatelessWidget {
  const _PhotoPickerArea({
    required this.photoPath,
    required this.isLoading,
    required this.hint,
    required this.semanticLabel,
    required this.onTap,
  });

  final String? photoPath;
  final bool isLoading;
  final String hint;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: photoPath == null ? hint : semanticLabel,
      button: true,
      // İçerideki ipucu Text'i (veya hiçbiri) dıştaki label ile
      // birleşmesin diye — bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümündeki
      // aynı Semantics birleşme gotcha'sı.
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            key: const Key('manifestPhotoPickerArea'),
            onTap: isLoading ? null : onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photoPath != null)
                  Image.file(
                    File(photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _BrokenImagePlaceholder(),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hint,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                if (photoPath != null && !isLoading)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      radius: 18,
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Geçmiş vizyon panosu galerisindeki tek bir kart — küçük fotoğraf +
/// kısaltılmış niyet metni + tarih. Dokununca tam detay diyaloğu açılır.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({super.key, required this.entry, required this.onTap});

  final ManifestEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(entry.photoPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _BrokenImagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.intentionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(entry.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir fotoğraf dosyası beklenmedik şekilde bulunamadığında/okunamadığında
/// (ör. kullanıcı cihaz depolamasından elle sildiyse) `Image.file`'ın
/// `errorBuilder`'ında gösterilen basit yer tutucu.
class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.broken_image_outlined,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
