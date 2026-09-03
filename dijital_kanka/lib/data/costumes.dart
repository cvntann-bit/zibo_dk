import '../models/costume.dart';

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
/// **2026 mimari değişikliği — "TÜM kostümler hedefle de açılabilsin"
/// mekaniği TAMAMEN KALDIRILDI (kullanıcı isteği).** Önceki bir turda her
/// kostüme bir `unlockRequirement` (bir hedefi tamamlayarak ücretsiz açma)
/// eklenmişti — bu, `Costume.unlockRequirement`/`CostumeUnlockRequirement`/
/// `CostumeProvider.reconcileGoalUnlocks`/`CostumeCard`'ın ilerleme
/// satırıyla BİRLİKTE SİLİNDİ. **Kostümler artık YALNIZCA İKİ yoldan
/// kazanılabilir: (1) Mağaza'dan Zibo Coin ile SATIN ALMA, (2) belirli bir
/// rozeti kazanıp hediye olarak alma** — bkz. YENİ
/// `data/badge_gift_rewards.dart` (yalnızca DOKUZ rozet bir kostüm/tema
/// hediye ediyor, "TÜM kostümler" gibi genel bir mekanizma DEĞİL).
const costumes = <Costume>[
  Costume(
    id: 'zibo_hippi',
    imageAsset: 'assets/images/zibo_hippi.png',
    name: 'Hippi Zibo',
    price: 440,
  ),
  Costume(
    id: 'zibo_sporcu',
    imageAsset: 'assets/images/zibo_sporcu.png',
    name: 'Sporcu Zibo',
    price: 440,
  ),
  Costume(
    id: 'zibo_asker',
    imageAsset: 'assets/images/zibo_asker.png',
    name: 'Asker Zibo',
    price: 550,
  ),
  Costume(
    id: 'zibo_hoca',
    imageAsset: 'assets/images/zibo_hoca.png',
    name: 'Hoca Zibo',
    price: 550,
  ),
  Costume(
    id: 'zibo_punk',
    imageAsset: 'assets/images/zibo_punk.png',
    name: 'Punk Zibo',
    price: 715,
  ),
  Costume(
    id: 'zibo_rapci',
    imageAsset: 'assets/images/zibo_rapci.png',
    name: 'Rapçi Zibo',
    price: 715,
  ),
  Costume(
    id: 'zibo_gentleman',
    imageAsset: 'assets/images/zibo_gentleman.png',
    name: 'Centilmen Zibo',
    price: 770,
  ),
  Costume(
    id: 'zibo_samurai',
    imageAsset: 'assets/images/zibo_samurai.png',
    name: 'Samuray Zibo',
    price: 770,
  ),
  Costume(
    id: 'zibo_gladyator',
    imageAsset: 'assets/images/zibo_gladyator.png',
    name: 'Gladyatör Zibo',
    price: 880,
  ),
  Costume(
    id: 'zibo_korsan',
    imageAsset: 'assets/images/zibo_korsan.png',
    name: 'Korsan Zibo',
    price: 880,
  ),
  Costume(
    id: 'zibo_cyborg',
    imageAsset: 'assets/images/zibo_cyborg.png',
    name: 'Siborg Zibo',
    price: 935,
  ),
  Costume(
    id: 'zibo_astronot',
    imageAsset: 'assets/images/zibo_astronot.png',
    name: 'Astronot Zibo',
    price: 990,
  ),
  Costume(
    id: 'zibo_king',
    imageAsset: 'assets/images/zibo_king.png',
    name: 'Kral Zibo',
    price: 1045,
  ),
  Costume(
    id: 'zibo_zombi',
    imageAsset: 'assets/images/zibo_zombi.png',
    name: 'Zombi Zibo',
    price: 1100,
  ),
  Costume(
    id: 'zibo_altin',
    imageAsset: 'assets/images/zibo_altin.png',
    name: 'Altın Zibo',
    price: 22000,
  ),
  Costume(
    id: 'zibo_elmas',
    imageAsset: 'assets/images/zibo_elmas.png',
    name: 'Elmas Kaplama Zibo',
    price: 33000,
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
