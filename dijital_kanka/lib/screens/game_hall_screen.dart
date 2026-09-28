import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/game_points_provider.dart';
import '../providers/games_config_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/sticker_style.dart';
import 'game_exchange_screen.dart';
import 'game_webview_screen.dart';

/// Alt bardaki 2. sekme — Oyun Salonu (bkz. `docs/game_zibo.md`, bölüm 2b
/// "Navigasyon kararı"). Görsel dil onaylı taslakla aynı
/// (`docs/game_prototypes/oyun_salonu.html`): Zibo başlığı + oyun kartları.
///
/// `IndexedStack` tüm sekmeleri uygulama açılır açılmaz kurduğu için bu
/// sayfa HAFİF: yalnızca küçük kart görselleri; WebView yalnızca bir oyuna
/// dokununca [GameWebViewScreen] ile açılır.
///
/// Hangi oyunun oynanabilir olduğu [GamesConfigProvider]'dan gelir:
/// Firestore `config/games`'te `"enabled": false` olan oyun "Yakında"
/// görünür (acil kapatma). Üstteki kutu ★ bakiyesi + haftalık takas ilerlemesi
/// ve Takas Gişesi girişi (Faz 3).
class GameHallScreen extends StatelessWidget {
  const GameHallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final config = context.watch<GamesConfigProvider>().config;
    final games = <_GameEntry>[
      _GameEntry('kule', l10n.gameNameKule, l10n.gameDescKule, playable: config.isEnabled('kule')),
      _GameEntry('hafiza', l10n.gameNameHafiza, l10n.gameDescHafiza, playable: config.isEnabled('hafiza')),
      _GameEntry('2048', l10n.gameName2048, l10n.gameDesc2048, playable: config.isEnabled('2048')),
      _GameEntry('yakala', l10n.gameNameYakala, l10n.gameDescYakala, playable: config.isEnabled('yakala')),
      _GameEntry('tren', l10n.gameNameTren, l10n.gameDescTren, playable: config.isEnabled('tren')),
      _GameEntry('tugla', l10n.gameNameTugla, l10n.gameDescTugla, playable: config.isEnabled('tugla')),
      _GameEntry('zipla', l10n.gameNameZipla, l10n.gameDescZipla, playable: config.isEnabled('zipla')),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          children: [
            Image.asset('assets/images/zibo_df_pose4.webp', height: 88),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tabGameHall,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 800)],
                      fontSize: 28,
                      height: 1.05,
                      color: colorScheme.primary,
                      shadows: const [Shadow(color: kStickerOutline, offset: Offset(2, 2))],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameHallSubtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _PointsBox(),
        const SizedBox(height: 16),
        for (final game in games) ...[
          _GameCard(game: game),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _GameEntry {
  const _GameEntry(this.id, this.name, this.description, {required this.playable});

  final String id;
  final String name;
  final String description;

  /// `false` = uzaktan kapatılmış ("Yakında").
  final bool playable;
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final _GameEntry game;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameWebViewScreen(gameId: game.id, title: game.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: game.playable,
      label: game.name,
      excludeSemantics: true,
      child: Opacity(
        opacity: game.playable ? 1 : 0.62,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: game.playable ? () => _open(context) : null,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              decoration: stickerDecoration(
                fill: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: kStickerOutline, width: 2.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/game_${game.id}_thumb.webp',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontVariations: const [FontVariation('wght', 800)],
                            fontSize: 18,
                            height: 1.1,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.description,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: game.playable ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                      border: Border.all(color: kStickerOutline, width: 2.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      game.playable ? l10n.gameHallPlay : l10n.gameHallComingSoon,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 800)],
                        fontSize: 14,
                        color: game.playable ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ★ bakiyesi, bu haftanın takas ilerlemesi ve Takas Gişesi düğmesi.
class _PointsBox extends StatelessWidget {
  const _PointsBox();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final points = context.watch<GamePointsProvider>();
    final config = context.watch<GamesConfigProvider>().config;
    final sub = context.watch<SubscriptionProvider>();
    final tier = sub.isProPlus ? 'plus' : (sub.isPro ? 'pro' : 'free');
    final cap = points.weeklyCap(tier, config);
    final done = points.weekExchanged;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FD3FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: kStickerOutline, width: 2.5),
                ),
                child: const Text('★', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0E3A5C))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${points.points}',
                      key: const Key('gameHallPoints'),
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 800)],
                        fontSize: 28,
                        height: 1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      l10n.gameHallPointsLabel.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: 0.6, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              stickerButtonShadow(
                radius: 12,
                child: FilledButton(
                  key: const Key('gameHallExchangeButton'),
                  style: stickerFilledButtonStyle(context, radius: 12, fontSize: 14).copyWith(
                    backgroundColor: const WidgetStatePropertyAll(Color(0xFF8FD3FF)),
                    foregroundColor: const WidgetStatePropertyAll(Color(0xFF14110C)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const GameExchangeScreen()),
                  ),
                  child: Text(l10n.exchangeTitle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: cap == 0 ? 0 : done / cap,
              minHeight: 8,
              color: const Color(0xFF8FD3FF),
              backgroundColor: const Color(0xFFF3E4C0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.gameHallWeekProgress(done, cap),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
