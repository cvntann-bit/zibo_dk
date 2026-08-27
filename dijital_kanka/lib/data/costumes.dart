import '../models/costume.dart';
import '../models/costume_unlock_requirement.dart';

/// **2026 fiyat güncellemesi:** tüm kostümlerin fiyatı, erişilebilirliği
/// biraz zorlaştırmak için kullanıcı isteğiyle TOPLU %10 artırıldı (ör.
/// 400 ZC → 440 ZC). Liste ayrıca ucuzdan pahalıya SIRALI — Mağaza >
/// Kostümler ızgarası bu listeyi olduğu gibi (`for (final costume in
/// costumes) ...`) dolaştığı için, sıralama burada tanımlanınca ayrı bir
/// widget-seviyesi sıralama koduna gerek kalmadı (tek kaynak, tek yerde
/// düzenleniyor). Altın/Elmas Kaplama, %10 artıştan SONRA da listenin en
/// pahalı iki kostümü olarak kaldı — oranları zaten TAM %50 (33000/22000),
/// aynı katsayıyla ölçeklendiği için kullanıcının istediği "Elmas, Altın'ın
/// ~%50 üstünde" ilişkisi ayrıca elle ayarlamaya gerek kalmadan korundu.
///
/// **2026 GÜNCELLEMESİ — her kostüme bir `unlockRequirement` eklendi**
/// (kullanıcı isteği: "TÜM kostümler hedefle de açılabilsin, zorluk fiyata
/// göre ölçeklensin"). İki metrik kullanılıyor — `goalCompletions`
/// (`GoalsProvider.completions.length`, tamamlanan 7-günlük hedef döngüsü
/// sayısı, sınırsız büyür) ve `waterDaysCompleted`
/// (`WaterProvider.completedDaysCount`, su hedefinin tamamlandığı gün
/// sayısı, sınırsız büyür) — ikisi de fiyat sırasına göre monoton artıyor.
/// `goalStreak` (`GoalsProvider.longestStreak`) yalnızca EN ucuz kostümde
/// (zibo_hippi, hedef 3) kullanıldı çünkü bu metrik mimari gereği ASLA 7'yi
/// aşamıyor (bkz. `GoalsProvider` dokümantasyonu — bir 7 günlük döngü
/// tamamlanınca/bozulunca sıfırlanıyor), üst kademelerdeki "30-60 gün
/// streak" gibi örnekler bu yüzden `goalCompletions`/`waterDaysCompleted`
/// ile karşılanıyor (kullanıcının kendi "örn." ifadesiyle bu örneklerin
/// katı bir gereksinim olmadığı yorumlanarak). `zibo_hippi` = kullanıcının
/// kendi "3 gün streak" örneği, `zibo_elmas` = kullanıcının kendi "100 gün
/// su takibi" örneği; kalan 14 kostüm bu iki metriğin fiyatla ölçeklenen
/// ara değerleriyle dolduruldu. Bkz. `CostumeProvider.reconcileGoalUnlocks`
/// (otomatik açma) ve `CostumeCard` (kilitliyken ilerleme gösterimi).
const costumes = <Costume>[
  Costume(
    id: 'zibo_hippi',
    imageAsset: 'assets/images/zibo_hippi.png',
    name: 'Hippi Zibo',
    price: 440,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalStreak,
      target: 3,
    ),
  ),
  Costume(
    id: 'zibo_sporcu',
    imageAsset: 'assets/images/zibo_sporcu.png',
    name: 'Sporcu Zibo',
    price: 440,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 5,
    ),
  ),
  Costume(
    id: 'zibo_asker',
    imageAsset: 'assets/images/zibo_asker.png',
    name: 'Asker Zibo',
    price: 550,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 1,
    ),
  ),
  Costume(
    id: 'zibo_hoca',
    imageAsset: 'assets/images/zibo_hoca.png',
    name: 'Hoca Zibo',
    price: 550,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 10,
    ),
  ),
  Costume(
    id: 'zibo_punk',
    imageAsset: 'assets/images/zibo_punk.png',
    name: 'Punk Zibo',
    price: 715,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 2,
    ),
  ),
  Costume(
    id: 'zibo_rapci',
    imageAsset: 'assets/images/zibo_rapci.png',
    name: 'Rapçi Zibo',
    price: 715,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 15,
    ),
  ),
  Costume(
    id: 'zibo_gentleman',
    imageAsset: 'assets/images/zibo_gentleman.png',
    name: 'Centilmen Zibo',
    price: 770,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 3,
    ),
  ),
  Costume(
    id: 'zibo_samurai',
    imageAsset: 'assets/images/zibo_samurai.png',
    name: 'Samuray Zibo',
    price: 770,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 20,
    ),
  ),
  Costume(
    id: 'zibo_gladyator',
    imageAsset: 'assets/images/zibo_gladyator.png',
    name: 'Gladyatör Zibo',
    price: 880,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 4,
    ),
  ),
  Costume(
    id: 'zibo_korsan',
    imageAsset: 'assets/images/zibo_korsan.png',
    name: 'Korsan Zibo',
    price: 880,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 25,
    ),
  ),
  Costume(
    id: 'zibo_cyborg',
    imageAsset: 'assets/images/zibo_cyborg.png',
    name: 'Siborg Zibo',
    price: 935,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 5,
    ),
  ),
  Costume(
    id: 'zibo_astronot',
    imageAsset: 'assets/images/zibo_astronot.png',
    name: 'Astronot Zibo',
    price: 990,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 30,
    ),
  ),
  Costume(
    id: 'zibo_king',
    imageAsset: 'assets/images/zibo_king.png',
    name: 'Kral Zibo',
    price: 1045,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 6,
    ),
  ),
  Costume(
    id: 'zibo_zombi',
    imageAsset: 'assets/images/zibo_zombi.png',
    name: 'Zombi Zibo',
    price: 1100,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 40,
    ),
  ),
  Costume(
    id: 'zibo_altin',
    imageAsset: 'assets/images/zibo_altin.png',
    name: 'Altın Zibo',
    price: 22000,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.goalCompletions,
      target: 15,
    ),
  ),
  Costume(
    id: 'zibo_elmas',
    imageAsset: 'assets/images/zibo_elmas.png',
    name: 'Elmas Kaplama Zibo',
    price: 33000,
    unlockRequirement: CostumeUnlockRequirement(
      type: CostumeUnlockType.waterDaysCompleted,
      target: 100,
    ),
  ),
];

/// [id]'ye karşılık gelen kostümü bulur; bulunamazsa `null` döner (ör.
/// giyili id'nin listeden kaldırılmış olması gibi olmayacak ama savunmacı
/// bir durum).
Costume? findCostumeById(String id) {
  for (final costume in costumes) {
    if (costume.id == id) return costume;
  }
  return null;
}
