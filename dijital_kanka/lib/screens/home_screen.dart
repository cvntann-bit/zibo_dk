import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_themes.dart';
import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/zibo_event_messages.dart';
import '../data/zibo_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/goal.dart';
import '../models/water_entry.dart';
import '../providers/ad_free_provider.dart';
import '../providers/app_theme_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/custom_messages_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/water_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../services/sound_effects_service.dart';
import '../utils/address_term.dart';
import '../utils/motivation_quote_selector.dart';
import '../utils/zibo_event_signal.dart';
import '../widgets/ad_free_promo_sheet.dart';
import '../widgets/custom_messages_button.dart';
import '../widgets/favorite_quote_button.dart';
import '../widgets/home_module_widget.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/starry_gradient_background.dart';
import '../widgets/zibo_animated_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.soundEffectsService, this.adPromoRandom});

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `AudioPlayersSoundEffectsService()` (`AdService`/`ShareService` ile
  /// AYNI desen).
  final SoundEffectsService? soundEffectsService;

  /// Art arda dokunmada reklam/Reklamsız Zibo teklifi seçimini test
  /// ortamında SABİT bir sonuca zorlayabilmek için — `wheel_prizes_test.
  /// dart`'taki `_FixedRandom` deseniyle AYNI amaç. **BİLEREK [_random]'dan
  /// (söz seçimi) AYRI bir alan** — söz seçim motoru (`motivation_quote_
  /// selector.dart`) SABİT bir `Random` (her zaman aynı değeri döndüren)
  /// ile beslendiğinde "farklı bir sonuç gelene kadar tekrar dene" tarzı
  /// bir döngüye girebilir (eski `_pickNewMessageIndex()`'in `do-while`'ında
  /// GERÇEKTEN yaşanmış, testte tespit edilmiş bir sonsuz döngü riski — yeni
  /// motor bunu `maxAttempts` sınırıyla ele alıyor ama AYNI ihtiyatı
  /// korumak için test amaçlı sabit `Random` YİNE DE YALNIZCA bu alana
  /// enjekte edilebiliyor, `_random`'a DEĞİL).
  final Random? adPromoRandom;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late final Random _adPromoRandom = widget.adPromoRandom ?? Random();
  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();
  // 2026 güncellemesi — Motivasyon Sözü Sistemi (bkz. CLAUDE.md): söz artık
  // saf rastgele DEĞİL, `motivation_quote_selector.dart`'ın zaman dilimi +
  // ruh hali ağırlıklı seçimiyle geliyor. `_currentQuote` sözün METNİNİ
  // DEĞİL, KİMLİĞİNİ (hangi havuzun kaçıncı elemanı) tutuyor — eski
  // `_messageIndex`'in "dil değişince aynı konumun yeni dildeki karşılığına
  // ANINDA geçmesi" garantisini `resolveMotivationQuoteText` ile koruyor
  // (bkz. o dosyadaki dokümantasyon). `null` yalnızca ilk `build()`'den
  // ÖNCE — `_pickAndSetQuote()` `context`'e ihtiyaç duyduğu için (locale/
  // ruh hali/özel mesajlar) `initState()`'te DEĞİL, ilk `build()`'de
  // (`_currentQuote == null` koşuluyla) hesaplanıyor.
  MotivationQuotePick? _currentQuote;

  /// Tekrar-önleme — son gösterilen sözlerin kimlikleri (kısa süreliğine,
  /// yalnızca bu oturum boyunca — `_recentZiboTaps` ile AYNI "kalıcılık
  /// gerektirmeyen, kısa ömürlü liste" deseni). Sabit bir üst sınırda
  /// tutuluyor ki liste sınırsız büyümesin.
  final List<String> _recentQuoteIds = [];
  static const _maxRecentQuoteIds = 20;

  /// `context.read`/`Localizations.localeOf(context)` kullandığı için
  /// yalnızca `build()` çalıştıktan SONRA (ilk `build()` dahil, `_currentQuote
  /// == null` koşuluyla) çağrılabilir — `initState()`'te DEĞİL.
  ///
  /// **2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md
  /// aynı adlı bölüm).** [pendingZiboEvent] BİR OLAY taşıyorsa, normal
  /// zaman/ruh hali ağırlıklı seçim TAMAMEN BAYPAS EDİLİP doğrudan o
  /// olayın özel havuzundan bir söz seçiliyor — olay ANINDA TÜKETİLİYOR
  /// (`pendingZiboEvent.value = null`) ki bir SONRAKİ seçimde (dokunuş/
  /// tekrar tetiklenme) normal akışa dönülsün.
  void _pickAndSetQuote() {
    final locale = Localizations.localeOf(context);
    final pendingEvent = pendingZiboEvent.value;
    if (pendingEvent != null) {
      pendingZiboEvent.value = null;
      final pool = eventMessagesForLocale(pendingEvent, locale);
      final pick = MotivationQuotePick(
        source: 'event',
        tag: pendingEvent.name,
        index: _random.nextInt(pool.length),
      );
      _currentQuote = pick;
      _recentQuoteIds.add(pick.id);
      if (_recentQuoteIds.length > _maxRecentQuoteIds) {
        _recentQuoteIds.removeAt(0);
      }
      return;
    }
    final generalPool = [
      ...ziboMessagesForLocale(locale),
      ...context.read<CustomMessagesProvider>().messages,
    ];
    final moodEntries = context.read<MoodProvider>().entries;
    final latestMood = moodEntries.isEmpty ? null : moodEntries.first.mood;
    final latestMoodNote = moodEntries.isEmpty ? null : moodEntries.first.note;
    final now = DateTime.now();
    final pick = pickMotivationQuote(
      localNow: now,
      locale: locale,
      latestMood: latestMood,
      recentLowMoodRatio: recentLowMoodRatio(moodEntries, now),
      generalPool: generalPool,
      recentIds: _recentQuoteIds.toSet(),
      random: _random,
      latestMoodNote: latestMoodNote,
    );
    _currentQuote = pick;
    _recentQuoteIds.add(pick.id);
    if (_recentQuoteIds.length > _maxRecentQuoteIds) {
      _recentQuoteIds.removeAt(0);
    }
  }

  /// [pendingZiboEvent] BAŞKA bir ekranda (Hedef Takibi, Mağaza, Günlük
  /// Giriş Ödülleri) tetiklendiğinde, Ana Sayfa `IndexedStack` içinde
  /// GÖRÜNMÜYOR bile olsa konuşma balonunun ANINDA (kullanıcı sekmeyi
  /// değiştirmeden ÖNCE) güncellenmiş olmasını sağlar — aksi halde olay
  /// yalnızca kullanıcı Zibo'ya GERÇEKTEN dokunursa görünürdü, bu da
  /// "hedefimi tamamladım, Ana Sayfa'ya döndüğümde Zibo'nun beni
  /// kutlaması" beklentisini karşılamazdı.
  void _onPendingZiboEventChanged() {
    if (pendingZiboEvent.value != null && mounted) {
      setState(_pickAndSetQuote);
    }
  }

  /// 2026 güncellemesi — kullanıcı isteği: Zibo'ya art arda hızlı
  /// dokunulunca (5-6 kez, birkaç saniye içinde) bir reklam VEYA (daha
  /// düşük ihtimalle) Reklamsız Zibo teklifiyle karşılaşılsın. Gerçek
  /// zaman damgası tutuluyor (`WheelTriggerButton`/`AdFreePromoTrigger`
  /// ile AYNI `DateTime.now().difference(...)` deseni) — bu ekranda başka
  /// yerde kalıcılık gerektirmeyen, saf/geçici bir "art arda dokunma"
  /// penceresi olduğu için ayrı bir enjekte edilebilir saate gerek yok.
  final List<DateTime> _recentZiboTaps = [];
  static const _rapidTapThreshold = 5;
  static const _rapidTapWindow = Duration(seconds: 3);

  /// Art arda dokunma eşiği dolunca reklam yerine Reklamsız Zibo
  /// teklifinin gösterilme ihtimali — kullanıcının kendi ifadesiyle
  /// "%20-30 ihtimalle", ikisinin ortası seçildi.
  static const _adFreePromoChanceOnRapidTap = 0.25;

  /// Bir gösterim (reklam ya da promo) sürerken YENİ bir tetiklemeyi
  /// engeller — kullanıcı gösterim kapanmadan tekrar hızlı dokunursa iki
  /// gösterim üst üste binmesin diye.
  bool _showingRapidTapPromo = false;

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
  void initState() {
    super.initState();
    pendingZiboEvent.addListener(_onPendingZiboEventChanged);
  }

  @override
  void dispose() {
    pendingZiboEvent.removeListener(_onPendingZiboEventChanged);
    _bounceController.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  void _onZiboTap() {
    _bounceController.forward(from: 0);
    setState(_pickAndSetQuote);
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
    _registerRapidTap();
  }

  /// Her dokunuşta çağrılır; son [_rapidTapWindow] içindeki dokunuş
  /// sayısını izler, eşik dolunca [_showRapidTapPromoOrAd]'ı tetikleyip
  /// sayacı sıfırlar (bkz. yukarıdaki alan dokümantasyonu).
  void _registerRapidTap() {
    final now = DateTime.now();
    _recentZiboTaps.add(now);
    _recentZiboTaps.removeWhere((t) => now.difference(t) > _rapidTapWindow);
    if (_recentZiboTaps.length < _rapidTapThreshold || _showingRapidTapPromo) {
      return;
    }
    _recentZiboTaps.clear();
    unawaited(_showRapidTapPromoOrAd());
  }

  /// Reklam VEYA (kullanıcının bazen "reklamsız ol" teklifiyle de
  /// karşılaşması için) Reklamsız Zibo tanıtım sheet'ini gösterir —
  /// İKİSİ BİRDEN asla aynı tetiklemede olmuyor, `_adPromoRandom` her
  /// seferinde tek bir yol seçiyor. Kullanıcı ZATEN "Zibo ADS" satın
  /// aldıysa ikisi de anlamsız (reklam zaten `CoinProvider.
  /// showInterstitialAd()` içinde engelleniyor, tanıtım sheet'i ise
  /// zaten sahip olduğu bir şeyi tekrar tekrar satmaya çalışırdı) — bu
  /// yüzden BURADA erken çıkılıyor.
  Future<void> _showRapidTapPromoOrAd() async {
    if (context.read<AdFreeProvider>().isAdFree) return;
    _showingRapidTapPromo = true;
    try {
      if (_adPromoRandom.nextDouble() < _adFreePromoChanceOnRapidTap) {
        if (mounted) await showAdFreePromoSheet(context);
      } else {
        await context.read<CoinProvider>().showInterstitialAd();
      }
    } finally {
      _showingRapidTapPromo = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    // Kullanıcının kendi eklediği özel mesajlar, "genel" dilimin (bkz.
    // `motivation_quote_selector.dart`) SONUNA eklenip aynı havuzdan
    // seçiliyor — bkz. `_pickAndSetQuote`.
    final customMessages = context.watch<CustomMessagesProvider>().messages;
    final generalPool = [...ziboMessagesForLocale(locale), ...customMessages];
    // İlk `build()`'den ÖNCE `_currentQuote` `null` — `initState()` bu
    // pick'i yapamıyor çünkü `context`'e (locale/ruh hali) ihtiyaç duyuyor
    // (bkz. `_pickAndSetQuote` dokümantasyonu). `setState` GEREKMİYOR —
    // build() zaten BU ÇAĞRIDA taze değeri kullanacak.
    if (_currentQuote == null) _pickAndSetQuote();
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final message = applyAddressTerm(
      resolveMotivationQuoteText(_currentQuote!, locale, generalPool),
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

    // Su/Hedef mini kartları — "Çizgi Roman Çıkartması" mockup'ında Ana
    // Sayfa'ya YENİ eklenen, konuşma balonu ile alt bar arasındaki widget
    // sırası (bkz. `docs/theme_new.md` "Onaylanan: Ana Sayfa yerleşimi").
    final water = context.watch<WaterProvider>();
    final waterUnitLabel = water.unit == WaterUnit.glass
        ? l10n.waterUnitGlass
        : l10n.waterUnitBottle;
    final waterProgress = water.todayCount / water.goalUnitCount;
    final waterSubtitle = water.isTodayComplete
        ? l10n.homeWaterCompleteLabel
        : l10n.homeWaterRemainingLabel(
            water.goalUnitCount - water.todayCount,
            waterUnitLabel,
          );

    final goals = context.watch<GoalsProvider>().goals;
    final today = Goal.dateOnly(DateTime.now());
    final doneGoalsToday = goals
        .where((goal) => goal.completedDates.contains(today))
        .length;
    final goalProgress = goals.isEmpty ? 0.0 : doneGoalsToday / goals.length;
    final String goalSubtitle;
    if (goals.isEmpty) {
      goalSubtitle = l10n.homeGoalEmptyLabel;
    } else if (doneGoalsToday >= goals.length) {
      goalSubtitle = l10n.homeGoalCompleteLabel;
    } else {
      goalSubtitle = goals
          .firstWhere((goal) => !goal.completedDates.contains(today))
          .name;
    }

    // Mockup'ın `.mid-space{flex:1 1 auto}` alanı — maskot+balon+ipucu
    // KENDİ `SingleChildScrollView`'ında üstte, mini kartlar SABİT olarak
    // altta kalır; aradaki tüm boş alan burada birikir (küçük ekranda
    // yeterse maskot bölümü kendi içinde kayar, dış Column asla taşmaz).
    // Not: `Spacer`/`Expanded` DOĞRUDAN bir `SingleChildScrollView`'ın
    // İÇİNDE kullanılamaz (o eksende sınırsız yükseklik verir) — bu yüzden
    // esnek boşluk dış `Column`'da, kaydırma İÇ `Column`'da.
    final content = Column(
      children: [
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SizedBox(height: 8),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SpeechBubble(message: message),
                    Positioned(
                      top: -13,
                      right: -13,
                      child: ShareZiboButton(message: message),
                    ),
                    Positioned(
                      top: -13,
                      left: -13,
                      child: FavoriteQuoteButton(message: message),
                    ),
                    const Positioned(
                      bottom: -13,
                      right: -13,
                      child: CustomMessagesButton(),
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 44),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeModuleWidget(
                icon: Icons.water_drop,
                title: l10n.homeWaterWidgetTitle,
                valueLabel: '${water.todayCount}/${water.goalUnitCount}',
                progress: waterProgress,
                subtitle: waterSubtitle,
                newBadgeLabel: l10n.homeWidgetNewBadge,
              ),
              const SizedBox(width: 12),
              HomeModuleWidget(
                icon: Icons.flag,
                title: l10n.homeGoalWidgetTitle,
                valueLabel: '$doneGoalsToday/${goals.length}',
                progress: goalProgress,
                subtitle: goalSubtitle,
                newBadgeLabel: l10n.homeWidgetNewBadge,
              ),
            ],
          ),
        ),
      ],
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
