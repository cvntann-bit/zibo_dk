import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costumes.dart';
import '../data/games_config.dart';
import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/game_points_provider.dart';
import '../providers/games_config_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/game_analytics.dart';
import '../utils/tab_navigation.dart';
import '../widgets/sticker_style.dart';
import 'paywall_screen.dart';

const _ice = Color(0xFF8FD3FF);
const _icePale = Color(0xFFDDF2FF);
const _iceInk = Color(0xFF0E3A5C);

/// Takas Gişesi — Oyun Puanı ★ → Zibo Coin (bkz. `docs/game_zibo.md`
/// bölüm 3, Faz 3). Haftalık, giderek pahalılaşan kur basamakları
/// ([GamesConfig.exchangeLadder]); üyelik haftalık tavanı yükseltir.
/// Görsel dil onaylı taslakla aynı (`docs/game_prototypes/oyun_salonu.html`).
class GameExchangeScreen extends StatefulWidget {
  const GameExchangeScreen({super.key});

  @override
  State<GameExchangeScreen> createState() => _GameExchangeScreenState();
}

class _GameExchangeScreenState extends State<GameExchangeScreen> {
  int _amount = 0;
  bool _capLogged = false;

  String _tierOf(SubscriptionProvider sub) => sub.isProPlus ? 'plus' : (sub.isPro ? 'pro' : 'free');

  void _exchange(GamePointsProvider points, String tier, GamesConfig config) {
    final l10n = AppLocalizations.of(context)!;
    final zc = _amount;
    final cost = points.exchange(zc, tier, config);
    if (cost == null) return;
    context.read<CoinProvider>().earnGameExchange(zc);
    GameAnalytics.log('points_exchanged', {'zc': zc, 'cost': cost, 'week_total': points.weekExchanged, 'tier': tier});
    setState(() => _amount = 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.exchangeDone(cost, zc))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final points = context.watch<GamePointsProvider>();
    final config = context.watch<GamesConfigProvider>().config;
    final tier = _tierOf(context.watch<SubscriptionProvider>());
    final coins = context.watch<CoinProvider>();
    final costumeProvider = context.watch<CostumeProvider>();

    final maxN = points.maxAffordable(tier, config);
    final capped = points.weeklyRoom(tier, config) == 0;
    if (capped && !_capLogged) {
      _capLogged = true;
      GameAnalytics.log('exchange_cap_hit', {'tier': tier});
    }
    if (_amount > maxN) _amount = maxN;
    if (_amount == 0 && maxN > 0) _amount = maxN < 5 ? maxN : 5;
    final cost = points.costFor(_amount, tier, config) ?? 0;
    final days = points.daysUntilWeekReset;

    // Bakiyenin yetmediği ilk (en ucuz, sahip olunmayan) kostüm.
    final candidates = costumes
        .where((c) => !costumeProvider.isOwned(c.id) && c.price > coins.balance && c.price < 5000)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    final Costume? target = candidates.isEmpty ? null : candidates.first;

    TextStyle title(double size) => TextStyle(
      fontFamily: 'Baloo2',
      fontVariations: const [FontVariation('wght', 800)],
      fontSize: size,
      height: 1.1,
      color: colorScheme.onSurface,
    );
    final muted = TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: plainStickerAppBar(context, title: l10n.exchangeTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Image.asset('assets/images/zibo_df_pose3.webp', height: 72),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.exchangeResetIn(days), style: muted)),
            ],
          ),
          const SizedBox(height: 12),
          _Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _StarBadge(size: 32),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${points.points}', style: title(30)),
                        Text(l10n.exchangeBalanceLabel.toUpperCase(), style: muted.copyWith(fontSize: 10.5, letterSpacing: 0.6)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.exchangeLadderLabel.toUpperCase(), style: muted.copyWith(fontSize: 10.5, letterSpacing: 0.6)),
                const SizedBox(height: 6),
                ..._ladder(points, tier, config, l10n, colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (capped)
            _Box(
              fill: _icePale,
              child: Column(
                children: [
                  Text(l10n.exchangeCapTitle, textAlign: TextAlign.center, style: title(17).copyWith(color: _iceInk)),
                  const SizedBox(height: 4),
                  Text(l10n.exchangeCapBody(days), textAlign: TextAlign.center, style: muted.copyWith(color: _iceInk)),
                ],
              ),
            )
          else
            _Box(
              child: Column(
                children: [
                  Row(
                    children: [
                      _SquareButton(
                        key: const Key('exchangeMinus'),
                        label: '−',
                        onTap: _amount > 1 ? () => setState(() => _amount--) : null,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/zibo_coin.webp', height: 26),
                                const SizedBox(width: 6),
                                Text('$_amount', key: const Key('exchangeAmount'), style: title(28)),
                              ],
                            ),
                            Text(l10n.exchangeCost(cost), style: muted),
                          ],
                        ),
                      ),
                      _SquareButton(
                        key: const Key('exchangePlus'),
                        label: '+',
                        onTap: _amount < maxN ? () => setState(() => _amount++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        key: const Key('exchangeMax'),
                        onPressed: maxN > 0 ? () => setState(() => _amount = maxN) : null,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kStickerOutline, width: 2.5),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(l10n.exchangeMaxButton),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          maxN < 1 && points.currentRate(tier, config) != null
                              ? l10n.exchangeCurrentRate(points.currentRate(tier, config)!)
                              : l10n.exchangeMaxHint(maxN),
                          textAlign: TextAlign.end,
                          style: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: stickerButtonShadow(
                      radius: 14,
                      child: FilledButton(
                        key: const Key('exchangeButton'),
                        style: stickerFilledButtonStyle(context, radius: 14, fontSize: 16),
                        onPressed: _amount >= 1 ? () => _exchange(points, tier, config) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(_amount >= 1 ? l10n.exchangeButton(cost, _amount) : l10n.exchangeNotEnough),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (target != null) ...[
            const SizedBox(height: 14),
            _Box(
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(target.imageAsset, height: 64),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.exchangeUpsellTitle(target.localizedName(l10n), target.price - coins.balance),
                              style: title(15),
                            ),
                            const SizedBox(height: 2),
                            Text(l10n.exchangeUpsellBody(((target.price - coins.balance) / 55).ceil().clamp(1, 999)), style: muted),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: stickerButtonShadow(
                      radius: 14,
                      child: FilledButton(
                        key: const Key('exchangeUpsellButton'),
                        style: stickerFilledButtonStyle(context, radius: 14, fontSize: 15),
                        onPressed: () {
                          GameAnalytics.log('game_upsell_tap', {'costume': target.id, 'missing': target.price - coins.balance});
                          Navigator.of(context).popUntil((r) => r.isFirst);
                          storeTabRequest.value++;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(l10n.exchangeUpsellButton),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (tier == 'free') ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                GameAnalytics.log('game_pro_tap');
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
                );
              },
              child: Text(
                l10n.exchangeProLine(points.weeklyCap('pro', config)),
                style: const TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _ladder(GamePointsProvider points, String tier, GamesConfig config, AppLocalizations l10n, ColorScheme colorScheme) {
    final rows = <Widget>[];
    var base = 0;
    final ex = points.weekExchanged;
    for (var i = 0; i < config.exchangeLadder.length; i++) {
      final step = config.exchangeLadder[i];
      final locked = !step.openFor(tier);
      final got = (ex - base).clamp(0, step.zc);
      final done = !locked && got >= step.zc;
      final current = !locked && !done && ex >= base;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _StepRow(
            index: i + 1,
            title: i == 0 ? l10n.exchangeStepFirst(step.zc) : l10n.exchangeStep(step.zc),
            subtitle: locked ? l10n.exchangeStepLocked : l10n.exchangeStepProgress(got, step.zc),
            rate: l10n.exchangeRate(step.rate),
            tag: step.minTier == 'pro' ? 'Pro' : (step.minTier == 'plus' ? 'Pro+' : null),
            locked: locked,
            done: done,
            current: current,
            progress: step.zc == 0 ? 0 : got / step.zc,
          ),
        ),
      );
      base += step.zc;
    }
    return rows;
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child, this.fill});

  final Widget child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: stickerDecoration(
        fill: fill ?? Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _ice,
        shape: BoxShape.circle,
        border: Border.all(color: kStickerOutline, width: 2.5),
      ),
      child: Text('★', style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w800, color: _iceInk)),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kStickerOutline, width: 2.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.rate,
    required this.tag,
    required this.locked,
    required this.done,
    required this.current,
    required this.progress,
  });

  final int index;
  final String title;
  final String subtitle;
  final String rate;
  final String? tag;
  final bool locked;
  final bool done;
  final bool current;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = current
        ? _icePale
        : done
        ? const Color(0xFFFFF1CC)
        : colorScheme.surfaceContainerLowest;
    final ink = current || done ? const Color(0xFF2A2115) : colorScheme.onSurface;
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kStickerOutline, width: 2.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? colorScheme.primary : (current ? _ice : const Color(0xFFF3E4C0)),
                border: Border.all(color: kStickerOutline, width: 2.5),
              ),
              child: Text(
                done ? '✓' : (locked ? '🔒' : '$index'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2A2115)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: kStickerOutline, width: 2),
                          ),
                          child: Text(tag!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF14110C))),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'Baloo2', fontVariations: const [FontVariation('wght', 800)], fontSize: 14, color: ink),
                      ),
                    ],
                  ),
                  Text(subtitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: ink.withValues(alpha: 0.7))),
                  if (current) ...[
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        color: _ice,
                        backgroundColor: const Color(0xFFF3E4C0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              rate,
              style: TextStyle(fontFamily: 'Baloo2', fontVariations: const [FontVariation('wght', 800)], fontSize: 13, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
