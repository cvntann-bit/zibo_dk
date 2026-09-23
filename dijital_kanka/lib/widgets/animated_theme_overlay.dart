import 'package:flutter/material.dart';

import '../models/app_theme_option.dart';
import '../utils/tab_navigation.dart';
import 'theme_particle_effect.dart';

/// [child]'ın üzerine, aktif temanın [animationType]'ına göre hafif bir
/// parçacık animasyonu (kar/galaksi/konfeti) bindirir — Mağaza > Temalar >
/// "Premium/Animasyonlu" bölümünden satın alınıp uygulanan temaların renk
/// paleti/arka planı (bkz. `ColorScheme` uygulaması, `main.dart`) TÜM
/// sayfalarda tutarlı kalırken, HAREKETLİ parçacık katmanı BİLEREK yalnızca
/// Ana Sayfa'da gösteriliyor (2026 güncellemesi — kullanıcı isteği: "diğer
/// sayfalarda dikkat dağıtmasın, performansı gereksiz zorlamasın"; bkz. altta
/// `isHomeTabActive`). `main.dart`'taki `MaterialApp.builder:` zincirinde
/// `ThemeFadeOverlay`'in İÇİNE sarılıyor (bkz. o dosyadaki "her sayfayı
/// saran tek bir widget" deseni) — böylece tema değişince fade "perdesi"
/// parçacıkları da kapsar, ani bir belirme/kaybolma olmaz.
class AnimatedThemeOverlay extends StatefulWidget {
  const AnimatedThemeOverlay({
    super.key,
    required this.animationType,
    required this.isDark,
    required this.child,
  });

  final ThemeAnimationType animationType;
  final bool isDark;
  final Widget child;

  @override
  State<AnimatedThemeOverlay> createState() => _AnimatedThemeOverlayState();
}

class _AnimatedThemeOverlayState extends State<AnimatedThemeOverlay>
    with SingleTickerProviderStateMixin {
  // `late final ... = AnimationController(...)` alan başlatıcısı olarak
  // YAZILMADI BİLEREK — `animationType == none` iken `build()`/
  // `_syncRunningState()` `_controller`'a HİÇ dokunmuyor (bkz. altta), bu
  // yüzden "late" bir alan ilk kez `dispose()` içinde erişilip AynI ANDA
  // başlatılırdı — `vsync: this` bu noktada zaten deaktif olan context'in
  // `TickerMode`'unu aramaya çalışıp "Looking up a deactivated widget's
  // ancestor is unsafe" hatası fırlatırdı (testte yakalandı). Bunun yerine
  // `initState()`'te HER ZAMAN erkenden, koşulsuz oluşturuluyor.
  late final AnimationController _controller;

  // Uzun bir döngü süresi (24sn) — parçacıklar YAVAŞ, göz yormayan bir
  // hızda hareket etsin diye (bkz. ThemeParticleEffect'in painter'larındaki
  // `speed` çarpanları, bu sürenin İÇİNDE bir/birkaç tam döngü tamamlıyor).
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    // Ana Sayfa'dan başka bir sekmeye geçildiğinde/geri dönüldüğünde
    // (bkz. tab_navigation.dart) katmanı göster/gizle + controller'ı
    // durdur/başlat kararını yeniden değerlendir.
    isHomeTabActive.addListener(_syncRunningState);
  }

  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRunningState();
  }

  @override
  void didUpdateWidget(covariant AnimatedThemeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRunningState();
  }

  // WheelTriggerButton/ZFloatingButton'daki AYNI desen: OS'in "hareketi
  // azalt" erişilebilirlik tercihine (ve flutter_test'in `pumpAndSettle()`
  // sonsuza dek beklememesi için bunu sabitleyebilmesine) saygı duy — aksi
  // halde sürekli tekrar eden bir `AnimationController` testleri askıda
  // bırakırdı. **2026 güncellemesi:** artık ayrıca `isHomeTabActive`'e de
  // bakıyor — Ana Sayfa'dan başka bir sekmedeyken (performans + dikkat
  // dağıtmama isteği) controller'ı tamamen durduruyor, yalnızca `build()`'de
  // katmanı gizlemekle yetinmiyor.
  void _syncRunningState() {
    final active = widget.animationType != ThemeAnimationType.none;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final shouldRun = active && !reduceMotion && isHomeTabActive.value;
    if (shouldRun && !_running) {
      _running = true;
      _controller.repeat();
    } else if (!shouldRun && _running) {
      _running = false;
      _controller.stop();
    }
    // `isHomeTabActive` değişimi bir `ValueNotifier` dinleyicisinden geliyor,
    // `build()`'i otomatik tetiklemez — katmanın görünürlüğünü güncellemek
    // için elle `setState` gerekiyor.
    //
    // **Bug düzeltmesi — Crashlytics'te tekrarlayan ("Regressed issue",
    // 1.7.2–1.10.8) çökme.** Bu dinleyici SENKRON tetikleniyor: örneğin
    // `FocusTimerScreen.dispose()` kendi `isHomeTabActive.value`'sini geri
    // yüklerken (bkz. o dosya), bu BAŞKA widget'ın unmount edilme sürecinin
    // TAM ORTASINDA (bir frame'in `SchedulerBinding._handleDrawFrame`'i
    // içinde, widget ağacı "kilitliyken") çalışıyordu — o anda doğrudan
    // `setState()` çağırmak "setState() or markNeedsBuild() called when
    // widget tree was locked" hatasıyla çöküyordu (`mounted` `true` olsa
    // bile, ağacın o anki kilitli durumunu KONTROL ETMİYOR). `addPostFrame
    // Callback` ile çağrıyı bir SONRAKİ frame'e ertelemek — resmi Flutter
    // deseni — görünür bir gecikme yaratmadan bu çakışmayı ortadan
    // kaldırıyor.
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    isHomeTabActive.removeListener(_syncRunningState);
    _controller.dispose();
    super.dispose();
  }

  // **Faz 6 KRİTİK bug düzeltmesi — Crashlytics'te "tema değiştirince/başka
  // bir ekran açılınca çöküyor" olarak bildirilen `_dependents.isEmpty`
  // assertion'ı.** Bu widget `main.dart`'ta `MaterialApp.builder:`
  // seviyesinde, UYGULAMANIN TAMAMININ (Navigator dahil) ÜSTÜNDE oturuyor.
  // Eskiden `animationType == none || !isHomeTabActive.value` iken
  // `widget.child`'ı DOĞRUDAN (bir `Stack`'in dışında, `build()`'in tek
  // sonucu olarak), aksi halde AYNI `widget.child`'ı bir `Stack`'in İLK
  // ELEMANI olarak döndürüyordu — `widget.child`'ın ağaçtaki DERİNLİĞİ
  // (slot'u) bu iki durum arasında DEĞİŞİYORDU. Flutter'ın element
  // uzlaştırması bunu "aynı alt ağaç, yeri değişti" olarak DEĞİL, "eski
  // silinsin, yeni yerine kurulsun" olarak ele alıyor — `widget.child`
  // TÜM UYGULAMA (Navigator, tüm route'lar, tüm Provider'ların Inherited
  // element'leri) olduğu için bu YIKIM/YENİDEN-KURMA sırasında bazı
  // Inherited element'lerin `_dependents` listesi düzgün temizlenmeden
  // unmount ediliyor. **Düzeltme:** `build()` ARTIK HER ZAMAN AYNI YAPIYI
  // (her zaman bir `Stack`, `widget.child` HER ZAMAN 0. eleman) döndürüyor
  // — yalnızca parçacık katmanının VAR OLUP OLMADIĞI değişiyor, bu
  // `widget.child`'ın derinliğini/element kimliğini HİÇ ETKİLEMiyor.
  @override
  Widget build(BuildContext context) {
    final showParticles =
        widget.animationType != ThemeAnimationType.none &&
        isHomeTabActive.value;
    return Stack(
      children: [
        widget.child,
        // Dokunuşları ALTINDAKİ gerçek içeriğe geçirmesi ZORUNLU — bu salt
        // dekoratif bir katman, hiçbir buton/kart tıklamasını engellememeli.
        if (showParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ThemeParticleEffect(
                  key: const Key('themeParticleEffect'),
                  type: widget.animationType,
                  progress: _controller,
                  isDark: widget.isDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
