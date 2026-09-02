import '../models/badge_definition.dart';

/// Sosyal/Paylaşım Rozetleri — bkz. CLAUDE.md "Rozet Sistemi" bölümü. Bu
/// kategori, uygulamanın önceden var olan "Zibonu Paylaş" özelliği VE
/// "Arkadaşını Davet Et" (Referral) sistemiyle DOĞRUDAN bağlantılı — yeni
/// bir mekanik İCAT EDİLMEDİ, mevcut iki özelliğin olay/veri akışına
/// bağlanan üç yeni rozet.
///
/// **İlk Paylaşım** — kullanıcı `ZiboShareSheet._share()`'i (bir başarı
/// kartını sosyal medyaya/WhatsApp'a paylaşma) İLK KEZ başarıyla
/// tamamladığında kazanılır — bkz. `BadgeProvider.reconcileSocialBadges`'in
/// `hasSharedAtLeastOnce` parametresi, yalnızca paylaşım BAŞARILI olunca
/// `true` geçiriliyor.
///
/// **Elçi** + **Topluluk Kurucusu** — `ReferralProvider.
/// successfulReferralCount`'a (davet EDEREK kaç arkadaşını BAŞARIYLA
/// kaydettirdiği — sunucu tarafı `processReferralRewards.js`'in bir SONRAKİ
/// çalıştırmasında artırılan, ANINDA GÜNCELLENMEYEN bir sayaç, bkz. o
/// provider'ın dokümantasyonu) bağlı, yalnızca EŞİK farklı (1 / 5).
///
/// Görseller kullanıcının masaüstündeki `rozetler/sosyal paylaşım
/// rozetleri` klasöründen `tool/process_social_badge_images.dart` ile
/// (dosya adları AYNEN korunarak, yalnızca 512px'e küçültülerek)
/// `assets/images/`e kopyalandı.
const socialBadges = <ZiboBadgeDefinition>[
  ZiboBadgeDefinition(
    id: 'first_share',
    category: BadgeCategory.social,
    imageAsset: 'assets/images/ilk_paylasim_rozet.png',
    zcReward: 15,
  ),
  ZiboBadgeDefinition(
    id: 'ambassador',
    category: BadgeCategory.social,
    imageAsset: 'assets/images/elci_rozet.png',
    zcReward: 30,
  ),
  ZiboBadgeDefinition(
    id: 'community_founder',
    category: BadgeCategory.social,
    imageAsset: 'assets/images/topluluk_kurucu_rozet.png',
    zcReward: 150,
  ),
];
