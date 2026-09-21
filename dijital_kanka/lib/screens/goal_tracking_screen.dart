import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/goal_quotes.dart';
import '../l10n/app_localizations.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sound_effects_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../services/sound_effects_service.dart';
import '../utils/address_term.dart';
import '../utils/info_dialog.dart';
import '../utils/zibo_event_signal.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_confetti_burst.dart';
import '../widgets/share_zibo_button.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

/// Hedef Takibi sayfası. [isActive], bu sekmenin şu anda görünen sekme olup
/// olmadığını belirtir — RootScreen'deki IndexedStack TÜM sekmeleri baştan
/// monte ettiği için, otomatik söz döndürme zamanlayıcısının yalnızca bu
/// sekme gerçekten görünürken çalışmasını sağlamak için gerekli (bkz.
/// MoneyScreen'deki aynı desen).
class GoalTrackingScreen extends StatefulWidget {
  const GoalTrackingScreen({super.key, required this.isActive, this.soundEffectsService});

  final bool isActive;

  /// Testte sahte bir implementasyon enjekte edebilmek için — varsayılan
  /// `AudioPlayersSoundEffectsService()` (`HomeScreen` ile AYNI desen).
  final SoundEffectsService? soundEffectsService;

  @override
  State<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

class _GoalTrackingScreenState extends State<GoalTrackingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _random = Random();
  // Dizin tabanlı (metin değil) — dil değişince (bkz. LocaleProvider) aynı
  // "konum" korunarak build()'de doğru dildeki karşılığı gösterebilmek için.
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  /// Titreşim bitince (dokunmadan TAM 2 saniye sonra) konfetiyi başlatan
  /// gecikme — `Timer` olarak (bare `Future.delayed` DEĞİL) tutuluyor ki
  /// widget erken dispose edilirse `dispose()`'ta iptal edilebilsin; aksi
  /// halde `flutter_test` "A Timer is still pending even after the widget
  /// tree was disposed" diye BAŞARISIZ oluyor (gerçekten yaşandı) —
  /// üretimde de kullanıcı bu 2 saniye içinde ekrandan ayrılırsa gereksiz
  /// bir zamanlayıcının askıda kalmasını önlüyor.
  Timer? _confettiDelayTimer;

  late final SoundEffectsService _soundEffectsService =
      widget.soundEffectsService ?? AudioPlayersSoundEffectsService();

  /// Kullanıcı bugünün hedef kutucuğunu işaretleyince TAM 2 saniye süren bir
  /// "titreşim" (shake) efekti için — bkz. [_triggerCompletionCelebration].
  /// **2026 güncellemesi — süre 400ms'ten TAM 2 saniyeye çıkarıldı**
  /// (kullanıcı isteği: ses/konfeti zamanlamasıyla senkron olsun). Kısa,
  /// sabit bir `TweenSequence`'i UZATMAK (aynı beş adımı 2 saniyeye
  /// yaymak) yavaş/tembel tek bir sallanma gibi hissettirirdi — bunun
  /// yerine [_shakeOffset] getter'ı `_shakeController.value`'dan DOĞRUDAN
  /// sönümlenen (decaying) bir sinüs dalgası hesaplıyor: ~5Hz'lik gerçek
  /// bir titreşim hissi süre boyunca devam ediyor, yalnızca SON %15'lik
  /// dilimde (son 300ms) genlik yumuşakça sıfıra iniyor — ani bir
  /// "kesilme" yerine akıcı bir bitiş, tam da konfetinin başladığı ana denk
  /// geliyor.
  late final _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  static const _shakeCycles = 10.0; // 2 saniyede toplam salınım sayısı (~5Hz)
  static const _shakeAmplitude = 9.0;
  static const _shakeDecayStart = 0.85; // sönümlenmenin başladığı an (t, 0..1)

  double get _shakeOffset {
    final t = _shakeController.value;
    final decay = t < _shakeDecayStart
        ? 1.0
        : (1 - t) / (1 - _shakeDecayStart);
    return sin(t * 2 * pi * _shakeCycles) * _shakeAmplitude * decay;
  }

  /// Titreşim bitince (dokunmadan TAM 2 saniye sonra) başlayan konfeti
  /// patlaması — [GoalConfettiBurst] kendi tek seferlik "üstten patlayıp
  /// yerçekimiyle düşme" fizik modelini kullanıyor (bkz. o dosyadaki
  /// dokümantasyon); BİR KEZ `forward()` ile oynatılıp bitince kaldırılıyor.
  late final _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _showConfetti = false);
      // Kutlama (titreşim+konfeti) TAM BİTTİKTEN SONRA — bkz.
      // [_onCycleCompleted] — bekleyen bir 7/7 tamamlama reklamı varsa
      // ŞİMDİ gösteriliyor; reklam kutlamanın ÜSTÜNE binip onu KESMESİN
      // diye bilerek buraya (animasyonun GERÇEK bitiş anına) bağlandı.
      if (_pendingCycleCompletionAd) {
        _pendingCycleCompletionAd = false;
        unawaited(context.read<CoinProvider>().showInterstitialAd());
      }
    }
  });
  bool _showConfetti = false;

  /// [GoalCard.onCycleCompleted] tarafından (7/7 tamamlanınca) `true`
  /// yapılır — kullanıcı isteği "hedef tamamlama (7 gün)" sonrası geçilebilir
  /// (interstitial, ÖDÜLLÜ DEĞİL) bir reklam göstermek. Konfeti kutlaması
  /// bu SIRADA zaten oynamaya BAŞLAMIŞ oluyor (aynı tıklama `onMarkedToday`'i
  /// de tetikliyor, bkz. `GoalCard._onTodayTap`) — reklamı ANINDA göstermek
  /// yerine `_confettiController`'ın `completed` durumuna kadar (~4sn)
  /// BEKLETİLİYOR ki tam ekran reklam kutlama animasyonunu KESMESİN.
  bool _pendingCycleCompletionAd = false;

  void _onCycleCompleted() {
    _pendingCycleCompletionAd = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ekran ilk kurulduğunda (uygulama soğuk başlangıçta) bugüne göre
    // kontrol et.
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconcileForToday());
    if (widget.isActive) _startQuoteTimer();
  }

  @override
  void didUpdateWidget(covariant GoalTrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startQuoteTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopQuoteTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plandan öne geldiğinde (ör. bir gece boyunca kapalı
    // kaldıktan sonra) günün değişip değişmediğini gerçek cihaz tarihine
    // göre yeniden kontrol et.
    if (state == AppLifecycleState.resumed) _reconcileForToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopQuoteTimer();
    _confettiDelayTimer?.cancel();
    _shakeController.dispose();
    _confettiController.dispose();
    _soundEffectsService.dispose();
    super.dispose();
  }

  /// Kullanıcı bugünün hedef kutucuğunu YENİ işaretlediğinde
  /// `GoalCard.onMarkedToday` üzerinden çağrılır. **2026 güncellemesi —
  /// zamanlama kullanıcı isteğiyle yeniden tasarlandı:** dokunma ANINDA
  /// (0sn) titreşim (shake) VE `zibo_target.wav` AYNI ANDA başlar (ses
  /// dosyası kendi kendine 4sn'de biter, 3. saniyede "Zibo!" kelimesi
  /// geçiyor — buradan senkronize edilecek başka bir şey yok, yalnızca
  /// BAŞLANGIÇ anının doğru olması yeterli); titreşim TAM 2 saniye sürüp
  /// bitince (2sn) konfeti patlaması başlar. Konfeti (2sn) ile ses (4sn)
  /// kasıtlı olarak AYRI zamanlanmış — ikisinin çakışması sorun değil
  /// (kullanıcının kendi ifadesi).
  void _triggerCompletionCelebration() {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
    if (context.read<SoundEffectsProvider>().enabled) {
      _soundEffectsService.playGoalComplete();
    }
    _confettiDelayTimer?.cancel();
    _confettiDelayTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showConfetti = true);
      _confettiController.forward(from: 0);
    });
  }

  void _startQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _showNewQuote(),
    );
  }

  void _stopQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = null;
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = goalQuotesForLocale(Localizations.localeOf(context));
      if (quotes.length <= 1) {
        _quoteIndex = 0;
        return;
      }
      int next;
      do {
        next = _random.nextInt(quotes.length);
      } while (next == _quoteIndex);
      _quoteIndex = next;
    });
  }

  void _reconcileForToday() {
    if (!mounted) return;
    final resetNames = context.read<GoalsProvider>().reconcileForToday();
    if (resetNames.isEmpty || !mounted) return;

    // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md):
    // kaçırılan bir gün yüzünden döngü sıfırlanınca, Ana Sayfa'nın
    // konuşma balonu bir SONRAKİ seçiminde nazik/suçlamayan bir "tekrar
    // deneyelim" mesajı gösterecek — bkz. `zibo_event_signal.dart`.
    pendingZiboEvent.value = ZiboEventType.streakBroken;

    final l10n = AppLocalizations.of(context)!;
    showInfoDialog(context, l10n.goalStreakReset(resetNames.join(', ')));
  }

  Future<void> _showAddGoalDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addGoalDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.addGoalDialogHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addGoal(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalsProvider = context.watch<GoalsProvider>();
    final goals = goalsProvider.goals;
    final today = goalsProvider.today;
    final locale = Localizations.localeOf(context);
    final quotes = goalQuotesForLocale(locale);
    final addressTerm = context.watch<ProfileProvider>().addressTerm;
    final quote = applyAddressTerm(
      quotes[_quoteIndex % quotes.length],
      addressTerm,
      locale,
    );

    // Mağaza > Kostümler'den giyilen bir kostüm varsa Zibo'nun görseli onunla
    // değişir; yoksa (veya kostüm listeden kaldırılmışsa) varsayılan görsele
    // düşülür (bkz. HomeScreen'deki aynı desen).
    final equippedId = context.watch<CostumeProvider>().equippedId;
    final equippedImageAsset = equippedId == null
        ? defaultZiboImage
        : (findCostumeById(equippedId)?.imageAsset ?? defaultZiboImage);
    final poseStep = context.watch<ZiboPoseProvider>().poseStep;

    final listView = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Column(
          children: [
            ZiboAnimatedImage(
              imageKey: const Key('ziboGoalTrackingImage'),
              costumeId: equippedId,
              poseStep: poseStep,
              fallbackImage: equippedImageAsset,
              height: 200,
              semanticLabel: l10n.ziboImagePlaceholder,
            ),
            const SizedBox(height: 2),
            Stack(
              clipBehavior: Clip.none,
              children: [
                SpeechBubble(message: quote),
                Positioned(
                  top: -13,
                  right: -13,
                  child: ShareZiboButton(message: quote),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        BannerAdSlot(isActive: widget.isActive),
        const SizedBox(height: 12),
        for (final goal in goals) ...[
          GoalCard(
            goal: goal,
            today: today,
            onMarkedToday: _triggerCompletionCelebration,
            onCycleCompleted: _onCycleCompleted,
          ),
          const SizedBox(height: 12),
        ],
        DashedStickerButton(
          onPressed: () => _showAddGoalDialog(context),
          label: l10n.addGoalButton,
        ),
      ],
    );

    // Titreşim (shake) + konfeti — bkz. `_triggerCompletionCelebration`
    // dokümantasyonu. Konfeti `Positioned.fill` + `IgnorePointer` ile üstte
    // duruyor, altındaki listeyle ETKİLEŞİMİ ENGELLEMEZ; yalnızca
    // `_showConfetti` true iken (aktif patlama sırasında) ağaçta.
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) =>
              Transform.translate(offset: Offset(_shakeOffset, 0), child: child),
          child: listView,
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: GoalConfettiBurst(progress: _confettiController),
            ),
          ),
      ],
    );
  }
}
