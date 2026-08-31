import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_state_store.dart';

/// Kullanıcının görünüm tercihini (Açık/Koyu/Sistemi Takip Et) tutan ve
/// kalıcı olarak saklayan tek kaynak. `CloudStateStore` ile kalıcı — [uid]
/// varsa Firestore'a da yazılır, `SharedPreferences` her zaman yerel yedek.
///
/// **2026 güncellemesi — kullanıcı test geri bildirim raporu: "Sistem Teması
/// Desteği" eksik.** Eskiden yalnızca bir `bool isDarkMode` tutuyordu (iki
/// durumlu); artık Flutter'ın KENDİ `ThemeMode` enum'unu (`light`/`dark`/
/// `system`) doğrudan saklıyor — yeni bir özel enum İCAT EDİLMEDİ, `MaterialApp.
/// themeMode` zaten TAM OLARAK bu üç değeri bekliyor ve `system` iken
/// `theme`/`darkTheme` arasında cihazın kendi parlaklığına göre OTOMATİK
/// seçim yapıyor (bkz. `main.dart`'taki `themeMode: themeProvider.themeMode`
/// satırı — HİÇ değişmedi, artık üçüncü değeri de doğru şekilde taşıyor).
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({String? uid}) : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'isDarkMode';

  final CloudStateStore _store;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  /// O ANDA gerçekten koyu mu görünüyor — tercih `system` ise cihazın
  /// GÜNCEL parlaklığına (`PlatformDispatcher.instance.platformBrightness`)
  /// göre çözümleniyor. **Bilinçli basitleştirme:** bu getter `WidgetsBinding
  /// Observer` ile cihaz parlaklığı DEĞİŞİNCE kendiliğinden `notifyListeners()`
  /// TETİKLEMİYOR (bu, `ThemeProvider`'ı — plain `test()` bloklarında hiçbir
  /// binding kurulmadan doğrudan örneklenen bir sınıf olduğu için —
  /// `WidgetsBinding.instance`'a bağımlı kılıp TÜM testlerini "Binding has
  /// not yet been initialized" hatasıyla kırardı, gerçek cihazda ise
  /// `MaterialApp`'in KENDİSİ zaten `themeMode: system` iken sistem
  /// parlaklığını canlı/reaktif olarak takip edip doğru `theme`/`darkTheme`'i
  /// seçiyor — bu getter yalnızca İKİNCİL/dekoratif tüketiciler
  /// (`AnimatedThemeOverlay.isDark`, `home_screen.dart`'taki yıldızlı arka
  /// plan varyantı, `theme_option_card.dart`'taki önizleme rengi) için
  /// kullanılıyor, bunlar zaten BAŞKA bir nedenle [herhangi bir rebuild —
  /// ekran geçişi, dil/tema değişimi, uygulama öne gelmesi] ortaya çıkan
  /// bir SONRAKİ build'de güncel değeri doğru okuyacak, yalnızca kullanıcı
  /// uygulama AÇIKKEN elle OS ayarını değiştirirse çok kısa bir gecikme
  /// yaşanabilir — kabul edilebilir bir ödünleşim.
  bool get isDarkMode => _themeMode == ThemeMode.system
      ? PlatformDispatcher.instance.platformBrightness == Brightness.dark
      : _themeMode == ThemeMode.dark;

  /// İlk yükleme (Firestore/yerel) tamamlandı mı — bkz.
  /// [main.dart]'taki başlangıç yükleme ekranı, `RootScreen`'i göstermeden
  /// önce bunun `true` olmasını bekliyor ki kullanıcı varsayılan (açık)
  /// temadan gerçek tercihe aniden "zıplayan" bir geçiş görmesin.
  bool _isReady = false;
  bool get isReady => _isReady;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // Firestore migrasyonundan ÖNCE bu anahtar altında düz bir bool
      // (`prefs.setBool`) saklanıyordu — `CloudStateStore` yalnızca JSON
      // map okuyabildiği için bu ÇOK ESKİ biçimi burada ayrıca tanıyıp
      // yeni sarmalanmış biçime göç ettiriyoruz (bkz. `GratitudeProvider`
      // ile aynı gerekçeli göç deseni).
      final legacy = await _loadLegacyBool();
      if (legacy != null) {
        data = {'value': legacy};
        await _store.save(data);
      }
    }
    final saved = data?['value'];
    if (saved is bool) {
      // **2026 ÖNCESİ (Sistem Teması eklenmeden önceki) kayıtlı format** —
      // düz bir bool (`true`=koyu, `false`=açık). `system` o zaman hiç
      // yoktu, bu yüzden ikili değeri en yakın karşılığına eşliyoruz.
      _themeMode = saved ? ThemeMode.dark : ThemeMode.light;
    } else if (saved is String) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    }
    _isReady = true;
    notifyListeners();
  }

  Future<bool?> _loadLegacyBool() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _store.save({'value': mode.name});
  }
}
