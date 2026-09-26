import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';

import '../data/costumes.dart';
import '../data/localized_calendar_names.dart';
import '../data/manifest_frames.dart';
import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../models/manifest_entry.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/manifest_decor_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/photo_picker_service.dart';
import '../services/share_service.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/manifest_frame_view.dart';
import '../widgets/sticker_style.dart';
import '../utils/photo_file.dart';

typedef GallerySaver = Future<bool> Function(Uint8List png, String name);

/// `gal` ile PNG'yi cihaz galerisine yazar. Android 10 ve altında izin
/// ister (bkz. AndroidManifest `WRITE_EXTERNAL_STORAGE maxSdkVersion=29`).
Future<bool> saveImageToGallery(Uint8List png, String name) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
    await Gal.putImageBytes(png, name: name);
    return true;
  } catch (_) {
    return false;
  }
}

enum _Ratio {
  post(4 / 5),
  square(1),
  story(9 / 16);

  const _Ratio(this.aspect);
  final double aspect;
}

enum _Tab { frame, template, background, sticker, text }

enum _StickerKind { image, emoji, text }

File? _existingFile(String? path) => isReadablePhotoFile(path) ? File(path!) : null;

/// Kolaj kutusunun içeriği: fotoğraf ya da (fotoğrafsız manifest için)
/// niyet yazısı. [zoom]/[offset] kutu içinde parmakla kaydırma/yakınlaştırma
/// (offset kutu boyutuna göre kesirli).
class _TileContent {
  _TileContent.photo(File this.file) : text = null;
  _TileContent.text(String this.text) : file = null;

  final File? file;
  final String? text;
  double zoom = 1;
  Offset offset = Offset.zero;

  static _TileContent? fromEntry(ManifestEntry entry) {
    final file = _existingFile(entry.photoPath);
    if (file != null) return _TileContent.photo(file);
    final text = entry.intentionText.trim();
    return text.isEmpty ? null : _TileContent.text(text);
  }
}

class _TextColor {
  const _TextColor(this.fill, this.stroke);
  final Color fill;
  final Color stroke;
}

const _textColors = [
  _TextColor(Color(0xFFF3B23C), kStickerOutline),
  _TextColor(Color(0xFFFFF4DE), kStickerOutline),
  _TextColor(kStickerOutline, Color(0xFFFFF4DE)),
];

class _PlacedSticker {
  _PlacedSticker(this.kind, this.content, {this.textColor});

  final _StickerKind kind;
  final String content;
  _TextColor? textColor;
  Offset center = const Offset(0.5, 0.45);
  double scale = 1;
  double rotation = 0;
}

/// Manifest süsleme editörü — onaylı mockup:
/// https://claude.ai/artifact/21kf1TZT3sDKqgrpkc1Pew (bkz. docs/theme_new.md).
/// Kaydın fotoğrafına (yoksa niyet yazısına) çerçeve, Zibo/emoji sticker'ı
/// ve olumlama yazısı eklenir; 1080px genişlikte PNG olarak paylaşılır ya da
/// galeriye kaydedilir. Premium çerçeveler Zibo Coin ile açılır, kostümlü
/// Zibo sticker'ları yalnızca sahip olunan kostümler için açıktır, Pro
/// olmayan kullanıcının görselinde küçük "zibo" logosu bulunur.
///
/// [ManifestEditorScreen.collage] aynı editörü kolaj modunda açar (onaylı
/// mockup: https://claude.ai/artifact/D6AbNAeHSW4NCCVMnmakkD): çerçeve yerine
/// şablon + arka plan; kutular manifest kayıtlarından (fotoğrafsız olanlar
/// yazı kutusu) ya da telefon galerisinden doldurulur. Sticker/yazı/boyut/
/// dışa aktarma ortak.
class ManifestEditorScreen extends StatefulWidget {
  const ManifestEditorScreen({
    super.key,
    required ManifestEntry this.entry,
    this.shareService = const SharePlusService(),
    this.gallerySaver = saveImageToGallery,
    this.photoService = const ImagePickerPhotoService(),
  }) : collageEntries = const [];

  const ManifestEditorScreen.collage({
    super.key,
    required this.collageEntries,
    this.shareService = const SharePlusService(),
    this.gallerySaver = saveImageToGallery,
    this.photoService = const ImagePickerPhotoService(),
  }) : entry = null;

  /// Tek fotoğraf modunda süslenen kayıt; kolaj modunda `null`.
  final ManifestEntry? entry;

  /// Kolaj modunda seçilebilecek kayıtlar (en yeni önce).
  final List<ManifestEntry> collageEntries;
  final ShareService shareService;
  final GallerySaver gallerySaver;
  final PhotoPickerService photoService;

  @override
  State<ManifestEditorScreen> createState() => _ManifestEditorScreenState();
}

class _ManifestEditorScreenState extends State<ManifestEditorScreen> {
  static const _exportWidth = 1080.0;

  final _captureKey = GlobalKey();
  final List<_PlacedSticker> _stickers = [];
  ManifestFrame _frame = ManifestFrame.polaroid;
  _Ratio _ratio = _Ratio.post;
  _Tab _tab = _Tab.frame;
  _TextColor _textColor = _textColors.first;
  _PlacedSticker? _selected;
  File? _photoFile;
  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;
  bool _busy = false;
  bool _capturing = false;

  CollageTemplate _template = CollageTemplate.three;
  CollageBackground _background = CollageBackground.dots;
  final List<_TileContent?> _tiles = List.filled(CollageTemplate.maxSlots, null);
  double _tileStartZoom = 1;

  bool get _isCollage => widget.entry == null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _photoFile = _existingFile(entry.photoPath);
      return;
    }
    _tab = _Tab.template;
    // Önce fotoğraflı kayıtlar (en yeni önce), sonra yalnızca yazı olanlar.
    final contents =
        widget.collageEntries.map(_TileContent.fromEntry).whereType<_TileContent>().toList();
    final ordered = [
      ...contents.where((c) => c.file != null),
      ...contents.where((c) => c.file == null),
    ];
    for (var i = 0; i < _tiles.length && i < ordered.length; i++) {
      _tiles[i] = ordered[i];
    }
  }

  String _frameName(AppLocalizations l10n, ManifestFrame frame) => switch (frame) {
    ManifestFrame.none => l10n.manifestFrameNone,
    ManifestFrame.polaroid => l10n.manifestFramePolaroid,
    ManifestFrame.film => l10n.manifestFrameFilm,
    ManifestFrame.washi => l10n.manifestFrameWashi,
    ManifestFrame.gold => l10n.manifestFrameGold,
    ManifestFrame.stars => l10n.manifestFrameStars,
    ManifestFrame.hearts => l10n.manifestFrameHearts,
    ManifestFrame.notebook => l10n.manifestFrameNotebook,
    ManifestFrame.album => l10n.manifestFrameAlbum,
    ManifestFrame.pop => l10n.manifestFramePop,
    ManifestFrame.stamp => l10n.manifestFrameStamp,
    ManifestFrame.neon => l10n.manifestFrameNeon,
    ManifestFrame.floral => l10n.manifestFrameFloral,
    ManifestFrame.night => l10n.manifestFrameNight,
    ManifestFrame.royal => l10n.manifestFrameRoyal,
    ManifestFrame.zibo => l10n.manifestFrameZibo,
  };

  void _addSticker(_PlacedSticker sticker) {
    setState(() {
      _stickers.add(sticker);
      _selected = sticker;
    });
  }

  void _deleteSticker(_PlacedSticker sticker) {
    setState(() {
      _stickers.remove(sticker);
      if (identical(_selected, sticker)) _selected = null;
    });
  }

  Future<void> _addCustomText() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _CustomTextDialog(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    _addSticker(_PlacedSticker(_StickerKind.text, text.trim(), textColor: _textColor));
  }

  /// `true` → çerçeve açık (zaten açıktı ya da şimdi satın alındı).
  Future<bool> _unlockFrame(ManifestFrame frame) async {
    final decor = context.read<ManifestDecorProvider>();
    if (decor.isFrameUnlocked(frame)) return true;
    final l10n = AppLocalizations.of(context)!;
    final name = _frameName(l10n, frame);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manifestEditorUnlockTitle(name)),
        content: Text(l10n.manifestEditorUnlockBody(frame.price)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          FilledButton(
            key: const Key('manifestFrameUnlockConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.manifestEditorUnlockButton(frame.price)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    final coins = context.read<CoinProvider>();
    if (coins.balance < frame.price ||
        !coins.spendOnManifestFrame(frameId: frame.id, cost: frame.price)) {
      showInsufficientCoinsWarning(context);
      return false;
    }
    decor.unlockFrame(frame);
    await showInfoDialog(context, l10n.manifestEditorUnlockedMessage(name));
    return true;
  }

  Future<Uint8List?> _capture() async {
    setState(() {
      _selected = null;
      _capturing = true;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: _exportWidth / boundary.size.width);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  String get _fileName => 'zibo_manifest_${DateTime.now().millisecondsSinceEpoch}.png';

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await widget.shareService.shareImageBytes(
        bytes,
        fileName: _fileName,
        text: l10n.manifestEditorShareCaption,
      );
    } catch (_) {
      // Paylaşım menüsü açılamadı — kullanıcı tekrar deneyebilir.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    var saved = false;
    try {
      final bytes = await _capture();
      if (bytes != null) saved = await widget.gallerySaver(bytes, _fileName);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    await showInfoDialog(context, saved ? l10n.manifestEditorSaved : l10n.manifestEditorSaveFailed);
  }

  Future<void> _openExportSheet() async {
    if (_busy) return;
    if (!_isCollage && (!await _unlockFrame(_frame) || !mounted)) return;
    setState(() => _selected = null);
    final l10n = AppLocalizations.of(context)!;
    final isPro = context.read<SubscriptionProvider>().isPro;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _ExportSheet(
        subtitle: switch (_ratio) {
          _Ratio.post => l10n.manifestEditorExportPost,
          _Ratio.square => l10n.manifestEditorExportSquare,
          _Ratio.story => l10n.manifestEditorExportStory,
        },
        showWatermarkNote: !isPro,
      ),
    );
    if (!mounted) return;
    if (action == 'share') await _share();
    if (action == 'save') await _saveToGallery();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final decor = context.watch<ManifestDecorProvider>();
    final frameLocked = !_isCollage && !decor.isFrameUnlocked(_frame);

    return Scaffold(
      appBar: plainStickerAppBar(
        context,
        title: _isCollage ? l10n.manifestCollageTitle : l10n.manifestEditorTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _PillButton(
                key: const Key('manifestEditorShareButton'),
                label: l10n.manifestEditorShareButton,
                busy: _busy,
                onTap: _openExportSheet,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _RatioSelector(
                  selected: _ratio,
                  labels: {
                    _Ratio.post: l10n.manifestEditorRatioPost,
                    _Ratio.square: l10n.manifestEditorRatioSquare,
                    _Ratio.story: l10n.manifestEditorRatioStory,
                  },
                  onSelected: (r) => setState(() => _ratio = r),
                ),
                if (frameLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _PillButton(
                      key: const Key('manifestFrameLockedPill'),
                      label: l10n.manifestEditorLockedPreview(_frame.price),
                      dark: true,
                      onTap: () => _unlockFrame(_frame),
                    ),
                  ),
                Expanded(child: _buildStage()),
                _buildTray(l10n, colorScheme, decor),
                _buildTabs(l10n, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth - 32;
        final maxH = constraints.maxHeight - 24;
        var w = maxW;
        var h = w / _ratio.aspect;
        if (h > maxH) {
          h = maxH;
          w = h * _ratio.aspect;
        }
        final size = Size(w, h);
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selected = null),
            child: RepaintBoundary(
              key: _captureKey,
              child: SizedBox.fromSize(
                size: size,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: _isCollage
                          ? _buildCollage(size)
                          : ManifestFrameView(
                              frame: _frame,
                              width: w,
                              photo: _buildPhoto(w),
                              caption: _caption(),
                            ),
                    ),
                    for (final sticker in _stickers) _buildSticker(sticker, size),
                    if (!context.watch<SubscriptionProvider>().isPro)
                      Positioned(
                        right: w * 0.025,
                        bottom: w * 0.022,
                        child: IgnorePointer(
                          child: Container(
                            key: const Key('manifestEditorWatermark'),
                            padding: EdgeInsets.symmetric(horizontal: w * 0.018),
                            decoration: BoxDecoration(
                              color: kStickerOutline.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(w * 0.018),
                            ),
                            child: Text(
                              'zibo',
                              style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontVariations: const [FontVariation('wght', 800)],
                                fontSize: w * 0.036,
                                color: const Color(0xFFFFF4DE),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _caption() {
    final entry = widget.entry!;
    final date = formatLongDate(entry.date, Localizations.localeOf(context));
    final text = entry.intentionText.trim();
    return text.isEmpty ? date : '$date · $text';
  }

  Widget _buildPhoto(double w) {
    final file = _photoFile;
    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _textBackdrop(widget.entry!.intentionText, w),
      );
    }
    return _textBackdrop(widget.entry!.intentionText, w);
  }

  Widget _textBackdrop(String text, double w, {double fontFactor = 0.07}) {
    return ColoredBox(
      color: const Color(0xFFF6D488),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: w * fontFactor,
              height: 1.2,
              color: kStickerOutline,
            ),
          ),
        ),
      ),
    );
  }

  static const _collageBackgroundColors = {
    CollageBackground.cream: Color(0xFFFFF4DE),
    CollageBackground.honey: Color(0xFFF6D488),
    CollageBackground.gold: Color(0xFFF3B23C),
    CollageBackground.night: Color(0xFF1B1712),
    CollageBackground.dots: Color(0xFFFFF4DE),
  };

  String _templateName(AppLocalizations l10n, CollageTemplate t) => switch (t) {
    CollageTemplate.twoStacked => l10n.manifestTemplateTwoStacked,
    CollageTemplate.twoSide => l10n.manifestTemplateTwoSide,
    CollageTemplate.three => l10n.manifestTemplateThree,
    CollageTemplate.four => l10n.manifestTemplateFour,
    CollageTemplate.six => l10n.manifestTemplateSix,
    CollageTemplate.polaroidWall => l10n.manifestTemplatePolaroidWall,
  };

  String _backgroundName(AppLocalizations l10n, CollageBackground b) => switch (b) {
    CollageBackground.cream => l10n.manifestBgCream,
    CollageBackground.honey => l10n.manifestBgHoney,
    CollageBackground.gold => l10n.manifestBgGold,
    CollageBackground.night => l10n.manifestBgNight,
    CollageBackground.dots => l10n.manifestBgDots,
  };

  Widget _collageBackground(CollageBackground bg, double unit) {
    return DecoratedBox(
      decoration: BoxDecoration(color: _collageBackgroundColors[bg]),
      child: bg == CollageBackground.dots
          ? CustomPaint(painter: _CollageDotPainter(unit: unit), child: const SizedBox.expand())
          : const SizedBox.expand(),
    );
  }

  Widget _buildCollage(Size size) {
    final w = size.width;
    final gap = w * 0.022;
    final outline = w * 0.008 + 1.5;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: kStickerOutline, width: outline),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.03),
        child: Stack(
          children: [
            Positioned.fill(child: _collageBackground(_background, w)),
            for (var i = 0; i < _template.slots.length; i++)
              _buildTile(i, _template.slots[i], size, gap, outline),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(int index, CollageSlot slot, Size size, double gap, double outline) {
    final polaroid = _template.isPolaroid;
    // Dış kenarlarda tam, iç kenarlarda yarım boşluk → her yerde eşit aralık.
    double nearEdge(double start) => polaroid ? 0 : (start <= 0.001 ? gap : gap / 2);
    double farEdge(double start, double length) =>
        polaroid ? 0 : (start + length >= 0.999 ? gap : gap / 2);
    final left = slot.left * size.width + nearEdge(slot.left);
    final top = slot.top * size.height + nearEdge(slot.top);
    final width = slot.width * size.width - nearEdge(slot.left) - farEdge(slot.left, slot.width);
    final height = slot.height * size.height - nearEdge(slot.top) - farEdge(slot.top, slot.height);
    final content = _tiles[index];
    final inset = polaroid
        ? EdgeInsets.fromLTRB(width * 0.05, width * 0.05, width * 0.05, width * 0.16)
        : EdgeInsets.zero;
    final photoW = width - inset.horizontal - outline * 2;
    final photoH = height - inset.vertical - outline * 2;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: slot.rotationDeg * 3.1415926535 / 180,
        child: GestureDetector(
          key: Key('manifestCollageTile_$index'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _pickForTile(index),
          onScaleStart: (_) {
            _selected = null;
            _tileStartZoom = content?.zoom ?? 1;
          },
          onScaleUpdate: (d) {
            if (content?.file == null) return;
            setState(() {
              final c = content!;
              if (d.pointerCount > 1) c.zoom = (_tileStartZoom * d.scale).clamp(1.0, 4.0);
              final limit = (c.zoom - 1) / 2;
              c.offset = Offset(
                (c.offset.dx + d.focalPointDelta.dx / photoW).clamp(-limit, limit),
                (c.offset.dy + d.focalPointDelta.dy / photoH).clamp(-limit, limit),
              );
            });
          },
          child: Container(
            padding: inset,
            decoration: BoxDecoration(
              color: polaroid ? const Color(0xFFFFFDF7) : null,
              border: Border.all(color: kStickerOutline, width: outline),
              borderRadius: BorderRadius.circular(polaroid ? width * 0.02 : size.width * 0.02),
              boxShadow: polaroid
                  ? [BoxShadow(color: kStickerOutline.withValues(alpha: 0.5), offset: Offset(outline, outline))]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(polaroid ? 0 : size.width * 0.012),
              child: _tileContent(content, photoW, photoH),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tileContent(_TileContent? content, double w, double h) {
    if (content == null) {
      return ColoredBox(
        color: const Color(0xFFF3E4C0),
        child: _capturing
            ? const SizedBox.expand()
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: kStickerOutline),
                    if (h > 70) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          AppLocalizations.of(context)!.manifestCollageEmptyTile,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: kStickerOutline),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      );
    }
    final file = content.file;
    if (file == null) return _textBackdrop(content.text!, w, fontFactor: 0.1);
    return ClipRect(
      child: Transform.translate(
        offset: Offset(content.offset.dx * w, content.offset.dy * h),
        child: Transform.scale(
          scale: content.zoom,
          child: Image.file(
            file,
            width: w,
            height: h,
            fit: BoxFit.cover,
            cacheWidth: 1080,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(color: Color(0xFFF3E4C0)),
          ),
        ),
      ),
    );
  }

  Future<void> _pickForTile(int index) async {
    setState(() => _selected = null);
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _CollagePickerSheet(entries: widget.collageEntries),
    );
    if (!mounted || choice == null) return;
    _TileContent? content;
    if (choice is ManifestEntry) {
      content = _TileContent.fromEntry(choice);
    } else if (choice == _CollagePickerSheet.galleryChoice) {
      final path = await widget.photoService.pickFromGallery();
      final file = _existingFile(path);
      if (file != null) content = _TileContent.photo(file);
    }
    if (content != null && mounted) setState(() => _tiles[index] = content);
  }

  Widget _buildSticker(_PlacedSticker s, Size canvas) {
    final l10n = AppLocalizations.of(context)!;
    final w = canvas.width;
    final selected = identical(s, _selected);
    const handle = 26.0;

    final Widget content = switch (s.kind) {
      _StickerKind.image => Image.asset(s.content, width: w * 0.32),
      _StickerKind.emoji => Text(s.content, style: TextStyle(fontSize: w * 0.13, height: 1)),
      _StickerKind.text => _OutlinedText(
        text: s.content,
        fontSize: w * 0.075,
        color: s.textColor ?? _textColors.first,
      ),
    };

    return Positioned(
      left: s.center.dx * canvas.width,
      top: s.center.dy * canvas.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          key: ObjectKey(s),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = s),
          onScaleStart: (_) => setState(() {
            _selected = s;
            _gestureStartScale = s.scale;
            _gestureStartRotation = s.rotation;
          }),
          onScaleUpdate: (d) => setState(() {
            s.center = Offset(
              (s.center.dx + d.focalPointDelta.dx / canvas.width).clamp(0.0, 1.0),
              (s.center.dy + d.focalPointDelta.dy / canvas.height).clamp(0.0, 1.0),
            );
            if (d.pointerCount > 1) {
              s.scale = (_gestureStartScale * d.scale).clamp(0.3, 4.0);
              s.rotation = _gestureStartRotation + d.rotation;
            }
          }),
          child: Transform.rotate(
            angle: s.rotation,
            child: Transform.scale(
              scale: s.scale,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(handle / 2),
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: selected
                            ? Border.all(color: const Color(0xFFFFF4DE), width: 2 / s.scale)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(padding: const EdgeInsets.all(4), child: content),
                    ),
                  ),
                  if (selected) ...[
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _StickerHandle(
                        key: const Key('manifestStickerDelete'),
                        icon: Icons.close_rounded,
                        label: l10n.manifestEditorDeleteSticker,
                        inverseScale: 1 / s.scale,
                        onTap: () => _deleteSticker(s),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _StickerHandle(
                        icon: Icons.open_in_full_rounded,
                        label: l10n.manifestEditorResizeSticker,
                        inverseScale: 1 / s.scale,
                        filled: true,
                        onPanUpdate: (d) => setState(() {
                          s.scale = (s.scale * (1 + (d.delta.dx + d.delta.dy) / 160)).clamp(0.3, 4.0);
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTray(AppLocalizations l10n, ColorScheme colorScheme, ManifestDecorProvider decor) {
    final Widget body = switch (_tab) {
      _Tab.frame => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          for (final frame in ManifestFrame.values)
            _TrayThumb(
              key: Key('manifestFrame_${frame.id}'),
              label: _frameName(l10n, frame),
              selected: frame == _frame,
              lockLabel: decor.isFrameUnlocked(frame) ? null : '${frame.price} ZC',
              onTap: () => setState(() => _frame = frame),
              child: SizedBox(
                width: 44,
                height: 44,
                child: ManifestFrameView(
                  frame: frame,
                  width: 44,
                  photo: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF7A86B), Color(0xFF7FB6C9)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      _Tab.template => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          for (final t in CollageTemplate.values)
            _TrayThumb(
              key: Key('manifestTemplate_${t.name}'),
              label: _templateName(l10n, t),
              selected: t == _template,
              onTap: () => setState(() => _template = t),
              child: SizedBox(width: 48, height: 48, child: _TemplatePreview(template: t)),
            ),
        ],
      ),
      _Tab.background => ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          for (final b in CollageBackground.values)
            _TrayThumb(
              key: Key('manifestBackground_${b.name}'),
              label: _backgroundName(l10n, b),
              selected: b == _background,
              onTap: () => setState(() => _background = b),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(width: 58, height: 58, child: _collageBackground(b, 58 * 4)),
              ),
            ),
        ],
      ),
      _Tab.sticker => _buildStickerTray(l10n),
      _Tab.text => _buildTextTray(l10n, colorScheme),
    };
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: kStickerOutline, width: 3)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: body,
    );
  }

  Widget _buildStickerTray(AppLocalizations l10n) {
    final costumeProvider = context.watch<CostumeProvider>();
    final owned = <Costume>[];
    final locked = <Costume>[];
    for (final costume in costumes) {
      (costumeProvider.isOwned(costume.id) ? owned : locked).add(costume);
    }
    final colorScheme = Theme.of(context).colorScheme;

    Widget group(String title, List<Widget> thumbs) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(children: thumbs),
          ],
        ),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        group('Zibo', [
          for (final asset in freeZiboStickerAssets)
            _TrayThumb(
              key: Key('manifestSticker_$asset'),
              onTap: () => _addSticker(_PlacedSticker(_StickerKind.image, asset)),
              child: Image.asset(asset, height: 54),
            ),
          for (final costume in owned)
            _TrayThumb(
              key: Key('manifestSticker_${costume.id}'),
              onTap: () => _addSticker(_PlacedSticker(_StickerKind.image, costume.imageAsset)),
              child: Image.asset(costume.imageAsset, height: 54),
            ),
          for (final costume in locked)
            _TrayThumb(
              key: Key('manifestSticker_${costume.id}'),
              lockLabel: '🔒',
              onTap: () => showInfoDialog(
                context,
                l10n.manifestEditorCostumeLocked(costume.localizedName(l10n)),
              ),
              child: Opacity(opacity: 0.45, child: Image.asset(costume.imageAsset, height: 54)),
            ),
        ]),
        for (final emojiGroup in ManifestEmojiGroup.values)
          group(_emojiGroupName(l10n, emojiGroup), [
            for (final emoji in emojiGroup.emojis)
              _TrayThumb(
                key: Key('manifestEmoji_$emoji'),
                onTap: () => _addSticker(_PlacedSticker(_StickerKind.emoji, emoji)),
                child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1)),
              ),
          ]),
      ],
    );
  }

  String _emojiGroupName(AppLocalizations l10n, ManifestEmojiGroup group) => switch (group) {
    ManifestEmojiGroup.luck => l10n.manifestEmojiGroupLuck,
    ManifestEmojiGroup.love => l10n.manifestEmojiGroupLove,
    ManifestEmojiGroup.nature => l10n.manifestEmojiGroupNature,
    ManifestEmojiGroup.goals => l10n.manifestEmojiGroupGoals,
    ManifestEmojiGroup.party => l10n.manifestEmojiGroupParty,
  };

  Widget _buildTextTray(AppLocalizations l10n, ColorScheme colorScheme) {
    final affirmations = manifestAffirmationsForLocale(Localizations.localeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _ChipButton(
                key: const Key('manifestCustomTextButton'),
                label: l10n.manifestEditorCustomText,
                onTap: _addCustomText,
              ),
              for (final phrase in affirmations)
                _ChipButton(
                  label: phrase,
                  onTap: () => _addSticker(
                    _PlacedSticker(_StickerKind.text, phrase, textColor: _textColor),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                l10n.manifestEditorColorLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              for (final color in _textColors)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _textColor = color;
                      final selected = _selected;
                      if (selected != null && selected.kind == _StickerKind.text) {
                        selected.textColor = color;
                      }
                    }),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.fill,
                        shape: BoxShape.circle,
                        border: Border.all(color: kStickerOutline, width: 2.5),
                        boxShadow: identical(color, _textColor)
                            ? [BoxShadow(color: colorScheme.primary, spreadRadius: 3)]
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(AppLocalizations l10n, ColorScheme colorScheme) {
    Widget tab(_Tab t, IconData icon, String label) {
      final selected = t == _tab;
      return Expanded(
        child: InkWell(
          key: Key('manifestEditorTab_${t.name}'),
          onTap: () => setState(() => _tab = t),
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: selected ? colorScheme.primary : Colors.transparent, width: 3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: const Border(top: BorderSide(color: kStickerOutline, width: 2)),
      ),
      child: Row(
        children: [
          if (_isCollage) ...[
            tab(_Tab.template, Icons.dashboard_outlined, l10n.manifestEditorTabTemplate),
            tab(_Tab.background, Icons.palette_outlined, l10n.manifestEditorTabBackground),
          ] else
            tab(_Tab.frame, Icons.crop_square_rounded, l10n.manifestEditorTabFrame),
          tab(_Tab.sticker, Icons.emoji_emotions_outlined, l10n.manifestEditorTabSticker),
          tab(_Tab.text, Icons.text_fields_rounded, l10n.manifestEditorTabText),
        ],
      ),
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText({required this.text, required this.fontSize, required this.color});

  final String text;
  final double fontSize;
  final _TextColor color;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Paint? foreground) => TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: const [FontVariation('wght', 800)],
      fontSize: fontSize,
      height: 1.1,
      foreground: foreground,
      color: foreground == null ? color.fill : null,
    );
    return Stack(
      children: [
        Text(
          text,
          style: style(
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.24
              ..strokeJoin = StrokeJoin.round
              ..color = color.stroke,
          ),
        ),
        Text(text, style: style(null)),
      ],
    );
  }
}

class _StickerHandle extends StatelessWidget {
  const _StickerHandle({
    super.key,
    required this.icon,
    required this.label,
    required this.inverseScale,
    this.onTap,
    this.onPanUpdate,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final double inverseScale;
  final VoidCallback? onTap;
  final GestureDragUpdateCallback? onPanUpdate;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanUpdate: onPanUpdate,
        child: Transform.scale(
          scale: inverseScale,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: filled ? const Color(0xFFF3B23C) : const Color(0xFFFFF4DE),
              shape: BoxShape.circle,
              border: Border.all(color: kStickerOutline, width: 2),
            ),
            child: Icon(icon, size: 14, color: kStickerOutline),
          ),
        ),
      ),
    );
  }
}

class _TrayThumb extends StatelessWidget {
  const _TrayThumb({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.selected = false,
    this.lockLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? label;
  final bool selected;
  final String? lockLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kStickerOutline, width: 2.5),
                      boxShadow: selected
                          ? [BoxShadow(color: colorScheme.primary, spreadRadius: 3)]
                          : null,
                    ),
                    child: child,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
              if (lockLabel != null)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: kStickerOutline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      lockLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        color: Color(0xFFFFF4DE),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: colorScheme.surface,
        shape: const StadiumBorder(side: BorderSide(color: kStickerOutline, width: 2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatioSelector extends StatelessWidget {
  const _RatioSelector({required this.selected, required this.labels, required this.onSelected});

  final _Ratio selected;
  final Map<_Ratio, String> labels;
  final ValueChanged<_Ratio> onSelected;

  @override
  Widget build(BuildContext context) {
    const ratioText = {_Ratio.post: '4:5', _Ratio.square: '1:1', _Ratio.story: '9:16'};
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in _Ratio.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: r == selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
              shape: const StadiumBorder(side: BorderSide(color: kStickerOutline, width: 2)),
              child: InkWell(
                key: Key('manifestRatio_${r.name}'),
                customBorder: const StadiumBorder(),
                onTap: () => onSelected(r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: ratioText[r], style: const TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ' ${labels[r]}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: r == selected ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({super.key, required this.label, required this.onTap, this.busy = false, this.dark = false});

  final String label;
  final VoidCallback onTap;
  final bool busy;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = dark ? kStickerOutline : colorScheme.primary;
    final ink = dark ? const Color(0xFFFFF4DE) : colorScheme.onPrimary;
    return stickerButtonShadow(
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: busy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: kStickerOutline, width: 2.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ink),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontSize: 14,
                      color: ink,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Dışa aktarma sheet'i — `'share'` / `'save'` döndürür, işi editör yapar.
class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.subtitle, required this.showWatermarkNote});

  final String subtitle;
  final bool showWatermarkNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    Widget button(String label, String action, {required bool primary, Key? key}) {
      return SizedBox(
        width: double.infinity,
        child: stickerButtonShadow(
          radius: 14,
          child: Material(
            color: primary ? colorScheme.primary : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: key,
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).pop(action),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: kStickerOutline, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 16,
                    color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.manifestEditorExportTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: 20,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            button(l10n.manifestEditorShareButton, 'share', primary: true, key: const Key('manifestExportShare')),
            const SizedBox(height: 10),
            button(l10n.manifestEditorSaveToGallery, 'save', primary: false, key: const Key('manifestExportSave')),
            if (showWatermarkNote) ...[
              const SizedBox(height: 10),
              Text(
                l10n.manifestEditorWatermarkNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Controller'ın ömrü dialog'un kendi State'ine bağlı (bkz. test/CLAUDE.md
/// "TextEditingController used after being disposed" dersi).
class _CustomTextDialog extends StatefulWidget {
  const _CustomTextDialog();

  @override
  State<_CustomTextDialog> createState() => _CustomTextDialogState();
}

class _CustomTextDialogState extends State<_CustomTextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      content: TextField(
        key: const Key('manifestCustomTextField'),
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(hintText: l10n.manifestEditorCustomTextHint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('manifestCustomTextAdd'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.manifestEditorAddText),
        ),
      ],
    );
  }
}

class _CollageDotPainter extends CustomPainter {
  const _CollageDotPainter({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = const Color(0xB3F3B23C);
    final step = unit * 0.034;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), unit * 0.0045, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_CollageDotPainter oldDelegate) => oldDelegate.unit != unit;
}

/// Şablon tepsisindeki küçük önizleme — kutuların yerleşimini gösterir.
class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.template});

  final CollageTemplate template;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.biggest;
        return Stack(
          children: [
            for (final slot in template.slots)
              Positioned(
                left: slot.left * s.width + 1.5,
                top: slot.top * s.height + 1.5,
                width: slot.width * s.width - 3,
                height: slot.height * s.height - 3,
                child: Transform.rotate(
                  angle: slot.rotationDeg * 3.1415926535 / 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: template.isPolaroid ? const Color(0xFFFFFDF7) : const Color(0xFF7FB6C9),
                      border: Border.all(color: kStickerOutline, width: 1.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Kolaj kutusu için seçici: manifest kayıtları (fotoğraflı olanlar küçük
/// resim, yalnızca yazı olanlar sarı kart) + telefon galerisi. Seçilen
/// `ManifestEntry`'yi ya da [galleryChoice]'ı döndürür.
class _CollagePickerSheet extends StatelessWidget {
  const _CollagePickerSheet({required this.entries});

  static const galleryChoice = 'gallery';

  final List<ManifestEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final usable = entries.where((e) => _TileContent.fromEntry(e) != null).toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.manifestCollagePickTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontVariations: const [FontVariation('wght', 800)],
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              if (usable.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.manifestCollageFromManifests,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final entry in usable)
                        GestureDetector(
                          key: Key('manifestCollagePick_${entry.id}'),
                          onTap: () => Navigator.of(context).pop(entry),
                          child: _PickerThumb(entry: entry),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              stickerButtonShadow(
                radius: 14,
                child: Material(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: const Key('manifestCollageFromGallery'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(galleryChoice),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: kStickerOutline, width: 3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.manifestCollageFromGallery,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontVariations: const [FontVariation('wght', 700)],
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerThumb extends StatelessWidget {
  const _PickerThumb({required this.entry});

  final ManifestEntry entry;

  @override
  Widget build(BuildContext context) {
    final file = _existingFile(entry.photoPath);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6D488),
        border: Border.all(color: kStickerOutline, width: 2.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: file != null
            ? Image.file(file, fit: BoxFit.cover, cacheWidth: 240)
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    entry.intentionText,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: [FontVariation('wght', 800)],
                      fontSize: 10.5,
                      height: 1.1,
                      color: kStickerOutline,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
