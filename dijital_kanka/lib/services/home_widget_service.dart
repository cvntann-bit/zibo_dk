import 'package:home_widget/home_widget.dart';

import '../utils/widget_module.dart';

/// [HomeWidgetService.pushCarousel] için tek bir "sayfa" — hem "Zibo'nun
/// Sözü" (yalnızca [value] dolu, düz bir söz metni) hem "İstatistiklerim"
/// (dördü de dolu: [label] kategori adı, [value] formatlanmış puan/oran,
/// [progress] ilerleme çubuğu yüzdesi, [hasData] o kategoride hiç veri
/// olup olmadığı) TARAFINDAN paylaşılan tek bir veri şekli — bkz.
/// `ZiboMotivationWidgetProvider.kt`/`ZiboProfileStatsWidgetProvider.kt`'nin
/// AYNI `{prefix}_item{i}_*` anahtar desenini okuyan Kotlin tarafı.
class CarouselItem {
  const CarouselItem({required this.value, this.label, this.progress, this.hasData = true});

  /// Sayfanın ana metni — motivasyon sözünün kendisi VEYA bir istatistik
  /// kategorisinin formatlanmış değeri (ör. "7.2/10").
  final String value;

  /// Yalnızca kategori bazlı carousel'lerde (İstatistiklerim) dolu —
  /// motivasyon sözlerinde `null` bırakılır, native taraf boş göndermeyi
  /// "etiket satırı YOK" olarak yorumlar.
  final String? label;

  /// 0-100 arası bir ilerleme çubuğu yüzdesi, yoksa `null` (İstatistiklerim
  /// dışındaki tüm carousel'lerde `null`).
  final int? progress;

  /// `false` ise (yalnızca İstatistiklerim'de bir kategori hiç kullanılmamış
  /// olabilir) native taraf [value] yerine "—" gösterir.
  final bool hasData;
}

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

  /// **2026 — carousel/`ViewFlipper` widget'ları için** ("Zibo'nun Sözü" +
  /// "İstatistiklerim", bkz. CLAUDE.md "Ana Ekran Widget'ları" bölümü).
  /// [items] boşsa native taraf tek sayfalık güvenli bir "—" durumuna
  /// düşer (Kotlin provider'ların kendi güvenlik ağı, bkz. o dosyalar).
  Future<void> pushCarousel(ZiboWidgetModule module, {required String title, required List<CarouselItem> items});

  /// Kullanıcıdan [module]'ün widget'ını ana ekranına EKLEMESİNİ ister
  /// (Android 8+, yalnızca bazı launcher'larda desteklenir). Sistem
  /// desteklemiyorsa veya istek reddedilirse `false` döner — arayüz bu
  /// durumda kullanıcıyı "ana ekrana uzun bas" akışına yönlendirmeli.
  Future<bool> requestPin(ZiboWidgetModule module);

  /// **2026 yeni özellik — widget derin bağlantısı.** Uygulama SOĞUK
  /// başlangıçta bir widget'a dokunularak açıldıysa hangi modülün
  /// widget'ına dokunulduğunu döner (`null` = normal açılış, widget'tan
  /// GELMEDİ). Yalnızca BİR KEZ, uygulama ömrü boyunca ilk sorulduğunda
  /// anlamlı bir değer taşır — bkz. `home_widget` paketinin kendi
  /// `initiallyLaunchedFromHomeWidget()` dokümantasyonu.
  Future<ZiboWidgetModule?> initialLaunchModule();

  /// Uygulama ZATEN AÇIKKEN (ön/arka planda) bir widget'a dokunulduğunda
  /// modülü yayınlayan akış — `null` = alakasız/parse edilemeyen bir olay,
  /// yok sayılabilir. `RootScreen` bunu dinleyip `_handleWidgetModuleTap`
  /// ile doğru ekrana/sekmeye yönlendiriyor.
  Stream<ZiboWidgetModule?> get moduleClicked;
}

/// `zibowidget://open/<dataKeyPrefix>` biçimindeki bir URI'yi (bkz.
/// `ZiboBaseWidgetProvider.kt`/`ZiboMotivationWidgetProvider.kt`/
/// `ZiboProfileStatsWidgetProvider.kt`'nin ÜÇÜNÜN de kullandığı AYNI
/// şema) [ZiboWidgetModule]'e çevirir — eşleşme yoksa (şema farklı, yol
/// segmenti hiçbir `dataKeyPrefix`'e uymuyor, `uri` `null`) `null` döner.
ZiboWidgetModule? _moduleFromWidgetUri(Uri? uri) {
  if (uri == null || uri.scheme != 'zibowidget' || uri.pathSegments.isEmpty) {
    return null;
  }
  final segment = uri.pathSegments.last;
  for (final module in ZiboWidgetModule.values) {
    if (module.dataKeyPrefix == segment) return module;
  }
  return null;
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
      // sessizce yut — NotificationService/AppodealAdService'teki AYNI "bir
      // platform kanalı hatası uygulamanın geri kalanını ETKİLEMEMELİ"
      // felsefesi.
    }
  }

  @override
  Future<void> pushCarousel(
    ZiboWidgetModule module, {
    required String title,
    required List<CarouselItem> items,
  }) async {
    try {
      final prefix = module.dataKeyPrefix;
      await HomeWidget.saveWidgetData<String>('${prefix}_title', title);
      await HomeWidget.saveWidgetData<int>('${prefix}_itemCount', items.length);
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await HomeWidget.saveWidgetData<String>('${prefix}_item${i}_value', item.value);
        await HomeWidget.saveWidgetData<String>('${prefix}_item${i}_label', item.label ?? '');
        await HomeWidget.saveWidgetData<int>('${prefix}_item${i}_progress', item.progress ?? -1);
        await HomeWidget.saveWidgetData<int>('${prefix}_item${i}_hasData', item.hasData ? 1 : 0);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: module.qualifiedAndroidName);
    } catch (_) {
      // Bkz. pushStatus'taki AYNI gerekçe.
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

  @override
  Future<ZiboWidgetModule?> initialLaunchModule() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return _moduleFromWidgetUri(uri);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ZiboWidgetModule?> get moduleClicked =>
      HomeWidget.widgetClicked.map(_moduleFromWidgetUri);
}
