import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/dream_journal_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/gratitude_journal_screen.dart';
import '../screens/manifest_journal_screen.dart';
import '../screens/money_screen.dart';
import '../screens/mood_tracking_screen.dart';
import '../screens/water_tracking_screen.dart';
import 'sticker_style.dart';
import 'z_floating_button.dart';

/// Z butonuna basınca açılan, ek modüllerin (Rüya Günlüğü, Şükran Günlüğü,
/// Günlük Ruh Hali Takibi, Su Takibi) listelendiği bottom sheet. Bu ekranlar
/// daha önce dağınık yerlerdeydi (Dream Journal AppBar'da bir ay ikonu,
/// diğerleri Ayarlar'da birer satırdı) — artık hepsi tek, keşfedilebilir bir
/// menüde (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü). Su Takibi, önceki
/// üçünden farklı olarak baştan beri bu menüde tanıtıldı (Ayarlar'da hiç
/// yaşamadı).
///
/// Görsel dil, onaylanan mockup'la (`docs/theme_new.md` "Onaylanan: Modül
/// menüsü") birebir — kalın konturlu sheet + her modül için beyaz/kontur
/// kart, altın dolgulu emoji dairesi, sağda köşeli ">" butonu.
Future<void> showModulesMenuSheet(BuildContext context) {
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
    builder: (sheetContext) {
      // Mockup'ta Z butonu sheet'in KENDİ içeriğinin bir parçası —
      // `.z-fab{position:absolute; top:-33px}` — sheet'in üst kenarından
      // yarısı taşacak şekilde, SALT görsel (statik HTML, tıklanabilir
      // değil). `Scaffold.floatingActionButton` modal route açılınca AYNI
      // Navigator'ın üstüne binen barrier/sheet tarafından ÖRTÜLDÜĞÜ için
      // (persistent değil), aynı görseli burada `IgnorePointer` ile SALT
      // dekoratif olarak tekrar çiziyoruz.
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModuleCard(
                    emoji: '🌙',
                    title: l10n.dreamJournalTooltip,
                    description: l10n.dreamModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DreamJournalScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    emoji: '❤️',
                    title: l10n.gratitudeSettingsTitle,
                    description: l10n.gratitudeModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GratitudeJournalScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    emoji: '🙂',
                    title: l10n.moodSettingsTitle,
                    description: l10n.moodModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MoodTrackingScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    emoji: '💧',
                    title: l10n.waterSettingsTitle,
                    description: l10n.waterModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WaterTrackingScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    emoji: '✨',
                    title: l10n.manifestSettingsTitle,
                    description: l10n.manifestModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManifestJournalScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ModuleCard(
                    emoji: '💰',
                    title: l10n.moneyScreenTitle,
                    description: l10n.moneyModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const MoneyScreen()));
                    },
                  ),
                  const SizedBox(height: 10),
                  // 2026 yeni özellik — Odak Sayacı (bkz. CLAUDE.md).
                  _ModuleCard(
                    emoji: '⏱️',
                    title: l10n.focusTimerTooltip,
                    description: l10n.focusModuleDescription,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FocusTimerScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Mockup'ta bu Z butonu SALT görsel (statik HTML, tıklama davranışı
          // tanımlı değil) — `IgnorePointer` ile dokunmaları TAMAMEN görmezden
          // gelir, aksi halde `top:-33` taşması ilk modül kartının dokunma
          // alanıyla çakışıp onun tıklamasını YUTUYORDU (gerçek test
          // hatasıyla bulundu — bkz. `widget_test.dart`'taki Rüya Günlüğü
          // testleri).
          Positioned(
            top: -40,
            child: IgnorePointer(
              child: ZFloatingButton(
                label: l10n.modulesMenuZButtonTooltip,
                onTap: () {},
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
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
            fill: colorScheme.surfaceContainerLowest,
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
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: kStickerOutline, width: 2),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '>',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sticker Container'ın KENDİ dolgusu OPAK olduğu için InkWell'in
        // dalga efekti altında görünmez kalır — bkz. `home_module_widget.
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
