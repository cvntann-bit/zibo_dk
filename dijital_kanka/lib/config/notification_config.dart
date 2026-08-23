/// GEÇİCİ: Eski, tamamen yerel (`flutter_local_notifications` +
/// `AlarmManager`) günlük hatırlatma özelliği rafa kaldırıldı — bkz.
/// `notification_provider.dart`'ın kendi başındaki tam MIUI/HyperOS tanı
/// notu ve CLAUDE.md "Bildirimler" bölümü. Bu, HEM `NotificationProvider`
/// (Ayarlar UI'sını/zamanlamayı kapatmak için) HEM `NotificationService`
/// (bkz. `LocalNotificationService.initialize()` — bu `false` iken artık
/// `daily_reminders` kanalını da HİÇ OLUŞTURMUYOR, kullanıcı Android
/// bildirim ayarlarında kafa karıştırıcı, kullanılmayan bir kanal görmesin
/// diye) tarafından okunduğu için ayrı, küçük bir dosyaya çıkarıldı —
/// `notification_provider.dart`, `notification_service.dart`'ı zaten
/// import ettiği için sabiti oradan servise vermek DAİRESEL import
/// oluştururdu.
///
/// Yeniden etkinleştirmek için tek yapılması gereken bunu `true` yapıp
/// yeniden derlemek.
const notificationsFeatureEnabled = false;
