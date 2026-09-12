import '../models/badge_definition.dart';

/// Gizli/Eğlenceli Rozetler'in HEPSİ kazanılana kadar paylaştığı ortak
/// "gizem" görseli — kullanıcının masaüstünden `rozetler/gizli_rozet.png`
/// (üç rozetin bulunduğu `GizliEğlenceli Rozetler` ALT klasörünün DIŞINDA,
/// bir üstteki `rozetler` klasöründe) `tool/process_hidden_badge_images.dart`
/// ile kopyalandı. `BadgesGalleryScreen`'in `_BadgeGalleryCard`'ı
/// `badge.isHidden && !earned` iken [ZiboBadgeDefinition.imageAsset] YERİNE
/// bunu gösteriyor.
const hiddenBadgeMysteryImageAsset = 'assets/images/gizli_rozet.webp';

/// Gizli/Eğlenceli Rozetler — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Önceki
/// beş kategoriden İKİ yönden FARKLI:
///
/// 1. **Gizlilik mekaniği** — üçü de `isHidden: true` taşıyor (bkz. o alanın
///    dokümantasyonu). Kullanıcı bunları KAZANANA kadar galeri kartında ne
///    isim ne koşul görünür — yalnızca [hiddenBadgeMysteryImageAsset] +
///    "???" etiketi. **ZC ödül miktarı/ikonu İSTİSNA — bu HER ZAMAN
///    görünür** (2026 İKİNCİ güncelleme, kullanıcının netleştirmesi: "bu
///    gizli rozetlerin altına 777 ZC ve ikonu ekle" — ilk sürümde ödül de
///    isim/koşulla BİRLİKTE gizlenmişti). Kazanıldığı ANDA (kutlama
///    popup'ında VE ondan sonraki galeri kartında) her şey diğer
///    rozetlerle AYNI şekilde açıklanıyor.
/// 2. **`night_owl`/`early_bird`'ün zaman penceresi BİLEREK cihazın kendi
///    saatine (`DateTime.now()`) bağlı, `TrustedTimeProvider`/`AppStreakProvider`
///    GİBİ güvenlik-kritik bir kaynağa DEĞİL** — kullanıcının açık isteği
///    ("cihaz saatine göre") iki kez tekrarlandı; `motivation_quote_selector.
///    dart`'taki `timeBucketFor`'un AYNI "kozmetik/eğlenceli özellik, cihazın
///    GERÇEK yerel saatini yansıtmalı" gerekçesiyle tutarlı — bkz.
///    `HiddenBadgeProvider`'ın kendi dokümantasyonu.
///
/// **Gece Kuşu** (`night_owl`) — cihaz saatine göre gece yarısı (00:00) ile
/// sabah 05:00 arası, 30 FARKLI günde uygulamayı aç — 777 ZC.
/// **Erken Kuş** (`early_bird`) — cihaz saatine göre sabah 06:00-08:00
/// arası, 30 FARKLI günde uygulamayı aç — 777 ZC.
/// **Denge Ustası** (`balance_master`) — AYNI takvim günü içinde
/// uygulamadaki 7 modülün (Hedef Takibi, Şükran Günlüğü, Ruh Hali Takibi,
/// Su Takibi, Manifest Günlüğü, Rüya Günlüğü, Para ve Birikim) HEPSİNE en
/// az bir kayıt/etkileşim ekle — 777 ZC.
///
/// Görseller kullanıcının masaüstündeki `rozetler/GizliEğlenceli Rozetler`
/// klasöründen `tool/process_hidden_badge_images.dart` ile (dosya adları
/// AYNEN korunarak, yalnızca 512px'e küçültülerek) `assets/images/`e
/// kopyalandı.
const hiddenBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'night_owl',
    category: BadgeCategory.hidden,
    imageAsset: 'assets/images/gece_kusu_rozet.webp',
    zcReward: 777,
    isHidden: true,
  ),
  ZiboBadgeDefinition(
    id: 'early_bird',
    category: BadgeCategory.hidden,
    imageAsset: 'assets/images/erkenci_kus_rozet.webp',
    zcReward: 777,
    isHidden: true,
  ),
  ZiboBadgeDefinition(
    id: 'balance_master',
    category: BadgeCategory.hidden,
    imageAsset: 'assets/images/denge_ustasi_rozet.webp',
    zcReward: 777,
    isHidden: true,
  ),
];
