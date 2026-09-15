import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/localized_calendar_names.dart';
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
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

const _intentionMaxLength = 280;

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
      showInfoDialog(
        context,
        justCompleted
            ? l10n.manifestCoinRewardMessage
            : l10n.manifestSavedMessage,
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
        title: Text(formatLongDate(entry.date, Localizations.localeOf(context))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _SafeFileImage(path: entry.photoPath, fit: BoxFit.cover),
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
      appBar: plainStickerAppBar(context, title: l10n.manifestScreenTitle),
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
                      imageKey: const Key('ziboManifestImage'),
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
                _PhotoPickerArea(
                  photoPath: _photoPath,
                  isLoading: _isPicking,
                  hint: l10n.manifestPhotoPickerHint,
                  semanticLabel: l10n.manifestPhotoSemanticLabel,
                  onTap: _pickPhoto,
                ),
                const SizedBox(height: 16),
                StickerCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.manifestIntentionHint,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.4,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _textController,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: _intentionMaxLength,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.5,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Mockup notu: Kaydet butonu bilerek TAM GENİŞLİK DEĞİL —
                // içeriği kadar dar, sola yaslı (diğer modüllerin çoğundan
                // FARKLI). `Align` burada `ListView`'ın sıkı genişlik
                // kısıtını (sliver child'ları varsayılan olarak tam genişliğe
                // zorlar) ETKİSİZ hale getirip butonu doğal boyutuna
                // küçültüyor.
                Align(
                  alignment: Alignment.centerLeft,
                  child: stickerButtonShadow(
                    radius: 12,
                    child: FilledButton(
                      style: stickerFilledButtonStyle(context, radius: 12),
                      onPressed: _canSave ? _save : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.manifestSaveButton),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.manifestHistoryTitle,
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
        ],
      ),
    );
  }
}

/// Fotoğraf seçim/önizleme alanı — mockup'ın `.photo-box` (bkz.
/// `docs/theme_new.md`): büyük, diğer kartlardan BİLİNÇLİ olarak daha
/// yuvarlak köşeli (26px) sticker kutusu. Boşken ipucu ikonu+metni gösterir,
/// doluyken fotoğrafı kaplar ve köşede taşan küçük bir "düzenle" rozeti
/// belirir (tekrar dokununca YENİ bir fotoğrafla değiştirir — ayrı bir
/// kaldır/sil kontrolü yok).
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
    final radius = BorderRadius.circular(26);
    return Semantics(
      label: photoPath == null ? hint : semanticLabel,
      button: true,
      // İçerideki ipucu Text'i (veya hiçbiri) dıştaki label ile
      // birleşmesin diye — bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümündeki
      // aynı Semantics birleşme gotcha'sı.
      excludeSemantics: true,
      child: Padding(
        // Köşede TAŞAN düzenle rozetinin kırpılmaması için — bkz.
        // `CostumeCard`'daki AYNI "dıştaki Stack clipBehavior:none" deseni.
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: stickerDecoration(
                  fill: colorScheme.surfaceContainerLowest,
                  borderRadius: radius,
                  shadowOffset: const Offset(4, 4),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('manifestPhotoPickerArea'),
                    onTap: isLoading ? null : onTap,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photoPath != null)
                          _SafeFileImage(path: photoPath!, fit: BoxFit.cover)
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 44,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hint,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isLoading)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (photoPath != null && !isLoading)
              Positioned(
                right: -8,
                bottom: -8,
                child: DecoratedBox(
                  decoration: stickerCircleDecoration(
                    fill: colorScheme.primary,
                    borderWidth: 2.5,
                  ),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(child: Text('✏️', style: TextStyle(fontSize: 14, height: 1))),
                  ),
                ),
              ),
          ],
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
    final radius = BorderRadius.circular(16);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kStickerOutline, width: 2)),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: _SafeFileImage(path: entry.photoPath, fit: BoxFit.cover),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.intentionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.35,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatLongDate(entry.date, Localizations.localeOf(context)),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: radius,
        shadowOffset: const Offset(3, 3),
      ),
      child: Stack(
        children: [
          content,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(borderRadius: radius, onTap: onTap),
            ),
          ),
        ],
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

/// **2026 bug düzeltmesi — Crashlytics'teki EN BÜYÜK tekrarlayan hata
/// (`_File.length` → `PathNotFoundException`, 58 olay/6 kullanıcı, TÜM
/// sürümlerde).** Firebase Console'da GERÇEK stack trace'e bakılınca
/// (`FileImage._loadAsync (image_provider.dart) → MultiFrameImageStreamCompleter.
/// _handleCodecReady`) kök nedenin `share_plus`/`cross_file` DEĞİL, TAM
/// OLARAK BU ekranın `Image.file(File(entry.photoPath))` çağrıları olduğu
/// kanıtlandı — path her zaman `app_flutter/app_photos/` (kalıcı belge
/// dizini, `PhotoPickerService.saveToPermanentStorage`'ın yazdığı klasör).
///
/// **Neden dosya artık orada değil — CLAUDE.md'nin "Manifest Günlüğü"
/// bölümünde ZATEN bilinen bir sınırlamanın SOMUT sonucu:** fotoğraflar
/// yalnızca CİHAZDA yerel olarak saklanıyor, Firestore'a yalnızca `photoPath`
/// STRING'i senkronize ediliyor (dosyanın kendisi DEĞİL) — "cihazlar arası
/// fotoğraf taşınmaz". Kullanıcı AYNI cihazda "Çıkış Yap"/"Hesap Değiştir"
/// yapıp SONRA (aynı VEYA farklı bir hesapla) eski bir manifest kaydına
/// (Firestore'dan geri gelen, BAŞKA bir oturuma/cihaza ait `photoPath`)
/// erişince, o path BU cihazda hiç var OLMAMIŞ olabilir.
///
/// **Neden mevcut `errorBuilder` bunu YAKALAMIYORDU:** `Image.file`'ın
/// `errorBuilder`'ı, `FileImage._loadAsync`'in async codec çözümleme
/// sürecinde (özellikle dosya SİSTEMİ seviyesinde, decode BAŞLAMADAN önce)
/// oluşan istisnaları GÜVENİLİR şekilde yakalamıyor — Flutter SDK'nın
/// bilinen bir davranışı (bkz. flutter/flutter#112881/#145112 gibi
/// issue'lar) — bu yüzden hata widget ağacına hiç ULAŞMADAN doğrudan global
/// `PlatformDispatcher.instance.onError`'a (bkz. "Crashlytics" bölümü)
/// sızıyordu.
///
/// **Düzeltme:** `errorBuilder`'a GÜVENMEK yerine, `Image.file()`'ı dosya
/// GERÇEKTEN var olmadan HİÇ İNŞA ETMİYORUZ — `File(path).existsSync()`
/// (küçük/yerel bir dosya sistemi `stat()` çağrısı, `build()` içinde
/// senkron kullanımı bu ölçekte zararsız) ile ÖNCEDEN kontrol edip yoksa
/// doğrudan `_BrokenImagePlaceholder`'a düşüyoruz. `errorBuilder` YİNE DE
/// KORUNDU — dosya VAR ama BOZUK/OKUNAMAZ (corrupt JPEG vb.) senaryosu
/// için hâlâ ikinci bir savunma katmanı.
class _SafeFileImage extends StatelessWidget {
  const _SafeFileImage({required this.path, required this.fit});

  /// **2026 güncellemesi — nullable'a çevrildi.** `ManifestEntry.photoPath`
  /// artık `ManifestProvider.reconcileMissingPhotos()` tarafından `null`'a
  /// çevrilebiliyor (bkz. o metodun dokümantasyonu) — `null` iken bu widget
  /// dosya sistemine HİÇ dokunmadan doğrudan `_BrokenImagePlaceholder`'a
  /// düşer, `path == null` ile "dosya var ama okunamıyor" durumu AYNI
  /// görsel sonuca (kırık resim ikonu) varır.
  final String? path;
  final BoxFit fit;

  bool get _exists {
    final p = path;
    if (p == null) return false;
    try {
      return File(p).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_exists) return const _BrokenImagePlaceholder();
    return Image.file(
      File(path!),
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const _BrokenImagePlaceholder(),
    );
  }
}
