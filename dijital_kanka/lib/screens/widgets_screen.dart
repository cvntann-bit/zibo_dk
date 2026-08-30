import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/home_widget_service.dart';
import '../utils/widget_module.dart';

/// Beş modülün ana ekran widget'larını (bkz. CLAUDE.md "Ana Ekran
/// Widget'ları" bölümü — 2026 güncellemesi, beş "basit günlük/checkbox"
/// widget'ı kaldırılıp yerine [ZiboWidgetModule.profileStats] geldi) TEK
/// bir listede toplayıp her biri için ekleme TALİMATLARINI gösteren bir
/// ekran — Ayarlar > Genel'deki "Ana Ekran Widget'ları" satırından push
/// edilir.
///
/// **2026 İKİNCİ güncelleme — "uygulama içinden widget eklenmiyor" raporu.**
/// `HomeWidgetService.requestPin()` (`AppWidgetManager.requestPinAppWidget`)
/// bazı launcher'larda (canlı doğrulanan örnek: MIUI) `true` DÖNÜYOR ama
/// widget'ı GERÇEKTEN bağlamıyor — `adb dumpsys appwidget` ile kanıtlandı,
/// bkz. CLAUDE.md. Bu, API'nin KENDİSİ hatasız `true` döndüğü için Dart/
/// Kotlin tarafından TESPİT EDİLEMEYEN bir OEM launcher kısıtlaması —
/// bu yüzden "Ekle" butonunun BAŞARI/BAŞARISIZLIK mesajı artık
/// `requestPin()`'in dönüş değerine GÜVENMİYOR. Bunun yerine buton HER
/// ZAMAN [_showAddInstructionsSheet]'i (manuel "uzun bas → Widget'lar"
/// akışının adım adım talimatı) açıyor — TEK güvenilir, evrensel yol bu
/// olduğu için. `requestPin()` YİNE DE arka planda (`unawaited`, sonucunu
/// hiç beklemeden/UI'a yansıtmadan) çağrılmaya devam ediyor — bu API'yi
/// GERÇEKTEN doğru uygulayan launcher'larda (ör. stok Android/Pixel)
/// kullanıcı belki hiç uzun basmadan sistemin kendi onay diyaloğunu görüp
/// tek adımda ekleyebilir, bu "bonus" yol tamamen zararsız.
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

  void _addWidget(
    ZiboWidgetModule module,
    String emoji,
    String title,
    Color accent,
  ) {
    // Bkz. sınıf dokümantasyonu — sonucunu HİÇ beklemiyoruz/UI'a
    // yansıtmıyoruz, yalnızca destekleyen launcher'lar için sessiz bir
    // "bonus" deneme.
    unawaited(_service.requestPin(module));
    _showAddInstructionsSheet(
      context,
      emoji: emoji,
      title: title,
      accent: accent,
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
          Text(
            l10n.widgetsScreenIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final module in ZiboWidgetModule.values) ...[
            _WidgetModuleTile(module: module, onAdd: _addWidget),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

void _showAddInstructionsSheet(
  BuildContext context, {
  required String emoji,
  required String title,
  required Color accent,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // `ad_free_promo_sheet.dart`'taki AYNI desen — üç adımlık talimat +
    // başlık + buton dar/kısa ekranlarda sabit sheet yüksekliğine
    // sığmayıp `RenderFlex overflow`'a yol açabiliyordu (gerçek bir hata,
    // yalnızca test viewport'una özgü değil — dar bir telefonda da
    // olurdu); `isScrollControlled: true` + `SingleChildScrollView` bunu
    // kökten önlüyor.
    isScrollControlled: true,
    builder: (sheetContext) {
      final steps = [
        l10n.widgetsScreenAddStep1,
        l10n.widgetsScreenAddStep2,
        l10n.widgetsScreenAddStep3,
      ];
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withValues(alpha: 0.18),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.widgetsScreenAddSheetTitle,
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < steps.length; i++) ...[
                  _AddStepRow(index: i + 1, text: steps[i], accent: accent),
                  if (i != steps.length - 1) const SizedBox(height: 14),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.widgetsScreenAddSheetGotIt),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AddStepRow extends StatelessWidget {
  const _AddStepRow({
    required this.index,
    required this.text,
    required this.accent,
  });

  final int index;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: accent,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _WidgetModuleTile extends StatelessWidget {
  const _WidgetModuleTile({required this.module, required this.onAdd});

  final ZiboWidgetModule module;
  final void Function(
    ZiboWidgetModule module,
    String emoji,
    String title,
    Color accent,
  )
  onAdd;

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
          onPressed: () => onAdd(module, emoji, title, accent),
          child: Text(l10n.widgetsScreenAddButton),
        ),
      ),
    );
  }

  (String, String, Color) _presentationFor(
    ZiboWidgetModule module,
    AppLocalizations l10n,
  ) {
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
