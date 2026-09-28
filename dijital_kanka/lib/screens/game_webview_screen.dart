import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/coin_provider.dart';
import '../providers/game_points_provider.dart';
import '../providers/games_config_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/game_analytics.dart';
import '../widgets/sticker_style.dart';

/// Oyun Salonu'ndaki bir HTML oyununu (APK içindeki `assets/games/<id>/`)
/// WebView'da açan GENEL ekran — bkz. `docs/game_zibo.md` "Mimari karar —
/// HİBRİT" ve "Köprü (bridge) taslağı".
///
/// Oyun ↔ Flutter konuşması `ZiboBridge` JavaScript kanalı üzerinden JSON:
/// `ready` → [_sendInit]; `start` → hak düşülür; `finish` → puan tur
/// tavanına göre DOĞRULANIP [GamePointsProvider]'a yazılır; `requestAd` →
/// ödüllü reklam; `exit` → kapanır. Sonuç ekranı oyunun içinde (kullanıcı
/// kararı 2026-09-29).
///
/// Rakamlar [GamesConfigProvider]'dan (varsayılanlar + Firestore
/// `config/games`), haklar/puanlar/rekorlar [GamePointsProvider]'dan gelir.
class GameWebViewScreen extends StatefulWidget {
  const GameWebViewScreen({super.key, required this.gameId, required this.title});

  /// `assets/games/<gameId>/index.html`.
  final String gameId;
  final String title;

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  late final WebViewController _controller;
  late final GamePointsProvider _points;
  late final GamesConfigProvider _configProvider;
  final Stopwatch _openTimer = Stopwatch()..start();

  /// Başlatılmış ama henüz `finish` gelmemiş tur var mı (tura tek finish).
  bool _roundOpen = false;

  @override
  void initState() {
    super.initState();
    _points = context.read<GamePointsProvider>();
    _configProvider = context.read<GamesConfigProvider>();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFE9B8))
      ..addJavaScriptChannel('ZiboBridge', onMessageReceived: _onMessage)
      ..setOnConsoleMessage((m) => debugPrint('ZIBO_GAME console: ${m.message}'))
      ..loadFlutterAsset('assets/games/${widget.gameId}/index.html');
    GameAnalytics.log('game_open', {'game': widget.gameId});
  }

  String get _tier {
    final sub = context.read<SubscriptionProvider>();
    if (sub.isProPlus) return 'plus';
    if (sub.isPro) return 'pro';
    return 'free';
  }

  Future<void> _call(String fn, Map<String, Object?> payload) {
    return _controller.runJavaScript('window.$fn(${jsonEncode(payload)});');
  }

  Future<void> _onMessage(JavaScriptMessage message) async {
    if (!mounted) return;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(message.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final config = _configProvider.config;
    final game = widget.gameId;
    switch (msg['type']) {
      case 'ready':
        await _points.ready;
        if (!mounted) return;
        debugPrint('ZIBO_GAME $game ready in ${_openTimer.elapsedMilliseconds} ms');
        await _sendInit();
      case 'start':
        final tier = _tier;
        final ok = _points.consumePlay(game, tier, config);
        GameAnalytics.log(ok ? 'game_start' : 'game_no_plays', {'game': game, 'tier': tier});
        if (ok) _roundOpen = true;
        await _call('ziboStartResult', _playState(ok: ok));
      case 'finish':
        final claimed = (msg['points'] as num?)?.toInt() ?? 0;
        final accepted = _roundOpen;
        _roundOpen = false;
        final points = accepted
            ? _points.recordFinish(
                game,
                claimedPoints: claimed,
                score: (msg['score'] as num?)?.toInt(),
                config: config,
              )
            : 0;
        debugPrint('ZIBO_GAME finish $game: claimed=$claimed accepted=$points balance=${_points.points}');
        if (accepted) {
          GameAnalytics.log('game_finish', {
            'game': game,
            'tier': _tier,
            'points': points,
            'claimed': claimed,
            'score': (msg['score'] as num?)?.toInt() ?? 0,
          });
        }
        await _call('ziboFinishResult', {..._playState(), 'accepted': accepted, 'points': points, 'balance': _points.points});
      case 'requestAd':
        final reason = msg['reason'] as String? ?? '';
        final tier = _tier;
        var ok = false;
        if (reason != 'extraPlay' || _points.canAdForPlay(game, tier, config)) {
          ok = await context.read<CoinProvider>().showGameRewardedAd();
          if (ok && reason == 'extraPlay') ok = _points.grantAdPlay(game, tier, config);
        }
        if (!mounted) return;
        GameAnalytics.log('game_ad', {'game': game, 'reason': reason, 'ok': ok ? 1 : 0});
        await _call('ziboAdResult', _playState(ok: ok, reason: reason));
      case 'exit':
        if (mounted) Navigator.of(context).pop();
    }
  }

  /// Oyuna her cevapta giden güncel hak durumu.
  Map<String, Object?> _playState({bool? ok, String? reason}) {
    final config = _configProvider.config;
    final tier = _tier;
    return {
      'ok': ?ok,
      'reason': ?reason,
      'playsLeft': _points.playsLeft(widget.gameId, tier, config),
      'canAdForPlay': _points.canAdForPlay(widget.gameId, tier, config),
    };
  }

  Future<void> _sendInit() {
    final config = _configProvider.config;
    final game = widget.gameId;
    final tier = _tier;
    return _call('ziboInit', {
      'locale': Localizations.localeOf(context).languageCode,
      'tier': tier,
      'playsLeft': _points.playsLeft(game, tier, config),
      'canAdForPlay': _points.canAdForPlay(game, tier, config),
      'best': _points.best(game),
      ...config.gameConfig(game),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: plainStickerAppBar(context, title: widget.title),
      backgroundColor: const Color(0xFFFFE9B8),
      body: SafeArea(top: false, child: WebViewWidget(controller: _controller)),
    );
  }
}
