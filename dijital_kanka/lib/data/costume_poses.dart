/// Kostümsüz (varsayılan) Zibo görseli — hiçbir kostüm giyilmemişken VE
/// giyili bir kostümün henüz poz seti YOKSA (bkz. [costumePoses]) bu tek
/// statik görsele düşülür. `ZiboAnimatedImage`'ın `fallbackImage`'ı olarak
/// kullanılıyor.
const defaultZiboImage = 'assets/images/zibo_yeni.png';

/// Kostümsüz Zibo'nun poz seti — Akinatör tarzı poz döngüsü
/// (`ZiboAnimatedImage`, bkz. o widget'ın dokümantasyonu) bu beş görsel
/// arasında dönüyor. [costumePoses] ile aynı mekanizmayı paylaşır, yalnızca
/// anahtarı `null` kostüm (giyili kostüm yok) durumuna karşılık geldiği için
/// ayrı bir sabit olarak tutuluyor.
const defaultZiboPoses = <String>[
  'assets/images/zibo_df_pose1.png',
  'assets/images/zibo_df_pose2.png',
  'assets/images/zibo_df_pose3.png',
  'assets/images/zibo_df_pose4.png',
  'assets/images/zibo_df_pose5.png',
];

/// Kostüm id → o kostüme ait poz görselleri listesi. **2026 güncellemesi —
/// artık 16 kostümün TÜMÜ burada** (yalnızca kostümsüz varsayılan
/// [defaultZiboPoses] ayrı tutuluyor) — en son eklenen 5'i (Centilmen/Kral/
/// Astronot/Siborg/Samuray, `tool/process_new_costume_poses.dart` ile AYNI
/// global 763px hedefe işlendi). YALNIZCA burada bir girdisi olan
/// kostümler poz döngüsüne sahip olur — henüz poz seti eklenmemiş bir
/// kostüm (bu Map'te YOKSA)
/// `ZiboAnimatedImage` otomatik olarak o kostümün tek statik
/// `Costume.imageAsset`'ine düşer, hata vermez. Yeni bir kostüm için poz
/// seti eklendiğinde tek yapılması gereken buraya bir girdi eklemek —
/// `ZiboAnimatedImage`'ı kullanan 8 ekranın hiçbiri değişmeden otomatik
/// olarak poz döngüsüne geçer.
///
/// Tüm poz PNG'leri `tool/process_all_poses.dart`/`tool/process_new_costume_
/// poses.dart` ile TEK bir GLOBAL hedef içerik yüksekliğine (763px) göre
/// kırpılıp ölçeklendi — yalnızca AYNI kostümün kendi pozları arasında değil,
/// FARKLI kostümler arasında geçiş yapıldığında da Zibo'nun görünen boyutu
/// SABİT kalır (bkz. CLAUDE.md "Zibo Poz/Animasyon Sistemi" bölümü).
const costumePoses = <String, List<String>>{
  'zibo_sporcu': [
    'assets/images/zibo_sporcu_pose1.png',
    'assets/images/zibo_sporcu_pose2.png',
    'assets/images/zibo_sporcu_pose3.png',
    'assets/images/zibo_sporcu_pose4.png',
  ],
  'zibo_rapci': [
    'assets/images/zibo_rapci_pose1.png',
    'assets/images/zibo_rapci_pose2.png',
    'assets/images/zibo_rapci_pose3.png',
    'assets/images/zibo_rapci_pose4.png',
  ],
  'zibo_punk': [
    'assets/images/zibo_punk_pose1.png',
    'assets/images/zibo_punk_pose2.png',
  ],
  'zibo_asker': [
    'assets/images/zibo_asker_pose1.png',
    'assets/images/zibo_asker_pose2.png',
    'assets/images/zibo_asker_pose3.png',
  ],
  'zibo_gladyator': [
    'assets/images/zibo_gladyator_pose1.png',
    'assets/images/zibo_gladyator_pose2.png',
    'assets/images/zibo_gladyator_pose3.png',
    'assets/images/zibo_gladyator_pose4.png',
  ],
  'zibo_hippi': [
    'assets/images/zibo_hippi_pose1.png',
    'assets/images/zibo_hippi_pose2.png',
    'assets/images/zibo_hippi_pose3.png',
    'assets/images/zibo_hippi_pose4.png',
  ],
  'zibo_hoca': [
    'assets/images/zibo_hoca_pose1.png',
    'assets/images/zibo_hoca_pose2.png',
    'assets/images/zibo_hoca_pose3.png',
  ],
  // Kullanıcı "zibo_korsan_pose1-3" dedi ama eklenen dosyalarda 4. bir poz
  // da vardı (`zibo_koran_pose4.png` — dosya adında YAZIM HATASI, "korsan"
  // yerine "koran"; `zibo_korsan_pose4.png` olarak düzeltilip yeniden
  // adlandırıldı). Dördü de kullanılıyor.
  'zibo_korsan': [
    'assets/images/zibo_korsan_pose1.png',
    'assets/images/zibo_korsan_pose2.png',
    'assets/images/zibo_korsan_pose3.png',
    'assets/images/zibo_korsan_pose4.png',
  ],
  'zibo_zombi': [
    'assets/images/zibo_zombi_pose1.png',
    'assets/images/zibo_zombi_pose2.png',
    'assets/images/zibo_zombi_pose3.png',
  ],
  'zibo_altin': [
    'assets/images/zibo_altin_pose1.png',
    'assets/images/zibo_altin_pose2.png',
    'assets/images/zibo_altin_pose3.png',
  ],
  'zibo_elmas': [
    'assets/images/zibo_elmas_pose1.png',
    'assets/images/zibo_elmas_pose2.png',
    'assets/images/zibo_elmas_pose3.png',
  ],
  // Kullanıcı "gentleman_zibo_pose1-2" dedi ama eklenen dosyalarda 3. bir
  // poz da vardı (`gentleman_zibo_pose2.png` — dosya adında YAZIM HATASI,
  // kelime sırası ters; `zibo_gentleman_pose2.png` olarak düzeltilip diğer
  // iki pozla ("zibo_gentleman_pose1/3.png") aynı düzene getirildi). Üçü de
  // kullanılıyor.
  'zibo_gentleman': [
    'assets/images/zibo_gentleman_pose1.png',
    'assets/images/zibo_gentleman_pose2.png',
    'assets/images/zibo_gentleman_pose3.png',
  ],
  'zibo_samurai': [
    'assets/images/zibo_samurai_pose1.png',
    'assets/images/zibo_samurai_pose2.png',
  ],
  'zibo_cyborg': [
    'assets/images/zibo_cyborg_pose1.png',
    'assets/images/zibo_cyborg_pose2.png',
  ],
  'zibo_astronot': [
    'assets/images/zibo_astronot_pose1.png',
    'assets/images/zibo_astronot_pose2.png',
    'assets/images/zibo_astronot_pose3.png',
  ],
  'zibo_king': [
    'assets/images/zibo_king_pose1.png',
    'assets/images/zibo_king_pose2.png',
    'assets/images/zibo_king_pose3.png',
  ],
};

/// [costumeId] için poz listesini döner: `null` (kostümsüz) ise
/// [defaultZiboPoses]; belirli bir kostüm id'si verilip [costumePoses]'ta
/// karşılığı YOKSA `null` döner (çağıran taraf, `ZiboAnimatedImage`, bu
/// durumda statik tek görsele düşer).
List<String>? posesForCostume(String? costumeId) {
  if (costumeId == null) return defaultZiboPoses;
  return costumePoses[costumeId];
}
