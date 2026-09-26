import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../models/goal.dart';
import '../providers/app_streak_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/coin_feedback.dart';
import 'sticker_style.dart';
import 'streak_freeze_balance_card.dart' show streakFreezeIconAsset;

/// Donmuş günün buz mavisi — Hedefler'deki `GoalCard` ile AYNI renkler.
const _iceBlue = Color(0xFF8FD3FF);
const _iceInk = Color(0xFF0E3A5C);
const _icePale = Color(0xFFDDF2FF);

/// Dün kaçırılan günü kurtarma teklifi. `RootScreen` her açılışta/öne
/// gelişte, iki provider da yüklendikten SONRA gösterir: "Zibo'yu açma"
/// serisi risk altındaysa ([appStreakAtRisk]) ve/veya dünü işaretlenmemiş
/// hedefler varsa ([atRiskGoals]). TEK bir Streak Freeze dünü HER YERDE
/// kurtarır — iki ayrı pencere/iki ayrı ödeme yok.
///
/// Onaylı mockup: https://claude.ai/artifact/1keevubiqgQexouMtYb5tZ (bkz.
/// docs/theme_new.md). Gün şeridinde dün buz renginde kesikli; Freeze
/// kullanılınca aynı pencere "Dün donduruldu!" onayına döner ve dün mavi ❄️
/// olur — ayrı bir bilgi penceresi açılmaz.
///
/// Ana buton sırasıyla ilk mevcut kaynağı sunar: (1) Pro/Pro+ aylık ücretsiz
/// hak, (2) Mağaza stoğu, (3) anında `CoinEconomy.streakFreezeInstantRepair`
/// ZC. Kullanılırsa `true`, "Vazgeç" seçilirse `false` döner; hedeflerin
/// dondurulması/sıfırlanması `RootScreen`'de `GoalsProvider.
/// resolveYesterdayFreeze` ile yapılır.
class StreakFreezeOfferDialog extends StatefulWidget {
  const StreakFreezeOfferDialog({
    super.key,
    this.appStreakAtRisk = true,
    this.atRiskGoals = const [],
  });

  final bool appStreakAtRisk;
  final List<Goal> atRiskGoals;

  @override
  State<StreakFreezeOfferDialog> createState() => _StreakFreezeOfferDialogState();
}

class _StreakFreezeOfferDialogState extends State<StreakFreezeOfferDialog> {
  late final int _streakBefore;
  late final DateTime _today;
  StreakFreezeSource? _usedSource;

  bool get _done => _usedSource != null;
  bool get _hasGoals => widget.atRiskGoals.isNotEmpty;
  DateTime get _yesterday => _today.subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _streakBefore = context.read<AppStreakProvider>().currentStreak;
    _today = context.read<GoalsProvider>().today;
  }

  bool _consume(AppStreakProvider streak, StreakFreezeSource source) => widget.appStreakAtRisk
      ? streak.repairMissedDayWithFreeze(source: source)
      : streak.consumeFreezeForGoals(source: source);

  void _accept(StreakFreezeSource source) {
    final streak = context.read<AppStreakProvider>();
    if (source == StreakFreezeSource.coins) {
      final coins = context.read<CoinProvider>();
      if (coins.balance < CoinEconomy.streakFreezeInstantRepair || !coins.spendStreakFreeze()) {
        showInsufficientCoinsWarning(context);
        return;
      }
    }
    if (!_consume(streak, source)) return;
    setState(() => _usedSource = source);
  }

  /// Dünden önceki gün ([daysBefore] = 1 → evvelsi gün) korunmuş mu?
  bool _coveredBefore(int daysBefore) {
    if (widget.appStreakAtRisk) return _streakBefore >= daysBefore;
    final date = _yesterday.subtract(Duration(days: daysBefore));
    return widget.atRiskGoals.any((g) => g.isCovered(date));
  }

  String _weekday(DateTime date, String localeName) {
    try {
      return DateFormat.E(localeName).format(date);
    } catch (_) {
      return MaterialLocalizations.of(context).narrowWeekdays[date.weekday % 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final streak = context.watch<AppStreakProvider>();
    final coins = context.watch<CoinProvider>();

    final source =
        _usedSource ??
        (streak.remainingFreeStreakFreezes > 0
            ? StreakFreezeSource.freeQuota
            : streak.ownedStreakFreezes > 0
            ? StreakFreezeSource.owned
            : StreakFreezeSource.coins);

    final title = _done ? l10n.streakFreezeDoneTitle : l10n.streakFreezeOfferTitle;
    final pill = widget.appStreakAtRisk
        ? l10n.streakFreezePillStreak(_done ? _streakBefore + 1 : _streakBefore)
        : _done
        ? l10n.streakFreezePillGoalsSaved
        : l10n.streakFreezePillGoals(widget.atRiskGoals.length);
    final body = switch ((widget.appStreakAtRisk, _hasGoals, _done)) {
      (true, false, false) => l10n.streakFreezeBodyStreak,
      (true, true, false) => l10n.streakFreezeBodyBoth,
      (false, _, false) => l10n.streakFreezeBodyGoals,
      (true, false, true) => l10n.streakFreezeDoneBodyStreak(_streakBefore + 1),
      (true, true, true) => l10n.streakFreezeDoneBodyBoth,
      (false, _, true) => l10n.streakFreezeDoneBodyGoals,
    };
    final resource = switch (source) {
      StreakFreezeSource.freeQuota => l10n.streakFreezeResourceFree(
        streak.remainingFreeStreakFreezes,
        streak.freeStreakFreezeQuota,
      ),
      StreakFreezeSource.owned => l10n.streakFreezeResourceOwned(streak.ownedStreakFreezes),
      StreakFreezeSource.coins => l10n.streakFreezeResourceCoins(coins.balance),
    };
    final declineHint = !widget.appStreakAtRisk
        ? l10n.streakFreezeDeclineHintGoals
        : _hasGoals
        ? l10n.streakFreezeDeclineHintBoth
        : l10n.streakFreezeDeclineHintStreak;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(18, 74, 18, 10),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        shadowOffset: const Offset(5, 5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 800)],
              fontSize: 22,
              height: 1.15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: stickerDecoration(
              fill: colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
              borderWidth: 2.5,
              shadowOffset: const Offset(2, 2),
            ),
            child: Text(
              pill,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontVariations: const [FontVariation('wght', 800)],
                fontSize: 14,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var k = 3; k >= 1; k--)
                _DayColumn(
                  label: _weekday(_yesterday.subtract(Duration(days: k)), l10n.localeName),
                  state: _coveredBefore(k) ? _DayState.done : _DayState.empty,
                ),
              _DayColumn(
                key: const Key('streakFreezeYesterdayDot'),
                label: l10n.streakFreezeDayYesterday,
                state: _done ? _DayState.frozen : _DayState.missed,
                highlighted: true,
              ),
              _DayColumn(label: l10n.streakFreezeDayToday, state: _DayState.today),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.4,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_hasGoals) ...[
            const SizedBox(height: 12),
            _GoalsBox(
              header: l10n.streakFreezeGoalsHeader,
              goals: widget.atRiskGoals,
              today: _today,
              frozen: _done,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: _icePale,
              border: Border.all(color: kStickerOutline, width: 2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              resource,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _iceInk),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: stickerButtonShadow(
              radius: 14,
              child: FilledButton(
                key: Key(switch ((_done, source)) {
                  (true, _) => 'streakFreezeDoneButton',
                  (false, StreakFreezeSource.freeQuota) => 'streakFreezeUseFreeButton',
                  (false, StreakFreezeSource.owned) => 'streakFreezeUseOwnedButton',
                  (false, StreakFreezeSource.coins) => 'streakFreezeUseCoinsButton',
                }),
                style: stickerFilledButtonStyle(context, radius: 14, fontSize: 16).copyWith(
                  side: const WidgetStatePropertyAll(
                    BorderSide(color: kStickerOutline, width: 3),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  ),
                ),
                onPressed: _done ? () => Navigator.of(context).pop(true) : () => _accept(source),
                child: Text(
                  _done
                      ? l10n.streakFreezeDoneButton
                      : switch (source) {
                          StreakFreezeSource.freeQuota => l10n.streakFreezeUseFreeLabel,
                          StreakFreezeSource.owned => l10n.streakFreezeUseOwnedLabel,
                          StreakFreezeSource.coins => l10n.streakFreezeOfferCoinButton(
                            CoinEconomy.streakFreezeInstantRepair,
                          ),
                        },
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (!_done) ...[
            const SizedBox(height: 4),
            TextButton(
              key: const Key('streakFreezeDeclineButton'),
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
              child: Column(
                children: [
                  Text(
                    l10n.streakFreezeOfferDeclineButton,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    declineHint,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 66, right: 5, bottom: 5),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                card,
                Positioned(
                  top: -66,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedRotation(
                        turns: _done ? -0.022 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedScale(
                          scale: _done ? 1.06 : 1,
                          duration: const Duration(milliseconds: 300),
                          child: Image.asset(streakFreezeIconAsset, width: 128),
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
  }
}

enum _DayState { done, missed, frozen, today, empty }

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    super.key,
    required this.label,
    required this.state,
    this.highlighted = false,
  });

  final String label;
  final _DayState state;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = highlighted
        ? (isDark ? _iceBlue : _iceInk)
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              child: child,
            ),
            child: KeyedSubtree(key: ValueKey(state), child: _dot(colorScheme)),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, color: labelColor),
          ),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme colorScheme) {
    const size = 36.0;
    const textStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 15);
    switch (state) {
      case _DayState.missed:
        return CustomPaint(
          painter: const _DashedCirclePainter(fill: _icePale, color: _iceInk),
          child: const SizedBox(
            width: size,
            height: size,
            child: Center(child: Text('?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _iceInk))),
          ),
        );
      case _DayState.frozen:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _iceBlue,
            shape: BoxShape.circle,
            border: Border.all(color: kStickerOutline, width: 2.5),
          ),
          child: const Icon(Icons.ac_unit_rounded, size: 18, color: _iceInk),
        );
      case _DayState.done:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: kStickerOutline, width: 2.5),
          ),
          child: Icon(Icons.check_rounded, size: 18, color: colorScheme.onPrimary),
        );
      case _DayState.today:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 2.5),
            boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(1.5, 1.5))],
          ),
          child: Text('✦', style: textStyle.copyWith(color: colorScheme.primary)),
        );
      case _DayState.empty:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant, width: 2.5),
          ),
        );
    }
  }
}

class _GoalsBox extends StatelessWidget {
  const _GoalsBox({
    required this.header,
    required this.goals,
    required this.today,
    required this.frozen,
  });

  final String header;
  final List<Goal> goals;
  final DateTime today;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final yesterday = today.subtract(const Duration(days: 1));
    return CustomPaint(
      painter: _DashedRectPainter(fill: colorScheme.surfaceContainerLow),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (final goal in goals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (var i = 0; i < Goal.daysPerCycle; i++)
                      _miniDot(colorScheme, goal, i, yesterday),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniDot(ColorScheme colorScheme, Goal goal, int dayIndex, DateTime yesterday) {
    final date = goal.dateForDay(dayIndex);
    final isYesterday = date == yesterday;
    final Color? fill;
    if (goal.completedDates.contains(date)) {
      fill = colorScheme.primary;
    } else if (goal.frozenDates.contains(date) || (isYesterday && frozen)) {
      fill = _iceBlue;
    } else if (isYesterday) {
      fill = _icePale;
    } else {
      fill = null;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: kStickerOutline, width: 1.5),
        ),
      ),
    );
  }
}

/// Kaçırılan günün kesikli buz çemberi.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.fill, required this.color});

  final Color fill;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const dashes = 12;
    const sweep = 2 * 3.141592653589793 / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.color != color;
}

/// Hedef kutusunun kesikli sticker kenarı.
class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.fill});

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    ).deflate(stroke / 2);
    canvas.drawRRect(rrect, Paint()..color = fill);
    final outline = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        dashed.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + 5;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = kStickerOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) => oldDelegate.fill != fill;
}
