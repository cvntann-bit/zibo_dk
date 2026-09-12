import '../models/badge_definition.dart';

/// Sadakat Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü. İstikrar
/// Rozetleri'nden BİLEREK FARKLI: ARDIŞIKLIK (streak) GEREKTİRMİYOR,
/// yalnızca TOPLAM kullanım gün SAYISINI veya geçen takvim SÜRESİNİ baz
/// alıyor — kullanıcı arada boşluk bıraksa/ara sıra kullansa bile zamanla
/// bu rozetleri kazanabilir.
///
/// **İlk Hafta** + **Sadık Dost** — `AppStreakProvider.totalDaysOpened`'e
/// (uygulamanın açıldığı TOPLAM benzersiz gün sayısı, bir gün kaçırılsa
/// bile SIFIRLANMAYAN, yalnızca monotonik artan bir sayaç — `currentStreak`
/// ile KARIŞTIRILMAMALI) bağlı, yalnızca EŞİK farklı (7 / 100).
///
/// **Yıl Dönümü** — `ProfileProvider.daysSinceFirstUsed()`'e (kullanıcının
/// Zibo ile İLK tanıştığı tarihten bu yana geçen takvim günü) bağlı, 365
/// gün eşiği — bkz. `BadgeProvider.reconcileLoyaltyBadges`.
///
/// Görseller kullanıcının masaüstündeki `rozetler/sadakat rozetleri`
/// klasöründen `tool/process_loyalty_badge_images.dart` ile (dosya adları
/// AYNEN korunarak, yalnızca 512px'e küçültülerek) `assets/images/`e
/// kopyalandı.
const loyaltyBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'first_week',
    category: BadgeCategory.loyalty,
    imageAsset: 'assets/images/ilk_hafta_rozet.webp',
    zcReward: 15,
  ),
  ZiboBadgeDefinition(
    id: 'loyal_friend',
    category: BadgeCategory.loyalty,
    imageAsset: 'assets/images/sadik_dost_rozet.webp',
    zcReward: 100,
  ),
  ZiboBadgeDefinition(
    id: 'anniversary',
    category: BadgeCategory.loyalty,
    imageAsset: 'assets/images/yil_donumu_rozet.webp',
    zcReward: 300,
  ),
];
