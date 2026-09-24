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
import '../services/share_service.dart';
import '../utils/coin_feedback.dart';
import '../utils/info_dialog.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/manifest_frame_view.dart';
import '../widgets/sticker_style.dart';

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

enum _Tab { frame, sticker, text }

enum _StickerKind { image, emoji, text }

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
class ManifestEditorScreen extends StatefulWidget {
  const ManifestEditorScreen({
    super.key,
    required this.entry,
    this.shareService = const SharePlusService(),
    this.gallerySaver = saveImageToGallery,
  });

  final ManifestEntry entry;
  final ShareService shareService;
  final GallerySaver gallerySaver;

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

  @override
  void initState() {
    super.initState();
    final path = widget.entry.photoPath;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) _photoFile = file;
      } catch (_) {}
    }
  }

  String _frameName(AppLocalizations l10n, ManifestFrame frame) => switch (frame) {
    ManifestFrame.none => l10n.manifestFrameNone,
    ManifestFrame.polaroid => l10n.manifestFramePolaroid,
    ManifestFrame.film => l10n.manifestFrameFilm,
    ManifestFrame.washi => l10n.manifestFrameWashi,
    ManifestFrame.gold => l10n.manifestFrameGold,
    ManifestFrame.stars => l10n.manifestFrameStars,
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
    setState(() => _selected = null);
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: _exportWidth / boundary.size.width);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
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
    if (!await _unlockFrame(_frame) || !mounted) return;
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
    final frameLocked = !decor.isFrameUnlocked(_frame);

    return Scaffold(
      appBar: plainStickerAppBar(
        context,
        title: l10n.manifestEditorTitle,
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
                      child: ManifestFrameView(
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
    final date = formatLongDate(widget.entry.date, Localizations.localeOf(context));
    final text = widget.entry.intentionText.trim();
    return text.isEmpty ? date : '$date · $text';
  }

  Widget _buildPhoto(double w) {
    final file = _photoFile;
    if (file != null) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _textBackdrop(w),
      );
    }
    return _textBackdrop(w);
  }

  Widget _textBackdrop(double w) {
    return ColoredBox(
      color: const Color(0xFFF6D488),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(w * 0.08),
          child: Text(
            widget.entry.intentionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: w * 0.07,
              height: 1.2,
              color: kStickerOutline,
            ),
          ),
        ),
      ),
    );
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
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
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
        for (final emoji in manifestEmojiStickers)
          _TrayThumb(
            onTap: () => _addSticker(_PlacedSticker(_StickerKind.emoji, emoji)),
            child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1)),
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
      ],
    );
  }

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
