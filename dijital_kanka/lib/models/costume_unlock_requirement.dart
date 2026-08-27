/// Bir kostümün coin ile satın almanın YANI SIRA bir hedefi tamamlayarak da
/// (ücretsiz) açılabilmesi için gereken koşul türü. Her tür,
/// [CostumeProvider.reconcileGoalUnlocks]'ta ilgili provider'dan okunan bir
/// "ilerleme" sayısıyla karşılaştırılır — bkz. o metodun dokümantasyonu.
enum CostumeUnlockType {
  /// `GoalsProvider.longestStreak` — herhangi bir hedefin en uzun kesintisiz
  /// serisi. 7 günlük döngü mimarisi yüzünden ASLA 7'yi aşamaz (bkz.
  /// `GoalsProvider` dokümantasyonu) — bu yüzden yalnızca en düşük/kolay
  /// zorluk kademesinde kullanılır.
  goalStreak,

  /// `GoalsProvider.completions.length` — tamamlanan TÜM 7 günlük hedef
  /// döngülerinin toplam sayısı (herhangi bir hedef, sınırsız büyür) — orta
  /// ve yüksek zorluk kademelerinin ana metriği.
  goalCompletions,

  /// `WaterProvider.completedDaysCount` — su hedefinin tamamlandığı toplam
  /// gün sayısı (sınırsız büyür) — çeşitlilik için ikinci bir metrik.
  waterDaysCompleted,
}

/// Bir [Costume]'un ücretsiz açılması için gereken koşul — `type`'a göre
/// hangi ilerleme sayısının okunacağını, `target`'a göre bu sayının ne kadar
/// olması gerektiğini belirtir. Bkz. `lib/data/costumes.dart`'taki 16
/// kostümün tam eşleme tablosu (fiyatla monoton artan zorluk).
class CostumeUnlockRequirement {
  const CostumeUnlockRequirement({required this.type, required this.target});

  final CostumeUnlockType type;
  final int target;
}
