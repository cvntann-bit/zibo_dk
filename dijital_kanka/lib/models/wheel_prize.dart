/// Şans Çarkı'nda bir dilime karşılık gelen tek bir ödül.
class WheelPrize {
  const WheelPrize({required this.amount, required this.weight});

  /// Kazanılacak Zibo Coin miktarı.
  final int amount;

  /// Diğer ödüllere göre göreceli ağırlık — büyük olan daha sık çıkar.
  /// Mutlaka 100'e tamamlanması gerekmez (bkz. [pickWeightedPrize]), ama
  /// okunabilirlik için lib/data/wheel_prizes.dart'ta yüzde gibi seçildi.
  final double weight;
}
