import '../models/coin_package.dart';

// 2026 güncellemesi — her paket miktarına özel görsel. Dosya adı ile
// coinAmount BİLEREK eşleşiyor (ör. zibo_coin_1000.png → 1000 ZC) — yeni bir
// paket eklenirse aynı adlandırma deseniyle bir görsel eklenip aşağıdaki
// listeye bir satır eklemek yeterli. Görseller birbirinden farklı
// boyutlarda/sahnelerde olabilir; bunu tek tip bir çerçeveye sığdırma işi
// (BoxFit.contain, sabit kart boyutu) UI tarafında (`store_screen.dart`
// `_PackageCard`) yapılıyor, burada yalnızca dosya yolu eşleniyor.
const coinPackages = <CoinPackage>[
  CoinPackage(
    id: 'coins_100',
    coinAmount: 100,
    imageAsset: 'assets/images/zibo_coin_100.png',
    price: PackagePrice(amount: 19.99),
  ),
  CoinPackage(
    id: 'coins_250',
    coinAmount: 250,
    imageAsset: 'assets/images/zibo_coin_250.png',
    price: PackagePrice(amount: 44.99),
  ),
  CoinPackage(
    id: 'coins_500',
    coinAmount: 500,
    imageAsset: 'assets/images/zibo_coin_500.png',
    price: PackagePrice(amount: 84.99),
  ),
  CoinPackage(
    id: 'coins_1000',
    coinAmount: 1000,
    imageAsset: 'assets/images/zibo_coin_1000.png',
    price: PackagePrice(amount: 159.99),
  ),
  CoinPackage(
    id: 'coins_10000',
    coinAmount: 10000,
    imageAsset: 'assets/images/zibo_coin_10000.png',
    price: PackagePrice(amount: 1499.99),
    imageScale: 1.2,
  ),
];
