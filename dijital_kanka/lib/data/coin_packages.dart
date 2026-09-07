import '../models/coin_package.dart';

// 2026 güncellemesi — her paket miktarına özel görsel. Dosya adı GENELDE
// coinAmount ile eşleşir (ör. zibo_coin_1000.png → 1000 ZC). **İstisna:
// `coins_5000`** kullanıcı isteğiyle KENDİ görseli olmadan, 1000 ZC'nin
// görselini (`zibo_coin_1000.png`) yeniden kullanır — yeni bir varlık
// eklenmedi. Görseller birbirinden farklı boyutlarda/sahnelerde olabilir;
// bunu tek tip bir çerçeveye sığdırma işi (BoxFit.contain, sabit kart
// boyutu) UI tarafında (`store_screen.dart` `_PackageCard`) yapılıyor,
// burada yalnızca dosya yolu eşleniyor.
//
// **2026 fiyat + bonus güncellemesi (kullanıcı isteği):** tüm paketlerin
// TL fiyatı ~%15-27 DÜŞÜRÜLDÜ, araya yeni bir `coins_5000` paketi eklendi
// (1000→10000 arasındaki büyük boşluğu doldurmak için) ve HER paket artık
// bir `bonusCoins` taşıyor — Mağaza kartında ayrı, yeşil parlak bir
// "+N bonus" satırı olarak gösteriliyor. Satın almada bakiyeye eklenen
// GERÇEK tutar `CoinPackage.totalCoins` (miktar + bonus).
//
// **`CoinPackage.id` hâlâ Play Console tüketilebilir ürün id'leriyle
// BİREBİR eşleşmeli** — buradaki `price` yalnızca GÖRSEL/fallback değer,
// kullanıcının ödediği tutar Play Console'dan gelir (bkz.
// `CoinProvider.queryLocalizedPrice`). Yeni `coins_5000` ürünü Play
// Console'da AÇILMALI, diğerlerinin fiyatı da orada güncellenmeli — aksi
// halde uygulama düşük fiyatı gösterir ama Google eski fiyattan tahsil eder.
const coinPackages = <CoinPackage>[
  CoinPackage(
    id: 'coins_100',
    coinAmount: 100,
    bonusCoins: 10,
    imageAsset: 'assets/images/zibo_coin_100.png',
    price: PackagePrice(amount: 16.99),
  ),
  CoinPackage(
    id: 'coins_250',
    coinAmount: 250,
    bonusCoins: 25,
    imageAsset: 'assets/images/zibo_coin_250.png',
    price: PackagePrice(amount: 37.99),
  ),
  CoinPackage(
    id: 'coins_500',
    coinAmount: 500,
    bonusCoins: 50,
    imageAsset: 'assets/images/zibo_coin_500.png',
    price: PackagePrice(amount: 69.99),
  ),
  CoinPackage(
    id: 'coins_1000',
    coinAmount: 1000,
    bonusCoins: 100,
    imageAsset: 'assets/images/zibo_coin_1000.png',
    price: PackagePrice(amount: 129.99),
  ),
  CoinPackage(
    id: 'coins_5000',
    coinAmount: 5000,
    bonusCoins: 250,
    // Kendi görseli YOK — kullanıcı isteğiyle 1000 ZC görseli yeniden
    // kullanılıyor.
    imageAsset: 'assets/images/zibo_coin_1000.png',
    price: PackagePrice(amount: 599.99),
  ),
  CoinPackage(
    id: 'coins_10000',
    coinAmount: 10000,
    bonusCoins: 500,
    imageAsset: 'assets/images/zibo_coin_10000.png',
    price: PackagePrice(amount: 1099.99),
    imageScale: 1.2,
  ),
];
