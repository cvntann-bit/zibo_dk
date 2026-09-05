import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/dream_journal_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../screens/gratitude_journal_screen.dart';
import '../screens/manifest_journal_screen.dart';
import '../screens/money_screen.dart';
import '../screens/mood_tracking_screen.dart';
import '../screens/water_tracking_screen.dart';

/// Z butonuna basınca açılan, ek modüllerin (Rüya Günlüğü, Şükran Günlüğü,
/// Günlük Ruh Hali Takibi, Su Takibi) listelendiği bottom sheet. Bu ekranlar
/// daha önce dağınık yerlerdeydi (Dream Journal AppBar'da bir ay ikonu,
/// diğerleri Ayarlar'da birer satırdı) — artık hepsi tek, keşfedilebilir bir
/// menüde (bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümü). Su Takibi, önceki
/// üçünden farklı olarak baştan beri bu menüde tanıtıldı (Ayarlar'da hiç
/// yaşamadı).
Future<void> showModulesMenuSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModuleCard(
                icon: Icons.nights_stay_outlined,
                title: l10n.dreamJournalTooltip,
                description: l10n.dreamModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DreamJournalScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.favorite_outline,
                title: l10n.gratitudeSettingsTitle,
                description: l10n.gratitudeModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GratitudeJournalScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.mood_outlined,
                title: l10n.moodSettingsTitle,
                description: l10n.moodModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MoodTrackingScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.water_drop_outlined,
                title: l10n.waterSettingsTitle,
                description: l10n.waterModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WaterTrackingScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.auto_awesome_outlined,
                title: l10n.manifestSettingsTitle,
                description: l10n.manifestModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManifestJournalScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                icon: Icons.savings_outlined,
                title: l10n.moneyScreenTitle,
                description: l10n.moneyModuleDescription,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MoneyScreen()));
                },
              ),
              const SizedBox(height: 12),
              // 2026 yeni özellik — Odak Sayacı (bkz. CLAUDE.md).
              _ModuleCard(
                icon: Icons.timer_outlined,
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
      );
    },
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
