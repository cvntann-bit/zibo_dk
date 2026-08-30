import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/notification_config.dart';

/// Bilinen agresif Android üreticilerinin kendi "otomatik başlatma" izin
/// ekranının component adı — bkz. [LocalNotificationService.openAutostartSettings]
/// dokümantasyonu. Sürümler arası değişebildiği için her üretici için birden
/// fazla aday tutuluyor; ilk ÇÖZÜLEBİLEN (bkz. `canResolveActivity`)
/// kullanılır.
const _autostartIntentCandidates = <String, List<String>>{
  'xiaomi': [
    'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
  ],
  'huawei': [
    'com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
    'com.huawei.systemmanager/com.huawei.systemmanager.optimize.process.ProtectActivity',
  ],
  'honor': [
    'com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity',
  ],
  'oppo': [
    'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
    'com.coloros.safecenter/com.coloros.safecenter.startupapp.StartupAppListActivity',
  ],
  'realme': [
    'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
  ],
  'vivo': [
    'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
    'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
  ],
  'oneplus': [
    'com.oneplus.security/com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
  ],
};

/// Yerel (cihaz üzerinde, sunucu gerektirmeyen) günlük hatırlatma
/// bildirimlerinden sorumlu servisin soyut arayüzü. `AdService`/
/// `ShareService` ile aynı desen: gerçek implementasyon platform channel'a
/// dokunuyor, bu yüzden `flutter_test` onun yerine [FakeNotificationService]
/// enjekte eder.
abstract class NotificationService {
  const NotificationService();

  /// Bildirim eklentisini kurar. [onNotificationTap], kullanıcı uygulama
  /// açıkken (ön/arka planda) bir bildirime dokunduğunda çağrılır — soğuk
  /// başlangıçta uygulama zaten Ana Sayfa'da açıldığı için ayrıca ele
  /// alınmıyor (bkz. RootScreen'in varsayılan `_selectedIndex = 0`'ı).
  Future<void> initialize({required void Function() onNotificationTap});

  /// Bildirim izni ister (Android 13+'ta gerekli); iOS'ta da aynı
  /// kullanılabilir. Kullanıcı izni verdiyse true döner.
  Future<bool> requestPermission();

  /// Daha önce planlanmış tüm bildirimleri iptal eder.
  Future<void> cancelAll();

  /// [time]'da başlayıp her gün tekrar eden bir bildirim planlar. Aynı [id]
  /// ile tekrar çağrılırsa öncekinin yerine geçer.
  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  });

  /// Uygulama pil optimizasyonundan (Doze/App Standby) muaf mı? Değilse,
  /// işletim sistemi planlanmış alarmları geciktirebilir veya tamamen
  /// engelleyebilir — bkz. CLAUDE.md "Bildirimler" bölümündeki tanı notu.
  Future<bool> isIgnoringBatteryOptimizations();

  /// Kullanıcıdan pil optimizasyonu istisnası ister (standart Android
  /// sistem diyaloğu — tüm cihazlarda çalışır, yalnızca Xiaomi/Huawei gibi
  /// üreticilere özel değil).
  Future<void> requestIgnoreBatteryOptimizations();

  /// Bilinen agresif üreticilerde (Xiaomi/MIUI, Huawei, Oppo, Vivo,
  /// OnePlus, ...) o üreticinin "otomatik başlatma" izin ekranını açmayı
  /// dener; böyle bir ekran bulunamazsa (bilinmeyen cihaz/sürüm) uygulamanın
  /// genel sistem ayarlarını açar. Hiçbir zaman sessizce hiçbir şey
  /// yapmadan dönmez.
  Future<void> openAutostartOrAppSettings();

  /// Android'in (özellikle MIUI/HyperOS'ta daha agresif uygulanan)
  /// "kullanılmıyorsa uygulama etkinliğini duraklat" ayarını açar — bu AÇIK
  /// olduğunda sistem izinleri geri alıp ARKA PLAN BİLDİRİMLERİNİ
  /// DURDURUYOR (pil optimizasyonu/otomatik başlatmadan tamamen ayrı, üçüncü
  /// bir mekanizma — bkz. CLAUDE.md "Bildirimler" bölümündeki tanı). Standart
  /// `ACTION_AUTO_REVOKE_PERMISSIONS` (Android 11+, tüm üreticilerde
  /// çalışır) kullanılır; çözülemezse genel uygulama ayarlarına düşülür.
  Future<void> openUnusedAppsSettings();

  /// GEÇİCİ/DEBUG: Bildirim izninin ŞU AN açık olup olmadığını sorgular
  /// (izin İSTEMEZ, yalnızca mevcut durumu okur). Ayarlar'daki geçici
  /// bildirim test panelinde gösterilir.
  Future<bool> hasPermission();

  /// GEÇİCİ/DEBUG: Zamanlamaya hiç dokunmadan bildirimi HEMEN gösterir —
  /// temel gösterim + iznin gerçekten çalıştığını saniyeler içinde
  /// doğrulamak için (AlarmManager/arka plan teslimatını test ETMEZ, bkz.
  /// [scheduleTestNotificationIn]).
  Future<void> showTestNotificationNow();

  /// GEÇİCİ/DEBUG: Üretimdeki [scheduleDaily] ile TAMAMEN AYNI mekanizmayı
  /// (AlarmManager tabanlı `zonedSchedule`, `inexactAllowWhileIdle`)
  /// kullanarak [delay] sonra tetiklenecek tek seferlik bir bildirim
  /// planlar — asıl sorunun (ör. MIUI'nin arka plan alarmlarını
  /// engellemesi) gerçekten çözülüp çözülmediğini saatler değil dakikalar
  /// içinde görebilmek için.
  Future<void> scheduleTestNotificationIn(Duration delay);

  /// [title]/[body] ile bir bildirimi HEMEN gösterir — [showTestNotificationNow]
  /// ile AYNI alt mekanizma (`_plugin.show`), ama sabit bir metin yerine
  /// keyfi içerik alır. **2026 güncellemesi — FCM push bildirimleri ÖN
  /// PLANDAYKEN** (bkz. `PushNotificationService.FirebaseMessagingPushNotification
  /// Service`) OS'in kendisi bir sistem bildirimi GÖSTERMEZ (yalnızca
  /// `FirebaseMessaging.onMessage` akışına bir `RemoteMessage` düşer) — bu
  /// metot o boşluğu dolduruyor: gelen push'un başlığını/gövdesini
  /// `flutter_local_notifications` üzerinden yerel bir bildirim olarak
  /// gösterip kullanıcı deneyimini arka/kapalı plandaki davranışla tutarlı
  /// kılıyor.
  ///
  /// **2026 bug düzeltmesi — "bildirimler 2şer tane gelmeye başladı"
  /// kullanıcı raporu.** [id] verilmezse (eski davranış) her çağrı
  /// `DateTime.now()`'a dayalı YENİ/rastgele bir bildirim id'si üretiyordu —
  /// FCM'in kendi teslimat garantisi "en az bir kez" (at-least-once), YANİ
  /// "tam olarak bir kez" DEĞİL (bkz. Firebase'in kendi resmi dokümantasyonu)
  /// — ağ yeniden bağlanması/OS'in kendi yeniden deneme mantığı AYNI mantıksal
  /// mesajı ARADA SIRADA İKİNCİ kez `onMessage`'a düşürebiliyor. Rastgele id
  /// kullanıldığında Android bunu TAMAMEN AYRI, ikinci bir bildirim olarak
  /// gösteriyordu (aynı id'yle çağrılan `_plugin.show()` normalde VAR OLAN
  /// bildirimin YERİNE geçer/günceller, farklı id'yle YENİ bir tane EKLER) —
  /// kullanıcı bu yüzden "aynı bildirim 2 kez geldi" diye bildirdi.
  /// **Düzeltme:** çağıran taraf (bkz. `PushNotificationService`) artık FCM
  /// mesajının KENDİ `messageId`'sinden TÜRETİLMİŞ, DETERMİNİSTİK bir [id]
  /// geçiyor — aynı mantıksal mesaj ikinci kez düşerse Android bunu SESSİZCE
  /// mevcut bildirimin ÜZERİNE YAZAR, ikinci bir kart OLUŞTURMAZ. [id]
  /// verilmezse geriye dönük uyumluluk için eski rastgele davranışa düşülür.
  Future<void> showNow({required String title, required String body, int? id});
}

/// `flutter_local_notifications` ile gerçek yerel bildirimleri planlayan
/// implementasyon. Uygulama şu an yalnızca Türkçe/Türkiye'yi hedeflediği
/// için (bkz. CLAUDE.md "Yerelleştirme") saat dilimi de aynı gerekçeyle
/// `Europe/Istanbul` olarak sabitlendi — çoklu saat dilimi/dil desteği
/// eklendiğinde burası da (cihazın gerçek saat dilimini okuyan bir pakete,
/// ör. `flutter_timezone`, geçilerek) yeniden ele alınmalı.
///
/// Platform channel'a dokunan her metot try/catch ile sarılı: eklenti
/// başlatılamazsa (ör. desteklenmeyen platform, `flutter_test` ortamı) tüm
/// uygulamanın çökmesi yerine bildirim özelliği sessizce devre dışı kalır —
/// tıpkı [SharePlusService]'in test dışı kalan gerçek çağrılarının widget
/// ağacını kurmayı engellememesi gibi.
class LocalNotificationService extends NotificationService {
  LocalNotificationService();

  static const _channelId = 'daily_reminders';
  static const _channelName = 'Günlük Hatırlatmalar';
  static const _channelDescription =
      'Zibo\'dan günde birkaç kez motivasyon sözü';

  /// **2026 yeni özellik.** FCM push bildirimleri (bkz. `PushNotificationService`)
  /// İÇİN ayrı, özel sesli bir kanal — eski `daily_reminders` kanalından
  /// BİLEREK AYRI tutuldu (o kanal hâlâ rafta olan yerel hatırlatma sistemine
  /// ait, bkz. "Bildirimler" bölümü). Ses dosyası
  /// `android/app/src/main/res/raw/zibo_notification.wav`'dan geliyor —
  /// Android'in RAW KAYNAK adlandırma kısıtlaması yüzünden (yalnızca küçük
  /// harf/rakam/alt çizgi, boşluk/büyük harf YASAK) kullanıcının verdiği
  /// orijinal "Zibo notification new.wav" dosyası `zibo_notification.wav`
  /// olarak KOPYALANDI (Flutter asset'i DEĞİL — `assets/sounds/`'taki
  /// orijinal dosya bu özellik için KULLANILMIYOR, Android bildirim kanalı
  /// sesleri yalnızca native `res/raw/` kaynaklarından veya `content://`
  /// URI'lerinden atanabiliyor, Flutter asset yolundan DEĞİL).
  static const _pushChannelId = 'push_notifications';
  static const _pushChannelName = 'Push Bildirimleri';
  static const _pushChannelDescription =
      'Zibo\'dan gelen push bildirimleri (motivasyon, streak, ödül, geri kazanma)';
  static const _pushChannelSound = RawResourceAndroidNotificationSound(
    'zibo_notification',
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> initialize({required void Function() onNotificationTap}) async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const settings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (_) => onNotificationTap(),
      );

      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // `daily_reminders` kanalı YALNIZCA eski yerel hatırlatma özelliği
      // GERÇEKTEN aktifken oluşturuluyor — bu metot (push kanalı için)
      // `notificationsFeatureEnabled == false` iken de HER uygulama
      // başlangıcında çalıştığı için, bu `if` olmadan kullanılmayan bir
      // kanal Android'in bildirim ayarlarında kalıcı olarak görünmeye devam
      // ederdi (gerçekten yaşandı — kullanıcı "Push Bildirimleri" ile
      // "Günlük Hatırlatmalar" adında, hangisinin gerçek/aktif olduğu belli
      // olmayan iki kanal görüp kafası karıştı). Özellik yeniden
      // etkinleştirilirse (`notificationsFeatureEnabled = true`) kanal bir
      // sonraki `initialize()` çağrısında (her uygulama açılışı) otomatik
      // oluşur, elle bir adım gerekmez.
      if (notificationsFeatureEnabled) {
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
          ),
        );
      }
      // Push kanalı da BURADA (eski yerel hatırlatma sistemi kapalı olsa
      // bile) oluşturuluyor — `PushNotificationService.initialize()` her
      // uygulama başlangıcında `initialize()`'ı ÇAĞIRIYOR (bkz. o dosya),
      // bu yüzden kanal + özel ses, uygulama arka planda/kapalıyken gelen
      // İLK push bildiriminden ÖNCE bile Android'de kayıtlı olur — Android
      // O+'ta FCM mesajının `android.notification.channel_id`'si HENÜZ
      // OLUŞTURULMAMIŞ bir kanala işaret ederse bildirim SESSİZCE
      // DÜŞÜRÜLÜR, bu yüzden erken/koşulsuz oluşturmak kritik.
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _pushChannelId,
          _pushChannelName,
          description: _pushChannelDescription,
          sound: _pushChannelSound,
        ),
      );

      _initialized = true;
    } catch (_) {
      // Bildirim altyapısı bu ortamda/platformda kullanılamıyor — özellik
      // sessizce devre dışı kalır, uygulamanın geri kalanı etkilenmez.
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOf(time),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await ph.Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await ph.Permission.ignoreBatteryOptimizations.request();
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<void> openAutostartOrAppSettings() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final manufacturer = info.manufacturer.toLowerCase();
      final candidates = _autostartIntentCandidates[manufacturer] ?? const [];
      for (final component in candidates) {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          componentName: component,
        );
        if (await intent.canResolveActivity() ?? false) {
          await intent.launch();
          return;
        }
      }
    } catch (_) {
      // Bilinen bir eşleşme bulunamadı/başlatılamadı — aşağıdaki genel
      // ayarlar sayfasına düşülüyor.
    }
    try {
      await ph.openAppSettings();
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<void> openUnusedAppsSettings() async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.AUTO_REVOKE_PERMISSIONS',
        data: 'package:com.dijitalkanka.dijital_kanka',
      );
      if (await intent.canResolveActivity() ?? false) {
        await intent.launch();
        return;
      }
    } catch (_) {
      // Aşağıdaki genel ayarlar sayfasına düşülüyor.
    }
    try {
      await ph.openAppSettings();
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showTestNotificationNow() async {
    try {
      await _plugin.show(
        id: 9999,
        title: 'Zibo (test)',
        body: 'Bildirimler çalışıyor! 🎉',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName),
        ),
      );
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<void> scheduleTestNotificationIn(Duration delay) async {
    try {
      await _plugin.zonedSchedule(
        id: 9998,
        title: 'Zibo (planlanmış test)',
        body:
            'Bu bildirim gerçek zamanlama mekanizmasıyla '
            '${delay.inSeconds} saniye önce planlandı.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  @override
  Future<void> showNow({required String title, required String body, int? id}) async {
    try {
      // `PushNotificationService` (ön plandaki FCM mesajlarını göstermek
      // için) bu metodu `initialize()`'ı hiç çağırmadan kullanabiliyordu —
      // eski yerel hatırlatma sistemi kapalıyken (`notificationsFeatureEnabled
      // == false`, bkz. "Bildirimler" bölümü) `_plugin.initialize()` HİÇBİR
      // ZAMAN çalışmıyor, bu da `_plugin.show()`'un (ve dolayısıyla push
      // bildirimlerinin ön planda hiç görünmemesinin) SESSİZCE başarısız
      // olmasına yol açan gerçek bir bug'dı. Artık burada da idempotent
      // şekilde (zaten initialize edilmişse no-op) çağrılıyor.
      await initialize(onNotificationTap: () {});
      await _plugin.show(
        // `id` verilmemişse (bkz. arayüz dokümantasyonundaki 2026 "2şer tane
        // geliyor" bug düzeltmesi) eski rastgele davranışa düşülüyor.
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _pushChannelId,
            _pushChannelName,
            sound: _pushChannelSound,
          ),
        ),
      );
    } catch (_) {
      // Yoksayılır — bkz. sınıf yorumu.
    }
  }

  /// [time]'a denk gelen, şu andan sonraki ilk zamanı (bugün henüz
  /// geçmediyse bugün, geçtiyse yarın) döner. `matchDateTimeComponents:
  /// DateTimeComponents.time` ile birleşince bu yalnızca İLK tetiklenmeyi
  /// belirler — sonrasında işletim sistemi bunu her gün aynı saatte kendi
  /// başına tekrarlar, uygulamanın açık/çalışır olması gerekmez.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// `flutter_test`'te platform channel'a hiç dokunmayan sahte implementasyon.
class FakeNotificationService extends NotificationService {
  const FakeNotificationService();

  @override
  Future<void> initialize({required void Function() onNotificationTap}) async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {}

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => true;

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {}

  @override
  Future<void> openAutostartOrAppSettings() async {}

  @override
  Future<void> openUnusedAppsSettings() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> showTestNotificationNow() async {}

  @override
  Future<void> scheduleTestNotificationIn(Duration delay) async {}

  @override
  Future<void> showNow({required String title, required String body, int? id}) async {}
}
