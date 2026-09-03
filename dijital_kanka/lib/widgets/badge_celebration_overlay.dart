import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/badge_gift_rewards.dart';
import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_definition.dart';
import '../models/badge_gift_reward.dart';
import '../providers/app_theme_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../screens/badges_gallery_screen.dart';
import '../services/sound_effects_service.dart';
import '../utils/badge_celebration_signal.dart';
import '../utils/badge_special_reward.dart';
import '../utils/root_navigator_key.dart';
import 'goal_confetti_burst.dart';

/// Bir rozet kazanıldığında uygulamanın HER YERİNDE (hangi ekranda olursa
/// olsun) konfeti + kazanım popup'ı gösteren, `MaterialApp.builder`
/// SEVİYESİNDE (`AdBlurOverlay` ile AYNI konum — bkz. `main.dart`) mount
/// edilen global bir overlay — bkz. CLAUDE.md "Rozet Sistemi" bölümü.
///
/// **`home:` İÇİNE DEĞİL, `builder:` seviyesine yerleştirilmesinin nedeni:**
/// `home:` içindeki içerik, başka bir rota PUSH edilince artık BOYANMIYOR
/// (standart opak `MaterialPageRoute` davranışı) — "HER YERDE" görünürlük
/// yalnızca `builder:` seviyesinde garanti edilebiliyor. Ama bu seviyenin
/// kendi `context`'i Navigator'ın ATASI DEĞİL, bu yüzden "Ödülü Al"dan sonra
/// Rozetler Galerisi'ni açmak için `Navigator.of(context)` YERİNE global
/// [rootNavigatorKey] kullanılıyor.
class BadgeCelebrationOverlay extends StatefulWidget {
  const BadgeCelebrationOverlay({
    super.key,
    required this.child,
    this.soundEffectsService,
  });

  final Widget child;

  /// Testte gerçek `audioplayers` platform kanalına dokunmadan sahte bir
  /// implementasyon enjekte edebilmek için var — `HomeScreen`/
  /// `GoalTrackingScreen`/`WaterTrackingScreen`'deki AYNI desen. `null` ise
  /// gerçek `AudioPlayersSoundEffectsService()` kullanılır.
  final SoundEffectsService? soundEffectsService;

  @override
  State<BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<BadgeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  // `late final` alan başlatıcısı YERİNE `initState()`'te KOŞULSUZ, erkenden
  // oluşturuluyor — bu widget bir rozet HİÇ kazanılmadan (yani bu alana hiç
  // erişilmeden) dispose edilirse, `late final`'in tembel başlatıcısı İLK
  // erişimi `dispose()`'a denk getirip "Looking up a deactivated widget's
  // ancestor is unsafe" hatasıyla çökerdi (gerçekten yakalandı, `flutter
  // test`'te — `AnimatedThemeOverlay`'deki AYNI dokümante edilmiş gotcha,
  // bkz. CLAUDE.md "Premium/Animasyonlu temalar" bölümü).
  late final AnimationController _confettiController;

  // Diğer ses efekti çalan widget'larla AYNI desen (bkz. `HomeScreen.
  // _soundEffectsService`) — bu overlay KENDİ ayrı `SoundEffectsService`
  // örneğini oluşturur, diğer bağlamlardaki sesleri KESMESİN diye.
  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();

  ZiboBadgeDefinition? _badge;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    pendingBadgePopup.addListener(_onPendingBadgeChanged);
  }

  void _onPendingBadgeChanged() {
    final badge = pendingBadgePopup.value;
    if (badge == null) return;
    setState(() => _badge = badge);
    _confettiController.forward(from: 0);
    // Konfeti ile TAM EŞ ZAMANLI kutlama sesi — kullanıcının Ayarlar > Ses
    // Efektleri tercihine bağlı (bkz. SoundEffectsService.playBadgeWin).
    if (mounted && context.read<SoundEffectsProvider>().enabled) {
      _soundEffectsService.playBadgeWin();
    }
  }

  @override
  void dispose() {
    pendingBadgePopup.removeListener(_onPendingBadgeChanged);
    _confettiController.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _dismissAndOpenGallery(GrantedBadgeGift? grantedGift) {
    setState(() => _badge = null);
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => BadgesGalleryScreen(grantedGift: grantedGift),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    return Stack(
      children: [
        widget.child,
        if (badge != null) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: GoalConfettiBurst(progress: _confettiController),
            ),
          ),
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: Theme.of(
                context,
              ).colorScheme.scrim.withValues(alpha: 0.55),
            ),
          ),
          // Kullanıcı isteği: rozet popup'ı diğerlerinden (Çark/Günlük
          // Giriş) DAHA FAZLA yukarı kaydırılsın — konfeti animasyonu
          // (yukarıdaki GoalConfettiBurst) hiç dokunulmadan aynen kalıyor,
          // yalnızca kartın DÜŞEY konumu değişiyor.
          Align(
            alignment: const Alignment(0, -0.45),
            child: _BadgeClaimCard(
              badge: badge,
              onClaim: _dismissAndOpenGallery,
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgeClaimCard extends StatelessWidget {
  const _BadgeClaimCard({required this.badge, required this.onClaim});

  final ZiboBadgeDefinition badge;

  /// `badgeGiftRewards`'ta bir hediyesi olan bir rozette "Ödülü Al"a
  /// basılınca hediye GERÇEKTEN verildiyse türü + yerelleştirilmiş adı —
  /// bkz. `BadgesGalleryScreen.grantedGift`. Hediye yoksa VEYA (yalnızca
  /// tema tipinde, teorik olarak nadir) sahip olunmayan standart tema
  /// kalmadıysa `null`.
  final void Function(GrantedBadgeGift? grantedGift) onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Bu rozetin bir hediyesi var mı — bkz. `data/badge_gift_rewards.dart`.
    // Kostüm tipi SABİT/deterministik olduğu için hangi kostümün
    // verileceği "Ödülü Al"a basılmadan ÖNCE bile biliniyor (aşağıdaki
    // notta gösteriliyor); tema tipi yalnızca claim anında belli oluyor.
    final gift = badgeGiftRewards[badge.id];
    final giftCostume = gift?.type == BadgeGiftType.costume
        ? findCostumeById(gift!.costumeId!)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kullanıcı isteği: görsel biraz büyütülsün. Bu Column'da PNG'nin
              // ARKASINDA hiçbir dekoratif Container/daire YOK — kullanıcının
              // gördüğü "siyah yuvarlak arkaplan" gerçekte
              // `yilmaz_efsanevi_rozet.png`nin (Yılmaz/Efsanevi rozeti) kaynak
              // dosyasına BAKILI, şeffaf OLMAYAN siyah bir kare arka plandı —
              // `tool/remove_black_bg.dart` ile assetin kendisi düzeltildi,
              // burada ayrıca kaldırılacak bir widget/dekorasyon yoktu.
              Image.asset(badge.imageAsset, width: 152, height: 152),
              const SizedBox(height: 16),
              Text(
                badge.localizedName(l10n),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.localizedRequirement(l10n),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.storeCoinAmount(badge.zcReward),
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Kostüm/tema hediyesi taşıyan DOKUZ rozetten biri için —
              // bkz. `data/badge_gift_rewards.dart`. Kostüm tipi SABİT
              // olduğu için hangi kostümün verileceği burada, "Ödülü Al"a
              // basılmadan ÖNCE bile gösteriliyor (görsel + isim); tema
              // tipinde henüz HANGİ temanın çıkacağı belli olmadığı için
              // genel bir "+ tema hediyesi" notu gösteriliyor, gerçek isim
              // yalnızca claim SONRASI (SnackBar'la) açıklanıyor.
              if (gift != null) ...[
                const SizedBox(height: 8),
                if (giftCostume != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(giftCostume.imageAsset, width: 28, height: 28),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.badgeGiftCostumeMessage(
                            giftCostume.localizedName(l10n),
                          ),
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.badgeSpecialRewardThemeNote,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<BadgeProvider>().markClaimed(badge.id);
                    context.read<CoinProvider>().earnBadgeReward(
                      badge.zcReward,
                      badge.id,
                    );
                    // Hediye — kostüm tipi SABİT/deterministik (yukarıdaki
                    // `giftCostume`'un AYNISI, `markOwned` idempotent olduğu
                    // için kullanıcı zaten satın almış olsa bile GÜVENLE
                    // tekrar çağrılabilir), tema tipi ise sahip OLUNMAYAN
                    // standart temalardan rastgele seçiliyor. Verilecek
                    // hiçbir şey kalmadıysa (yalnızca tema tipinde, teorik
                    // olarak nadir) sessizce hiçbir şey verilmiyor.
                    GrantedBadgeGift? granted;
                    if (gift != null) {
                      if (giftCostume != null) {
                        unawaited(
                          context.read<CostumeProvider>().markOwned(
                            giftCostume.id,
                          ),
                        );
                        granted = (
                          type: BadgeGiftType.costume,
                          name: giftCostume.localizedName(l10n),
                        );
                      } else {
                        final themeProvider = context.read<AppThemeProvider>();
                        final theme = pickRandomUnownedStandardTheme(
                          themeProvider.ownedIds,
                        );
                        if (theme != null) {
                          unawaited(themeProvider.markOwned(theme.id));
                          granted = (
                            type: BadgeGiftType.theme,
                            name: theme.localizedName(l10n),
                          );
                        }
                      }
                    }
                    pendingBadgePopup.value = null;
                    onClaim(granted);
                  },
                  child: Text(l10n.badgeClaimRewardButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
