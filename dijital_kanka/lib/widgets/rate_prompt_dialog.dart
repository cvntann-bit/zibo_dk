import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_streak_provider.dart';
import '../utils/rate_prompt_trigger.dart';
import 'rate_us_sheet.dart' show openPlayStoreListing;
import 'sticker_style.dart';

const _ziboImage = 'assets/images/zibo_df_pose3.webp';

/// Mutlu bir anda çağrılır; [RatePromptTrigger] kuralları izin verirse
/// pencereyi açar ve `true` döner (7 günlük hedefte o seferki reklamın
/// YERİNE gösterildiği için çağıranın bilmesi gerekiyor). Bir kutlama/bilgi
/// penceresi varsa O KAPANDIKTAN sonra çağrılmalı.
bool maybeShowRatePrompt(BuildContext context) {
  final shouldShow = RatePromptTrigger.shouldShow(
    daysOpened: () => context.read<AppStreakProvider>().totalDaysOpened,
  );
  if (!shouldShow) return false;
  unawaited(showRatePromptDialog(context));
  return true;
}

/// Kurallara bakmadan doğrudan açar — Ayarlar debug paneli için.
Future<void> showRatePromptDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const RatePromptDialog(),
  );
}

/// "Bizi Google Play'de Puanla" penceresi — onaylı mockup:
/// https://claude.ai/artifact/Qf33JAT5BwXqEkiuHU3cBr (bkz. docs/theme_new.md).
/// Yıldız / Puanla → Play Store + kalıcı kapanış; Daha Sonra / ✕ → yalnızca
/// kapanır (bekleme süresi gösterimde başladı); Zaten puanladım → kalıcı
/// kapanış.
class RatePromptDialog extends StatefulWidget {
  const RatePromptDialog({super.key});

  @override
  State<RatePromptDialog> createState() => _RatePromptDialogState();
}

class _RatePromptDialogState extends State<RatePromptDialog> {
  int _stars = 0;
  bool _leaving = false;

  void _rate() {
    RatePromptTrigger.markCompleted();
    // `await` EDİLMİYOR — `launchUrl` test ortamında asılı kalabiliyor (bkz.
    // `rate_us_sheet.dart`'taki AYNI gerekçe).
    unawaited(openPlayStoreListing());
    Navigator.of(context).pop();
  }

  Future<void> _onStar(int count) async {
    if (_leaving) return;
    setState(() {
      _stars = count;
      _leaving = true;
    });
    // Dolan yıldızlar görünsün, sonra Play Store'a geçilsin.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) _rate();
  }

  void _alreadyRated() {
    RatePromptTrigger.markCompleted();
    Navigator.of(context).pop();
  }

  void _later() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surfaceContainerLowest;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 12),
      decoration: stickerDecoration(
        fill: surface,
        borderRadius: BorderRadius.circular(26),
        shadowOffset: const Offset(5, 5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.ratePromptTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 22,
              height: 1.15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ratePromptBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _StarButton(
                    key: ValueKey('ratePromptStar$i'),
                    filled: i <= _stars,
                    label: l10n.ratePromptStarLabel(i),
                    onTap: () => _onStar(i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.ratePromptStarHint,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: stickerButtonShadow(
              radius: 14,
              child: Material(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const Key('ratePromptRateButton'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: _leaving ? null : _rate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: kStickerOutline, width: 3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.ratePromptRateButton,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontSize: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('ratePromptLaterButton'),
            onPressed: _later,
            style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
            child: Text(
              l10n.ratePromptLaterButton,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          TextButton(
            key: const Key('ratePromptAlreadyRatedButton'),
            onPressed: _alreadyRated,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              l10n.ratePromptAlreadyRatedButton,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 104, right: 5, bottom: 5),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              Positioned(
                top: -104,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Image.asset(
                      _ziboImage,
                      height: 190,
                      semanticLabel: l10n.ziboImagePlaceholder,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Semantics(
                  button: true,
                  label: MaterialLocalizations.of(context).closeButtonTooltip,
                  excludeSemantics: true,
                  child: Material(
                    color: surface,
                    shape: const CircleBorder(
                      side: BorderSide(color: kStickerOutline, width: 2.5),
                    ),
                    child: InkWell(
                      key: const Key('ratePromptCloseButton'),
                      customBorder: const CircleBorder(),
                      onTap: _later,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurface),
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

class _StarButton extends StatelessWidget {
  const _StarButton({
    super.key,
    required this.filled,
    required this.label,
    required this.onTap,
  });

  final bool filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final empty = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.22),
      colorScheme.surfaceContainerLowest,
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: filled ? 1.08 : 1,
          duration: const Duration(milliseconds: 160),
          child: SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _StickerStarPainter(fill: filled ? colorScheme.primary : empty),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kalın konturlu sticker yıldızı — mockup'taki 48'lik SVG yolunun aynısı.
class _StickerStarPainter extends CustomPainter {
  const _StickerStarPainter({required this.fill});

  final Color fill;

  static const _points = [
    Offset(24, 4.5),
    Offset(29.6, 16.1),
    Offset(42.3, 17.8),
    Offset(33, 26.6),
    Offset(35.3, 39.2),
    Offset(24, 33.1),
    Offset(12.7, 39.2),
    Offset(15, 26.6),
    Offset(5.7, 17.8),
    Offset(18.4, 16.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    final path = Path()..moveTo(_points.first.dx * scale, _points.first.dy * scale);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx * scale, p.dy * scale);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = kStickerOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * scale
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StickerStarPainter oldDelegate) => oldDelegate.fill != fill;
}
