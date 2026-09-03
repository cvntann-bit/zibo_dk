import '../l10n/app_localizations.dart';

/// Zibo Coin ile satın alınabilen, Ana Sayfa'daki Zibo'ya "giydirilebilen"
/// bir kostüm.
///
/// **2026 mimari değişikliği — "hedefle ücretsiz açma" mekaniği TAMAMEN
/// KALDIRILDI** (kullanıcı isteği: "kostümler artık sadece PARAYLA satın
/// alınabilsin VEYA rozet sistemi üzerinden hediye olarak kazanılsın").
/// Eski `unlockRequirement` alanı (bir hedefi tamamlayarak ücretsiz açma)
/// ve onu tüketen `CostumeProvider.reconcileGoalUnlocks`/`CostumeCard`'ın
/// ilerleme satırı SİLİNDİ — bkz. `data/badge_gift_rewards.dart`'taki YENİ,
/// çok daha dar kapsamlı mekanizma (yalnızca DOKUZ belirli rozet bir kostüm/
/// tema hediye ediyor, "TÜM kostümler" DEĞİL).
class Costume {
  const Costume({
    required this.id,
    required this.imageAsset,
    required this.name,
    required this.price,
  });

  /// Kalıcı depoda (SharedPreferences) sahiplik/giyili durumu bu id ile
  /// saklanır — dosya adından türetildiği için stabildir.
  final String id;
  final String imageAsset;

  /// Yalnızca dahili/geliştirme referansı — EKRANDA GÖSTERMEYİN, kullanıcı
  /// dil değiştirse bile bu hep Türkçe kalır. Görünen isim için
  /// [localizedName] kullanın (bkz. o metodun dokümantasyonu).
  final String name;
  final int price;

  /// [id]'ye göre kostümün o anki dildeki (TR/EN/ES) görünen adı — ARB'deki
  /// `costumeName<Id>` anahtarlarından okunur. `name` alanı yalnızca sabit/
  /// dahili bir referans olarak kalıyor (ör. coin işlem geçmişi etiketinde
  /// varsayılan); UI'de HER ZAMAN bu metot kullanılmalı.
  String localizedName(AppLocalizations l10n) {
    switch (id) {
      case 'zibo_hippi':
        return l10n.costumeNameZiboHippi;
      case 'zibo_sporcu':
        return l10n.costumeNameZiboSporcu;
      case 'zibo_asker':
        return l10n.costumeNameZiboAsker;
      case 'zibo_hoca':
        return l10n.costumeNameZiboHoca;
      case 'zibo_punk':
        return l10n.costumeNameZiboPunk;
      case 'zibo_rapci':
        return l10n.costumeNameZiboRapci;
      case 'zibo_gladyator':
        return l10n.costumeNameZiboGladyator;
      case 'zibo_korsan':
        return l10n.costumeNameZiboKorsan;
      case 'zibo_zombi':
        return l10n.costumeNameZiboZombi;
      case 'zibo_altin':
        return l10n.costumeNameZiboAltin;
      case 'zibo_elmas':
        return l10n.costumeNameZiboElmas;
      case 'zibo_gentleman':
        return l10n.costumeNameZiboGentleman;
      case 'zibo_samurai':
        return l10n.costumeNameZiboSamurai;
      case 'zibo_cyborg':
        return l10n.costumeNameZiboCyborg;
      case 'zibo_astronot':
        return l10n.costumeNameZiboAstronot;
      case 'zibo_king':
        return l10n.costumeNameZiboKing;
      default:
        return name;
    }
  }
}
