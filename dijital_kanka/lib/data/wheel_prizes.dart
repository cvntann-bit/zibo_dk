import 'dart:math';

import '../models/wheel_prize.dart';

/// Şans Çarkı'ndaki 8 dilim ve ağırlıklı olasılıkları — tek yerde, kolayca
/// ayarlanabilir bir listede tanımlı. Ağırlıklar okunabilirlik için yüzde
/// gibi seçildi (toplamı 100) ama bu zorunlu değil — [pickWeightedPrize]
/// yalnızca göreceli ağırlığa bakar.
///
/// Dağılım kasıtlı: küçük ödüller (2/5/10 ZC) sık çıkar, orta ödül (20 ZC)
/// daha seyrek, büyük ödüller (50-250 ZC) çok seyrek çıkar — en büyük ödül
/// (250 ZC) hepsinin en düşük ihtimallisi.
const wheelPrizes = <WheelPrize>[
  WheelPrize(amount: 2, weight: 28),
  WheelPrize(amount: 5, weight: 27),
  WheelPrize(amount: 10, weight: 27),
  WheelPrize(amount: 20, weight: 9),
  WheelPrize(amount: 50, weight: 3),
  WheelPrize(amount: 100, weight: 2.5),
  WheelPrize(amount: 150, weight: 2),
  WheelPrize(amount: 250, weight: 1.5),
];

/// [prizes] içinden ağırlıklara göre rastgele bir ödül seçer. [random]
/// testte sabit/kontrollü bir üreteç enjekte edebilmek için parametre
/// olarak alınıyor (bkz. [CoinProvider]'ın enjekte edilebilir `Random`'ı).
WheelPrize pickWeightedPrize(List<WheelPrize> prizes, Random random) {
  final totalWeight = prizes.fold<double>(0, (sum, p) => sum + p.weight);
  var roll = random.nextDouble() * totalWeight;
  for (final prize in prizes) {
    if (roll < prize.weight) return prize;
    roll -= prize.weight;
  }
  // Kayan nokta yuvarlama hatalarına karşı güvenlik ağı — normalde buraya
  // ulaşılmaz.
  return prizes.last;
}
