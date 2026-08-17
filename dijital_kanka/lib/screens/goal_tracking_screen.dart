import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/goal_quotes.dart';
import '../l10n/app_localizations.dart';
import '../providers/costume_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../widgets/goal_card.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/zibo_animated_image.dart';

/// Hedef Takibi sayfası. [isActive], bu sekmenin şu anda görünen sekme olup
/// olmadığını belirtir — RootScreen'deki IndexedStack TÜM sekmeleri baştan
/// monte ettiği için, otomatik söz döndürme zamanlayıcısının yalnızca bu
/// sekme gerçekten görünürken çalışmasını sağlamak için gerekli (bkz.
/// MoneyScreen'deki aynı desen).
class GoalTrackingScreen extends StatefulWidget {
  const GoalTrackingScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  State<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

class _GoalTrackingScreenState extends State<GoalTrackingScreen>
    with WidgetsBindingObserver {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ekran ilk kurulduğunda (uygulama soğuk başlangıçta) bugüne göre
    // kontrol et.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcileForToday());
    if (widget.isActive) _startQuoteTimer();
  }

  @override
  void didUpdateWidget(covariant GoalTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startQuoteTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopQuoteTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plandan öne geldiğinde (ör. bir gece boyunca kapalı
    // kaldıktan sonra) günün değişip değişmediğini gerçek cihaz tarihine
    // göre yeniden kontrol et.
    if (state == AppLifecycleState.resumed) _reconcileForToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopQuoteTimer();
    super.dispose();
  }

  void _startQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showNewQuote(),
    );
  }

  void _stopQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = null;
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = goalQuotesForLocale(Localizations.localeOf(context));
      if (quotes.length <= 1) {
        _quoteIndex = 0;
        return;
      }
      int next;
      do {
        next = _random.nextInt(quotes.length);
      } while (next == _quoteIndex);
      _quoteIndex = next;
    });
  }

  void _reconcileForToday() {
    if (!mounted) return;
    final resetNames = context.read<GoalsProvider>().reconcileForToday();
    if (resetNames.isEmpty || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.goalStreakReset(resetNames.join(', ')))),
      );
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addGoalDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.addGoalDialogHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addGoal(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalsProvider = context.watch<GoalsProvider>();
    final goals = goalsProvider.goals;
    final today = goalsProvider.today;
    final locale = Localizations.localeOf(context);
    final quotes = goalQuotesForLocale(locale);
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final quote = applyAddressTerm(
      quotes[_quoteIndex % quotes.length],
      addressTerm,
      locale,
    );

    // Mağaza > Kostümler'den giyilen bir kostüm varsa Zibo'nun görseli onunla
    // değişir; yoksa (veya kostüm listeden kaldırılmışsa) varsayılan görsele
    // düşülür (bkz. HomeScreen'deki aynı desen).
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final equippedImageAsset = equippedId == null
        ? defaultZiboImage
        : (findCostumeById(equippedId)?.imageAsset ?? defaultZiboImage);
    final poseStep = context.watch<ZiboPoseProvider>().poseStep;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Column(
          children: [
            ZiboAnimatedImage(
              imageKey: const Key('ziboGoalTrackingImage'),
              costumeId: equippedId,
              poseStep: poseStep,
              fallbackImage: equippedImageAsset,
              height: 200,
              semanticLabel: l10n.ziboImagePlaceholder,
            ),
            const SizedBox(height: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                SpeechBubble(message: quote),
                Positioned(
                  top: -6,
                  right: -6,
                  child: ShareZiboButton(message: quote),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final goal in goals) ...[
          GoalCard(goal: goal, today: today),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => _showAddGoalDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.addGoalButton),
        ),
      ],
    );
  }
}
