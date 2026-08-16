import '../models/coin_package.dart';

// Şimdilik tüm paketler aynı zibo_coin.png görselini kullanıyor. İleride bir
// pakete özel görsel eklemek için o satırdaki imageAsset değerini
// değiştirmek yeterli — kodun başka hiçbir yerine dokunmaya gerek yok.
const _defaultCoinImage = 'assets/images/zibo_coin.png';

// 2026 güncellemesi — kullanıcının verdiği gerçek TL fiyatları. Bu değerler
// ŞİMDİLİK sabit/görsel (gerçek bir ödeme işlemi tetiklemiyor,
// `MockPurchaseService` hâlâ kullanılıyor) — gerçek IAP bağlandığında
// mağaza/App Store'un kendi fiyatlarıyla değiştirilecek. `PackagePrice`'ın
// `currencyCode` alanı sayesinde ileride ülkeye göre farklı bir para birimi
// eklenmek istenirse yalnızca burada yeni bir değer atamak yeterli olacak.
const coinPackages = <CoinPackage>[
  CoinPackage(
    id: 'coins_100',
    coinAmount: 100,
    imageAsset: _defaultCoinImage,
    price: PackagePrice(amount: 19.99),
  ),
  CoinPackage(
    id: 'coins_250',
    coinAmount: 250,
    imageAsset: _defaultCoinImage,
    price: PackagePrice(amount: 44.99),
  ),
  CoinPackage(
    id: 'coins_500',
    coinAmount: 500,
    imageAsset: _defaultCoinImage,
    price: PackagePrice(amount: 84.99),
  ),
  CoinPackage(
    id: 'coins_1000',
    coinAmount: 1000,
    imageAsset: _defaultCoinImage,
    price: PackagePrice(amount: 159.99),
  ),
  CoinPackage(
    id: 'coins_10000',
    coinAmount: 10000,
    imageAsset: _defaultCoinImage,
    price: PackagePrice(amount: 1499.99),
  ),
];
