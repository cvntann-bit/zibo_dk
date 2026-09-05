import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('tr'),
  ];

  /// Uygulamanın adı
  ///
  /// In tr, this message translates to:
  /// **'Zibo'**
  String get appTitle;

  /// Başlık çubuğundaki Zibo logosu için erişilebilirlik (ekran okuyucu) etiketi
  ///
  /// In tr, this message translates to:
  /// **'Zibo'**
  String get homeAppBarTitle;

  /// Başlık çubuğundaki coin bakiyesi rozetinin erişilebilirlik (ekran okuyucu) etiketi
  ///
  /// In tr, this message translates to:
  /// **'{count} Zibo Coin'**
  String coinBalanceLabel(int count);

  /// Kullanıcı bakiyesi yetmeyen bir harcama denediğinde gösterilen uyarı metni
  ///
  /// In tr, this message translates to:
  /// **'Yetersiz Zibo Coin'**
  String get insufficientCoins;

  /// Zibo görseli için erişilebilirlik (ekran okuyucu) etiketi
  ///
  /// In tr, this message translates to:
  /// **'Zibo'**
  String get ziboImagePlaceholder;

  /// Konuşma balonunun altında gösterilen, Zibo'ya dokunulabileceğini belirten küçük ipucu metni
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir söz için Zibo\'ya dokun'**
  String get tapZiboHint;

  /// Alt gezinme çubuğunda Ana Sayfa sekmesinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get tabHome;

  /// Alt gezinme çubuğunda Hedef Takibi sekmesinin erişilebilirlik etiketi ve sekmenin üst başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hedef Takibi'**
  String get tabGoalTracking;

  /// Alt gezinme çubuğunun kendi görselinde (açık tema) veya üzerine çizilen metinde (koyu tema) görünen KISA Hedef Takibi etiketi — tabGoalTracking'den farklı olarak yalnızca bar içindeki dar sütuna sığması için kısaltılmış
  ///
  /// In tr, this message translates to:
  /// **'Hedefler'**
  String get bottomBarGoalsLabel;

  /// Alt gezinme çubuğunda Ayarlar sekmesinin etiketi ve Ayarlar sekmesinin üst başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get tabSettings;

  /// Bir hedefin güncel 7 günlük döngüde kaç gün işaretlendiğini gösteren metin
  ///
  /// In tr, this message translates to:
  /// **'{completed}/7 gün'**
  String goalProgressLabel(int completed);

  /// Bugüne karşılık gelen, işaretlenebilir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, bugün'**
  String goalDayToday(int day);

  /// İşaretlenmiş bir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, tamamlandı'**
  String goalDayDone(int day);

  /// Tarihi geçmiş ama işaretlenmemiş bir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, kaçırıldı'**
  String goalDayMissed(int day);

  /// Tarihi henüz gelmemiş, kilitli bir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, henüz açılmadı'**
  String goalDayUpcoming(int day);

  /// Bir hedefin 7 günlük döngüsü tamamlanıp coin ödülü verildiğinde gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Harika! 7 günlük hedefi tamamladın, +50 Zibo Coin kazandın.'**
  String get goalCycleCompleted;

  /// Bir veya daha fazla hedefin, kaçırılan bir gün yüzünden döngüsü sıfırlandığında gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'{goalNames} hedefinde bir gün kaçırıldı, seri sıfırlandı. Bugünden yeniden başlıyoruz.'**
  String goalStreakReset(String goalNames);

  /// Yeni bir hedef eklemek için gösterilen butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hedef Ekle'**
  String get addGoalButton;

  /// Yeni hedef ekleme diyalog kutusunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hedef'**
  String get addGoalDialogTitle;

  /// Yeni hedef ekleme diyalog kutusundaki metin alanının örnek (hint) metni
  ///
  /// In tr, this message translates to:
  /// **'ör. Günde 30 dakika kitap oku'**
  String get addGoalDialogHint;

  /// Bir hedef kartındaki silme ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Hedefi sil'**
  String get deleteGoalTooltip;

  /// Hedefler sekmesindeyken başlık çubuğunda görünen, Tamamlanan Hedefler ekranını açan ikonun ipucu
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan Hedefler'**
  String get completedGoalsButtonTooltip;

  /// Tamamlanan Hedefler ekranının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan Hedefler'**
  String get completedGoalsScreenTitle;

  /// Hiç tamamlanan döngü olmadığında Tamamlanan Hedefler ekranında gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanan bir hedef yok. İlk 7 günlük döngünü tamamlayınca burada görünecek!'**
  String get completedGoalsEmpty;

  /// Her tamamlanan 7 günlük döngü kaydının yanındaki rozet metni
  ///
  /// In tr, this message translates to:
  /// **'1 haftalık tamamlama'**
  String get completedGoalsBadgeLabel;

  /// Bir hedef grubunun kaç kez tamamlandığını gösteren alt başlık
  ///
  /// In tr, this message translates to:
  /// **'{count} tamamlama'**
  String completedGoalsGroupCount(int count);

  /// Tamamlanan bir döngünün başlangıç-bitiş tarih aralığı
  ///
  /// In tr, this message translates to:
  /// **'{start} – {end}'**
  String completedGoalsDateRange(String start, String end);

  /// Ayarlar listesindeki dil seçimi satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// Ayarlar listesindeki 'Uygulama Hakkında' bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Hakkında'**
  String get settingsAbout;

  /// ARTIK KULLANILMIYOR (bkz. settingsAppearance) — 2026 güncellemesiyle koyu/açık anahtarı yerini üç seçenekli (Açık/Koyu/Sistem) bir seçiciye bıraktı, silinmedi (proje convansiyonu)
  ///
  /// In tr, this message translates to:
  /// **'Koyu Tema'**
  String get settingsDarkTheme;

  /// 2026 — Ayarlar listesindeki görünüm (açık/koyu/sistem) satırının başlığı VE seçim sheet'inin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// Görünüm seçicisindeki 'Açık tema' seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeModeLight;

  /// Görünüm seçicisindeki 'Koyu tema' seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeModeDark;

  /// Görünüm seçicisindeki 'cihazın sistem temasını takip et' seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Sistemi Takip Et'**
  String get settingsThemeModeSystem;

  /// Ayarlar listesindeki uygulama içi ses efektleri (ör. Zibo dokunma sesi) anahtarının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ses Efektleri'**
  String get settingsSoundEffects;

  /// Ayarlar listesindeki 'Genel' bölüm başlığı (koyu tema/dil/bildirimler)
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get settingsSectionGeneral;

  /// Ayarlar listesindeki 'Destek' bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get settingsSectionSupport;

  /// Ayarlar listesindeki 'Push Bildirimleri' (FCM) bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Push Bildirimleri'**
  String get settingsSectionPushNotifications;

  /// Push bildirim tercihi: günlük motivasyon sözü
  ///
  /// In tr, this message translates to:
  /// **'Günlük Motivasyon'**
  String get pushNotificationDailyMotivationTitle;

  /// Günlük Motivasyon push bildirim tercihinin açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Her sabah 9-11 arası rastgele bir motivasyon sözü al'**
  String get pushNotificationDailyMotivationSubtitle;

  /// Push bildirim tercihi: streak/hedef hatırlatması
  ///
  /// In tr, this message translates to:
  /// **'Streak Hatırlatması'**
  String get pushNotificationStreakReminderTitle;

  /// Streak Hatırlatması push bildirim tercihinin açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Günü kaçırmak üzereysen akşam hatırlat'**
  String get pushNotificationStreakReminderSubtitle;

  /// Push bildirim tercihi: günlük ödül hatırlatması
  ///
  /// In tr, this message translates to:
  /// **'Günlük Ödül Hatırlatması'**
  String get pushNotificationDailyRewardTitle;

  /// Günlük Ödül Hatırlatması push bildirim tercihinin açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Günlük ödülünü almadıysan öğleden sonra hatırlat'**
  String get pushNotificationDailyRewardSubtitle;

  /// Push bildirim tercihi: geri kazanma bildirimi
  ///
  /// In tr, this message translates to:
  /// **'Seni Özledik'**
  String get pushNotificationReEngagementTitle;

  /// Seni Özledik (geri kazanma) push bildirim tercihinin açıklaması
  ///
  /// In tr, this message translates to:
  /// **'2 gündür uğramadıysan Zibo seni özler'**
  String get pushNotificationReEngagementSubtitle;

  /// Destek bölümündeki, dokununca mail uygulamasını açan satırın başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bize Ulaşın'**
  String get settingsContactUs;

  /// 2026 — Destek bölümündeki, dokununca yıldız puanlama sheet'ini açan satırın başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bizi Puanlayın'**
  String get settingsRateUs;

  /// Bizi Puanlayın satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Play Store\'da yıldız ver, Zibo\'nun gelişmesine yardımcı ol'**
  String get settingsRateUsSubtitle;

  /// Yıldız puanlama sheet'inin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'yu Seviyor musun?'**
  String get rateUsSheetTitle;

  /// Yıldız puanlama sheet'indeki açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Yıldızlara dokun, Play Store\'da bizi değerlendir!'**
  String get rateUsSheetSubtitle;

  /// Hakkında bölümündeki uygulama sürüm numarası satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get settingsVersion;

  /// Hakkında bölümündeki, dokununca web sitesini açan satırın başlığı
  ///
  /// In tr, this message translates to:
  /// **'Web Sitesi'**
  String get settingsWebsite;

  /// Hakkında bölümündeki Gizlilik Politikası satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get settingsPrivacyPolicy;

  /// Hakkında bölümündeki Kullanım Koşulları satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get settingsTermsOfService;

  /// Gizlilik Politikası/Kullanım Koşulları yer tutucu sayfasının gövde metni
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik yakında burada olacak.'**
  String get settingsLegalPlaceholderBody;

  /// Mail/web sitesi linki açılamadığında gösterilen kısa hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Açılamadı, lütfen tekrar deneyin.'**
  String get settingsCouldNotOpenLink;

  /// Alt gezinme çubuğunda Para ve Birikim sekmesinin erişilebilirlik etiketi (sekmeye dokunma/geçiş testleri buna dayanır) — ekranda görünen başlık için bkz. moneyScreenTitle
  ///
  /// In tr, this message translates to:
  /// **'Para ve Birikim'**
  String get tabMoney;

  /// Alt gezinme çubuğunun kendi görselinde (açık tema) veya üzerine çizilen metinde (koyu tema) görünen KISA Para ve Birikim etiketi — tabMoney'den farklı olarak yalnızca bar içindeki dar sütuna sığması için kısaltılmış
  ///
  /// In tr, this message translates to:
  /// **'Birikim'**
  String get bottomBarMoneyLabel;

  /// Z butonu modül menüsündeki Para ve Birikim kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Harcama, birikim ve gelen paranı takip et'**
  String get moneyModuleDescription;

  /// Para ve Birikim sayfasında ekranın kendi içinde görünen büyük başlık (2026 güncellemesi: eskiden tabMoney ile aynıydı, artık ayrı — modül adı kullanıcı isteğiyle değişti)
  ///
  /// In tr, this message translates to:
  /// **'Harcamalar ve Birikimler'**
  String get moneyScreenTitle;

  /// Para ve Birikim sayfasındaki harcamalar kategorisinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Harcamalar'**
  String get moneyExpenses;

  /// Para ve Birikim sayfasındaki birikimler kategorisinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Birikimler'**
  String get moneySavings;

  /// Para ve Birikim sayfasındaki gelen para (maaş, ek gelir vb.) kategorisinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Gelen Para'**
  String get moneyIncome;

  /// Sayfanın en altındaki harcama/birikim trend grafiği bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Durum'**
  String get moneyTrendSectionTitle;

  /// Trend grafiğinde gösterilecek hiç harcama/birikim kaydı yokken gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Trend grafiği için henüz yeterli veri yok. Harcama veya birikim ekleyince burada görünecek.'**
  String get moneyTrendEmpty;

  /// Trend grafiğindeki kırmızı (harcama) çizginin lejant etiketi
  ///
  /// In tr, this message translates to:
  /// **'Harcama'**
  String get moneyTrendExpenseLegend;

  /// Trend grafiğindeki yeşil (birikim) çizginin lejant etiketi
  ///
  /// In tr, this message translates to:
  /// **'Birikim'**
  String get moneyTrendSavingLegend;

  /// Trend grafiğinin sağ üstündeki periyot seçicide 'günlük' seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get moneyTrendGranularityDaily;

  /// Trend grafiğinin sağ üstündeki periyot seçicide 'haftalık' seçeneği
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get moneyTrendGranularityWeekly;

  /// Bir kategoride hiç kayıt yokken gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıt yok'**
  String get moneyEmptyCategory;

  /// Bir kategoriye yeni kayıt eklemek için gösterilen butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get moneyAddEntryButton;

  /// Yeni kayıt ekleme diyalog kutusunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kayıt'**
  String get moneyAddEntryTitle;

  /// Mevcut bir kaydı düzenleme diyalog kutusunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kaydı Düzenle'**
  String get moneyEditEntryTitle;

  /// Yeni kayıt ekleme diyalog kutusundaki ad alanının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get moneyEntryNameHint;

  /// Yeni kayıt ekleme diyalog kutusundaki tutar alanının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get moneyEntryAmountHint;

  /// 2026 — kayıt ekleme/düzenleme diyalog kutusundaki kayda özel para birimi seçicisinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get moneyEntryCurrencyLabel;

  /// Bir para kaydının yanındaki silme ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Kaydı sil'**
  String get moneyDeleteEntryTooltip;

  /// Para ve Birikim AppBar'ındaki para birimi seçme ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Para birimi'**
  String get moneyCurrencyTooltip;

  /// Para birimi seçim sayfasının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi Seç'**
  String get moneyCurrencyPickerTitle;

  /// Bir kategorideki kayıtların toplam tutarını gösteren metin
  ///
  /// In tr, this message translates to:
  /// **'Toplam: {amount}'**
  String moneyCategoryTotal(String amount);

  /// Başlık çubuğunda coin bakiyesinin yanındaki, Mağaza'yı açan '+' ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Coin satın al'**
  String get storeButtonTooltip;

  /// Alt gezinme çubuğunda Mağaza sekmesinin etiketi ve Mağaza sekmesinin üst başlığı
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get storeTitle;

  /// Mağaza sayfasında reklamsız deneyim satın alma bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız Zibo'**
  String get storeAdFreeSectionTitle;

  /// Mağaza'daki kalıcı 'Reklamsız Zibo' satın alma kartının başlığı — 'Zibo ADS' tanıtım sheet'inin kendi başlığından (aynı metni testte ayırt edebilmek için) BİLEREK FARKLI
  ///
  /// In tr, this message translates to:
  /// **'Reklamları Kaldır'**
  String get storeAdFreeCardTitle;

  /// Mağaza'daki kalıcı 'Reklamsız Zibo' satın alma kartının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Tüm reklamları kalıcı olarak kapat'**
  String get storeAdFreeCardSubtitle;

  /// Mağaza sayfasında satın alınabilir coin paketleri bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Coin Paketleri'**
  String get storePackagesSectionTitle;

  /// Bir coin paketinin miktarını gösteren kısa etiket
  ///
  /// In tr, this message translates to:
  /// **'{amount} ZC'**
  String storeCoinAmount(int amount);

  /// Gerçek fiyat henüz bağlanmamış bir paketin satın alma butonunun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Satın Al'**
  String get storeBuyButton;

  /// Mağaza sayfasında reklam izleyerek coin kazanma bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get storeFreeSectionTitle;

  /// Reklam izleyerek coin kazanma kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Reklam İzle'**
  String get storeWatchAdTitle;

  /// Reklam izleyerek kazanılacak coin miktarını açıklayan alt metin
  ///
  /// In tr, this message translates to:
  /// **'{amount} Zibo Coin kazan, tamamen ücretsiz'**
  String storeWatchAdSubtitle(int amount);

  /// Reklam izleme akışını başlatan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'İzle'**
  String get storeWatchAdButton;

  /// Günlük reklam karşılığı hak (Mağaza'nın Ücretsiz kartı VEYA Şans Çarkı) tükendiğinde gösterilen mesaj — ikisi de aynı metni paylaşıyor
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü hakların bitti, yarın tekrar gel!'**
  String get dailyAdLimitReachedMessage;

  /// Bir satın alma veya reklam ödülü tamamlanıp coin eklendiğinde gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'{amount} Zibo Coin hesabına eklendi!'**
  String storeCoinsAdded(int amount);

  /// Gerçek bir Play Billing satın alma başarısız olduğunda (iptal, ödeme hatası, ürün mağazada henüz aktif değil vb.) gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı. Lütfen tekrar dene.'**
  String get storePurchaseFailedMessage;

  /// Bir Zibo sözünün yanındaki paylaş ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Bu sözü paylaş'**
  String get shareButtonTooltip;

  /// Ana Sayfa'daki konuşma balonunun yanındaki kalp ikonunun, söz henüz favorilenmemişken erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Bu sözü favorile'**
  String get favoriteQuoteAddTooltip;

  /// Ana Sayfa'daki konuşma balonunun yanındaki kalp ikonunun, söz zaten favorilenmişken erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get favoriteQuoteRemoveTooltip;

  /// Paylaşım kartı önizleme sayfasının (bottom sheet) başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibonu Paylaş'**
  String get shareSheetTitle;

  /// Paylaşım kartındaki gradyan arka plan seçicisinin üstündeki küçük etiket
  ///
  /// In tr, this message translates to:
  /// **'Arka plan'**
  String get shareBackgroundLabel;

  /// Paylaşım kartındaki yazı tipi/renk seçicisinin üstündeki küçük etiket
  ///
  /// In tr, this message translates to:
  /// **'Yazı Stili'**
  String get shareTextStyleLabel;

  /// Paylaşım kartını native paylaşım sayfasına gönderen butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get shareActionButton;

  /// Görsel oluşturma veya native paylaşım sayfasını açma başarısız olduğunda gösterilen uyarı
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım başlatılamadı, tekrar dener misin?'**
  String get shareErrorMessage;

  /// Mağaza sayfasındaki iki segmentten 'coin satın al' segmentinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'Coin Al'**
  String get storeCoinsTabLabel;

  /// Mağaza sayfasındaki iki segmentten 'kostümler' segmentinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kostümler'**
  String get storeCostumesTabLabel;

  /// zibo_hippi kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Hippi Zibo'**
  String get costumeNameZiboHippi;

  /// zibo_sporcu kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Sporcu Zibo'**
  String get costumeNameZiboSporcu;

  /// zibo_asker kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Asker Zibo'**
  String get costumeNameZiboAsker;

  /// zibo_hoca kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Hoca Zibo'**
  String get costumeNameZiboHoca;

  /// zibo_punk kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Punk Zibo'**
  String get costumeNameZiboPunk;

  /// zibo_rapci kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Rapçi Zibo'**
  String get costumeNameZiboRapci;

  /// zibo_gladyator kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Gladyatör Zibo'**
  String get costumeNameZiboGladyator;

  /// zibo_korsan kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Korsan Zibo'**
  String get costumeNameZiboKorsan;

  /// zibo_zombi kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Zombi Zibo'**
  String get costumeNameZiboZombi;

  /// zibo_altin kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Altın Zibo'**
  String get costumeNameZiboAltin;

  /// zibo_elmas kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Elmas Kaplama Zibo'**
  String get costumeNameZiboElmas;

  /// zibo_gentleman kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Centilmen Zibo'**
  String get costumeNameZiboGentleman;

  /// zibo_samurai kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Samuray Zibo'**
  String get costumeNameZiboSamurai;

  /// zibo_cyborg kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Siborg Zibo'**
  String get costumeNameZiboCyborg;

  /// zibo_astronot kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Astronot Zibo'**
  String get costumeNameZiboAstronot;

  /// zibo_king kostümünün görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Kral Zibo'**
  String get costumeNameZiboKing;

  /// Satın alınmış ama şu an giyili olmayan bir kostüm kartındaki rozet
  ///
  /// In tr, this message translates to:
  /// **'Sahip olunan'**
  String get costumeOwnedBadge;

  /// Şu an Ana Sayfa'da giyili olan kostümün kartındaki rozet
  ///
  /// In tr, this message translates to:
  /// **'Giyili'**
  String get costumeEquippedBadge;

  /// Bir kostüm satın alma tamamlandığında gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'{name} satın alındı!'**
  String costumePurchasedMessage(String name);

  /// Henüz satın alınmamış bir kostüm kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name}, kilitli, {price} Zibo Coin'**
  String costumeLockedSemanticLabel(String name, int price);

  /// Sahip olunan ama giyili olmayan bir kostüm kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name} giy'**
  String costumeEquipSemanticLabel(String name);

  /// Şu an giyili olan kostüm kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name} çıkar'**
  String costumeUnequipSemanticLabel(String name);

  /// Kilitli bir kostüm kartında, seri (streak) ile ücretsiz açma ilerlemesi
  ///
  /// In tr, this message translates to:
  /// **'🎯 {current}/{target} gün seri ile ücretsiz aç'**
  String costumeUnlockViaStreak(int current, int target);

  /// Kilitli bir kostüm kartında, tamamlanan hedef sayısıyla ücretsiz açma ilerlemesi
  ///
  /// In tr, this message translates to:
  /// **'🎯 {current}/{target} hedef tamamlayarak ücretsiz aç'**
  String costumeUnlockViaCompletions(int current, int target);

  /// Kilitli bir kostüm kartında, su takibi gün sayısıyla ücretsiz açma ilerlemesi
  ///
  /// In tr, this message translates to:
  /// **'🎯 {current}/{target} gün su takibiyle ücretsiz aç'**
  String costumeUnlockViaWater(int current, int target);

  /// Mağaza'ya girildiğinde bir/birden fazla kostüm hedefle otomatik açılınca gösterilen SnackBar
  ///
  /// In tr, this message translates to:
  /// **'🎉 {name} hedefini tamamlayarak ücretsiz açtın!'**
  String costumeUnlockedViaGoalMessage(String name);

  /// Mağaza sayfasındaki üç segmentten 'temalar' segmentinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'Temalar'**
  String get storeThemesTabLabel;

  /// Zibo ADS (reklamsız deneyim) mockup tanıtım sheet'inin kırmızı banner'ındaki ana başlık
  ///
  /// In tr, this message translates to:
  /// **'Zibo ADS'**
  String get adFreePromoTitle;

  /// Zibo ADS banner'ındaki alt başlık
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız Deneyim'**
  String get adFreePromoSubtitle;

  /// Zibo ADS tanıtımındaki fayda maddelerinden biri
  ///
  /// In tr, this message translates to:
  /// **'Reklam yok'**
  String get adFreePromoBenefitNoAds;

  /// Zibo ADS tanıtımındaki fayda maddelerinden biri
  ///
  /// In tr, this message translates to:
  /// **'Kesintisiz kullanım'**
  String get adFreePromoBenefitUninterrupted;

  /// Zibo ADS tanıtımındaki fayda maddelerinden biri
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'ya destek ol'**
  String get adFreePromoBenefitSupport;

  /// Zibo ADS tanıtımındaki (henüz gerçek işlem yapmayan mockup) satın alma butonu
  ///
  /// In tr, this message translates to:
  /// **'Satın Al'**
  String get adFreePromoBuyButton;

  /// Zibo ADS tanıtımını kapatan buton
  ///
  /// In tr, this message translates to:
  /// **'Belki Sonra'**
  String get adFreePromoDismissButton;

  /// Zibo ADS 'Satın Al' butonuna basılınca gösterilen mockup mesajı
  ///
  /// In tr, this message translates to:
  /// **'Yakında! Reklamsız deneyim çok yakında sunulacak.'**
  String get adFreePromoComingSoon;

  /// sunset temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Gün Batımı'**
  String get themeNameSunset;

  /// ocean temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Okyanus'**
  String get themeNameOcean;

  /// forest temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Orman'**
  String get themeNameForest;

  /// night_sky temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Gece Gökyüzü'**
  String get themeNameNightSky;

  /// golden_age temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Altın Çağ'**
  String get themeNameGoldenAge;

  /// winter_snow (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Kış Teması'**
  String get themeNameWinterSnow;

  /// galaxy_stars (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Galaksi'**
  String get themeNameGalaxyStars;

  /// party_confetti (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Parti Konfeti'**
  String get themeNamePartyConfetti;

  /// hearts_love (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Kalpli Tema'**
  String get themeNameHeartsLove;

  /// music_notes (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Nota Teması'**
  String get themeNameMusicNotes;

  /// tropical_paradise (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Tropikal Tema'**
  String get themeNameTropicalParadise;

  /// cherry_blossom (Premium/Animasyonlu) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Çiçekli Tema'**
  String get themeNameCherryBlossom;

  /// lavender_garden (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Lavanta Bahçesi'**
  String get themeNameLavenderGarden;

  /// coral_reef (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Mercan Resifi'**
  String get themeNameCoralReef;

  /// cherry_orchard (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Vişne Bahçesi'**
  String get themeNameCherryOrchard;

  /// mint_greens (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Nane Yeşillikleri'**
  String get themeNameMintGreens;

  /// desert_dunes (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Çöl Kumulları'**
  String get themeNameDesertDunes;

  /// moonlight (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Ay Işığı'**
  String get themeNameMoonlight;

  /// copper_hills (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Bakır Tepeler'**
  String get themeNameCopperHills;

  /// emerald_valley (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Zümrüt Vadisi'**
  String get themeNameEmeraldValley;

  /// amethyst_cave (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Ametist Mağarası'**
  String get themeNameAmethystCave;

  /// dusty_rose_dream (standart) temasının görünen adı
  ///
  /// In tr, this message translates to:
  /// **'Gül Kurusu Rüyası'**
  String get themeNameDustyRoseDream;

  /// Mağaza > Temalar segmentindeki statik (animasyonsuz) temalar bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Standart Temalar'**
  String get storeThemesStandardSectionTitle;

  /// Mağaza > Temalar segmentindeki hareketli (parçacık animasyonlu) temalar bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Premium / Animasyonlu'**
  String get storeThemesPremiumSectionTitle;

  /// Premium/Animasyonlu bölüm başlığının altındaki açıklayıcı alt metin
  ///
  /// In tr, this message translates to:
  /// **'Ekranında hafif bir hareket efekti olan özel temalar'**
  String get storeThemesPremiumSectionSubtitle;

  /// Satın alınmış ama şu an aktif olmayan bir tema kartındaki rozet
  ///
  /// In tr, this message translates to:
  /// **'Sahip olunan'**
  String get themeOwnedBadge;

  /// Şu an uygulanmış (aktif) temanın kartındaki rozet
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get themeActiveBadge;

  /// Bir tema satın alma tamamlandığında gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'{name} teması satın alındı!'**
  String themePurchasedMessage(String name);

  /// Henüz satın alınmamış bir tema kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name} teması, kilitli, {price} Zibo Coin'**
  String themeLockedSemanticLabel(String name, int price);

  /// Sahip olunan ama aktif olmayan bir tema kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name} temasını uygula'**
  String themeApplySemanticLabel(String name);

  /// Şu an aktif olan tema kartının erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{name} temasını kaldır'**
  String themeRemoveSemanticLabel(String name);

  /// Ekranın sol kenarındaki sürekli görünen Şans Çarkı tetikleyicisinin erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Şans Çarkı'**
  String get wheelTriggerTooltip;

  /// Şans Çarkı popup'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Şans Çarkı'**
  String get wheelTitle;

  /// Çarkın tam ortasındaki, reklam izleyip çarkı çeviren butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Reklam İzle\nve Çevir'**
  String get wheelSpinButton;

  /// Şans Çarkı popup'ını kapatan X ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get wheelCloseTooltip;

  /// Çark döndükten sonra açılan kutlama diyaloğunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler!'**
  String get wheelResultTitle;

  /// Çark döndükten sonra kazanılan ödülü bildiren mesaj
  ///
  /// In tr, this message translates to:
  /// **'{amount} Zibo Coin kazandın!'**
  String wheelResultMessage(int amount);

  /// Kutlama diyaloğunu kapatan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get wheelResultButton;

  /// Ekranın sağ kenarındaki sürekli görünen Günlük Giriş Ödülleri tetikleyicisinin erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Günlük Ödüller'**
  String get dailyRewardsTriggerTooltip;

  /// Günlük Giriş Ödülleri popup'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Günlük Giriş Ödülleri'**
  String get dailyRewardsTitle;

  /// Günlük Giriş Ödülleri popup'ını kapatan X ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get dailyRewardsCloseTooltip;

  /// Bir gün kutucuğunun üstündeki gün numarası etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}'**
  String dailyRewardsDayLabel(int day);

  /// Bugünün ödülü henüz alınmadığında popup'ın üstünde gösterilen durum mesajı
  ///
  /// In tr, this message translates to:
  /// **'Bugünün ödülünü almak için Gün {day} kutusuna dokun: {amount} Zibo Coin!'**
  String dailyRewardsPromptToday(int day, int amount);

  /// Bugünün ödülü zaten alınmışsa popup'ın üstünde gösterilen durum mesajı
  ///
  /// In tr, this message translates to:
  /// **'Bugün {amount} Zibo Coin aldın! Yarın tekrar gel.'**
  String dailyRewardsAlreadyClaimedToday(int amount);

  /// Ödülü zaten alınmış bir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, {amount} Zibo Coin alındı'**
  String dailyRewardsClaimedSemanticLabel(int day, int amount);

  /// Bugüne karşılık gelen, tıklanabilir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day} ödülünü al, {amount} Zibo Coin'**
  String dailyRewardsClaimSemanticLabel(int day, int amount);

  /// Tarihi henüz gelmemiş, kilitli bir gün kutucuğunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}, henüz açılmadı, {amount} Zibo Coin'**
  String dailyRewardsLockedSemanticLabel(int day, int amount);

  /// Ayarlar sayfasındaki bildirim sıklığı/saatleri kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationsSectionTitle;

  /// Bildirim sıklığı seçeneği: bildirim gönderilmez
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get notificationFrequencyOff;

  /// Bildirim sıklığı seçeneği: günde bir kez
  ///
  /// In tr, this message translates to:
  /// **'Günde 1'**
  String get notificationFrequencyOnce;

  /// Bildirim sıklığı seçeneği: günde üç kez
  ///
  /// In tr, this message translates to:
  /// **'Günde 3'**
  String get notificationFrequencyThrice;

  /// Bildirim zaman dilimi etiketi: sabah
  ///
  /// In tr, this message translates to:
  /// **'Sabah'**
  String get notificationSlotMorning;

  /// Bildirim zaman dilimi etiketi: öğlen
  ///
  /// In tr, this message translates to:
  /// **'Öğlen'**
  String get notificationSlotNoon;

  /// Bildirim zaman dilimi etiketi: akşam
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get notificationSlotEvening;

  /// Pil optimizasyonu/otomatik başlatma bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bildirimlerin güvenilir gelmesi için'**
  String get notificationReliabilityTitle;

  /// Uygulama pil optimizasyonundan muaf değilken gösterilen uyarı
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu bildirimleri geciktirebilir'**
  String get notificationBatteryOptimizationWarning;

  /// Uygulama pil optimizasyonundan muafken gösterilen onay metni
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu kapalı'**
  String get notificationBatteryOptimizationOk;

  /// Pil optimizasyonu istisnası isteyen butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get notificationBatteryOptimizationButton;

  /// Otomatik başlatma ayarı satırının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Bazı telefonlarda (Xiaomi, Huawei, Oppo, Vivo gibi) bildirimlerin gelmesi için ayrıca \"otomatik başlatma\" izni gerekir'**
  String get notificationAutostartDescription;

  /// Android'in kullanılmayan uygulama hibernasyonu/izin geri alma ayarını açıklayan metin
  ///
  /// In tr, this message translates to:
  /// **'Telefon, uygulamayı \"kullanılmıyor\" sayıp bildirimleri durdurabilir — bu ayarı da kapatmak gerekebilir'**
  String get notificationUnusedAppsDescription;

  /// Kullanılmayan uygulama ayarını açan buton metni
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get notificationUnusedAppsButton;

  /// Otomatik başlatma ayar ekranını açan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get notificationAutostartButton;

  /// Ana başlık çubuğundaki Rüya Günlüğü ikonunun tooltip'i
  ///
  /// In tr, this message translates to:
  /// **'Rüya Günlüğü'**
  String get dreamJournalTooltip;

  /// Rüya Günlüğü sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Rüya Günlüğü'**
  String get dreamJournalTitle;

  /// Yeni rüya ekleme formunu açan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Yeni Rüya Ekle'**
  String get dreamAddButton;

  /// Hiç rüya kaydı yokken listede gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir rüya yazmadın. Bugün gördüğün bir rüya var mı?'**
  String get dreamEmptyState;

  /// Bir rüya kaydının listede, aynı tarihte olumsuz bir rüya + düşük bir ruh hali kaydı BİRLİKTE bulunduğunda gösterilen ikinci alt metin satırı
  ///
  /// In tr, this message translates to:
  /// **'O gün ruh halin de düşüktü 😔'**
  String get dreamMoodCorrelationNote;

  /// Rüya formundaki başlık alanının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get dreamTitleHint;

  /// Rüya formundaki metin alanının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Rüyanı anlat...'**
  String get dreamTextHint;

  /// Rüya formundaki kaydet butonunun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get dreamSaveButton;

  /// Yeni rüya eklerken form ekranının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Yeni Rüya'**
  String get dreamNewEntryTitle;

  /// Var olan bir rüyayı düzenlerken form ekranının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Rüyayı Düzenle'**
  String get dreamEditEntryTitle;

  /// Rüya formundaki silme ikonunun tooltip'i
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get dreamDeleteEntryTooltip;

  /// Silme onay diyaloğunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Rüyayı sil?'**
  String get dreamDeleteConfirmTitle;

  /// Silme onay diyaloğunun açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Bu rüya kalıcı olarak silinecek.'**
  String get dreamDeleteConfirmBody;

  /// Silme onay diyaloğundaki silme butonunun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get dreamDeleteConfirmButton;

  /// Z butonu modül menüsündeki Şükran Günlüğü kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Şükran Günlüğü'**
  String get gratitudeSettingsTitle;

  /// Şükran Günlüğü sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Şükran Günlüğü'**
  String get gratitudeScreenTitle;

  /// Üç şükran metin alanından birinin etiketi
  ///
  /// In tr, this message translates to:
  /// **'{n}. Şükran cümlen'**
  String gratitudeFieldLabel(int n);

  /// Şükran formundaki kaydet butonunun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get gratitudeSaveButton;

  /// Bugünün kaydı tamamlandığında gösterilen başlık
  ///
  /// In tr, this message translates to:
  /// **'Bugün tamamlandı!'**
  String get gratitudeTodayDoneTitle;

  /// Bugünün kaydı tamamlandığında gösterilen açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'3 şükran cümleni yazdın ve 5 Zibo Coin kazandın. Yarın tekrar gel!'**
  String get gratitudeTodayDoneBody;

  /// Geçmiş şükran kayıtları listesinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Kayıtlar'**
  String get gratitudeHistoryTitle;

  /// Geçmiş kayıt listesi boşken gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanmış bir kayıt yok.'**
  String get gratitudeHistoryEmpty;

  /// Bugünün kaydı kaydedilince gösterilen kısa kutlama mesajı
  ///
  /// In tr, this message translates to:
  /// **'+5 Zibo Coin kazandın!'**
  String get gratitudeCoinRewardMessage;

  /// Geçmiş kayıt detay diyaloğunu kapatan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get gratitudeEntryDetailCloseButton;

  /// Bugünün tamamlanmış kartındaki düzenleme ikonunun tooltip metni
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get gratitudeEditTooltip;

  /// Z butonu modül menüsündeki Ruh Hali Takibi kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Günlük Ruh Hali Takibi'**
  String get moodSettingsTitle;

  /// Ruh Hali Takibi sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Günlük Ruh Hali Takibi'**
  String get moodScreenTitle;

  /// Son 7 günün ruh hali özetinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün'**
  String get moodWeekSummaryTitle;

  /// Tüm geçmiş ruh hali kayıtları listesinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get moodHistoryTitle;

  /// Bugünün ruh haline eşlik eden serbest not alanının ipucu metni
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıl hissettiğini kısaca yazabilirsin (opsiyonel)'**
  String get moodNoteHint;

  /// Geçmiş kayıt listesi boşken gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir kayıt yok.'**
  String get moodHistoryEmpty;

  /// En kötü ruh hali seçeneğinin erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Çok kötü'**
  String get moodLabelVeryUnhappy;

  /// Kötü ruh hali seçeneğinin erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kötü'**
  String get moodLabelUnhappy;

  /// Nötr ruh hali seçeneğinin erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Nötr'**
  String get moodLabelNeutral;

  /// İyi ruh hali seçeneğinin erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'İyi'**
  String get moodLabelHappy;

  /// En iyi ruh hali seçeneğinin erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Çok iyi'**
  String get moodLabelVeryHappy;

  /// Alt gezinme çubuğundaki Z butonunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Ek modülleri aç'**
  String get modulesMenuZButtonTooltip;

  /// Z butonuna basınca açılan modül menüsünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ek Modüller'**
  String get modulesMenuTitle;

  /// Modül menüsündeki Rüya Günlüğü kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Gördüğün rüyaları yaz, geçmişini gör'**
  String get dreamModuleDescription;

  /// Modül menüsündeki Şükran Günlüğü kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Günde 3 şükran cümlesi yaz, Zibo Coin kazan'**
  String get gratitudeModuleDescription;

  /// Modül menüsündeki Ruh Hali Takibi kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ruh halini emoji ile işaretle'**
  String get moodModuleDescription;

  /// Z butonu modül menüsündeki Su Takibi kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get waterSettingsTitle;

  /// Modül menüsündeki Su Takibi kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefini bardak bardak takip et'**
  String get waterModuleDescription;

  /// Su Takibi sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get waterScreenTitle;

  /// Bugün içilen birim sayısı / günlük hedef
  ///
  /// In tr, this message translates to:
  /// **'{count}/{goal} {unit}'**
  String waterProgressLabel(int count, int goal, String unit);

  /// Bugün içilen su miktarı (ml) / günlük hedef (ml)
  ///
  /// In tr, this message translates to:
  /// **'{consumedMl} ml / {goalMl} ml'**
  String waterProgressMl(int consumedMl, int goalMl);

  /// Doldurulmuş bir su birimi ikonunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{index}. {unit}, dolu'**
  String waterGlassFilledLabel(int index, String unit);

  /// Boş bir su birimi ikonunun erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'{index}. {unit}, boş'**
  String waterGlassEmptyLabel(int index, String unit);

  /// Günlük su hedefi tamamlanınca gösterilen kısa kutlama mesajı
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefini tamamladın! +5 Zibo Coin kazandın!'**
  String get waterGoalCompletedMessage;

  /// Hedef tamamlandığında ilerleme kartının altında gösterilen kısa metin
  ///
  /// In tr, this message translates to:
  /// **'Bugün su hedefini tamamladın, harikasın kanka!'**
  String get waterTodayCompleteBody;

  /// Su Takibi ekranındaki hedef düzenleme ikonunun tooltip metni
  ///
  /// In tr, this message translates to:
  /// **'Günlük Su Hedefi'**
  String get waterGoalSettingsTitle;

  /// Su hedefi değiştirme diyaloğunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Günlük Su Hedefi'**
  String get waterGoalDialogTitle;

  /// Su hedefi değiştirme diyaloğunda ortadaki sayaç metni
  ///
  /// In tr, this message translates to:
  /// **'{count} {unit}'**
  String waterGoalDialogUnitCount(int count, String unit);

  /// Su takibi birim seçeneği: bardak
  ///
  /// In tr, this message translates to:
  /// **'bardak'**
  String get waterUnitGlass;

  /// Su takibi birim seçeneği: şişe
  ///
  /// In tr, this message translates to:
  /// **'şişe'**
  String get waterUnitBottle;

  /// Hedef diyaloğunda birim seçici bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get waterUnitSectionLabel;

  /// Hedef diyaloğunda seçili birimin ml değerini ayarlayan alanın etiketi
  ///
  /// In tr, this message translates to:
  /// **'1 {unit} = kaç ml?'**
  String waterMlPerUnitLabel(String unit);

  /// Su Takibi ekranındaki geçmiş kayıtlar bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get waterHistoryTitle;

  /// Geçmiş kaydı hiç olmadığında gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz geçmiş kayıt yok.'**
  String get waterHistoryEmpty;

  /// Hedefin tamamlandığı bir geçmiş günü için satır metni
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde hedef tamamlandı'**
  String waterHistoryCompletedEntry(String date);

  /// Hedefin tamamlanmadığı bir geçmiş günü için satır metni
  ///
  /// In tr, this message translates to:
  /// **'{date}: {count}/{goal}'**
  String waterHistoryPartialEntry(String date, int count, int goal);

  /// Z butonu modül menüsündeki Manifest Günlüğü kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Manifest Günlüğü'**
  String get manifestSettingsTitle;

  /// Modül menüsündeki Manifest Günlüğü kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ve niyetinle günlük vizyon panonu oluştur'**
  String get manifestModuleDescription;

  /// Manifest Günlüğü sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Manifest Günlüğü'**
  String get manifestScreenTitle;

  /// Henüz fotoğraf seçilmemişken fotoğraf alanında gösterilen ipucu metni
  ///
  /// In tr, this message translates to:
  /// **'Bir fotoğraf seç'**
  String get manifestPhotoPickerHint;

  /// Kullanıcının yüklediği fotoğrafın erişilebilirlik (ekran okuyucu) etiketi
  ///
  /// In tr, this message translates to:
  /// **'Yüklenen fotoğraf'**
  String get manifestPhotoSemanticLabel;

  /// Niyet metni alanının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Bugün ne manifest etmek istiyorsun?'**
  String get manifestIntentionHint;

  /// Manifest Günlüğü formundaki kaydet butonunun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get manifestSaveButton;

  /// Bugün zaten tamamlanmışken (coin tekrar verilmeden) tekrar kaydedilince gösterilen kısa mesaj
  ///
  /// In tr, this message translates to:
  /// **'Bugünün girişi kaydedildi.'**
  String get manifestSavedMessage;

  /// Bugünün girişi İLK KEZ tamamlanıp coin kazanılınca gösterilen kısa kutlama mesajı
  ///
  /// In tr, this message translates to:
  /// **'+5 Zibo Coin kazandın!'**
  String get manifestCoinRewardMessage;

  /// Geçmiş manifest kayıtları galerisinin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Kayıtlar'**
  String get manifestHistoryTitle;

  /// Geçmiş kayıt listesi boşken gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir kayıt yok. Bugün ilk vizyonunu ekle!'**
  String get manifestHistoryEmpty;

  /// Geçmiş kayıt detay diyaloğunu kapatan butonun etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get manifestDetailCloseButton;

  /// Profil sayfasının AppBar başlığı ve modül menüsündeki kart başlığı
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileScreenTitle;

  /// Modül menüsündeki Profil kartının açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Fotoğrafını, ismini ve alışkanlık istatistiklerini gör'**
  String get profileModuleDescription;

  /// Profil fotoğrafı alanının erişilebilirlik (ekran okuyucu) etiketi
  ///
  /// In tr, this message translates to:
  /// **'Profil fotoğrafı, değiştirmek için dokun'**
  String get profilePhotoSemanticLabel;

  /// İsim alanı boşken gösterilen ipucu metni
  ///
  /// In tr, this message translates to:
  /// **'İsmini yaz'**
  String get profileNameHint;

  /// Profil sayfasındaki istatistik kartları bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'İstatistiklerim'**
  String get profileStatsSectionTitle;

  /// Para Yönetimi istatistik kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Para Yönetimi'**
  String get profileStatMoneyTitle;

  /// Şükür ve Manifest istatistik kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Şükür ve Manifest'**
  String get profileStatGratitudeManifestTitle;

  /// İstikrar istatistik kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'İstikrar'**
  String get profileStatConsistencyTitle;

  /// Öz Saygı ve Sağlık istatistik kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Öz Saygı ve Sağlık'**
  String get profileStatSelfCareTitle;

  /// Para Yönetimi kartında hiç veri yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok — Para ve Birikim\'i kullanmaya başla!'**
  String get profileStatMoneyEmpty;

  /// Şükür ve Manifest kartında hiç veri yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok — Şükran Günlüğü veya Manifest Günlüğü\'nü kullanmaya başla!'**
  String get profileStatGratitudeManifestEmpty;

  /// İstikrar kartında hiç veri yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok — Hedef Takibi\'ni kullanmaya başla!'**
  String get profileStatConsistencyEmpty;

  /// Öz Saygı ve Sağlık kartında hiç veri yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz veri yok — Su Takibi\'ni kullanmaya başla!'**
  String get profileStatSelfCareEmpty;

  /// Profil sayfasındaki 7 satırlık liste bölümünün başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile Bağın'**
  String get profileBondSectionTitle;

  /// Bağ Seviyesi satırının başlığı VE açtığı sayfanın AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile Bağ Seviyesi'**
  String get bondLevelScreenTitle;

  /// Bağ Seviyesi satırının/sayfasının gün sayısını gösteren alt metni — 'kanka' kelimesi hitap tercihine göre değiştirilir (bkz. applyAddressTerm)
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile {days} gündür kankasın'**
  String profileBondLevelRowSubtitle(int days);

  /// Bağ Seviyesi sayfasında bir sonraki kademeye kaç gün kaldığını gösteren metin
  ///
  /// In tr, this message translates to:
  /// **'{days} gün sonra {tier} olacaksın'**
  String profileBondNextLevelHint(int days, String tier);

  /// Bağ Seviyesi sayfasında kullanıcı en üst kademedeyken (bir sonraki yok) gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Zaten en üst kademedesin, tebrikler!'**
  String get profileBondMaxLevelHint;

  /// Bağ Seviyesi kademesi: 7 günden az
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kanka'**
  String get bondLevelNewBuddy;

  /// Bağ Seviyesi kademesi: 7-29 gün
  ///
  /// In tr, this message translates to:
  /// **'Yakınlaşan Dost'**
  String get bondLevelGettingClose;

  /// Bağ Seviyesi kademesi: 30-89 gün
  ///
  /// In tr, this message translates to:
  /// **'Eski Dost'**
  String get bondLevelOldFriend;

  /// Bağ Seviyesi kademesi: 90-364 gün
  ///
  /// In tr, this message translates to:
  /// **'Can Kanka'**
  String get bondLevelSoulBuddy;

  /// Bağ Seviyesi kademesi: 365+ gün
  ///
  /// In tr, this message translates to:
  /// **'Ömür Boyu Dost'**
  String get bondLevelLifetimeBuddy;

  /// En Uzun Seri satırının başlığı VE açtığı sayfanın AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'En Uzun Seri Rekoru'**
  String get longestStreakScreenTitle;

  /// En Uzun Seri satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'En uzun serin: {days} gün'**
  String profileStreakRowSubtitle(int days);

  /// En Uzun Seri sayfasındaki büyük rakamın altındaki açıklama
  ///
  /// In tr, this message translates to:
  /// **'Hedef Takibi\'ndeki en uzun kesintisiz serin'**
  String get longestStreakScreenSubtitle;

  /// En Uzun Seri sayfasındaki teşvik kartı metni
  ///
  /// In tr, this message translates to:
  /// **'Bu rekoru geçmek için bugün de bir hedefini işaretle!'**
  String get longestStreakEncouragement;

  /// Kostüm Dolabı Önizlemesi satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kostüm Dolabı'**
  String get profileCostumeClosetRowTitle;

  /// Kostüm Dolabı Önizlemesi'nde hiç sahip olunan kostüm yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir kostümün yok — Mağaza\'dan birini seç!'**
  String get profileCostumeClosetEmpty;

  /// Zibo Coin Özeti satırının başlığı VE açtığı sayfanın AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo Coin Özeti'**
  String get coinSummaryScreenTitle;

  /// Coin Özeti sayfasında ömür boyu kazanılan ZC kartının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Toplam Kazanılan'**
  String get coinSummaryTotalEarnedLabel;

  /// Coin Özeti sayfasında ömür boyu harcanan ZC kartının etiketi
  ///
  /// In tr, this message translates to:
  /// **'Toplam Harcanan'**
  String get coinSummaryTotalSpentLabel;

  /// Coin Özeti sayfasındaki bir tutarın gösterimi
  ///
  /// In tr, this message translates to:
  /// **'{amount} ZC'**
  String coinSummaryAmount(int amount);

  /// Profil'deki Zibo Coin Özeti satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Kazanılan {earned} ZC · Harcanan {spent} ZC'**
  String profileCoinSummaryRowSubtitle(int earned, int spent);

  /// Hitap Tercihi satırının başlığı VE açtığı sayfanın AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hitap Tercihi'**
  String get addressTermScreenTitle;

  /// Hitap Tercihi sayfasındaki açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo sana nasıl seslensin? Yazdığın kelime, sözlerinde \"kanka\" geçen yerlerde kullanılır.'**
  String get addressTermScreenDescription;

  /// Hitap Tercihi sayfasındaki serbest metin kutusunun placeholder'ı
  ///
  /// In tr, this message translates to:
  /// **'Zibo sana nasıl seslensin? Örn: Kanka, Reis, Aslanım...'**
  String get addressTermFieldHint;

  /// Profil'deki Hitap Tercihi satırının, o an seçili terimi gösteren alt metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo sana \"{term}\" diyor'**
  String profileAddressTermRowSubtitle(String term);

  /// Favori Sözler satırının başlığı VE açtığı sayfanın AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Favori Sözler'**
  String get favoriteQuotesScreenTitle;

  /// Favori Sözler sayfasında hiç favori yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori sözün yok — Ana Sayfa\'daki kalp ikonuyla sevdiğin sözleri kaydet!'**
  String get favoriteQuotesEmpty;

  /// Ana Sayfa'daki konuşma balonunun yanındaki, özel mesaj ekranını açan ikonun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Kendi mesajını ekle'**
  String get customMessagesButtonTooltip;

  /// Özel mesajlar sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Özel Mesajlarım'**
  String get customMessagesScreenTitle;

  /// Özel mesajlar sayfasının üstündeki açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'nun sana ara sıra söylemesini istediğin kendi cümlelerini ekle — standart sözlerle karışık, rastgele gösterilirler.'**
  String get customMessagesSubtitle;

  /// Özel mesajlar sayfasında hiç mesaj yokken gösterilen teşvik mesajı
  ///
  /// In tr, this message translates to:
  /// **'Henüz özel mesaj eklemedin.'**
  String get customMessagesEmpty;

  /// Özel mesajlar sayfasındaki yeni mesaj ekleme butonu
  ///
  /// In tr, this message translates to:
  /// **'Yeni Mesaj Ekle'**
  String get customMessagesAddButton;

  /// Yeni özel mesaj metin alanının placeholder'ı
  ///
  /// In tr, this message translates to:
  /// **'Zibo bunu sana söylesin...'**
  String get customMessagesFieldHint;

  /// Yeni özel mesaj ekleme diyaloğundaki kaydet butonu
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get customMessagesSaveButton;

  /// Yeni özel mesaj ekleme diyaloğundaki iptal butonu
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get customMessagesCancelButton;

  /// Özel mesaj listesindeki her satırın silme ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get customMessagesDeleteTooltip;

  /// Profil'deki Favori Sözler satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'{count} favori söz'**
  String profileFavoriteQuotesRowSubtitle(int count);

  /// Profil Kartı Paylaşımı satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Profil Kartını Paylaş'**
  String get profileShareCardRowTitle;

  /// Profil Kartı Paylaşımı satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Bağ seviyeni ve istatistiklerini bir kartta paylaş'**
  String get profileShareCardRowSubtitle;

  /// Profil'deki Geçmiş Ay İstatistikleri satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Ay İstatistikleri'**
  String get monthlyStatsRowTitle;

  /// Profil'deki Geçmiş Ay İstatistikleri satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'{count} ay arşivlendi'**
  String monthlyStatsRowSubtitle(int count);

  /// Geçmiş Ay İstatistikleri sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Ay İstatistikleri'**
  String get monthlyStatsScreenTitle;

  /// Geçmiş Ay İstatistikleri sayfasında henüz arşiv yokken gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Henüz arşivlenmiş bir ay yok. İlk ay sonunda burada görünmeye başlayacak.'**
  String get monthlyStatsEmpty;

  /// Paylaşılan profil kartı metninin başlığı (ZiboShareSheet'e geçirilen mesajın ilk satırı)
  ///
  /// In tr, this message translates to:
  /// **'🐣 Zibo ile Bağım'**
  String get profileShareCardTitle;

  /// Onboarding akışının en ilk (dil seçimi) adımının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Hangi dili konuşalım?'**
  String get onboardingLanguageStepTitle;

  /// Onboarding akışının dil seçimi adımının alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın geri kalanı seçtiğin dilde açılacak — istersen sonra Ayarlar\'dan değiştirebilirsin.'**
  String get onboardingLanguageStepSubtitle;

  /// Onboarding akışının ilk (isim) adımının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sana ne diyelim?'**
  String get onboardingNameStepTitle;

  /// Onboarding akışının ilk (isim) adımının alt başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo seninle bu isimle konuşacak — istersen sonra Profil\'den değiştirebilirsin.'**
  String get onboardingNameStepSubtitle;

  /// Onboarding isim adımındaki devam butonu
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get onboardingContinueButton;

  /// Onboarding modül tanıtım adımlarındaki ileri butonu
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get onboardingNextButton;

  /// Onboarding akışını atlayıp doğrudan Ana Sayfa'ya geçen buton
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get onboardingSkipButton;

  /// Onboarding akışının son (kapanış) adımındaki bitirme butonu
  ///
  /// In tr, this message translates to:
  /// **'Hadi Başlayalım!'**
  String get onboardingStartButton;

  /// Onboarding'de Hedef Takibi modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Büyük hayallerini küçük adımlara böl.'**
  String get onboardingGoalsDescription;

  /// Onboarding'de Su Takibi modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Vücuduna verdiğin en küçük sözü bile tutmayı öğren.'**
  String get onboardingWaterDescription;

  /// Onboarding'de Şükran Günlüğü modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Güne, sahip olduklarını hatırlayarak bak.'**
  String get onboardingGratitudeDescription;

  /// Onboarding'de Günlük Ruh Hali Takibi modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Duygularını görmezden gelme, onları takip et.'**
  String get onboardingMoodDescription;

  /// Onboarding'de Rüya Günlüğü modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Bilinçaltının sana ne anlattığını keşfet.'**
  String get onboardingDreamJournalDescription;

  /// Onboarding'de Manifest Günlüğü modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Hayal ettiğin hayatı gözünün önüne seriyorsun.'**
  String get onboardingManifestDescription;

  /// Onboarding'de Mağaza modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Emeğini renklendir, Zibo\'yu kendi tarzınla giydir.'**
  String get onboardingStoreDescription;

  /// Onboarding'de Profil modülünü tanıtan, tek cümlelik 'bu ne işe yarar' açıklaması
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'yla olan bağını ve ilerlemeni tek bakışta gör.'**
  String get onboardingProfileDescription;

  /// Onboarding akışının son (kapanış) adımının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile Yolculuğun Başlıyor!'**
  String get onboardingClosingTitle;

  /// Onboarding akışının son adımındaki, Zibo'nun ağzından motive edici kapanış mesajı
  ///
  /// In tr, this message translates to:
  /// **'Artık hazırsın, {name}! Küçük adımlarla büyük değişimler yaratacağız — hedeflerini takip et, kendine iyi bak, ben hep yanındayım. Hadi başlayalım kanka!'**
  String onboardingClosingMessage(String name);

  /// Profil/Ayarlar'daki Google hesap bağlama satırının başlığı — hesap HENÜZ bağlı değilken
  ///
  /// In tr, this message translates to:
  /// **'Google ile Bağla'**
  String get googleLinkRowTitleUnlinked;

  /// Profil/Ayarlar'daki Google hesap bağlama satırının başlığı — hesap ZATEN bağlıyken
  ///
  /// In tr, this message translates to:
  /// **'Google Hesabın'**
  String get googleLinkRowTitleLinked;

  /// Google hesap bağlama satırının alt metni — hesap bağlı DEĞİLKEN gösterilen teşvik metni
  ///
  /// In tr, this message translates to:
  /// **'Satın alımlarını ve verilerini güvende tut'**
  String get googleLinkRowSubtitle;

  /// Google hesabı bağlama başarılı olunca gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Google hesabına başarıyla bağlandı!'**
  String get googleLinkSuccessMessage;

  /// Google hesabı bağlama beklenmeyen bir hatayla başarısız olunca gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Bağlanırken bir sorun oluştu, tekrar dene.'**
  String get googleLinkFailedMessage;

  /// Seçilen Google hesabı zaten BAŞKA bir Firebase kullanıcısına bağlıyken açılan uyarı diyaloğunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bu hesap başka bir cihaza bağlı'**
  String get googleAlreadyLinkedDialogTitle;

  /// Google hesabı başka bir cihaza bağlıyken açılan uyarı diyaloğunun gövde metni
  ///
  /// In tr, this message translates to:
  /// **'Bu Google hesabı zaten başka bir cihazdaki verilerle ilişkili. O hesaba geçip verilerine ulaşmak istersen, bu cihazdaki mevcut ilerleme kaybolur.'**
  String get googleAlreadyLinkedDialogBody;

  /// Google hesabı başka bir cihaza bağlıyken, o hesaba GEÇMEK için sunulan butonun metni
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş Yap'**
  String get googleSignInInsteadButton;

  /// Yeni cihazda Google ile giriş yapıp eski hesap kurtarıldığında gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Google hesabınla giriş yapıldı, verilerin geri yüklendi!'**
  String get googleSignInSuccessMessage;

  /// Google ile giriş yapma beklenmeyen bir hatayla başarısız olunca gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapılırken bir sorun oluştu, tekrar dene.'**
  String get googleSignInFailedMessage;

  /// Mağaza'da ilk gerçek coin satın alma denemesinde gösterilen Google bağlama teşvik sheet'inin başlığı
  ///
  /// In tr, this message translates to:
  /// **'Satın Alımlarını Güvende Tut'**
  String get googleLinkPromoTitle;

  /// Google bağlama teşvik sheet'inin gövde metni
  ///
  /// In tr, this message translates to:
  /// **'Google hesabınla bağlanırsan, Zibo Coin\'lerin ve tüm ilerlemen cihaz değişse bile kaybolmaz.'**
  String get googleLinkPromoBody;

  /// Google bağlama teşvik sheet'inde bağlamadan devam etmek için sunulan butonun metni — zorunlu değil
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik Atla'**
  String get googleLinkPromoSkipButton;

  /// Ayarlar'da bağlı bir Google hesabından çıkış yapmak için sunulan butonun metni
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get googleSignOutButton;

  /// Ayarlar'da farklı bir Google hesabına geçmek için sunulan butonun metni
  ///
  /// In tr, this message translates to:
  /// **'Hesap Değiştir'**
  String get googleSwitchAccountButton;

  /// Çıkış yapmadan önce sorulan onay diyaloğunun başlığı
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get googleSignOutConfirmTitle;

  /// Çıkış yapmadan önce sorulan onay diyaloğunun gövde metni
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapmak istediğine emin misin? Bu hesaba bağlı verilerin kaybolmaz — aynı Google hesabıyla tekrar giriş yaptığında geri yüklenir.'**
  String get googleSignOutConfirmBody;

  /// Çıkış yapma beklenmeyen bir hatayla başarısız olunca gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapılırken bir sorun oluştu, tekrar dene.'**
  String get googleSignOutFailedMessage;

  /// Davet Et ekranının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşını Davet Et'**
  String get referralScreenTitle;

  /// Profil'deki 'Zibo ile Bağın' listesindeki Davet Et satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşını Davet Et'**
  String get referralRowTitle;

  /// Davet Et satırının, kullanıcı henüz bir kod kullanmamışken gösterilen alt metni
  ///
  /// In tr, this message translates to:
  /// **'Davet et, ikiniz de Zibo Coin kazanın'**
  String get referralRowSubtitle;

  /// Davet Et ekranında kullanıcının kendi kodunun üstündeki etiket, ayrıca kod giriş alanının hint metni
  ///
  /// In tr, this message translates to:
  /// **'Davet Kodun'**
  String get referralCodeLabel;

  /// Davet kodunu panoya kopyalayan buton
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get referralCopyButton;

  /// Kopyala butonuna basınca gösterilen SnackBar mesajı
  ///
  /// In tr, this message translates to:
  /// **'Davet kodu panoya kopyalandı!'**
  String get referralCodeCopiedMessage;

  /// Davet kodunu share_plus ile paylaşan buton
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get referralShareButton;

  /// Davet kodu paylaşılırken gönderilen düz metin mesajı
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'yu deniyorum, sen de katıl! Davet kodum: {code} — Profil > Arkadaşını Davet Et\'ten gir, ikimiz de {amount} Zibo Coin kazanalım! 🎉'**
  String referralShareMessage(String code, int amount);

  /// Kod giriş alanının üstündeki başlık
  ///
  /// In tr, this message translates to:
  /// **'Bir davet kodun var mı?'**
  String get referralRedeemFieldLabel;

  /// Girilen davet kodunu gönderen buton
  ///
  /// In tr, this message translates to:
  /// **'Kullan'**
  String get referralRedeemButton;

  /// Bir davet kodu başarıyla gönderilince (ANINDA kredi değil, arka planda işlenir) gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Kodun gönderildi! Coin\'in kısa süre içinde hesabına eklenecek.'**
  String get referralRedeemSuccessMessage;

  /// Kullanıcı kendi kodunu girmeye çalışınca gösterilen hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Kendi davet kodunu kullanamazsın.'**
  String get referralRedeemSelfCodeError;

  /// Boş bir kod gönderilmeye çalışılınca gösterilen hata mesajı
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir davet kodu gir.'**
  String get referralRedeemInvalidCodeError;

  /// Kullanıcı zaten bir davet kodu kullanmışsa hem Davet Et satırının alt metninde hem ekranın kendisinde gösterilen durum metni
  ///
  /// In tr, this message translates to:
  /// **'Davet kodunu kullandın, teşekkürler!'**
  String get referralAlreadyRedeemedStatus;

  /// uid yokken (Firebase kullanılamıyor) veya ağ hatası olunca gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'Davet sistemi şu an kullanılamıyor, daha sonra tekrar dene.'**
  String get referralUnavailableMessage;

  /// Profil fotoğrafının köşesindeki Kurucu Üye rozetinin tooltip/erişilebilirlik etiketi
  ///
  /// In tr, this message translates to:
  /// **'Kurucu Üye'**
  String get founderBadgeTooltip;

  /// Google hesabına bağlanma satırının üstündeki, henüz bağlanmamış kullanıcılara gösterilen teşvik kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Kurucu Üye Rozeti Kazan'**
  String get founderBadgePromoTitle;

  /// Kurucu Üye teşvik kartının alt metni — kaç hakkın kaldığını canlı gösterir
  ///
  /// In tr, this message translates to:
  /// **'Google hesabını bağlayan ilk 500 kişiden biri ol — {remaining} hak kaldı!'**
  String founderBadgePromoBody(int remaining);

  /// Google hesabı bağlanırken Kurucu Üye kontenjanından bir hak da kazanıldığında, bağlanma başarı mesajının ARDINDAN gösterilen ikinci SnackBar
  ///
  /// In tr, this message translates to:
  /// **'🏅 Kurucu Üye rozetini kazandın!'**
  String get founderBadgeClaimedMessage;

  /// Hedef Takibi ana ekran widget'ının başlığı (widget içinde + Widget'lar ekranındaki satırda)
  ///
  /// In tr, this message translates to:
  /// **'Hedef Takibi'**
  String get widgetTitleGoals;

  /// Su Takibi ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi'**
  String get widgetTitleWater;

  /// Şükran Günlüğü ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Şükran Günlüğü'**
  String get widgetTitleGratitude;

  /// Günlük Ruh Hali Takibi ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ruh Hali Takibi'**
  String get widgetTitleMood;

  /// Manifest Günlüğü ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Manifest Günlüğü'**
  String get widgetTitleManifest;

  /// Rüya Günlüğü ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Rüya Günlüğü'**
  String get widgetTitleDream;

  /// Para ve Birikim ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Para ve Birikim'**
  String get widgetTitleMoney;

  /// Günlük Giriş Ödülleri ana ekran widget'ının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Günlük Giriş Ödülleri'**
  String get widgetTitleDailyRewards;

  /// Zibo'nun Sözü (motivasyon cümleleri) ana ekran widget'ının başlığı (widget içinde + Widget'lar ekranındaki satırda)
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'nun Sözü'**
  String get widgetTitleMotivation;

  /// Profil ekranındaki İstatistiklerim kategorilerini döndüren ana ekran widget'ının başlığı (widget içinde + Widget'lar ekranındaki satırda)
  ///
  /// In tr, this message translates to:
  /// **'İstatistiklerim'**
  String get widgetTitleProfileStats;

  /// Hedef Takibi widget'ında hiç hedef yokken gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz hedef eklenmedi'**
  String get widgetGoalsEmptyHint;

  /// Hedef Takibi widget'ında 'X/Y' sayısının altında gösterilen açıklayıcı alt metin
  ///
  /// In tr, this message translates to:
  /// **'bugün işaretlenen hedef'**
  String get widgetGoalsActiveHint;

  /// Su Takibi widget'ının alt metni — {unit} 'bardak'/'şişe' gibi seçili birim etiketi
  ///
  /// In tr, this message translates to:
  /// **'{unit} · bugün'**
  String widgetWaterHint(String unit);

  /// Şükran Günlüğü widget'ında bugün zaten yazılmışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Bugün tamamlandı'**
  String get widgetGratitudeDoneHint;

  /// Şükran Günlüğü widget'ında bugün henüz yazılmamışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz yazılmadı'**
  String get widgetGratitudeEmptyHint;

  /// Ruh Hali Takibi widget'ında bugün bir seçim yapılmışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü ruh halin'**
  String get widgetMoodSetHint;

  /// Ruh Hali Takibi widget'ında bugün henüz seçim yapılmamışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz seçilmedi'**
  String get widgetMoodEmptyHint;

  /// Manifest Günlüğü widget'ında bugünkü giriş sayısının altında gösterilen açıklayıcı alt metin
  ///
  /// In tr, this message translates to:
  /// **'bugün eklenen giriş'**
  String get widgetManifestActiveHint;

  /// Manifest Günlüğü widget'ında bugün hiç giriş eklenmemişse gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz giriş yok'**
  String get widgetManifestEmptyHint;

  /// Rüya Günlüğü widget'ında toplam kayıt sayısının altında gösterilen açıklayıcı alt metin
  ///
  /// In tr, this message translates to:
  /// **'toplam rüya kaydı'**
  String get widgetDreamActiveHint;

  /// Rüya Günlüğü widget'ında hiç rüya eklenmemişse gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Henüz rüya eklenmedi'**
  String get widgetDreamEmptyHint;

  /// Para ve Birikim widget'ının alt metni — üstteki tutarın bu ayki net (birikim+gelir-harcama) toplamı olduğunu belirtir
  ///
  /// In tr, this message translates to:
  /// **'bu ay net'**
  String get widgetMoneyHint;

  /// Günlük Giriş Ödülleri widget'ında bugünün ödülü zaten alınmışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Bugün alındı ✓'**
  String get widgetDailyRewardsClaimedHint;

  /// Günlük Giriş Ödülleri widget'ında bugünün ödülü henüz alınmamışsa gösterilen alt metin
  ///
  /// In tr, this message translates to:
  /// **'Bugün alınabilir 🎁'**
  String get widgetDailyRewardsAvailableHint;

  /// Günlük Giriş Ödülleri widget'ının ana metni — {day} 1-7 arası güncel gün numarası
  ///
  /// In tr, this message translates to:
  /// **'Gün {day}/7'**
  String widgetDailyRewardsPrimary(int day);

  /// Widget'lar ekranının AppBar başlığı, aynı zamanda Ayarlar'daki giriş satırının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekran Widget\'ları'**
  String get widgetsScreenTitle;

  /// Widget'lar ekranının en üstündeki açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'nun modüllerini ana ekranından tek bakışta takip et. İstediğin modülün yanındaki butona dokunarak ana ekranına ekle.'**
  String get widgetsScreenIntro;

  /// Widget'lar ekranındaki her modül satırının 'ana ekrana ekle' butonu
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get widgetsScreenAddButton;

  /// Widget ekleme isteği başarıyla gönderilince gösterilen SnackBar metni
  ///
  /// In tr, this message translates to:
  /// **'Widget eklendi! Ana ekranını kontrol et.'**
  String get widgetsScreenAddedSuccessMessage;

  /// Widget ekleme isteği desteklenmiyorsa/başarısız olursa gösterilen SnackBar metni
  ///
  /// In tr, this message translates to:
  /// **'Widget eklenemedi — cihazın bu özelliği desteklemiyor olabilir, ana ekranına uzun basıp \"Widget\'lar\" listesinden Zibo\'yu da bulabilirsin.'**
  String get widgetsScreenAddFailedMessage;

  /// Widget ekleme talimatları sheet'inin başlığı — 2026 güncellemesi, `requestPinWidget`'ın bazı cihaz/launcher'larda sessizce tamamlanmaması nedeniyle doğrudan ekleme yerine kılavuz gösteriliyor
  ///
  /// In tr, this message translates to:
  /// **'Ana Ekranına Nasıl Eklenir?'**
  String get widgetsScreenAddSheetTitle;

  /// No description provided for @widgetsScreenAddStep1.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranının boş bir alanına parmağını basılı tut.'**
  String get widgetsScreenAddStep1;

  /// No description provided for @widgetsScreenAddStep2.
  ///
  /// In tr, this message translates to:
  /// **'Açılan menüden \"Widget\'lar\" (bazı cihazlarda \"Araçlar\") seçeneğine dokun.'**
  String get widgetsScreenAddStep2;

  /// No description provided for @widgetsScreenAddStep3.
  ///
  /// In tr, this message translates to:
  /// **'Listede Zibo\'yu bulup istediğin widget\'ı ana ekranına sürükle.'**
  String get widgetsScreenAddStep3;

  /// No description provided for @widgetsScreenAddSheetGotIt.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get widgetsScreenAddSheetGotIt;

  /// Ayarlar'daki 'Ana Ekran Widget'ları' satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Modül durumlarını ana ekranından takip et'**
  String get settingsWidgetsRowSubtitle;

  /// Ana Sayfa'daki Rozetler tetikleyici butonunun tooltip/semantics etiketi
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get badgesTriggerTooltip;

  /// Rozetler Galerisi ekranının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get badgesGalleryTitle;

  /// Rozetler Galerisi'ndeki İstikrar kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'İstikrar Rozetleri'**
  String get badgeCategoryConsistency;

  /// İstikrar Rozetleri'nin ilk rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'İlk Adım'**
  String get badgeNameFirstStep;

  /// İstikrar Rozetleri'nin ikinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'1 Haftalık Seri'**
  String get badgeNameWeekStreak;

  /// İstikrar Rozetleri'nin üçüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'1 Aylık Seri'**
  String get badgeNameMonthStreak;

  /// İstikrar Rozetleri'nin dördüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Demir İrade'**
  String get badgeNameIronWill;

  /// İstikrar Rozetleri'nin beşinci/en yüksek rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Yılmaz'**
  String get badgeNameUnyielding;

  /// İlk Adım rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'İlk 7 günlük hedef döngünü tamamla'**
  String get badgeRequirementFirstStep;

  /// 1 Haftalık Seri rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'7 gün üst üste giriş yap'**
  String get badgeRequirementWeekStreak;

  /// 1 Aylık Seri rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'30 gün üst üste giriş yap'**
  String get badgeRequirementMonthStreak;

  /// Demir İrade rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'90 gün üst üste giriş yap'**
  String get badgeRequirementIronWill;

  /// Yılmaz rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'180 gün üst üste giriş yap'**
  String get badgeRequirementUnyielding;

  /// Rozet kazanma popup'ındaki ödül alma butonu
  ///
  /// In tr, this message translates to:
  /// **'Ödülü Al'**
  String get badgeClaimRewardButton;

  /// Rozetler Galerisi'ndeki Modül Ustalığı kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Modül Ustalığı Rozetleri'**
  String get badgeCategoryModuleMastery;

  /// Modül Ustalığı Rozetleri'nin birinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Şükreden Kalp'**
  String get badgeNameGratefulHeart;

  /// Modül Ustalığı Rozetleri'nin ikinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Su Kahramanı'**
  String get badgeNameWaterHero;

  /// Modül Ustalığı Rozetleri'nin üçüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Ruh Hali Kaydedicisi'**
  String get badgeNameMoodChronicler;

  /// Modül Ustalığı Rozetleri'nin dördüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Birikim Ustası'**
  String get badgeNameSavingsMaster;

  /// Modül Ustalığı Rozetleri'nin beşinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Hayalperest'**
  String get badgeNameDreamer;

  /// Modül Ustalığı Rozetleri'nin altıncı rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Rüya Yorumcusu'**
  String get badgeNameDreamInterpreter;

  /// Şükreden Kalp rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Şükran Günlüğü\'nde toplam 30 kayıt oluştur'**
  String get badgeRequirementGratefulHeart;

  /// Su Kahramanı rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Su Takibi\'nde toplam 30 gün kayıt yap'**
  String get badgeRequirementWaterHero;

  /// Ruh Hali Kaydedicisi rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Ruh Hali Takibi\'nde toplam 30 kayıt oluştur'**
  String get badgeRequirementMoodChronicler;

  /// Birikim Ustası rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Para ve Birikim\'de toplam 20 kayıt oluştur'**
  String get badgeRequirementSavingsMaster;

  /// Hayalperest rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Manifest Günlüğü\'nde toplam 15 kayıt oluştur'**
  String get badgeRequirementDreamer;

  /// Rüya Yorumcusu rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Rüya Günlüğü\'nde toplam 15 kayıt oluştur'**
  String get badgeRequirementDreamInterpreter;

  /// Rozetler Galerisi'ndeki Koleksiyon kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyon Rozetleri'**
  String get badgeCategoryCollection;

  /// Koleksiyon Rozetleri'nin birinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyoncu'**
  String get badgeNameCollector;

  /// Koleksiyon Rozetleri'nin ikinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Moda İkonu'**
  String get badgeNameFashionIcon;

  /// Koleksiyon Rozetleri'nin üçüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Tam Gardırop'**
  String get badgeNameFullWardrobe;

  /// Koleksiyon Rozetleri'nin dördüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Tema Avcısı'**
  String get badgeNameThemeHunter;

  /// Koleksiyoncu rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'5 farklı kostüme sahip ol'**
  String get badgeRequirementCollector;

  /// Moda İkonu rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'10 farklı kostüme sahip ol'**
  String get badgeRequirementFashionIcon;

  /// Tam Gardırop rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Mağazadaki TÜM kostümlere sahip ol'**
  String get badgeRequirementFullWardrobe;

  /// Tema Avcısı rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'3 farklı temaya sahip ol'**
  String get badgeRequirementThemeHunter;

  /// ARTIK KULLANILMIYOR (bkz. badgeSpecialRewardThemeNote) — proje geneli 'kullanılmayan ARB anahtarını silme' konvansiyonuyla dosyada bırakıldı
  ///
  /// In tr, this message translates to:
  /// **'Özel Ödül (Yakında)'**
  String get badgeSpecialRewardComingSoon;

  /// Standart ZC ödülüne ek olarak sahip olunmayan temalardan rastgele birini hediye eden rozetlerin (ör. Tam Gardırop) yanında gösterilen etiket
  ///
  /// In tr, this message translates to:
  /// **'+ Rastgele Bir Tema Hediyesi'**
  String get badgeSpecialRewardThemeNote;

  /// İlk Paylaşım/Hayalperest gibi tema hediyesi taşıyan bir rozet kazanılıp rastgele bir standart tema hediye edildiğinde gösterilen SnackBar metni
  ///
  /// In tr, this message translates to:
  /// **'Özel ödülün: {themeName} teması hediye edildi! 🎁'**
  String badgeSpecialRewardThemeGrantedMessage(String themeName);

  /// Kostüm hediyesi taşıyan bir rozetin (ör. Demir İrade → Sporcu Zibo) kazanma popup'ında (ödül alınmadan önce) VE ödül alındıktan sonraki SnackBar'da gösterilen metin
  ///
  /// In tr, this message translates to:
  /// **'Ayrıca {costumeName} kazandın! 🎁'**
  String badgeGiftCostumeMessage(String costumeName);

  /// Rozetler Galerisi'ndeki kostüm/tema hediyesi önizleme satırının erişilebilirlik (semantics) etiketi
  ///
  /// In tr, this message translates to:
  /// **'Hediye: {itemName}'**
  String badgeGiftPreviewLabel(String itemName);

  /// Rozetler Galerisi'ndeki Sadakat kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sadakat Rozetleri'**
  String get badgeCategoryLoyalty;

  /// Sadakat Rozetleri'nin birinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'İlk Hafta'**
  String get badgeNameFirstWeek;

  /// Sadakat Rozetleri'nin ikinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Sadık Dost'**
  String get badgeNameLoyalFriend;

  /// Sadakat Rozetleri'nin üçüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Yıl Dönümü'**
  String get badgeNameAnniversary;

  /// İlk Hafta rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı toplam 7 farklı günde aç'**
  String get badgeRequirementFirstWeek;

  /// Sadık Dost rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı toplam 100 farklı günde aç'**
  String get badgeRequirementLoyalFriend;

  /// Yıl Dönümü rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile tanışmanın üzerinden 1 yıl geçsin'**
  String get badgeRequirementAnniversary;

  /// Rozetler Galerisi'ndeki Sosyal kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Rozetler'**
  String get badgeCategorySocial;

  /// Sosyal Rozetler'in birinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'İlk Paylaşım'**
  String get badgeNameFirstShare;

  /// Sosyal Rozetler'in ikinci rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Elçi'**
  String get badgeNameAmbassador;

  /// Sosyal Rozetler'in üçüncü rozetinin adı
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Kurucusu'**
  String get badgeNameCommunityFounder;

  /// İlk Paylaşım rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Bir Zibo kartını ilk kez paylaş'**
  String get badgeRequirementFirstShare;

  /// Elçi rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Davet Et ile 1 arkadaşını başarıyla davet et'**
  String get badgeRequirementAmbassador;

  /// Topluluk Kurucusu rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Davet Et ile 5 arkadaşını başarıyla davet et'**
  String get badgeRequirementCommunityFounder;

  /// Rozetler Galerisi'ndeki Gizli/Eğlenceli kategorisinin bölüm başlığı
  ///
  /// In tr, this message translates to:
  /// **'Gizli Rozetler'**
  String get badgeCategoryHidden;

  /// Henüz kazanılmamış gizli bir rozetin galeri kartında isim/koşul yerine gösterilen gizemli etiket
  ///
  /// In tr, this message translates to:
  /// **'???'**
  String get badgeHiddenPlaceholder;

  /// Gizli Rozetler'in birinci rozetinin adı — yalnızca rozet KAZANILDIKTAN sonra görünür
  ///
  /// In tr, this message translates to:
  /// **'Gece Kuşu'**
  String get badgeNameNightOwl;

  /// Gizli Rozetler'in ikinci rozetinin adı — yalnızca rozet KAZANILDIKTAN sonra görünür
  ///
  /// In tr, this message translates to:
  /// **'Erken Kuş'**
  String get badgeNameEarlyBird;

  /// Gizli Rozetler'in üçüncü rozetinin adı — yalnızca rozet KAZANILDIKTAN sonra görünür
  ///
  /// In tr, this message translates to:
  /// **'Denge Ustası'**
  String get badgeNameBalanceMaster;

  /// Gece Kuşu rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Gece yarısı ile sabah 05:00 arası 30 kez uygulamayı aç'**
  String get badgeRequirementNightOwl;

  /// Erken Kuş rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Sabah 06:00-08:00 arası 30 kez uygulamayı aç'**
  String get badgeRequirementEarlyBird;

  /// Denge Ustası rozetinin kazanma koşulu
  ///
  /// In tr, this message translates to:
  /// **'Aynı gün içinde uygulamadaki 7 modülün hepsine kayıt ekle'**
  String get badgeRequirementBalanceMaster;

  /// Seviye atlama kutlama kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level}\'e Ulaştın!'**
  String levelUpCelebrationTitle(int level);

  /// Seviye atlama kutlama kartının açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo ile harika gidiyorsun, büyümeye devam et!'**
  String get levelUpCelebrationBody;

  /// Seviye atlama kartındaki paylaşma butonu
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get levelUpShareButton;

  /// Seviye atlama kartındaki kapatma butonu
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get levelUpCloseButton;

  /// Seviye atlama paylaşım kartının mesaj metni
  ///
  /// In tr, this message translates to:
  /// **'Zibo\'da Seviye {level}\'e ulaştım! 🎉'**
  String levelUpShareMessage(int level);

  /// Profildeki seviye/XP ilerleme kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Seviyen'**
  String get profileLevelRowTitle;

  /// Profildeki seviye ilerleme çubuğunun altında gösterilen XP metni
  ///
  /// In tr, this message translates to:
  /// **'{current}/{needed} XP'**
  String profileLevelProgressLabel(int current, int needed);

  /// Z butonu modül menüsündeki Odak Sayacı kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Odak Sayacı'**
  String get focusTimerTooltip;

  /// Z butonu modül menüsündeki Odak Sayacı kartının açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'Odaklanma sürelerini takip et, üretkenliğini artır.'**
  String get focusModuleDescription;

  /// Odak Sayacı sayfasının AppBar başlığı
  ///
  /// In tr, this message translates to:
  /// **'Odak Sayacı'**
  String get focusTimerScreenTitle;

  /// Odak Sayacı'nın serbest kronometre modu seçici etiketi
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get focusModeFreeLabel;

  /// Odak Sayacı'nın belirli süreli (Pomodoro tarzı) mod seçici etiketi
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String focusModeMinutesLabel(int minutes);

  /// Odak Sayacı'nı başlatma butonu
  ///
  /// In tr, this message translates to:
  /// **'Başlat'**
  String get focusStartButton;

  /// Odak Sayacı'nı duraklatma butonu
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get focusPauseButton;

  /// Duraklatılmış Odak Sayacı'nı devam ettirme butonu
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get focusResumeButton;

  /// Odak seansını bitirip kaydetme butonu
  ///
  /// In tr, this message translates to:
  /// **'Bitir ve Kaydet'**
  String get focusFinishButton;

  /// Odak seansını kaydetmeden sıfırlama butonu
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get focusResetButton;

  /// Bir odak seansı kaydedilince gösterilen SnackBar metni
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika odaklandın! Harika iş.'**
  String focusSessionSavedMessage(int minutes);

  /// Bir dakikadan kısa bir odak seansı kaydedilmeye çalışılınca gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'En az 1 dakika odaklanmalısın.'**
  String get focusSessionTooShortMessage;

  /// Odak Sayacı sayfasındaki toplam odak süresi etiketi
  ///
  /// In tr, this message translates to:
  /// **'Toplam Odak Süren'**
  String get focusTotalTimeLabel;

  /// Profildeki 'Zibo ile Bağın' listesinde toplam odak süresini gösteren satırın başlığı
  ///
  /// In tr, this message translates to:
  /// **'Odak Süresi'**
  String get profileFocusRowTitle;

  /// Profildeki Odak Süresi satırının alt metni
  ///
  /// In tr, this message translates to:
  /// **'Toplam {durationText} odaklandın'**
  String profileFocusRowSubtitle(String durationText);

  /// Instagram takip kartının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Bizi Instagram\'da Takip Edin'**
  String get instagramFollowCardTitle;

  /// Instagram takip kartının açıklama metni
  ///
  /// In tr, this message translates to:
  /// **'@zibo.app hesabımızı takip et; 100 ZC, bir tema ve bir kostüm kazan!'**
  String get instagramFollowCardBody;

  /// Instagram takip kartındaki Instagram'ı açma butonu
  ///
  /// In tr, this message translates to:
  /// **'Instagram\'ı Aç'**
  String get instagramFollowOpenButton;

  /// Instagram takip kartındaki ödül talep butonu
  ///
  /// In tr, this message translates to:
  /// **'Takip Ettim'**
  String get instagramFollowClaimButton;

  /// Instagram takip ödülü verilince gösterilen SnackBar metni
  ///
  /// In tr, this message translates to:
  /// **'Ödülün hesabına eklendi! 🎉'**
  String get instagramFollowRewardGrantedMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
