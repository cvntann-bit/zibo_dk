import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/home_quick_module.dart';
import '../utils/home_quick_module_info.dart';
import 'sticker_style.dart';

/// Ana Sayfa'daki değiştirilebilir mini widget slotlarından biri için modül
/// seçim sheet'i — kullanıcı isteği: "kullanıcı istediği modülü widget
/// olarak ekleyebilsin". Görsel dil `modules_menu_sheet.dart`'taki
/// `_ModuleCard`'la BİREBİR aynı (emoji dairesi + başlık + açıklama), tek
/// fark sağdaki gezinme oku (">") yerine seçili modülde altın bir ✓
/// göstermesi — `settings_screen.dart`'taki `_SheetOptionRow`'un AYNI
/// "seçili olana ✓" deseni.
Future<void> showHomeQuickModulePicker(
  BuildContext context, {
  required HomeQuickModule current,
  required ValueChanged<HomeQuickModule> onSelect,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colorScheme.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      side: BorderSide(color: kStickerOutline, width: 3),
    ),
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.homeQuickWidgetPickerTitle,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontVariations: [FontVariation('wght', 800)],
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final module in HomeQuickModule.values) ...[
              _QuickModuleRow(
                emoji: homeQuickModuleEmoji(module),
                title: homeQuickModulePickerTitle(module, l10n),
                description: homeQuickModuleDescription(module, l10n),
                selected: module == current,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelect(module);
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

class _QuickModuleRow extends StatelessWidget {
  const _QuickModuleRow({
    required this.emoji,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(16);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: stickerDecoration(
            fill: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerLowest,
            borderRadius: borderRadius,
            borderWidth: 3,
            shadowOffset: Offset.zero,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: stickerCircleDecoration(
                  fill: colorScheme.primary,
                  borderWidth: 2.5,
                  shadowOffset: Offset.zero,
                ),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Text(
                  '✓',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
        // Sticker Container'ın KENDİ dolgusu OPAK olduğu için InkWell'in
        // dalga efekti altında görünmez kalır — bkz. `modules_menu_sheet.
        // dart`'taki AYNI çözüm (şeffaf bir Material katmanı ÜSTE eklenir).
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(borderRadius: borderRadius, onTap: onTap),
          ),
        ),
      ],
    );
  }
}
