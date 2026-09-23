import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/coin_economy.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_rewards_provider.dart';
import '../utils/zibo_event_signal.dart';
import '../widgets/sticker_style.dart';

/// Günlük Giriş Ödülleri popup'ı — `WheelScreen`'in aksine tam ekran DEĞİL,
/// ortada küçük bir `Dialog` (kullanıcı isteği: "ortada bir popup açılsın").
/// 7 gün kutucuğu + üstte o anki durumu (bugünün ödülü hazır mı/alındı mı)
/// özetleyen bir metin gösterir; `context.watch` ile provider'ı doğrudan
/// izlediği için bir gün kutusuna dokunulunca TÜM içerik (durum metni +
/// kutucuk) anında güncellenir, ayrı bir state yönetimine gerek yok.
class DailyRewardsScreen extends StatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  State<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends State<DailyRewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Popup her açıldığında bir kez daha reconcile et — uygulama arka
    // plana hiç alınmadan gün değiştiyse (nadir ama olası bir uç durum)
    // bile grid'in doğru günü göstermesini garantiler.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DailyRewardsProvider>().reconcileForToday();
    });
  }

  void _claimDay(BuildContext context, int index) {
    final provider = context.read<DailyRewardsProvider>();
    final amount = provider.claimToday();
    if (amount == null) return;
    final coin = context.read<CoinProvider>();
    coin.earnDailyLoginReward(amount);
    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // 7 günlük döngünün SON günü (index 6 = "Gün 7", en büyük tek günlük
    // ödül) alınınca Ana Sayfa'nın konuşma balonu bir SONRAKİ seçiminde
    // ayrı, daha coşkulu bir "seri bonusu" mesajı gösterecek — bkz.
    // `zibo_event_signal.dart`.
    if (index == 6) pendingZiboEvent.value = ZiboEventType.loginStreakBonus;
    // Kullanıcı isteği: günlük giriş ödülü alınınca geçilebilir (interstitial,
    // ÖDÜLLÜ DEĞİL) bir reklam gösterilsin — HomeScreen'in art arda dokunma
    // reklamıyla (bkz. `_showRapidTapPromoOrAd`) AYNI `CoinProvider.
    // showInterstitialAd()` çağrısı; coin bakiyesini/işlem geçmişini HİÇ
    // etkilemiyor, günde en fazla bir kez tetiklenir (ödül zaten günde bir
    // kez alınabildiği için).
    unawaited(coin.showInterstitialAd());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<DailyRewardsProvider>();
    // Faz 6 yeniden tasarımı — Zibo Pro/Pro+ çarpanı artık tabloda GÖRÜNÜR
    // (bkz. `_DayRewardBox.multiplierLabel`). Durum metni/erişilebilirlik
    // etiketleri de HER YERDE ham `CoinEconomy.dailyLoginRewards` yerine
    // `coin.previewDailyLoginReward(...)` (gerçekte kazanılacak/kazanılmış
    // tutar) kullanıyor — `earnDailyLoginReward`'ın kendisiyle AYNI
    // hesaplamayı paylaştığı için gösterilen tutar hiçbir zaman gerçekte
    // eklenenden SAPMIYOR.
    final coin = context.watch<CoinProvider>();
    final multiplierLabel = coin.dailyLoginMultiplierLabel;
    final todayAmount = provider.todayAmount == null
        ? null
        : coin.previewDailyLoginReward(provider.todayAmount!);

    final String statusMessage;
    if (provider.isTodayClaimed) {
      final claimedAmount = coin.previewDailyLoginReward(
        CoinEconomy.dailyLoginRewards[provider.todayIndex],
      );
      statusMessage = l10n.dailyRewardsAlreadyClaimedToday(claimedAmount);
    } else if (todayAmount != null) {
      statusMessage = l10n.dailyRewardsPromptToday(
        provider.todayIndex + 1,
        todayAmount,
      );
    } else {
      // todayIndex geçici olarak aralık dışında (reconcile henüz
      // çalışmadıysa) — bir sonraki frame'de reconcile edilip düzelecek.
      statusMessage = '';
    }

    return Dialog(
      // Kullanıcı isteği: popup biraz yukarıya kaydırılsın — merkezden
      // hafifçe yukarı kaymış bir hizalama.
      alignment: const Alignment(0, -0.2),
      // Faz 6 yeniden tasarımı — bu popup eskiden düz Material `Dialog`
      // varsayılanlarını (yumuşak elevation gölgesi, konturSUZ) kullanıyordu;
      // uygulamanın geri kalanının "Çizgi Roman Çıkartması" diline (kalın
      // `kStickerOutline` konturu, bkz. `sticker_style.dart`) UYMUYORDU —
      // onaylanan mockup TAM OLARAK bu kalın kontur diliyle tasarlanmıştı.
      backgroundColor: colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: kStickerOutline, width: 3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dailyRewardsTitle,
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontVariations: const [FontVariation('wght', 800)],
                      fontSize: 19,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                StickerIconButton(
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l10n.dailyRewardsCloseTooltip,
                  size: 32,
                  iconSize: 16,
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey(statusMessage),
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (var index = 0; index < CoinEconomy.dailyLoginRewards.length; index++)
                  _DayRewardBox(
                    dayNumber: index + 1,
                    amount: coin.previewDailyLoginReward(
                      CoinEconomy.dailyLoginRewards[index],
                    ),
                    multiplierLabel: multiplierLabel,
                    status: provider.statusForIndex(index),
                    onTap: () => _claimDay(context, index),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRewardBox extends StatelessWidget {
  const _DayRewardBox({
    required this.dayNumber,
    required this.amount,
    required this.multiplierLabel,
    required this.status,
    required this.onTap,
  });

  final int dayNumber;

  /// Zaten Pro/Pro+ çarpanı UYGULANMIŞ nihai tutar (bkz.
  /// `CoinProvider.previewDailyLoginReward`) — kutunun içinde HER ZAMAN
  /// kullanıcının GERÇEKTEN kazanacağı/kazandığı tutar gösterilir.
  final int amount;

  /// `'2x'`/`'1.5x'` (Pro/Pro+) — ücretsiz kullanıcı için `null`, bu
  /// durumda köşe rozeti hiç ÇİZİLMEZ.
  final String? multiplierLabel;
  final DailyRewardDayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final String semanticLabel;
    final Color background;
    final Color foreground;
    final Color borderColor;
    final double borderWidth;
    final Offset? shadowOffset;
    final Widget statusIcon;

    switch (status) {
      case DailyRewardDayStatus.claimed:
        semanticLabel = l10n.dailyRewardsClaimedSemanticLabel(dayNumber, amount);
        background = colorScheme.primary;
        foreground = colorScheme.onPrimary;
        borderColor = kStickerOutline;
        borderWidth = 2;
        shadowOffset = const Offset(3, 3);
        statusIcon = Icon(Icons.check_circle, size: 20, color: foreground);
      case DailyRewardDayStatus.today:
        semanticLabel = l10n.dailyRewardsClaimSemanticLabel(dayNumber, amount);
        background = colorScheme.primaryContainer;
        foreground = colorScheme.onPrimaryContainer;
        borderColor = kStickerOutline;
        borderWidth = 2.5;
        shadowOffset = const Offset(4, 4);
        statusIcon = const Text('🎁', style: TextStyle(fontSize: 20, height: 1));
      case DailyRewardDayStatus.upcoming:
        semanticLabel = l10n.dailyRewardsLockedSemanticLabel(dayNumber, amount);
        background = Colors.transparent;
        foreground = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        borderColor = colorScheme.outlineVariant;
        borderWidth = 1.5;
        shadowOffset = null;
        statusIcon = Icon(Icons.lock_outline, size: 18, color: foreground);
    }

    final isTappable = status == DailyRewardDayStatus.today;

    // Faz 6 yeniden tasarımı — Zibo Pro/Pro+ kullanıcıda köşede küçük bir
    // "2x"/"1.5x" rozeti (kutunun İÇİNDEKİ tutar zaten çarpan uygulanmış
    // nihai değer — bkz. `amount` dokümantasyonu). Rozet kutunun 8-10px
    // DIŞINA taştığı için dış `SizedBox` `clipBehavior: Clip.none`
    // gerektiriyor (bkz. `Wrap`'in `spacing`/`runSpacing`'i — bu taşma
    // payını karşılayacak kadar geniş bırakıldı, bkz. `daily_rewards_
    // screen.dart`'ın üst kısmındaki `Wrap`).
    return Semantics(
      label: semanticLabel,
      button: isTappable,
      // İçerideki Text'lerin (gün numarası + tutar) kendi otomatik ürettiği
      // semantics dıştaki `label`la BİRLEŞİP birleşik/gürültülü bir etikete
      // dönüşmesin diye — bkz. CLAUDE.md "Alt Gezinme Çubuğu" bölümündeki
      // aynı gotcha.
      excludeSemantics: true,
      child: SizedBox(
        width: 82,
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: isTappable ? onTap : null,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 82,
                height: 108,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: borderWidth),
                  // Faz 6 yeniden tasarımı — Material'ın yumuşak/bulanık
                  // gölgesi (`blurRadius`) YERİNE uygulamanın "sticker"
                  // dilindeki düz ofsetli, bulanıksız gölge (bkz.
                  // `stickerDecoration` dokümantasyonu — "kesilmiş sticker"
                  // hissi).
                  boxShadow: shadowOffset != null
                      ? [BoxShadow(color: kStickerOutline, offset: shadowOffset)]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dailyRewardsDayLabel(dayNumber),
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 800)],
                        fontSize: 11.5,
                        letterSpacing: .2,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    statusIcon,
                    const SizedBox(height: 4),
                    Text(
                      l10n.storeCoinAmount(amount),
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontVariations: const [FontVariation('wght', 800)],
                        fontSize: 13.5,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (multiplierLabel != null)
              Positioned(
                top: -10,
                right: -8,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Faz 6 — BİLEREK `colorScheme.tertiary` DEĞİL: bu
                      // rozet Mağaza'dan satın alınabilen HERHANGİ bir
                      // özel temanın renk şemasında da AYNI tanınabilir
                      // "bonus" hissini vermeli — `tertiary` bazı temalarda
                      // (ör. yeşil/mavi ağırlıklı seed'ler) rozeti fark
                      // edilmez hale getiriyordu. `error` rolü M3'te HER
                      // zaman sıcak/kırmızımsı bir aile kalır, bu yüzden
                      // tema ne olursa olsun tutarlı kalıyor.
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: kStickerOutline, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        multiplierLabel!,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: 10,
                          color: colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
