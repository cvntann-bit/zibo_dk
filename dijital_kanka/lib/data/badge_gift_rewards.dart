import '../models/badge_gift_reward.dart';

/// **2026 mimari değişikliği — kullanıcının kesin isteği/eşleme listesi.**
/// Belirli rozetler artık ZC ödülüne EK OLARAK bir kostüm/tema hediye
/// ediyor. Bu, ÖNCEKİ "TÜM kostümler hedefle de açılabilsin" mekaniğinin
/// (bkz. `data/costumes.dart`'ın TARİHÇE notu — o mekanizma TAMAMEN
/// KALDIRILDI: `Costume.unlockRequirement`/`CostumeUnlockRequirement`/
/// `CostumeProvider.reconcileGoalUnlocks`/`CostumeCard`'ın ilerleme satırı
/// SİLİNDİ) YERİNE geçen, ÇOK DAHA DAR kapsamlı bir ödül sistemi: kostümler
/// artık YALNIZCA (1) Mağaza'dan Zibo Coin ile SATIN ALINABİLİR VEYA (2)
/// aşağıdaki eşlemede listelenen DOKUZ rozetten biriyle hediye edilebilir.
///
/// **Yalnızca bu haritadaki id'ler bir hediye taşır — LİSTELENMEYEN HER
/// rozet (İlk Adım, 1 Haftalık Seri, 1 Aylık Seri, Su Kahramanı, Ruh Hali
/// Kaydedicisi, Rüya Yorumcusu, Birikim Ustası, Koleksiyoncu, Moda İkonu,
/// Tam Gardırop, Tema Avcısı, İlk Hafta, Gizli/Eğlenceli Rozetler'in
/// ÜÇÜ) SADECE ZC verir — kullanıcının açık isteği.** `full_wardrobe`
/// (Tam Gardırop) BİLEREK burada YOK — bkz. `collection_badges.dart`'taki
/// "Tam Gardırop" notu, önceki turda eklenen rastgele-tema özel ödülü bu
/// kesin listeyle İPTAL edildi.
///
/// Kostüm hediyeleri (`BadgeGiftReward.costume`) SABİT/deterministik —
/// `BadgeCelebrationOverlay`'in kazanma anı popup'ı hangi kostümün
/// verileceğini "Ödülü Al"a basılmadan ÖNCE bile gösterebiliyor. Tema
/// hediyeleri (`BadgeGiftReward.theme`) ise kullanıcının o an sahip
/// OLMADIĞI STANDART temalardan RASTGELE seçiliyor (bkz.
/// `pickRandomUnownedStandardTheme`) — hangisi olduğu yalnızca ödül
/// GERÇEKTEN talep edilince (`markOwned` çağrılınca) belli olur.
const badgeGiftRewards = <String, BadgeGiftReward>{
  // Demir İrade → Sporcu Zibo
  'iron_will': BadgeGiftReward.costume('zibo_sporcu'),
  // Şükreden Kalp → Hippi Zibo
  'grateful_heart': BadgeGiftReward.costume('zibo_hippi'),
  // Yılmaz → Gladyatör Zibo
  'unyielding': BadgeGiftReward.costume('zibo_gladyator'),
  // Sadık Dost → Kral Zibo
  'loyal_friend': BadgeGiftReward.costume('zibo_king'),
  // Yıl Dönümü → Altın Zibo
  'anniversary': BadgeGiftReward.costume('zibo_altin'),
  // Elçi → Hoca Zibo
  'ambassador': BadgeGiftReward.costume('zibo_hoca'),
  // Topluluk Kurucusu → Korsan Zibo
  'community_founder': BadgeGiftReward.costume('zibo_korsan'),
  // İlk Paylaşım → rastgele bir standart tema (kostüm DEĞİL)
  'first_share': BadgeGiftReward.theme(),
  // Hayalperest → rastgele bir standart tema (kostüm DEĞİL)
  'dreamer': BadgeGiftReward.theme(),
};
