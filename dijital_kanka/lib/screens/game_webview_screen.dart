import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/coin_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/sticker_style.dart';

/// Oyun Salonu'ndaki bir HTML oyununu (APK içindeki `assets/games/<id>/`)
/// WebView'da açan GENEL ekran — bkz. `docs/game_zibo.md` "Mimari karar —
/// HİBRİT" ve "Köprü (bridge) taslağı".
///
/// Oyun ↔ Flutter konuşması `ZiboBridge` JavaScript kanalı üzerinden JSON:
/// `ready` → [_sendInit]; `start` → hak düşülür; `finish` → puan tur
/// tavanına göre DOĞRULANIR; `requestAd` → ödüllü reklam; `exit` → kapanır.
/// Sonuç ekranı oyunun içinde (kullanıcı kararı 2026-09-29).
///
/// **Faz 1 (teknik deneme):** haklar ve puanlar henüz bellekte tutuluyor —
/// kalıcı cüzdan (`GamePointsProvider`) ve uzaktan ayarlar Faz 2'de gelecek.
class GameWebViewScreen extends StatefulWidget {
  const GameWebViewScreen({
    super.key,
    required this.gameId,
    required this.title,
    required this.config,
  });

  /// `assets/games/<gameId>/index.html`.
  final String gameId;
  final String title;

  /// Oyuna `ziboInit` ile giden oyun-özel rakamlar (puan oranı, `cap` vb.).
  /// `cap` Flutter tarafındaki doğrulamada da kullanılır.
  final Map<String, Object> config;

  @override
  State<GameWebViewScreen> createState() => _GameWebViewScreenState();
}

class _GameWebViewScreenState extends State<GameWebViewScreen> {
  late final WebViewController _controller;
  final Stopwatch _openTimer = Stopwatch()..start();

  // Faz 1: bellekte. Faz 2'de GamePointsProvider'a taşınacak.
  int _playsLeft = 3;
  int _adPlaysUsed = 0;
  int _best = 0;
  int _sessionPoints = 0;
  bool _roundOpen = false;

  static const _maxAdPlays = 2;

  int get _cap => (widget.config['cap'] as int?) ?? 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFE9B8))
      ..addJavaScriptChannel('ZiboBridge', onMessageReceived: _onMessage)
      ..setOnConsoleMessage((m) => debugPrint('ZIBO_GAME console: ${m.message}'))
      ..loadFlutterAsset('assets/games/${widget.gameId}/index.html');
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
    switch (msg['type']) {
      case 'ready':
        debugPrint('ZIBO_GAME ${widget.gameId} ready in ${_openTimer.elapsedMilliseconds} ms');
        await _sendInit();
      case 'start':
        final ok = _playsLeft > 0;
        if (ok) {
          _playsLeft--;
          _roundOpen = true;
        }
        await _call('ziboStartResult', {'ok': ok, 'playsLeft': _playsLeft});
      case 'finish':
        // Tura tek finish; puan asla tur tavanını aşamaz.
        final claimed = (msg['points'] as num?)?.toInt() ?? 0;
        final accepted = _roundOpen;
        final points = accepted ? claimed.clamp(0, _cap) : 0;
        _roundOpen = false;
        _sessionPoints += points;
        // Rekor: oyunun 'score' alanı (büyük olan iyi); yoksa tutulmaz.
        final score = (msg['score'] as num?)?.toInt();
        if (score != null && score > _best) _best = score;
        debugPrint('ZIBO_GAME finish ${widget.gameId}: claimed=$claimed accepted=$points session=$_sessionPoints');
        await _call('ziboFinishResult', {'accepted': accepted, 'points': points});
      case 'requestAd':
        final reason = msg['reason'] as String? ?? '';
        final ok = await _showAd(reason);
        if (ok && reason == 'extraPlay') {
          _adPlaysUsed++;
          _playsLeft++;
        }
        await _call('ziboAdResult', {'ok': ok, 'reason': reason, 'playsLeft': _playsLeft});
      case 'exit':
        if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _showAd(String reason) async {
    if (reason == 'extraPlay' && _adPlaysUsed >= _maxAdPlays) return false;
    return context.read<CoinProvider>().showGameRewardedAd();
  }

  Future<void> _sendInit() {
    final locale = Localizations.localeOf(context).languageCode;
    final tier = _tier;
    return _call('ziboInit', {
      'locale': locale,
      'tier': tier,
      'playsLeft': _playsLeft,
      'best': _best,
      'canAdForPlay': tier == 'free' && _adPlaysUsed < _maxAdPlays,
      ...widget.config,
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

/// Faz 1 deneme oyunu Zibo Kule'nin rakamları (docs/game_zibo.md bölüm 4).
/// Faz 2'de uzaktan ayara (`config/games`) taşınacak.
const Map<String, Object> kuleGameConfig = {'perFloor': 2, 'perfectBonus': 1, 'cap': 250};


/// Zibo Hafıza puanları: seviye başı taban × yıldız çarpanı (docs/game_zibo.md).
const Map<String, Object> hafizaGameConfig = {
  'ptsEasy': 100,
  'ptsMid': 180,
  'ptsHard': 300,
  'mult2': 0.6,
  'mult1': 0.3,
  'cap': 300,
};

/// Zibo 2048 puanları: skor ÷ scoreDiv + en yüksek kostüm bonusu; geri alma sınırı.
const Map<String, Object> game2048Config = {
  'scoreDiv': 20,
  'bonus256': 50,
  'bonus1024': 100,
  'bonus2048': 200,
  'cap': 600,
  'maxUndo': 3,
};

/// Coin Yakala: 1 skor = 1 ★ (kullanıcı kararı 2026-09-27), can biterse 0.
const Map<String, Object> yakalaGameConfig = {'perScore': 1, 'cap': 400};

/// Zibo Tren: coin başına 5 ★ (kullanıcı kararı 2026-09-27).
const Map<String, Object> trenGameConfig = {'perCoin': 5, 'cap': 600};

/// Zibo Zıpla: yalnızca coin puan verir, coin × 5 (kullanıcı kararı 2026-09-27).
const Map<String, Object> ziplaGameConfig = {'perCoin': 5, 'cap': 600};

/// Zibo Tuğla: kırılan tuğla × 1 (kullanıcı kararı 2026-09-27).
const Map<String, Object> tuglaGameConfig = {'perBrick': 1, 'cap': 400};
