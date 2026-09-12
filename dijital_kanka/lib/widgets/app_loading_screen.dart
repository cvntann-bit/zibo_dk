import 'package:flutter/material.dart';

/// Uygulama açılışında, kritik provider'lar (bkz. `main.dart` —
/// `ThemeProvider`/`AppThemeProvider`/`LocaleProvider`/`CoinProvider`/
/// `CostumeProvider`'ın `isReady` bayrağı) Firestore/yerel depodan
/// yüklenirken gösterilen markalı geçiş ekranı.
///
/// **Neden gerekli:** Firestore migrasyonundan sonra açılışta `Firebase.
/// initializeApp()` + `signInAnonymously()` + her provider'ın kendi
/// `CloudStateStore.load()` çağrısı asenkron sürdüğü için, `RootScreen`
/// hemen kurulup provider'lar hâlâ varsayılan (boş bakiye, açık tema vb.)
/// değerlerle ilk kare(leri) çizip SONRA gerçek veriye "zıplıyordu" —
/// kullanıcı gerçek bir cihazda bunu "uygulama sıfırlanmış gibi duruyor"
/// diye bildirdi. Bu ekran, o ara durumu gizliyor.
///
/// **Renk seçimi bilinçli olarak `ThemeProvider.isDarkMode`'a DEĞİL,
/// sistemin platform parlaklığına bağlı** — bu ekranın gösterildiği anda
/// `ThemeProvider` henüz yüklenmediği (`isReady == false`) için uygulama içi
/// tercih zaten bilinmiyor. Aynı renkler native Android splash'te de
/// kullanıldı (bkz. `android/app/src/main/res/drawable*/launch_background.
/// xml`) — böylece native splash'ten bu ekrana geçiş görsel olarak kesintisiz
/// (aynı zemin rengi, aynı logo).
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  static const _cream = Color(0xFFFFF8E8);
  static const _darkBackground = Color(0xFF17140F);

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _animationStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `WheelTriggerButton`'daki AYNI desen — sürekli tekrar eden bir
    // animasyon widget mount olduğu sürece asla "settle" olmaz, OS'un
    // "hareketi azalt" tercihine (ve flutter_test'in bunu sabitleyebilmesine)
    // burada da saygı duyuluyor.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion && _animationStarted) {
      _animationStarted = false;
      _controller.stop();
    } else if (!reduceMotion && !_animationStarted) {
      _animationStarted = true;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final background =
        isDark ? AppLoadingScreen._darkBackground : AppLoadingScreen._cream;

    return ColoredBox(
      color: background,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = 1.0 + (_controller.value * 0.06);
            final opacity = 0.75 + (_controller.value * 0.25);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: Image.asset(
            'assets/images/zibo_logo_new.webp',
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
