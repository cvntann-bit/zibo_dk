import 'package:home_widget/home_widget.dart';

import '../utils/widget_module.dart';

/// Ana ekran widget'larıyla iletişim soyutlaması — `AdService`/
/// `NotificationService` ile AYNI desen (gerçek implementasyon +
/// testte enjekte edilen sahte, bkz. CLAUDE.md "Ana Ekran Widget'ları"
/// bölümü). `home_widget` paketi bir platform kanalı kullandığı için
/// `flutter_test`'te doğrudan kullanılamaz.
abstract class HomeWidgetService {
  /// [module]'ün widget'ına güncel durumu yazıp native tarafı yeniden
  /// çizmeye zorlar. Kullanıcı o widget'ı hiç ana ekranına eklemediyse
  /// bu çağrı zararsızdır (Android'de eşleşen `appWidgetId` olmadığı için
  /// `onUpdate` hiç tetiklenmez, veri yalnızca gelecekte eklenirse diye
  /// depoda bekler).
  Future<void> pushStatus(
    ZiboWidgetModule module, {
    required String title,
    required String primary,
    required String secondary,
    int? progress,
  });

  /// Kullanıcıdan [module]'ün widget'ını ana ekranına EKLEMESİNİ ister
  /// (Android 8+, yalnızca bazı launcher'larda desteklenir). Sistem
  /// desteklemiyorsa veya istek reddedilirse `false` döner — arayüz bu
  /// durumda kullanıcıyı "ana ekrana uzun bas" akışına yönlendirmeli.
  Future<bool> requestPin(ZiboWidgetModule module);
}

/// Gerçek implementasyon — `home_widget` paketinin `HomeWidget` statik
/// API'sine ince bir sarmalayıcı.
class HomeWidgetPluginService implements HomeWidgetService {
  const HomeWidgetPluginService();

  @override
  Future<void> pushStatus(
    ZiboWidgetModule module, {
    required String title,
    required String primary,
    required String secondary,
    int? progress,
  }) async {
    try {
      final prefix = module.dataKeyPrefix;
      await HomeWidget.saveWidgetData<String>('${prefix}_title', title);
      await HomeWidget.saveWidgetData<String>('${prefix}_primary', primary);
      await HomeWidget.saveWidgetData<String>('${prefix}_secondary', secondary);
      await HomeWidget.saveWidgetData<int>('${prefix}_progress', progress ?? -1);
      // `name:`/`androidName:` DEĞİL — bkz. `ZiboWidgetModule.
      // qualifiedAndroidName` dokümantasyonundaki 2026 bug düzeltmesi.
      await HomeWidget.updateWidget(qualifiedAndroidName: module.qualifiedAndroidName);
    } catch (_) {
      // Eklenti kullanılamıyorsa (desteklenmeyen platform, ilk açılışın
      // çok erken bir anı vb.) veya kullanıcı bu widget'ı hiç eklemediyse
      // sessizce yut — NotificationService/AdMobAdService'teki AYNI "bir
      // platform kanalı hatası uygulamanın geri kalanını ETKİLEMEMELİ"
      // felsefesi.
    }
  }

  @override
  Future<bool> requestPin(ZiboWidgetModule module) async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
      if (!supported) return false;
      // `androidName:` DEĞİL — bkz. `ZiboWidgetModule.qualifiedAndroidName`
      // dokümantasyonundaki 2026 bug düzeltmesi.
      await HomeWidget.requestPinWidget(qualifiedAndroidName: module.qualifiedAndroidName);
      return true;
    } catch (_) {
      return false;
    }
  }
}
