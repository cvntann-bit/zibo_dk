/// FCM (Firebase Cloud Messaging) tabanlı push bildirim türleri — workspace
/// kökündeki `notification-scripts/` (GitHub Actions cron'larından çalışan
/// bağımsız Node.js betikleri, bkz. `common.js`'teki `sendToUser`)
/// tarafından gönderilen her `RemoteMessage`'ın `data['type']` alanına
/// yazılan değerlerle BİREBİR
/// eşleşir. Hem Ayarlar'daki açma/kapama tercihlerini (bkz.
/// `PushNotificationProvider`) hem de bildirime dokununca hangi sayfaya
/// yönlendirileceğini (bkz. `PushNotificationService`'in tap handler'ı)
/// belirlemek için tek bir kaynak.
enum PushNotificationType {
  /// Her gün sabah 9-11 arası rastgele bir saatte gönderilen, Ana Sayfa'nın
  /// söz havuzundan seçilmiş bir motivasyon cümlesi.
  dailyMotivation,

  /// Kullanıcının aktif bir hedefi/streak'i varsa VE bugünü henüz
  /// işaretlemediyse, günün bitmesine birkaç saat kala (~20:00) gönderilen
  /// "serini kaçırmak üzeresin" hatırlatması.
  streakReminder,

  /// Kullanıcı bugün henüz Günlük Giriş Ödülü'nü almadıysa öğleden sonra
  /// (~15:00) gönderilen hatırlatma.
  dailyReward,

  /// Kullanıcı 2+ gündür uygulamayı hiç açmadıysa gönderilen, Zibo'nun sıcak
  /// tonunda özel bir "seni özledim" bildirimi.
  reEngagement,

  /// Kullanıcının bugünkü su hedefi henüz tamamlanmadıysa öğleden sonra
  /// (~16:00) gönderilen "suyunu içtin mi" hatırlatması.
  waterReminder;

  /// Cloud Functions tarafının gönderdiği ham `data['type']` string'ini
  /// enum değerine çevirir; tanınmayan/eksik bir değer için `null` döner
  /// (bilinmeyen bir push türüne dokununca sessizce hiçbir şey yapılmaması
  /// için — bkz. `PushNotificationService._handleTap`).
  static PushNotificationType? fromWireValue(String? value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }

  /// `data['type']` alanında kullanılan sabit string karşılığı.
  String get wireValue => switch (this) {
    PushNotificationType.dailyMotivation => 'daily_motivation',
    PushNotificationType.streakReminder => 'streak_reminder',
    PushNotificationType.dailyReward => 'daily_reward',
    PushNotificationType.reEngagement => 're_engagement',
    PushNotificationType.waterReminder => 'water_reminder',
  };
}
