/// Zibo'nun abonelik katmanları. Sıralama ÖNEMLİ değil ama [SubscriptionTier.free]
/// her zaman varsayılan/geriye düşülen değerdir — bkz. `SubscriptionProvider`.
enum SubscriptionTier { free, pro, proPlus }

/// Firestore'da/`firestore.rules`'ta kullanılan tam küçük harfli değerler
/// (`'free'`/`'pro'`/`'proplus'`) — Dart'ın kendi enum `.name`'i
/// [SubscriptionTier.proPlus] için `'proPlus'` (büyük P) döner, bu da
/// `firestore.rules`'un beklediği `'proplus'` ile UYUŞMAZ. Bu yüzden
/// [SubscriptionProvider] `.name`/`.byName` YERİNE bu iki fonksiyonu
/// kullanır.
extension SubscriptionTierJson on SubscriptionTier {
  String toJson() => switch (this) {
    SubscriptionTier.free => 'free',
    SubscriptionTier.pro => 'pro',
    SubscriptionTier.proPlus => 'proplus',
  };

  static SubscriptionTier fromJson(String value) => switch (value) {
    'pro' => SubscriptionTier.pro,
    'proplus' => SubscriptionTier.proPlus,
    _ => SubscriptionTier.free,
  };
}
