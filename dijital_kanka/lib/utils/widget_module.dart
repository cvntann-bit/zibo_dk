/// Ana ekran widget'ı sunulan sekiz modül — bkz. CLAUDE.md "Ana Ekran
/// Widget'ları" bölümü. Her değer, Flutter tarafının [dataKeyPrefix] ile
/// `HomeWidget.saveWidgetData`'ya yazdığı anahtar önekini VE Android
/// tarafındaki (bkz. `android/app/src/main/kotlin/.../widgets/`)
/// widget provider Kotlin sınıfının adını taşır — ikisi de
/// `home_widget_sync_coordinator.dart`/`home_widget_service.dart`
/// tarafından kullanılıyor, TEK bir yerde eşleniyor ki sekiz modülün
/// hiçbirinde bu isimler yanlışlıkla birbirinden sapmasın.
enum ZiboWidgetModule {
  goals(dataKeyPrefix: 'goals', androidProviderName: 'ZiboGoalsWidgetProvider'),
  water(dataKeyPrefix: 'water', androidProviderName: 'ZiboWaterWidgetProvider'),
  gratitude(dataKeyPrefix: 'gratitude', androidProviderName: 'ZiboGratitudeWidgetProvider'),
  mood(dataKeyPrefix: 'mood', androidProviderName: 'ZiboMoodWidgetProvider'),
  manifest(dataKeyPrefix: 'manifest', androidProviderName: 'ZiboManifestWidgetProvider'),
  dream(dataKeyPrefix: 'dream', androidProviderName: 'ZiboDreamWidgetProvider'),
  money(dataKeyPrefix: 'money', androidProviderName: 'ZiboMoneyWidgetProvider'),
  dailyRewards(
    dataKeyPrefix: 'dailyRewards',
    androidProviderName: 'ZiboDailyRewardsWidgetProvider',
  ),
  /// 2026 güncellemesi — "Zibo'nun Sözü": diğer sekizinden FARKLI, ayrı bir
  /// native layout/provider kullanan (bkz. `ZiboMotivationWidgetProvider.kt`,
  /// `res/layout/widget_motivation.xml`) DAHA BÜYÜK, motivasyon
  /// cümlelerini gösteren widget — kullanıcının "Zibo'nun motivasyon
  /// cümlelerinin olduğu widget de yapabilirsin... daha büyük widgetler
  /// yapabilirsin" isteği.
  motivation(dataKeyPrefix: 'motivation', androidProviderName: 'ZiboMotivationWidgetProvider');

  const ZiboWidgetModule({required this.dataKeyPrefix, required this.androidProviderName});

  /// `HomeWidget.saveWidgetData` çağrılarında `{prefix}_title` /
  /// `{prefix}_primary` / `{prefix}_secondary` / `{prefix}_progress`
  /// anahtarlarını oluşturmak için — Android tarafında
  /// `ZiboBaseWidgetProvider.dataKeyPrefix` ile BİREBİR eşleşmeli.
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
  /// kanka.widgets.*` alt paketinde olduğu için (bkz. `android/app/src/
  /// main/kotlin/.../widgets/`), `androidName: 'ZiboGoalsWidgetProvider'`
  /// vermek native tarafta `com.dijitalkanka.dijital_kanka.
  /// ZiboGoalsWidgetProvider`'ı (`.widgets.` OLMADAN, GERÇEKTE VAR OLMAYAN
  /// bir sınıf) aramaya çalışıp `ClassNotFoundException` fırlatıyordu —
  /// bu da `WidgetsScreen`'deki "Ekle" butonunun HER ZAMAN sessizce
  /// başarısız olmasına (`requestPin` → `catch (_) { return false; }`)
  /// yol açıyordu (kullanıcı raporu: "widget eklenmedi"). **Çözüm:**
  /// `androidName`/`name` yerine `qualifiedAndroidName` (TAM nitelikli
  /// sınıf adı, `Class.forName` bunu OLDUĞU GİBİ kullanıyor, hiçbir
  /// birleştirme yapmıyor) kullanmak — bkz. `home_widget_service.dart`.
  String get qualifiedAndroidName =>
      'com.dijitalkanka.dijital_kanka.widgets.$androidProviderName';
}
