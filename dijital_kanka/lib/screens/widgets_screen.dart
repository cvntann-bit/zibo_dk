import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/home_widget_service.dart';
import '../utils/widget_module.dart';

/// Beş modülün ana ekran widget'larını (bkz. CLAUDE.md "Ana Ekran
/// Widget'ları" bölümü — 2026 güncellemesi, beş "basit günlük/checkbox"
/// widget'ı kaldırılıp yerine [ZiboWidgetModule.profileStats] geldi) TEK
/// bir listede toplayıp her biri için "Ekle" butonu sunan ekran — Ayarlar
/// > Genel'deki "Ana Ekran Widget'ları" satırından push edilir.
class WidgetsScreen extends StatefulWidget {
  const WidgetsScreen({super.key, this.homeWidgetService});

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `HomeWidgetPluginService()` (`AdService`/`ShareService` ile AYNI
  /// desen).
  final HomeWidgetService? homeWidgetService;

  @override
  State<WidgetsScreen> createState() => _WidgetsScreenState();
}

class _WidgetsScreenState extends State<WidgetsScreen> {
  late final HomeWidgetService _service =
      widget.homeWidgetService ?? const HomeWidgetPluginService();

  Future<void> _addWidget(ZiboWidgetModule module) async {
    final l10n = AppLocalizations.of(context)!;
    final added = await _service.requestPin(module);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added ? l10n.widgetsScreenAddedSuccessMessage : l10n.widgetsScreenAddFailedMessage,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.widgetsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          Text(l10n.widgetsScreenIntro, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          for (final module in ZiboWidgetModule.values) ...[
            _WidgetModuleTile(
              module: module,
              onAdd: () => _addWidget(module),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WidgetModuleTile extends StatelessWidget {
  const _WidgetModuleTile({required this.module, required this.onAdd});

  final ZiboWidgetModule module;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (emoji, title, accent) = _presentationFor(module, l10n);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: accent.withValues(alpha: 0.18),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(title),
        trailing: FilledButton.tonal(
          onPressed: onAdd,
          child: Text(l10n.widgetsScreenAddButton),
        ),
      ),
    );
  }

  (String, String, Color) _presentationFor(ZiboWidgetModule module, AppLocalizations l10n) {
    switch (module) {
      case ZiboWidgetModule.water:
        return ('💧', l10n.widgetTitleWater, const Color(0xFF2F7FBF));
      case ZiboWidgetModule.money:
        return ('💰', l10n.widgetTitleMoney, const Color(0xFF1E88E5));
      case ZiboWidgetModule.dailyRewards:
        return ('🎁', l10n.widgetTitleDailyRewards, const Color(0xFFC79A3D));
      case ZiboWidgetModule.motivation:
        return ('💬', l10n.widgetTitleMotivation, const Color(0xFFA9711F));
      case ZiboWidgetModule.profileStats:
        return ('📊', l10n.widgetTitleProfileStats, const Color(0xFF8E24AA));
    }
  }
}
