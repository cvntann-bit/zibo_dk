import '../utils/currency_format.dart';

/// Mağazada satılan bir Zibo Coin paketi. [imageAsset] paket verisinin bir
/// parçası olduğu için (kodda sabit değil), ileride her paket miktarına
/// özel bir görsel (ör. 100 ZC için kavanoz, 10000 ZC için taşan sandık)
/// eklemek yalnızca bu listedeki ilgili satırı güncellemek kadar kolay
/// olacak. [price] gerçek IAP fiyatları bağlanana kadar sabit/görsel bir
/// değer (bkz. [PackagePrice]) — henüz atanmamışsa `null` kalır ve mağaza
/// kartı genel "Satın Al" metnine düşer.
class CoinPackage {
  const CoinPackage({
    required this.id,
    required this.coinAmount,
    required this.imageAsset,
    this.price,
    this.imageScale = 1.0,
  });

  final String id;
  final int coinAmount;
  final String imageAsset;
  final PackagePrice? price;

  /// `_PackageCard`'ın ortak görsel çerçevesine (bkz. `store_screen.dart`)
  /// uygulanan çarpan — varsayılan `1.0` (tüm paketler AYNI çerçeve
  /// boyutunda). **2026 güncellemesi:** en yüksek paket (10000 ZC) kullanıcı
  /// isteğiyle diğerlerinden "biraz daha büyük" görünsün diye `1.2` olarak
  /// ayarlandı — kart düzeni (`GridView`'ın `childAspectRatio`'su) BOZULMADAN,
  /// yalnızca bu TEK paketin görsel çerçevesi büyütüldü.
  final double imageScale;
}

/// Bir paketin gösterilen fiyatı. `currencyCode` (ISO 4217, ör. `'TRY'`)
/// ayrı bir alan olarak tutuluyor — kullanıcının "ülkeye göre farklı para
/// birimi/fiyat gösterebilecek şekilde esnek tut" isteği doğrultusunda;
/// şimdilik yalnızca `'TRY'` kullanılıyor ama ileride ülkeye göre farklı bir
/// `PackagePrice` seçmek (ör. bir ülke → para birimi eşlemesi) yalnızca veri
/// katmanında bir değişiklik gerektirecek, `CoinPackage`/UI kodu
/// değişmeyecek.
class PackagePrice {
  const PackagePrice({required this.amount, this.currencyCode = 'TRY'});

  /// Ana para birimi cinsinden tutar (ör. 44.99) — en küçük birim (kuruş vb.)
  /// DEĞİL, doğrudan gösterilecek ondalıklı değer.
  final double amount;
  final String currencyCode;

  /// Kullanıcıya gösterilecek, para birimine göre biçimlendirilmiş metin
  /// (ör. "44,99 ₺") — sayı formatı sabit Türkçe kuralına göre (varsayılan
  /// `languageCode`, bkz. `formatCurrencyAmount`).
  String get formatted => formatCurrencyAmount(amount, currencyCode);

  /// [formatted] ile AYNI ama sayı biçimini (ondalık/binlik ayracı) verilen
  /// arayüz diline göre uyarlar (bkz. `formatCurrencyAmount`'taki
  /// `languageCode` notu) — ör. Zibo ADS fiyatı gibi üç dilde de gösterilen
  /// yerler için. `formatted` bilerek DEĞİŞTİRİLMEDİ (geriye dönük uyumluluk
  /// — mevcut Mağaza paket kartları hâlâ onu kullanıyor).
  String formattedForLocale(String languageCode) =>
      formatCurrencyAmount(amount, currencyCode, languageCode: languageCode);
}
