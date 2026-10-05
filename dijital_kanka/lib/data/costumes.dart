import '../models/costume.dart';
import '../models/costume_rarity.dart';

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
///
/// **2026-10 — nadirlik (rarity) + 10 yeni kostüm.** Her kostümün [Costume.rarity]
/// alanı var (Yaygın → Nadir → Epik → Efsanevi → Mitik); Mağaza bu alana göre
/// gruplar, kart çerçevesi bu alana göre renklenir. Liste hâlâ FİYATA göre
/// ucuzdan pahalıya sıralı tutuluyor (`pickRandomUnownedLowPricedCostume` ayrıca
/// kendisi de fiyata göre sıralar — bu sıra ona bağımlı değil).
///
/// **FİYATLAR (2026-10):** Efsanevi'nin TÜMÜ Altın Zibo'nun fiyatında (22000),
/// Mitik'in TÜMÜ Elmas Zibo'nun fiyatında (33000) — kullanıcı kararı. Altın Zibo
/// bu yüzden Mitik'ten Efsanevi'ye alındı. Yaygın/Nadir/Epik fiyatları kademe
/// içinde değişkendir. Galaksi Zibo (Mitik, 33000) damalı zeminli kaynaktan
/// `tool/cutout_checker_costumes.py` ile kesilip eklendi.
const costumes = <Costume>[
  Costume(
    id: 'zibo_hippi',
    imageAsset: 'assets/images/zibo_hippi.webp',
    name: 'Hippi Zibo',
    price: 440,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_sporcu',
    imageAsset: 'assets/images/zibo_sporcu.webp',
    name: 'Sporcu Zibo',
    price: 440,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_chef',
    imageAsset: 'assets/images/zibo_chef.webp',
    name: 'Şef Zibo',
    price: 450,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_ogrenci',
    imageAsset: 'assets/images/zibo_ogrenci.webp',
    name: 'Öğrenci Zibo',
    price: 450,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_asker',
    imageAsset: 'assets/images/zibo_asker.webp',
    name: 'Asker Zibo',
    price: 550,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_hoca',
    imageAsset: 'assets/images/zibo_hoca.webp',
    name: 'Hoca Zibo',
    price: 550,
    rarity: CostumeRarity.common,
  ),
  Costume(
    id: 'zibo_artist',
    imageAsset: 'assets/images/zibo_artist.webp',
    name: 'Sanatçı Zibo',
    price: 700,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_kovboy',
    imageAsset: 'assets/images/zibo_kovboy.webp',
    name: 'Kovboy Zibo',
    price: 700,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_punk',
    imageAsset: 'assets/images/zibo_punk.webp',
    name: 'Punk Zibo',
    price: 715,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_rapci',
    imageAsset: 'assets/images/zibo_rapci.webp',
    name: 'Rapçi Zibo',
    price: 715,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_gentleman',
    imageAsset: 'assets/images/zibo_gentleman.webp',
    name: 'Centilmen Zibo',
    price: 770,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_samurai',
    imageAsset: 'assets/images/zibo_samurai.webp',
    name: 'Samuray Zibo',
    price: 770,
    rarity: CostumeRarity.rare,
  ),
  Costume(
    id: 'zibo_gladyator',
    imageAsset: 'assets/images/zibo_gladyator.webp',
    name: 'Gladyatör Zibo',
    price: 880,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_korsan',
    imageAsset: 'assets/images/zibo_korsan.webp',
    name: 'Korsan Zibo',
    price: 880,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_cyborg',
    imageAsset: 'assets/images/zibo_cyborg.webp',
    name: 'Siborg Zibo',
    price: 935,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_astronot',
    imageAsset: 'assets/images/zibo_astronot.webp',
    name: 'Astronot Zibo',
    price: 990,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_buyucu',
    imageAsset: 'assets/images/zibo_buyucu.webp',
    name: 'Büyücü Zibo',
    price: 2000,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_ninja',
    imageAsset: 'assets/images/zibo_ninja.webp',
    name: 'Ninja Zibo',
    price: 2000,
    rarity: CostumeRarity.epic,
  ),
  Costume(
    id: 'zibo_king',
    imageAsset: 'assets/images/zibo_king.webp',
    name: 'Kral Zibo',
    price: 22000,
    rarity: CostumeRarity.legendary,
  ),
  Costume(
    id: 'zibo_zombi',
    imageAsset: 'assets/images/zibo_zombi.webp',
    name: 'Zombi Zibo',
    price: 22000,
    rarity: CostumeRarity.legendary,
  ),
  Costume(
    id: 'zibo_firavun',
    imageAsset: 'assets/images/zibo_firavun.webp',
    name: 'Firavun Zibo',
    price: 22000,
    rarity: CostumeRarity.legendary,
  ),
  Costume(
    id: 'zibo_viking',
    imageAsset: 'assets/images/zibo_viking.webp',
    name: 'Viking Zibo',
    price: 22000,
    rarity: CostumeRarity.legendary,
  ),
  Costume(
    id: 'zibo_altin',
    imageAsset: 'assets/images/zibo_altin.webp',
    name: 'Altın Zibo',
    price: 22000,
    rarity: CostumeRarity.legendary,
  ),
  Costume(
    id: 'zibo_anime',
    imageAsset: 'assets/images/zibo_anime.webp',
    name: 'Anime Zibo',
    price: 33000,
    rarity: CostumeRarity.mythic,
  ),
  Costume(
    id: 'zibo_ejder_ruhu',
    imageAsset: 'assets/images/zibo_ejder_ruhu.webp',
    name: 'Ejder Ruhu Zibo',
    price: 33000,
    rarity: CostumeRarity.mythic,
  ),
  Costume(
    id: 'zibo_galaksi',
    imageAsset: 'assets/images/zibo_galaksi.webp',
    name: 'Galaksi Zibo',
    price: 33000,
    rarity: CostumeRarity.mythic,
  ),
  Costume(
    id: 'zibo_elmas',
    imageAsset: 'assets/images/zibo_elmas.webp',
    name: 'Elmas Kaplama Zibo',
    price: 33000,
    rarity: CostumeRarity.mythic,
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
