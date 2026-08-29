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
  );

  const ZiboWidgetModule({required this.dataKeyPrefix, required this.androidProviderName});

  /// `HomeWidget.saveWidgetData` çağrılarında `{prefix}_title` /
  /// `{prefix}_primary` / `{prefix}_secondary` / `{prefix}_progress`
  /// anahtarlarını oluşturmak için — Android tarafında
  /// `ZiboBaseWidgetProvider.dataKeyPrefix` ile BİREBİR eşleşmeli.
  final String dataKeyPrefix;

  /// `android/app/src/main/AndroidManifest.xml`'deki `<receiver
  /// android:name=".widgets.X">` ile BİREBİR eşleşmeli — `HomeWidget.
  /// updateWidget(name: ...)`/`requestPinWidget(name: ...)` çağrılarında
  /// kullanılıyor.
  final String androidProviderName;
}
