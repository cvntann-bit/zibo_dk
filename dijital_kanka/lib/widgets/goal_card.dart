import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/goal.dart';
import '../providers/coin_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/info_dialog.dart';
import '../utils/zibo_event_signal.dart';
import 'sticker_style.dart';

/// Tek bir hedefi; adını, ilerleme durumunu ve 7 günlük işaretleme
/// kutucuklarını gösteren kart. Kutucuklardan yalnızca bugüne karşılık
/// gelen tıklanabilir; döngü tamamlandığında coin ödülünü verip kullanıcıya
/// haber verir.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.today,
    this.onMarkedToday,
    this.onCycleCompleted,
  });

  final Goal goal;
  final DateTime today;

  /// Kullanıcı bugünün kutucuğunu YENİ işaretlediğinde (işareti KALDIRMA
  /// değil) çağrılır — `GoalTrackingScreen`'in ekran-genelinde titreşim +
  /// konfeti + ses efektini tetiklemesi için (bkz. o dosyadaki
  /// dokümantasyon). `null` ise (varsayılan) hiçbir şey tetiklenmez —
  /// `flutter test`'teki `GoalCard(goal: ..., today: ...)` gibi doğrudan
  /// kurulan mevcut testler etkilenmesin diye.
  final VoidCallback? onMarkedToday;

  /// [onMarkedToday]'DEN AYRI, BİLEREK farklı bir sinyal — bu YALNIZCA
  /// döngü GERÇEKTEN 7/7 tamamlanınca (`cycleCompleted == true`) çağrılır,
  /// `onMarkedToday` her gün işaretlemede çağrılır. `GoalTrackingScreen`
  /// bunu, kutlama animasyonu (titreşim+konfeti) BİTTİKTEN SONRA bir geçiş
  /// reklamı göstermek için kullanıyor (bkz. o dosyadaki dokümantasyon) —
  /// reklamın kutlamayı KESMEMESİ için iki sinyal AYRI tutuldu.
  final VoidCallback? onCycleCompleted;

  void _onTodayTap(BuildContext context) {
    final goalsProvider = context.read<GoalsProvider>();
    final l10n = AppLocalizations.of(context)!;
    // Bu dokunuşun bir "işaretleme" mi yoksa "işaret kaldırma" mı olduğunu
    // `toggleToday()` çağrılmadan ÖNCE belirlememiz gerekiyor —
    // `toggleToday()`'in dönüş değeri (`cycleCompleted`) yalnızca 7/7
    // tamamlanma anını ayırt ediyor, tek başına işaretleme/kaldırma
    // yönünü DEĞİL (bkz. GoalsProvider.toggleToday dokümantasyonu).
    final wasAlreadyMarkedToday = goal.completedDates.contains(today);
    final cycleCompleted = goalsProvider.toggleToday(goal.id);

    if (!wasAlreadyMarkedToday) onMarkedToday?.call();

    if (cycleCompleted) {
      context.read<CoinProvider>().earnStreak7Bonus();
      showInfoDialog(context, l10n.goalCycleCompleted);
      // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
      // Ana Sayfa'nın konuşma balonu bir SONRAKİ seçiminde bu özel kutlama
      // havuzundan bir söz gösterecek, normal zaman/ruh hali seçimini
      // baypas ederek — bkz. `zibo_event_signal.dart`.
      pendingZiboEvent.value = ZiboEventType.goalCycleCompleted;
      onCycleCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // 2026 güncellemesi — kullanıcı isteği: gün numaraları döngü
    // tamamlanınca 1'e DÖNMESİN, ardışık devam etsin (1-7, sonra 8-14,
    // sonra 15-21...) — bkz. `GoalsProvider.completedCyclesFor`
    // dokümantasyonu. Yalnızca GÖRÜNTÜLENEN sayı değişiyor, `goal.
    // statusForDay`'in (dolayısıyla döngü/kilit/tamamlanma mantığının)
    // kendisi hiç dokunulmadı.
    final completedCycles = context.watch<GoalsProvider>().completedCyclesFor(
      goal.id,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        borderWidth: 3,
        shadowOffset: Offset.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _DeleteButton(
                tooltip: l10n.deleteGoalTooltip,
                onPressed: () =>
                    context.read<GoalsProvider>().removeGoal(goal.id),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.goalProgressLabel(goal.progressCount),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var day = 0; day < Goal.daysPerCycle; day++)
                _DayBox(
                  dayNumber: completedCycles * Goal.daysPerCycle + day + 1,
                  status: goal.statusForDay(day, today),
                  onTap: () => _onTodayTap(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mockup'ın `.del` butonu — dolgusuz, ince konturlu köşeli kare (Material
/// `IconButton.filled`in AKSİNE, `.icon-btn`/`.mini-btn` ailesinden FARKLI
/// bir "pasif/ikincil" varyant: dolgu YOK, yalnızca kontur).
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(7));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: kStickerOutline, width: 2),
              borderRadius: radius,
            ),
            child: Icon(Icons.close, size: 13, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

const _frozenBlue = Color(0xFF8FD3FF);
const _frozenInk = Color(0xFF0E3A5C);

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.dayNumber,
    required this.status,
    required this.onTap,
  });

  final int dayNumber;
  final GoalDayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final String semanticLabel;
    final Color background;
    final Color foreground;
    final Color borderColor;
    final Widget content;

    switch (status) {
      case GoalDayStatus.done:
        semanticLabel = l10n.goalDayDone(dayNumber);
        background = colorScheme.primary;
        foreground = colorScheme.onPrimary;
        borderColor = kStickerOutline;
        content = Icon(Icons.check, size: 16, color: foreground);
      case GoalDayStatus.today:
        semanticLabel = l10n.goalDayToday(dayNumber);
        background = colorScheme.surfaceContainerLowest;
        foreground = colorScheme.primary;
        borderColor = colorScheme.primary;
        content = Text(
          '$dayNumber',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 12),
        );
      case GoalDayStatus.frozen:
        // Kullanıcı isteği: dondurulan gün MAVİ olsun. Tek vurgu rengi
        // kuralının bilinçli istisnası — "buz" anlamını renk taşıyor.
        semanticLabel = l10n.goalDayFrozen(dayNumber);
        background = _frozenBlue;
        foreground = _frozenInk;
        borderColor = kStickerOutline;
        content = const Icon(Icons.ac_unit_rounded, size: 15, color: _frozenInk);
      case GoalDayStatus.missed:
        semanticLabel = l10n.goalDayMissed(dayNumber);
        background = kAccentMuted;
        foreground = kStickerOutline;
        borderColor = kStickerOutline;
        content = Icon(Icons.close, size: 14, color: foreground);
      case GoalDayStatus.upcoming:
        semanticLabel = l10n.goalDayUpcoming(dayNumber);
        background = Colors.transparent;
        foreground = colorScheme.onSurfaceVariant.withValues(alpha: 0.55);
        borderColor = colorScheme.outlineVariant;
        content = Text(
          '$dayNumber',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 12),
        );
    }

    final isTappable = status == GoalDayStatus.today;
    // Mockup'ta yalnızca "bugün" pip'i (`.pip.today`) düz ofsetli bir sticker
    // gölgesi taşıyor — "tamamlandı" DAHİL diğer üç durumda gölge YOK.
    final isEmphasized = status == GoalDayStatus.today;

    return Semantics(
      label: semanticLabel,
      button: isTappable,
      child: InkWell(
        onTap: isTappable ? onTap : null,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isEmphasized
                ? const [
                    BoxShadow(color: kStickerOutline, offset: Offset(1.5, 1.5)),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
