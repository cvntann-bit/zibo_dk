import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_themes.dart';
import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/zibo_messages.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_theme_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../services/sound_effects_service.dart';
import '../utils/address_term.dart';
import '../widgets/favorite_quote_button.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/starry_gradient_background.dart';
import '../widgets/zibo_animated_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.soundEffectsService});

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `AudioPlayersSoundEffectsService()` (`AdService`/`ShareService` ile
  /// AYNI desen).
  final SoundEffectsService? soundEffectsService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();
  // Dizin tabanlı tutuluyor (metnin kendisi değil) ki dil değişince (bkz.
  // LocaleProvider) aynı "konum" korunarak build()'de doğru dildeki karşılığı
  // gösterilebilsin — bkz. `ziboMessagesForLocale`.
  int _messageIndex = 0;

  late final _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // Zibo hafifçe zıplar...
  late final _jumpAnimation = TweenSequence<double>([
    TweenSequenceItem(
      weight: 35,
      tween: Tween(
        begin: 0.0,
        end: -18.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(
      weight: 65,
      tween: Tween(
        begin: -18.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.bounceOut)),
    ),
  ]).animate(_bounceController);

  // ...ve aynı anda hafifçe sallanır.
  late final _wobbleAnimation = TweenSequence<double>([
    TweenSequenceItem(weight: 20, tween: Tween(begin: 0.0, end: -0.06)),
    TweenSequenceItem(weight: 30, tween: Tween(begin: -0.06, end: 0.05)),
    TweenSequenceItem(weight: 25, tween: Tween(begin: 0.05, end: -0.03)),
    TweenSequenceItem(weight: 25, tween: Tween(begin: -0.03, end: 0.0)),
  ]).animate(_bounceController);

  @override
  void dispose() {
    _bounceController.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _onZiboTap() {
    _bounceController.forward(from: 0);
    setState(() => _messageIndex = _pickNewMessageIndex());
    // Poz HER dokunuşta değil, rastgele 5-10 dokunuşta bir ilerler — bkz.
    // ZiboPoseProvider dokümantasyonu.
    context.read<ZiboPoseProvider>().registerZiboTap();
    // Poz/söz değişimiyle AYNI ANDA, kullanıcının Ayarlar > Ses Efektleri
    // tercihine bağlı kısa bir "tık" sesi (bkz. SoundEffectsService — art
    // arda hızlı dokunuşlarda önceki ses kesilip yeniden başlıyor, üst üste
    // binmiyor).
    if (context.read<SoundEffectsProvider>().enabled) {
      _soundEffectsService.playZiboTap();
    }
  }

  int _pickNewMessageIndex() {
    final messages = ziboMessagesForLocale(Localizations.localeOf(context));
    if (messages.length <= 1) return 0;
    int next;
    do {
      next = _random.nextInt(messages.length);
    } while (next == _messageIndex);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final messages = ziboMessagesForLocale(locale);
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final message = applyAddressTerm(
      messages[_messageIndex % messages.length],
      addressTerm,
      locale,
    );
    // Zibo, ekranın ortasında baskın dursun diye ekran yüksekliğinin bir
    // oranı kadar büyütülüyor; çok uzun ekranlarda aşırı büyümesin diye
    // üst sınır konuyor. 2026 güncellemesi — kullanıcı "karakter ufacık
    // görünüyor, büyütelim" diye bildirdi. **Genişlik yerine YÜKSEKLİK
    // kullanılıyor** (bkz. ZiboAnimatedImage dokümantasyonu) — poz
    // görselleri artık karakterin gerçek sınır kutusuna sıkı kırpılmış
    // durumda, bu yüzden `width` yerine `height` vermek karakterin verilen
    // kutuyu neredeyse tamamen doldurmasını sağlıyor (eskiden `width`
    // büyütülse bile, görselin büyük kısmı şeffaf olduğu için görünen
    // karakter kutunun çok altında kalıyordu).
    final ziboHeight = (MediaQuery.sizeOf(context).height * 0.36).clamp(
      260.0,
      400.0,
    );
    // Mağaza > Kostümler'den giyilen bir kostüm varsa Zibo'nun görseli onunla
    // değişir; yoksa (veya kostüm listeden kaldırılmışsa) varsayılan görsele
    // düşülür.
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final equippedImageAsset = equippedId == null
        ? defaultZiboImage
        : (findCostumeById(equippedId)?.imageAsset ?? defaultZiboImage);
    // Poz döngüsü artık burada (Zibo'ya dokunuşla) İLERLETİLİYOR, diğer
    // ekranlar bu sayacı yalnızca İZLİYOR — bkz. ZiboPoseProvider.
    final poseStep = context.watch<ZiboPoseProvider>().poseStep;

    // Mağaza > Temalar'dan uygulanan kod-tabanlı bir tema varsa Ana Sayfa'nın
    // arka planına o temanın gradyanı çiziliyor — açık/koyu moda göre HANGİ
    // varyantın kullanılacağı `ThemeProvider.isDarkMode`'a bakılarak otomatik
    // seçiliyor (kullanıcı modu değiştirdiğinde ayrıca bir şey yapmasına
    // gerek yok, bu `build()` zaten yeniden çalışıp doğru gradyanı çizer).
    // Uygulanan tema yoksa (varsayılan) arka plan dokunulmadan
    // `colorScheme.surface`'a bırakılıyor.
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final equippedThemeId = context.watch<AppThemeProvider>().equippedId;
    final equippedTheme = equippedThemeId == null
        ? null
        : findAppThemeById(equippedThemeId);

    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onZiboTap,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _jumpAnimation.value),
                  child: Transform.rotate(
                    angle: _wobbleAnimation.value,
                    child: child,
                  ),
                ),
                child: ZiboAnimatedImage(
                  imageKey: const Key('ziboCharacterImage'),
                  costumeId: equippedId,
                  poseStep: poseStep,
                  fallbackImage: equippedImageAsset,
                  height: ziboHeight,
                  semanticLabel: l10n.ziboImagePlaceholder,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Stack(
              clipBehavior: Clip.none,
              children: [
                SpeechBubble(message: message),
                Positioned(
                  top: -6,
                  right: -6,
                  child: ShareZiboButton(message: message),
                ),
                Positioned(
                  top: -6,
                  left: -6,
                  child: FavoriteQuoteButton(message: message),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tapZiboHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (equippedTheme == null) return content;

    final gradientBackground = DecoratedBox(
      key: const Key('homeThemeGradientBackground'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: equippedTheme.colorsFor(isDarkMode),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: content,
    );

    return equippedTheme.isStarryInDark && isDarkMode
        ? StarryGradientBackground(child: gradientBackground)
        : gradientBackground;
  }
}
