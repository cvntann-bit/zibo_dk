import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/share_card_backgrounds.dart';
import '../data/share_card_text_styles.dart';
import '../l10n/app_localizations.dart';
import '../services/share_service.dart';
import 'zibo_share_card.dart';

/// Yazı stili önizleme kartçıklarının arka planı — uygulamanın açık/koyu
/// temasından bağımsız, sabit koyu bir zemin. Stil ön ayarlarındaki hem
/// beyaz hem altın metin rengi bu zeminde her zaman okunabilir kalır.
const _textStylePreviewBackground = Color(0xFF2A2118);

/// "Zibonu Paylaş" bottom sheet'i: canlı kart önizlemesi + gradyan arka plan
/// ve yazı stili seçicileri + native paylaşım sayfasını açan "Paylaş" butonu.
class ZiboShareSheet extends StatefulWidget {
  const ZiboShareSheet({
    super.key,
    required this.message,
    this.shareService = const SharePlusService(),
  });

  final String message;

  /// Testte gerçek `share_plus` platform channel'ına dokunmadan sahte bir
  /// implementasyon enjekte edebilmek için var (bkz. [ShareService]).
  final ShareService shareService;

  @override
  State<ZiboShareSheet> createState() => _ZiboShareSheetState();
}

class _ZiboShareSheetState extends State<ZiboShareSheet> {
  final _boundaryKey = GlobalKey();

  // Varsayılan arka plan: "Gece Kahvesi" — uygulamanın koyu temasıyla uyumlu,
  // altın logo ve beyaz/altın metinle her koşulda iyi kontrast verir.
  int _selectedBackgroundIndex = 0;
  int _selectedTextStyleIndex = 0;
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      // Instagram/TikTok Hikaye için yeterli çözünürlüğe (9:16 oranını
      // koruyarak) denk gelsin diye 3x pixelRatio ile yakalanıyor (bkz.
      // ZiboShareCard: 450×800 mantıksal boyut × 3 = 1350×2400).
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      await widget.shareService.shareImageBytes(
        bytes,
        fileName: 'zibo_soz.png',
        text: widget.message,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSharing = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.shareErrorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedBackground = shareCardBackgrounds[_selectedBackgroundIndex];
    final selectedTextStyle = shareCardTextStyles[_selectedTextStyleIndex];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        // Kısa ekranlarda (ör. küçük telefonlar, yatay mod) önizleme + iki
        // seçici + buton toplamı ekran yüksekliğini aşabilir; sabit bir
        // Column yerine kaydırılabilir bir gövde kullanmak taşmayı önler.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.shareSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: AspectRatio(
                  aspectRatio: ZiboShareCard.width / ZiboShareCard.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: ZiboShareCard(
                          message: widget.message,
                          gradient: selectedBackground.gradient,
                          textStyle: selectedTextStyle.style,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.shareBackgroundLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shareCardBackgrounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = shareCardBackgrounds[index];
                    final selected = index == _selectedBackgroundIndex;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: item.label,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedBackgroundIndex = index),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: item.gradient,
                            border: Border.all(
                              color: selected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.shareTextStyleLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shareCardTextStyles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = shareCardTextStyles[index];
                    final selected = index == _selectedTextStyleIndex;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: item.label,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedTextStyleIndex = index),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _textStylePreviewBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Aa',
                            style: item.style.copyWith(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(l10n.shareActionButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
