import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/goal_quotes.dart';
import '../data/zibo_messages.dart';
import '../services/cloud_state_store.dart';
import '../services/notification_service.dart';
import '../utils/tab_navigation.dart';

/// GEÇİCİ: Bildirim özelliği rafa kaldırıldı — gerçek bir MIUI/HyperOS
/// cihazında canlı `adb` tanısıyla doğrulandı ki `AlarmManager` alarmı tam
/// zamanında (saniyesi saniyesine) tetikliyor, ama `flutter_local_notifications`
/// alıcısı (`ScheduledNotificationReceiver`) hiçbir log/hata izi bırakmadan
/// bildirimi hiç göstermiyor — ne bir istisna, ne bir "alıcı başlatılamadı"
/// hatası, hiçbir şey. Pil optimizasyonu istisnası, MIUI otomatik başlatma VE
/// Android'in "kullanılmıyorsa duraklat" (auto-revoke) ayarı ÜÇÜ DE açıkça
/// doğrulanmış/kapatılmışken bile sorun sürüyor — bu, üçüncü parti bir
/// uygulamanın kod içinden ne sorgulayabildiği ne de güvenilir şekilde
/// atlatabildiği, MIUI'ye özel, belgelenmemiş bir arka plan kısıtlaması
/// olduğuna işaret ediyor (bkz. CLAUDE.md "Bildirimler" bölümündeki tam tanı
/// günlüğü). Kullanıcı isteğiyle özellik şimdilik `false`'a çekildi;
/// provider/servis kodu OLDUĞU GİBİ duruyor, yeniden etkinleştirmek için tek
/// yapılması gereken bunu `true` yapıp yeniden derlemek.
const notificationsFeatureEnabled = false;

/// Kullanıcının günlük hatırlatma bildirimi sıklığı tercihi.
enum NotificationFrequency {
  /// Bildirim gönderilmez.
  off,

  /// Günde bir kez, [NotificationProvider.onceSlotIndex] zaman diliminde.
  once,

  /// Günde üç kez (Sabah/Öğlen/Akşam, üç zaman diliminin hepsinde).
  thrice,
}

/// Yerel günlük hatırlatma bildirimlerinin tercihini (sıklık + saat) tutan
/// ve [NotificationService] üzerinden gerçek planlamayı tetikleyen tek
/// kaynak. `CloudStateStore` ile kalıcı — [uid] varsa Firestore'a da yazılır,
/// `SharedPreferences` her zaman yerel yedek (bkz. `CostumeProvider`/
/// `AppThemeProvider` ile aynı desen).
///
/// Bildirim İÇERİĞİ, Ana Sayfa'daki (`zibo_messages.dart`) ve Hedef
/// Takibi'ndeki (`goal_quotes.dart`) söz havuzlarının birleşiminden rastgele
/// seçilir. Her aktif zaman dilimi (Sabah/Öğlen/Akşam) planlama anında
/// BİRBİRİNDEN FARKLI bir söz alır — ama işletim sistemi bildirimi her gün
/// aynı saatte kendi başına tekrarladığı için (bkz. `NotificationService`
/// dokümantasyonu, `DateTimeComponents.time`) içerik, kullanıcı uygulamayı
/// tekrar açıp yeniden planlanana kadar GÜN İÇİNDE DEĞİŞMEZ — bu, bir arka
/// plan sunucusu/WorkManager kurulumu gerektirmeyen bilinçli bir
/// basitleştirme (bkz. CLAUDE.md "Bildirimler" bölümü).
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? notificationService, String? uid})
    : _notificationService = notificationService ?? LocalNotificationService(),
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'notificationState';
  // ÇOK ESKİ (Firestore migrasyonundan ÖNCEki) iki ayrı SharedPreferences
  // anahtarı — yalnızca BİR KEZLİK yerel-format göçü için okunuyor (bkz.
  // `_loadLegacyFormat`, `CostumeProvider`/`AppThemeProvider`'daki aynı
  // desenin birebir aynısı).
  static const _legacyFrequencyPrefsKey = 'notificationFrequency';
  static const _legacyTimesPrefsKey = 'notificationTimes';

  /// Üç sabit zaman dilimi: 0=Sabah, 1=Öğlen, 2=Akşam. "Günde 1" tercihinde
  /// yalnızca [onceSlotIndex] kullanılır.
  static const onceSlotIndex = 1;
  static const _defaultTimes = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
  ];

  final NotificationService _notificationService;
  final CloudStateStore _store;
  final _random = Random();

  // Varsayılan "Günde 3" — bildirimler bu uygulamanın ana etkileşim
  // mekanizmalarından biri olarak tasarlandığı için (kullanıcı isterse
  // Ayarlar'dan kapatabilir/azaltabilir).
  NotificationFrequency _frequency = NotificationFrequency.thrice;
  List<TimeOfDay> _times = List.of(_defaultTimes);
  bool _isBatteryOptimizationIgnored = false;

  NotificationFrequency get frequency => _frequency;
  List<TimeOfDay> get times => List.unmodifiable(_times);

  /// Uygulama pil optimizasyonundan muaf mı — bkz.
  /// [NotificationService.isIgnoringBatteryOptimizations] dokümantasyonu.
  /// Yalnızca [refreshBatteryOptimizationStatus] çağrıldığında güncellenir
  /// (sürekli sorgulamak yerine, Ayarlar ekranı açıldığında/döndüğünde).
  bool get isBatteryOptimizationIgnored => _isBatteryOptimizationIgnored;

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      data = await _loadLegacyFormat();
      if (data != null) await _store.save(data);
    }
    if (data != null) {
      final freqIndex = data['frequency'] as int?;
      if (freqIndex != null && freqIndex < NotificationFrequency.values.length) {
        _frequency = NotificationFrequency.values[freqIndex];
      }
      final savedTimes = (data['times'] as List?)?.cast<String>();
      if (savedTimes != null && savedTimes.length == _defaultTimes.length) {
        _times = savedTimes.map(_parseTime).toList();
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadLegacyFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final freqIndex = prefs.getInt(_legacyFrequencyPrefsKey);
    final savedTimes = prefs.getStringList(_legacyTimesPrefsKey);
    if (freqIndex == null && savedTimes == null) return null;
    return {
      'frequency': freqIndex ?? _frequency.index,
      'times': savedTimes ?? _times.map(_formatTime).toList(),
    };
  }

  Future<void> _save() =>
      _store.save({'frequency': _frequency.index, 'times': _times.map(_formatTime).toList()});

  Future<void> setFrequency(NotificationFrequency value) async {
    if (_frequency == value) return;
    _frequency = value;
    notifyListeners();
    await _save();
    await _reschedule();
  }

  Future<void> setTime(int slotIndex, TimeOfDay time) async {
    if (_times[slotIndex] == time) return;
    _times = List.of(_times)..[slotIndex] = time;
    notifyListeners();
    await _save();
    await _reschedule();
  }

  /// Uygulama gerçekten başlarken (bkz. `RootScreen.initState`) bir kez
  /// çağrılır: bildirim eklentisini kurar, izin ister ve mevcut tercihe
  /// göre bildirimleri planlar. `flutter test` ortamında enjekte edilen
  /// [FakeNotificationService] sayesinde bu çağrı zararsızdır.
  Future<void> initializeAndSchedule() async {
    await _notificationService.initialize(
      onNotificationTap: () => homeTabRequest.value++,
    );
    await _notificationService.requestPermission();
    await _reschedule();
    await refreshBatteryOptimizationStatus();
  }

  /// [isBatteryOptimizationIgnored]'ı günceller — Ayarlar ekranı her
  /// açıldığında/öne döndüğünde çağrılmalı, çünkü kullanıcı bu izni
  /// uygulamadan ayrılıp sistem ayarlarından değiştirmiş olabilir.
  Future<void> refreshBatteryOptimizationStatus() async {
    final ignored = await _notificationService.isIgnoringBatteryOptimizations();
    if (ignored == _isBatteryOptimizationIgnored) return;
    _isBatteryOptimizationIgnored = ignored;
    notifyListeners();
  }

  /// Standart Android pil optimizasyonu istisnası diyaloğunu açar (tüm
  /// cihazlarda çalışır). Kullanıcı karar verdikten hemen sonra durum
  /// güncellenir.
  Future<void> requestIgnoreBatteryOptimizations() async {
    await _notificationService.requestIgnoreBatteryOptimizations();
    await refreshBatteryOptimizationStatus();
  }

  /// Bilinen agresif üreticilerde (Xiaomi/MIUI vb.) o üreticinin "otomatik
  /// başlatma" ayar ekranını açar; bulunamazsa genel uygulama ayarlarına
  /// düşer. Bu ayarın açık/kapalı DURUMUNU sorgulayan genel bir Android
  /// API'si olmadığı için (yalnızca üreticiye özel, belgelenmemiş), burada
  /// bir "durum" göstergesi bilerek yok.
  Future<void> openAutostartOrAppSettings() async {
    await _notificationService.openAutostartOrAppSettings();
  }

  /// Android'in "kullanılmıyorsa uygulama etkinliğini duraklat" ayar
  /// ekranını açar — bkz. [NotificationService.openUnusedAppsSettings].
  /// Autostart ile aynı gerekçeyle burada da bir durum göstergesi yok
  /// (üçüncü taraf uygulamalar bu ayarın mevcut durumunu sorgulayamaz).
  Future<void> openUnusedAppsSettings() async {
    await _notificationService.openUnusedAppsSettings();
  }

  /// GEÇİCİ/DEBUG: Bildirim izninin şu an açık olup olmadığını sorgular.
  Future<bool> hasPermission() => _notificationService.hasPermission();

  /// GEÇİCİ/DEBUG: bkz. [NotificationService.showTestNotificationNow].
  Future<void> showTestNotificationNow() =>
      _notificationService.showTestNotificationNow();

  /// GEÇİCİ/DEBUG: bkz. [NotificationService.scheduleTestNotificationIn].
  Future<void> scheduleTestNotificationIn(Duration delay) =>
      _notificationService.scheduleTestNotificationIn(delay);

  Future<void> _reschedule() async {
    await _notificationService.cancelAll();
    if (_frequency == NotificationFrequency.off) return;

    final activeSlots = _frequency == NotificationFrequency.once
        ? const [onceSlotIndex]
        : const [0, 1, 2];
    // GEÇİCİ/DEVRE DIŞI özellik olduğu için (bkz. notificationsFeatureEnabled)
    // bilerek yalnızca Türkçe havuzdan seçiliyor — dil desteği eklenirse
    // (bkz. LocaleProvider) burası da ziboMessagesForLocale/goalQuotesForLocale
    // kullanacak şekilde güncellenmeli.
    final pool = [...ziboMessagesTr, ...goalQuotesTr];
    final chosen = <String>{};
    for (final slot in activeSlots) {
      var quote = pool[_random.nextInt(pool.length)];
      var attempts = 0;
      while (!chosen.add(quote) && attempts < pool.length) {
        quote = pool[_random.nextInt(pool.length)];
        attempts++;
      }
      await _notificationService.scheduleDaily(
        id: slot,
        time: _times[slot],
        title: 'Zibo',
        body: quote,
      );
    }
  }

  static TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
