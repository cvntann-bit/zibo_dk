import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_theme_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/instagram_follow_provider.dart';
import '../utils/badge_special_reward.dart';
import '../utils/info_dialog.dart';
import 'sticker_style.dart';

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Instagram Takip Kartı ve Ödülü. Profil'de, ödül henüz alınmamışsa
/// gösterilen teşvik kartı — TEK buton ("Instagram'ı Aç") @zibo.app'i açar;
/// kullanıcı uygulamadan gerçekten ÇIKIP (`paused`/`hidden`) geri
/// döndüğünde (`resumed`) ödül otomatik verilir: 100 ZC + rastgele bir
/// standart tema + rastgele düşük fiyatlı bir kostüm. Gerçek takip
/// doğrulaması teknik olarak mümkün değil; tekrar almayı
/// `InstagramFollowProvider.markClaimed()`'in kalıcı bayrağı engelliyor.
/// Yalnızca `inactive` (bildirim paneli vb.) çıkış sayılmaz.
///
/// Ödül alındıktan sonra kart TAMAMEN GİZLENİR (`SizedBox.shrink()`).
class InstagramFollowCard extends StatefulWidget {
  const InstagramFollowCard({super.key, this.launcher = _launchExternally});

  /// Testte sahtesi enjekte edilir; `false`/istisna → "açılamadı".
  final Future<bool> Function(Uri uri) launcher;

  @override
  State<InstagramFollowCard> createState() => _InstagramFollowCardState();
}

class _InstagramFollowCardState extends State<InstagramFollowCard>
    with WidgetsBindingObserver {
  bool _isClaiming = false;
  bool _awaitingReturn = false;
  bool _leftApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_awaitingReturn) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _leftApp = true;
    } else if (state == AppLifecycleState.resumed && _leftApp) {
      _awaitingReturn = false;
      _leftApp = false;
      unawaited(_claim());
    }
  }

  Future<void> _openInstagram() async {
    // Uygulama `launchUrl`'ün Future'ı dönmeden ÖNCE arka plana geçebiliyor,
    // bu yüzden bekleme bayrağı çağrıdan önce kuruluyor.
    _awaitingReturn = true;
    _leftApp = false;
    bool launched;
    try {
      launched = await widget.launcher(Uri.parse('https://www.instagram.com/zibo.app'));
    } catch (_) {
      launched = false;
    }
    if (!launched && !_leftApp) _awaitingReturn = false;
  }

  Future<void> _claim() async {
    setState(() => _isClaiming = true);
    try {
      final marked = await context.read<InstagramFollowProvider>().markClaimed();
      // Zaten alınmış (teorik olarak — kart zaten `claimed == true` iken
      // hiç render edilmiyor, bkz. build()) — ikinci bir güvenlik katmanı.
      if (!marked || !mounted) return;
      context.read<CoinProvider>().earnInstagramFollowReward();

      final appTheme = context.read<AppThemeProvider>();
      final theme = pickRandomUnownedStandardTheme(appTheme.ownedIds);
      if (theme != null) unawaited(appTheme.markOwned(theme.id));

      final costumeProvider = context.read<CostumeProvider>();
      final costume = pickRandomUnownedLowPricedCostume(
        costumeProvider.ownedIds,
      );
      if (costume != null) unawaited(costumeProvider.markOwned(costume.id));

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await showInfoDialog(context, l10n.instagramFollowRewardGrantedMessage);
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claimed = context.watch<InstagramFollowProvider>().claimed;
    if (claimed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: stickerDecoration(
        fill: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: stickerDecoration(
                  fill: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  borderWidth: 2.5,
                  shadowOffset: Offset.zero,
                ),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Text('📸', style: TextStyle(fontSize: 17, height: 1)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.instagramFollowCardTitle,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 14.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.instagramFollowCardBody,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _StickerRowButton(
              onPressed: _isClaiming ? null : _openInstagram,
              fill: colorScheme.primary,
              foreground: colorScheme.onPrimary,
              child: _isClaiming
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(l10n.instagramFollowOpenButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mockup'ın `.btn`/`.btn-outline`/`.btn-filled` — kalın kontur + düz ofsetli
/// gölge taşıyan, `OutlinedButton`/`FilledButton`'ın sticker karşılığı.
class _StickerRowButton extends StatelessWidget {
  const _StickerRowButton({
    required this.onPressed,
    required this.fill,
    required this.foreground,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Color fill;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: kStickerOutline, offset: Offset(2.5, 2.5))],
      ),
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: kStickerOutline, width: 2.5),
              borderRadius: radius,
            ),
            child: DefaultTextStyle(
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: foreground),
              child: IconTheme(data: IconThemeData(color: foreground), child: child),
            ),
          ),
        ),
      ),
    );
  }
}
