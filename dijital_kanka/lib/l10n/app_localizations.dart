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

  /// Ayarlar listesindeki koyu/açık tema anahtarının başlığı
  ///
  /// In tr, this message translates to:
  /// **'Koyu Tema'**
  String get settingsDarkTheme;

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

  /// Bir para kaydının yanındaki silme ikonunun erişilebilirlik ipucu
  ///
  /// In tr, this message translates to:
  /// **'Kaydı sil'**
  String get moneyDeleteEntryTooltip;

  /// Bir kategorideki kayıtların toplam tutarını gösteren metin
  ///
  /// In tr, this message translates to:
  /// **'Toplam: ₺{amount}'**
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

  /// Bir satın alma veya reklam ödülü tamamlanıp coin eklendiğinde gösterilen mesaj
  ///
  /// In tr, this message translates to:
  /// **'{amount} Zibo Coin hesabına eklendi!'**
  String storeCoinsAdded(int amount);

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
  /// **'3 şükran cümleni yazdın ve 2 Zibo Coin kazandın. Yarın tekrar gel!'**
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
  /// **'+2 Zibo Coin kazandın!'**
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
  /// **'Günlük su hedefini tamamladın! +2 Zibo Coin kazandın!'**
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
  /// **'+2 Zibo Coin kazandın!'**
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

  /// Paylaşılan profil kartı metninin başlığı (ZiboShareSheet'e geçirilen mesajın ilk satırı)
  ///
  /// In tr, this message translates to:
  /// **'🐣 Zibo ile Bağım'**
  String get profileShareCardTitle;

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

  /// Onboarding'de Hedef Takibi modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Kendi hedeflerini belirle, her gün işaretle — 7 günlük bir seriyi tamamladığında Zibo Coin kazanırsın.'**
  String get onboardingGoalsDescription;

  /// Onboarding'de Su Takibi modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Günlük su hedefini takip et, bardak bardak ilerlemeni gör — hedefi tamamlayınca ödül seni bekliyor.'**
  String get onboardingWaterDescription;

  /// Onboarding'de Şükran Günlüğü modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Her gün 3 şeye şükret, küçük anları yazıya dök — hem içini rahatlatır hem de bakış açını değiştirir.'**
  String get onboardingGratitudeDescription;

  /// Onboarding'de Günlük Ruh Hali Takibi modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıl hissettiğini tek dokunuşla kaydet, zamanla ruh halinin nasıl değiştiğini gör.'**
  String get onboardingMoodDescription;

  /// Onboarding'de Manifest Günlüğü modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Hayallerine bir fotoğraf ve niyet ekle — kendi vizyon panonu zamanla büyüt.'**
  String get onboardingManifestDescription;

  /// Onboarding'de Mağaza modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'Zibo Coin biriktir, yeni kostümler ve renkli temalar satın al — Zibo\'yu istediğin gibi giydir.'**
  String get onboardingStoreDescription;

  /// Onboarding'de Profil modülünü tanıtan 1-2 cümlelik açıklama
  ///
  /// In tr, this message translates to:
  /// **'İstatistiklerini gör, Zibo ile bağını takip et, favori sözlerini biriktir — hepsi tek bir yerde.'**
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
