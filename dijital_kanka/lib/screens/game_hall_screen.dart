import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/sticker_style.dart';
import 'game_webview_screen.dart';

/// Alt bardaki 2. sekme — Oyun Salonu (bkz. `docs/game_zibo.md`, bölüm 2b
/// "Navigasyon kararı"). Görsel dil onaylı taslakla aynı
/// (`docs/game_prototypes/oyun_salonu.html`): Zibo başlığı + oyun kartları.
///
/// `IndexedStack` tüm sekmeleri uygulama açılır açılmaz kurduğu için bu
/// sayfa HAFİF: yalnızca küçük kart görselleri; WebView yalnızca bir oyuna
/// dokununca [GameWebViewScreen] ile açılır.
///
/// 7 oyunun hepsi oynanabilir; config'i olmayan bir oyun
/// "Yakında". Oyun Puanı bakiyesi ve Takas Gişesi Faz 2-3'te eklenecek.
class GameHallScreen extends StatelessWidget {
  const GameHallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final games = <_GameEntry>[
      _GameEntry('kule', l10n.gameNameKule, l10n.gameDescKule, config: kuleGameConfig),
      _GameEntry('hafiza', l10n.gameNameHafiza, l10n.gameDescHafiza, config: hafizaGameConfig),
      _GameEntry('2048', l10n.gameName2048, l10n.gameDesc2048, config: game2048Config),
      _GameEntry('yakala', l10n.gameNameYakala, l10n.gameDescYakala, config: yakalaGameConfig),
      _GameEntry('tren', l10n.gameNameTren, l10n.gameDescTren, config: trenGameConfig),
      _GameEntry('tugla', l10n.gameNameTugla, l10n.gameDescTugla, config: tuglaGameConfig),
      _GameEntry('zipla', l10n.gameNameZipla, l10n.gameDescZipla, config: ziplaGameConfig),
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
        for (final game in games) ...[
          _GameCard(game: game),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _GameEntry {
  const _GameEntry(this.id, this.name, this.description, {this.config});

  final String id;
  final String name;
  final String description;

  /// `null` = henüz uygulamaya eklenmedi ("Yakında").
  final Map<String, Object>? config;

  bool get playable => config != null;
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final _GameEntry game;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameWebViewScreen(gameId: game.id, title: game.name, config: game.config!),
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
