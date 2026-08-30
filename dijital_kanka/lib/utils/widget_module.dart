/// Ana ekran widget'ı sunulan modüller — bkz. CLAUDE.md "Ana Ekran
/// Widget'ları" bölümü. Her değer, Flutter tarafının [dataKeyPrefix] ile
/// `HomeWidget.saveWidgetData`'ya yazdığı anahtar önekini VE Android
/// tarafındaki (bkz. `android/app/src/main/kotlin/.../widgets/`)
/// widget provider Kotlin sınıfının adını taşır — ikisi de
/// `home_widget_sync_coordinator.dart`/`home_widget_service.dart`
/// tarafından kullanılıyor, TEK bir yerde eşleniyor ki bu isimler
/// yanlışlıkla birbirinden sapmasın.
///
/// **2026 güncellemesi — beş "basit günlük/checkbox" widget'ı (Hedef
/// Takibi/Rüya Günlüğü/Şükran Günlüğü/Ruh Hali Takibi/Manifest Günlüğü)
/// TAMAMEN KALDIRILDI, kullanıcı isteğiyle — bunlar Profil ekranındaki
/// "İstatistiklerim" dört kategorisiyle örtüşüyordu. Yerlerine
/// [profileStats] geldi (bkz. altta).**
enum ZiboWidgetModule {
  water(dataKeyPrefix: 'water', androidProviderName: 'ZiboWaterWidgetProvider'),
  money(dataKeyPrefix: 'money', androidProviderName: 'ZiboMoneyWidgetProvider'),
  dailyRewards(
    dataKeyPrefix: 'dailyRewards',
    androidProviderName: 'ZiboDailyRewardsWidgetProvider',
  ),
  /// "Zibo'nun Sözü": diğerlerinden FARKLI, ayrı bir native layout/provider
  /// kullanan (bkz. `ZiboMotivationWidgetProvider.kt`,
  /// `res/layout/widget_motivation.xml`) DAHA BÜYÜK, motivasyon
  /// cümlelerini bir `ViewFlipper` ile OTOMATİK döndüren widget.
  motivation(dataKeyPrefix: 'motivation', androidProviderName: 'ZiboMotivationWidgetProvider'),

  /// **2026 yeni özellik — "İstatistiklerim" carousel'i.** Kaldırılan beş
  /// basit widget'ın YERİNE: Profil ekranındaki dört kategoriyi (Para
  /// Yönetimi/Şükür ve Manifest/İstikrar/Öz Saygı ve Sağlık) bir
  /// `ViewFlipper` ile sırayla, animasyonla döndürür — bkz.
  /// `ZiboProfileStatsWidgetProvider.kt`.
  profileStats(
    dataKeyPrefix: 'profileStats',
    androidProviderName: 'ZiboProfileStatsWidgetProvider',
  );

  const ZiboWidgetModule({required this.dataKeyPrefix, required this.androidProviderName});

  /// `HomeWidget.saveWidgetData` çağrılarında `{prefix}_...` anahtarlarını
  /// oluşturmak için — Android tarafındaki karşılık gelen provider'ın
  /// `dataKeyPrefix`'iyle BİREBİR eşleşmeli.
  final String dataKeyPrefix;

  /// `android/app/src/main/AndroidManifest.xml`'deki `<receiver
  /// android:name=".widgets.X">` ile BİREBİR eşleşen SADECE sınıf adı
  /// (paket öneki YOK) — yalnızca dokümantasyon/okunabilirlik için tutuluyor.
  /// `HomeWidget` çağrılarında DOĞRUDAN KULLANILMIYOR, bkz. [qualifiedAndroidName].
  final String androidProviderName;

  /// 2026 bug düzeltmesi — gerçek cihazda bulunan gerçek bug: `home_widget`
  /// paketinin native tarafı `HomeWidget.updateWidget(name:)`/
  /// `requestPinWidget(androidName:)` çağrılarında `Class.forName(
  /// "${context.packageName}.${className}")` kuruyor — yani `androidName`
  /// yalnızca `.widgets.` ALT PAKETİ OLMAYAN düz bir sınıf adı için doğru
  /// çalışıyor. Bizim widget provider'larımız `com.dijitalkanka.dijital_
  /// kanka.widgets.*` alt paketinde olduğu için, `androidName:
  /// 'ZiboWaterWidgetProvider'` vermek native tarafta `com.dijitalkanka.
  /// dijital_kanka.ZiboWaterWidgetProvider`'ı (`.widgets.` OLMADAN, GERÇEKTE
  /// VAR OLMAYAN bir sınıf) aramaya çalışıp `ClassNotFoundException`
  /// fırlatıyordu — bu da `WidgetsScreen`'deki "Ekle" butonunun HER ZAMAN
  /// sessizce başarısız olmasına (`requestPin` → `catch (_) { return
  /// false; }`) yol açıyordu (kullanıcı raporu: "widget eklenmedi").
  /// **Çözüm:** `androidName`/`name` yerine `qualifiedAndroidName` (TAM
  /// nitelikli sınıf adı, `Class.forName` bunu OLDUĞU GİBİ kullanıyor,
  /// hiçbir birleştirme yapmıyor) kullanmak — bkz. `home_widget_service.dart`.
  String get qualifiedAndroidName =>
      'com.dijitalkanka.dijital_kanka.widgets.$androidProviderName';
}
