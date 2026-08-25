import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/push_notification_type.dart';
import 'notification_service.dart';

/// **2026 yeni özellik.** FCM (Firebase Cloud Messaging) push bildirimlerinin
/// istemci tarafı — token kaydı, ön plandaki mesajları gösterme, bildirime
/// dokununca ilgili sayfaya yönlendirme sinyalini üretme. Gönderim tarafı
/// (Cloud Functions + Cloud Scheduler) TAMAMEN sunucuda; bu servis yalnızca
/// ALICI ucu (`AdService`/`ShareService` ile AYNI "gerçek implementasyon,
/// testte enjekte edilebilir sahtesi" felsefesi).
abstract class PushNotificationService {
  const PushNotificationService();

  /// `main()`'de (Firebase başlatıldıktan, `uid` belli olduktan sonra) bir kez
  /// çağrılır. [uid] `null` ise (Firebase kullanılamıyor) hiçbir şey yapmaz —
  /// token'ı hangi kullanıcıya ait olduğunu bilmeden kaydetmenin bir anlamı
  /// yok, Cloud Functions zaten yalnızca `users/{uid}` altındaki token'lara
  /// gönderim yapabiliyor. [localNotificationService], ön plandayken gelen
  /// mesajları göstermek için (bkz. `NotificationService.showNow`) — FCM ön
  /// plandayken OS'in kendisi bir sistem bildirimi GÖSTERMEZ, bu boşluğu
  /// dolduruyoruz. [onNotificationTap], kullanıcı bir push bildirimine
  /// dokunduğunda (uygulama ön/arka planda VEYA soğuk başlangıçta) çağrılır —
  /// bildirim türüne göre doğru sayfaya yönlendirme `RootScreen`'in
  /// sorumluluğunda (bkz. `tab_navigation.dart`'taki sinyaller).
  Future<void> initialize({
    required String? uid,
    required NotificationService localNotificationService,
    required void Function(PushNotificationType type) onNotificationTap,
  });

  /// Kullanıcının Firestore'daki `lastActiveAt` alanını "şimdi"ye, `timeZone`
  /// alanını cihazın GÜNCEL IANA saat dilimine (ör. `America/Bogota`) günceller.
  /// `lastActiveAt`, "Geri Kazanma" (re-engagement) bildiriminin "2 gündür
  /// uygulamayı hiç açmadı mı?" kontrolü için; `timeZone`, TÜM bildirim
  /// betiklerinin (bkz. `notification-scripts/src/common.js`'teki
  /// `userLocalHour`/`userDateKey`) kullanıcının KENDİ yerel saatine göre
  /// gönderim yapabilmesi için TEK veri kaynağı — 2026 güncellemesi, kullanıcı
  /// raporuyla eklendi (Kolombiya'daki bir test kullanıcısı sabah 4'te bildirim
  /// aldığını bildirdi; önceden TÜM bildirimler sabit Europe/Istanbul saatine
  /// göre gönderiliyordu). `RootScreen`'de hem `initState`'te (uygulama
  /// açılırken) hem `AppLifecycleState.resumed`'da (arka plandan öne dönünce)
  /// çağrılıyor — bu da saat dilimini kullanıcı seyahat ettiğinde bile makul
  /// bir sıklıkla tazeler, ayrı bir mekanizma GEREKMEDİ.
  Future<void> touchLastActive(String uid);
}

/// Gerçek `firebase_messaging` implementasyonu.
class FirebaseMessagingPushNotificationService extends PushNotificationService {
  FirebaseMessagingPushNotificationService();

  @override
  Future<void> initialize({
    required String? uid,
    required NotificationService localNotificationService,
    required void Function(PushNotificationType type) onNotificationTap,
  }) async {
    if (uid == null) return;
    try {
      // Push bildirim kanalını (özel sesiyle birlikte, bkz.
      // NotificationService.initialize) uygulama HER başlangıçta erkenden
      // oluşturur — eski yerel hatırlatma sistemi kapalı olsa bile
      // (`notificationsFeatureEnabled == false`) bu çağrı GEREKLİ: Android
      // O+'ta bir FCM mesajı henüz var olmayan bir kanala işaret ederse
      // (`android.notification.channel_id`) bildirim SESSİZCE düşürülür —
      // uygulama arka planda/kapalıyken gelen İLK bildirimden önce bile
      // kanalın kayıtlı olması gerekiyor.
      await localNotificationService.initialize(onNotificationTap: () {});

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));

      // Uygulama ÖN PLANDAYKEN gelen mesajlar — OS bunları otomatik
      // göstermiyor, `showNow` ile yerel bir bildirim olarak biz gösteriyoruz.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        localNotificationService.showNow(
          title: notification.title ?? 'Zibo',
          body: notification.body ?? '',
        );
      });

      // Uygulama ARKA PLANDAYKEN bir bildirime dokunulup uygulama öne
      // getirildiğinde.
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleTap(message, onNotificationTap),
      );

      // Uygulama TAMAMEN KAPALIYKEN (soğuk başlangıç) bir bildirime
      // dokunulduysa — `getInitialMessage` bunu yalnızca ilk çağrıda döner.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleTap(initialMessage, onNotificationTap);

      await touchLastActive(uid);
    } catch (_) {
      // Firebase Messaging bu ortamda/platformda kullanılamıyor (ör. web
      // önizlemesi, izin reddi) — özellik sessizce devre dışı kalır, diğer
      // `NotificationService` (eski yerel sistem, bkz. o dosyanın "GEÇİCİ
      // rafa kaldırıldı" notu) zaten AYRI ve buna bağımlı değil.
    }
  }

  @override
  Future<void> touchLastActive(String uid) async {
    // Saat dilimi okuması AYRI bir try/catch'te — bu platform/eklenti
    // sorunundan dolayı başarısız olsa bile (ör. desteklenmeyen bir OS
    // sürümü) `lastActiveAt` güncellemesi ("Geri Kazanma" bildiriminin tek
    // veri kaynağı) HİÇ etkilenmemeli.
    String? timeZone;
    try {
      timeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      // Yoksayılır — betikler `timeZone` alanı yoksa zaten Europe/Istanbul'a
      // düşüyor (bkz. notification-scripts/src/common.js).
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
        if (timeZone != null) 'timeZone': timeZone,
      }, SetOptions(merge: true));
    } catch (_) {
      // Yoksayılır — bir sonraki resume'da tekrar denenecek.
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Yoksayılır — token bir sonraki `initialize()` çağrısında (ör.
      // uygulama yeniden açıldığında) tekrar yazılmaya çalışılır.
    }
  }

  void _handleTap(
    RemoteMessage message,
    void Function(PushNotificationType type) onTap,
  ) {
    final type = PushNotificationType.fromWireValue(
      message.data['type'] as String?,
    );
    if (type != null) onTap(type);
  }
}

/// `flutter_test`'te platform channel'a hiç dokunmayan sahte implementasyon.
class FakePushNotificationService extends PushNotificationService {
  const FakePushNotificationService();

  @override
  Future<void> initialize({
    required String? uid,
    required NotificationService localNotificationService,
    required void Function(PushNotificationType type) onNotificationTap,
  }) async {}

  @override
  Future<void> touchLastActive(String uid) async {}
}

/// **2026 yeni özellik.** Uygulama TAMAMEN KAPALIYKEN (arka plan/terminated)
/// gelen FCM mesajlarını işleyen üst düzey (top-level) fonksiyon —
/// `FirebaseMessaging.onBackgroundMessage` yalnızca top-level veya `static`
/// bir fonksiyon kabul eder (AYRI bir isolate'te çalıştırılabilir), bu yüzden
/// bir sınıf metodu OLAMAZ. `main()`'de, `runApp`'tan ÖNCE kaydediliyor.
/// Şu an içeriği BOŞ bırakıldı — `notification` payload'lı mesajlar için
/// (bkz. Cloud Functions tarafında gönderim, HER ZAMAN `notification` alanı
/// dolduruluyor) Android/iOS işletim sistemi zaten OTOMATİK olarak sistem
/// bildirimini gösteriyor, bu handler'ın ekstra bir iş yapmasına GEREK YOK
/// — yalnızca `onBackgroundMessage`'ın KAYITLI olması (registration)
/// Android'de arka plan mesaj teslimatının güvenilir çalışması için gerekli.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
