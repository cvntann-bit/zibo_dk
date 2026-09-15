import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/costume_poses.dart';
import '../data/costumes.dart';
import '../data/focus_quotes.dart';
import '../l10n/app_localizations.dart';
import '../providers/costume_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/xp_provider.dart';
import '../providers/zibo_pose_provider.dart';
import '../utils/address_term.dart';
import '../utils/info_dialog.dart';
import '../utils/tab_navigation.dart';
import '../widgets/dot_grid_background.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/sticker_style.dart';
import '../widgets/zibo_animated_image.dart';

enum _FocusMode { free, min15, min25, min45 }

/// Odak Sayacı (Kronometre/Pomodoro) modülü — kullanıcı bir süre belirleyip
/// (15/25/45 dakika, geri sayım) veya serbest bir kronometre olarak
/// odaklanma sürelerini takip edebilir.
///
/// **2026 güncellemesi — çalışırken ekran TAMAMEN KARANLIK/immersive.**
/// Kullanıcı isteği: "başladığında ekran kapkaranlık olsun sadece sayaç
/// gözüksün, dikkat dağıtıcı hiçbir şey olmasın" — bu yüzden `build()`
/// `_isRunning`'e göre TAMAMEN FARKLI iki görünüme dallanıyor:
/// [_buildSetupView] (mod seçici + "Başlat", normal tema renkleriyle) ve
/// [_buildImmersiveView] (düz siyah zemin, yalnızca parlayan bir halka +
/// sayaç + altında soluk bir "Bitir" metni — mod seçici/toplam süre kartı
/// gibi HİÇBİR ŞEY görünmüyor). Bu tasarımda "Duraklat" BİLEREK KALDIRILDI —
/// oturum ya çalışıyor ya bitmiş, ara durum yok; kullanıcının minimalist
/// isteğiyle tutarlı.
class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  _FocusMode _mode = _FocusMode.free;
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  // Kurulum ekranındaki Zibo konuşma balonu — diğer 7 modülle AYNI "5
  // saniyede bir rastgele söz" deseni (bkz. `focus_quotes.dart`). Karanlık
  // moda geçince görünmüyor ama zamanlayıcı basitlik için kesintisiz
  // çalışmaya devam ediyor — `setState` o build dalında hiçbir görsel
  // etkisi olmadığı için zararsız.
  final _random = Random();
  int _quoteIndex = 0;
  Timer? _quoteTimer;

  /// Karanlık/immersive mod tam olarak "dikkat dağıtıcı hiçbir şey olmasın"
  /// isteğini karşılasın diye, bu ekranın ömrü boyunca `isHomeTabActive`
  /// (bkz. tab_navigation.dart) BİLEREK `false`'a sabitleniyor. **Neden
  /// gerekli:** Ana Sayfa'da aktif bir Premium/Animasyonlu tema varsa
  /// (bkz. `AnimatedThemeOverlay`), o parçacık katmanı yalnızca sekme
  /// GEÇİŞLERİNDE (`RootScreen._setSelectedIndex`) güncellenen bu bayrağa
  /// bakıyor — bir ekran PUSH etmek bayrağı DEĞİŞTİRMEZ (CLAUDE.md
  /// "Premium/Animasyonlu temalar" bölümündeki dokümante edilmiş bilinen
  /// sınırlama), yani Ana Sayfa'dan açılan bu ekranın ÜSTÜNE kar/galaksi/
  /// konfeti gibi bir efekt çizilmeye devam edebilirdi — tam da bu ekranın
  /// önlemeye çalıştığı türden bir dikkat dağınıklığı. Çıkışta ESKİ değere
  /// geri dönülüyor (Ana Sayfa'daysa efekt kaldığı yerden devam eder).
  bool? _previousHomeTabActive;

  int? get _targetSeconds => switch (_mode) {
    _FocusMode.free => null,
    _FocusMode.min15 => 15 * 60,
    _FocusMode.min25 => 25 * 60,
    _FocusMode.min45 => 45 * 60,
  };

  @override
  void initState() {
    super.initState();
    _previousHomeTabActive = isHomeTabActive.value;
    isHomeTabActive.value = false;
    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (_) => _showNewQuote());
  }

  void _showNewQuote() {
    if (!mounted) return;
    setState(() {
      final quotes = focusQuotesForLocale(Localizations.localeOf(context));
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

  void _start() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      final target = _targetSeconds;
      if (target != null && _elapsedSeconds >= target) {
        _finish();
      }
    });
  }

  void _finish() {
    _ticker?.cancel();
    final duration = _elapsedSeconds;
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
    });
    final l10n = AppLocalizations.of(context)!;
    final saved = context.read<FocusProvider>().addSession(duration);
    if (saved) {
      // Kazanılan XP, odaklanılan dakika kadar (en az 1, en fazla 60 —
      // tek bir oturumun aşırı büyük bir seviye atlamasına yol açmasın
      // diye üst sınır, bkz. CLAUDE.md "Level/XP Sistemi" bölümü).
      final minutes = (duration / 60).floor().clamp(1, 60);
      context.read<XpProvider>().addXp(minutes);
      showInfoDialog(context, l10n.focusSessionSavedMessage(minutes));
    } else {
      showInfoDialog(context, l10n.focusSessionTooShortMessage);
    }
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _quoteTimer?.cancel();
    isHomeTabActive.value = _previousHomeTabActive ?? true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isRunning ? _buildImmersiveView(context) : _buildSetupView(context);
  }

  Widget _buildSetupView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final totalSeconds = context.watch<FocusProvider>().totalFocusSeconds;
    final locale = Localizations.localeOf(context);
    final quotes = focusQuotesForLocale(locale);
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

    return Scaffold(
      appBar: plainStickerAppBar(context, title: l10n.focusTimerScreenTitle),
      body: Stack(
        children: [
          const Positioned.fill(child: DotGridBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Column(
                  children: [
                    ZiboAnimatedImage(
                      imageKey: const Key('ziboFocusImage'),
                      costumeId: equippedId,
                      poseStep: poseStep,
                      fallbackImage: equippedImageAsset,
                      height: 200,
                      semanticLabel: l10n.ziboImagePlaceholder,
                    ),
                    const SizedBox(height: 14),
                    SpeechBubble(message: quote),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ModeChip(
                      label: l10n.focusModeFreeLabel,
                      selected: _mode == _FocusMode.free,
                      onSelected: () => setState(() => _mode = _FocusMode.free),
                    ),
                    _ModeChip(
                      label: l10n.focusModeMinutesLabel(15),
                      selected: _mode == _FocusMode.min15,
                      onSelected: () => setState(() => _mode = _FocusMode.min15),
                    ),
                    _ModeChip(
                      label: l10n.focusModeMinutesLabel(25),
                      selected: _mode == _FocusMode.min25,
                      onSelected: () => setState(() => _mode = _FocusMode.min25),
                    ),
                    _ModeChip(
                      label: l10n.focusModeMinutesLabel(45),
                      selected: _mode == _FocusMode.min45,
                      onSelected: () => setState(() => _mode = _FocusMode.min45),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Mockup'ın "gauge" — Profil'in `CircularScoreGauge`'ıyla AYNI
                // görsel dil (kalın sabit kontur + iç "zımba" dairesi). Gerçek
                // bir `CircularProgressIndicator` DEĞİL — kurulum ekranında
                // ilerleme HER ZAMAN sıfır olduğu için (henüz başlamadı),
                // dolan bir halkanın burada gösterilecek bir anlamı yok;
                // gerçek dolum yalnızca (değişmeyen) karanlık moddaki
                // `_GlowRing`'de oluyor.
                Center(
                  child: Container(
                    width: 216,
                    height: 216,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerLowest,
                      border: Border.all(color: kStickerOutline, width: 10),
                    ),
                    child: Container(
                      width: 176,
                      height: 176,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerLowest,
                        border: Border.all(color: kStickerOutline, width: 3),
                      ),
                      child: Text(
                        _formatTimer(0),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 36,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                stickerButtonShadow(
                  radius: 14,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: stickerFilledButtonStyle(context, radius: 14, fontSize: 15),
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.focusStartButton),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                StickerCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.focusTotalTimeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatTimer(totalSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kullanıcının açık isteği — çalışırken TAMAMEN siyah, yalnızca parlayan
  /// bir halka + sayaç + altında soluk bir "Bitir" metni. `SystemUiOverlayStyle.
  /// light` ile durum çubuğu ikonları da (saat/pil vb.) açık renge dönüyor —
  /// siyah zeminle doğal bir bütünlük oluşturuyor, ekstra bir "immersive
  /// mode" (sistem çubuklarını tamamen gizleme) KULLANILMADI — geri
  /// dönüşü/çıkış akışını karmaşıklaştırma riskini almamak için bilinçli bir
  /// sınırlama.
  Widget _buildImmersiveView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = _targetSeconds;
    final progress = target == null
        ? null
        : (_elapsedSeconds / target).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlowRing(
                progress: progress,
                color: _immersiveAccentColor,
                size: 240,
                child: _FadingTimerText(
                  text: _formatTimer(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: _finish,
                child: Opacity(
                  opacity: 0.4,
                  child: Text(
                    l10n.focusFinishButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Karanlık moddaki halka/sayaç rengi — aktif temadan (`colorScheme.primary`)
/// BİLEREK BAĞIMSIZ, sabit bir Zibo altın tonu. Gerekçe: bu ekran çalışırken
/// zemin HER ZAMAN düz siyah (temadan bağımsız) olduğu için, rengin de
/// temaya göre değişmesi (ör. bir Premium temanın parçacık rengiyle
/// karışması/çarpışması) tutarsız görünürdü — `Zibo ADS` banner'ının "aktif
/// temadan bağımsız sabit marka rengi" felsefesiyle AYNI karar.
const _immersiveAccentColor = Color(0xFFE8B44A);

/// Sayaç metnindeki HER değişiklikte (saniye/dakika farketmez) yumuşak bir
/// fade geçişi — kullanıcının açık isteği. `AnimatedSwitcher`'ın varsayılan
/// `transitionBuilder`'ı zaten tam olarak bir `FadeTransition`, bu yüzden
/// ekstra bir builder YAZILMADI — `ValueKey(text)` her saniye/dakika
/// değişiminde widget'ı "yeni" saydırıp geçişi tetikliyor.
class _FadingTimerText extends StatelessWidget {
  const _FadingTimerText({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Text(text, key: ValueKey(text), style: style),
    );
  }
}

/// Dairesel ilerleme göstergesinin ETRAFINA hafif bir "parlama" (glow) halkası
/// ekleyen sarmalayıcı — kullanıcının "yuvarlak sayacın içinde dolan renkli
/// şey biraz parlama efekti" isteği. Gerçek bir shader/blur efekti YERİNE
/// (bu ölçekte gereksiz maliyetli), rengin kendisiyle bulanık bir `BoxShadow`
/// halesi — ucuz ve yeterince inandırıcı.
class _GlowRing extends StatelessWidget {
  const _GlowRing({
    required this.progress,
    required this.color,
    required this.size,
    required this.child,
  });

  final double? progress;
  final Color color;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 24,
            height: size - 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            // Serbest modda bir HEDEF (dolayısıyla bir "ilerleme oranı")
            // olmadığı için `progress` `null` geliyor — `CircularProgressIndicator
            // (value: null)` Material'ın VARSAYILAN belirsiz (indeterminate)
            // döngüsüne düşer (sürekli hızlı dönen bir yay). Kullanıcı
            // isteğiyle bu KALDIRILDI — Serbest modda sabit/durağan, DÖNMEYEN
            // dolu bir halka (renkli border) çiziliyor; yalnızca belirli
            // süreli modlarda (`progress != null`) gerçek ilerlemeyi
            // gösteren dolan halka kullanılıyor.
            child: progress == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 10),
                    ),
                  )
                : CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Mod seçici pilli — mockup'ın `.mode-chip`/`.mode-chip.on` (bkz.
/// `docs/theme_new.md`): seçili olan altın dolgu + hafif sticker gölgesi
/// alır, diğerleri düz kalır.
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surfaceContainerLowest,
            border: Border.all(color: kStickerOutline, width: 2.5),
            borderRadius: radius,
            boxShadow: selected
                ? const [BoxShadow(color: kStickerOutline, offset: Offset(2, 2))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: 13,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
