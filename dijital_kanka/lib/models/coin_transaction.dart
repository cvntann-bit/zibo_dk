enum CoinTransactionType { earn, spend }

/// Tek bir coin kazanma/harcama olayının kaydı. Şimdilik yalnızca bellekte
/// (CoinProvider içinde) tutulur; ileride geçmiş ekranı gerçek verilerle
/// çalışacağı zaman bu model kalıcı depolamaya (ör. bir veritabanına)
/// olduğu gibi taşınabilir.
class CoinTransaction {
  const CoinTransaction({
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });

  final CoinTransactionType type;
  final int amount; // Her zaman pozitif; işaret type'tan belli olur.
  final String reason;
  final DateTime timestamp;

  /// Bakiyeye etkisi: kazançta +amount, harcamada -amount.
  int get signedAmount =>
      type == CoinTransactionType.earn ? amount : -amount;
}
