import '../models/home_need.dart';
import '../models/subscription_tier.dart';

/// Zibo'nun Evi rakamları. Önce [HomeConfig.defaults], ardından Firestore
/// `config/home` dokümanı bir kez okunup üstüne uygulanır
/// (`HomeConfigProvider`) — fiyat ve hızlar güncellemesiz değişir.
///
/// Pro/Pro+ değerleri `docs/subscribe_model.md` "Zibo Dünyası avantajları"
/// taslağıdır; kesin liste kullanıcı onayıyla belirlenecek, bu yüzden hepsi
/// uzaktan ayarlanabilir.
class HomeConfig {
  const HomeConfig({
    required this.decayPerHour,
    required this.minLevel,
    required this.sleepMinutesToFull,
    required this.freeFoodsPerDay,
    required this.proFreeFoodsPerDay,
    required this.proPlusFreeFoodsPerDay,
    required this.proDiscount,
    required this.proPlusDiscount,
    required this.proSleepSpeed,
    required this.proPlusSleepSpeed,
    required this.proPlusDecayFactor,
    required this.priceOverrides,
    this.proOnlyItems = const {},
    this.limitedItems = const {},
  });

  /// Saatte düşen puan. 4/saat ≈ 100'den tabana bir günde iner.
  final Map<HomeNeed, double> decayPerHour;

  /// İhtiyaçların inebileceği en düşük değer.
  final double minLevel;

  /// Gerçek zamanlı uyku: enerji 0'dan 100'e bu kadar dakikada dolar
  /// (Faz 0 kararı, uygulama kapalıyken de).
  final double sleepMinutesToFull;

  final int freeFoodsPerDay;
  final int proFreeFoodsPerDay;
  final int proPlusFreeFoodsPerDay;

  /// Dekor ve sabun indirimi (0.1 = %10).
  final double proDiscount;
  final double proPlusDiscount;

  final double proSleepSpeed;
  final double proPlusSleepSpeed;

  /// Pro+'ta ihtiyaçlar bu oranla daha yavaş düşer.
  final double proPlusDecayFactor;

  /// `oda:kategori:eşya` (ya da `food:id`, `soap:id`) → ZC.
  final Map<String, int> priceOverrides;

  /// Yalnızca Pro/Pro+ aboneliğin alabildiği eşyalar (`oda:kategori:eşya`).
  /// Satın alınmışsa abonelik bitse de sahiplik kalır.
  final Set<String> proOnlyItems;

  /// Sezonluk/sınırlı eşyalar: yalnızca [from]–[to] (dahil, gün olarak)
  /// arasında mağazada görünür; satın alınmışsa hep kalır.
  final Map<String, ({DateTime from, DateTime to})> limitedItems;

  bool isProOnly(String key) => proOnlyItems.contains(key);

  bool isLimited(String key) => limitedItems.containsKey(key);

  /// Sınırlı değilse her zaman; sınırlıysa yalnızca tarih aralığında.
  bool isOnSale(String key, DateTime now) {
    final window = limitedItems[key];
    if (window == null) return true;
    final day = DateTime(now.year, now.month, now.day);
    return !day.isBefore(window.from) && !day.isAfter(window.to);
  }

  static const defaults = HomeConfig(
    decayPerHour: {HomeNeed.hunger: 4, HomeNeed.hygiene: 3, HomeNeed.energy: 3, HomeNeed.fun: 4},
    minLevel: 10,
    sleepMinutesToFull: 60,
    freeFoodsPerDay: 3,
    proFreeFoodsPerDay: 5,
    proPlusFreeFoodsPerDay: 7,
    proDiscount: 0.10,
    proPlusDiscount: 0.20,
    proSleepSpeed: 1.5,
    proPlusSleepSpeed: 2,
    proPlusDecayFactor: 0.75,
    priceOverrides: {},
  );

  int freeFoodsFor(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => freeFoodsPerDay,
    SubscriptionTier.pro => proFreeFoodsPerDay,
    SubscriptionTier.proPlus => proPlusFreeFoodsPerDay,
  };

  double sleepSpeedFor(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.free => 1,
    SubscriptionTier.pro => proSleepSpeed,
    SubscriptionTier.proPlus => proPlusSleepSpeed,
  };

  double decayFactorFor(SubscriptionTier tier) => tier == SubscriptionTier.proPlus ? proPlusDecayFactor : 1;

  /// Taban fiyata uzaktan ezme ve abonelik indirimi uygulanmış ZC. Bedava
  /// ürün bedava kalır.
  int priceFor(String key, int base, SubscriptionTier tier) {
    final price = priceOverrides[key] ?? base;
    if (price <= 0) return 0;
    final discount = switch (tier) {
      SubscriptionTier.free => 0.0,
      SubscriptionTier.pro => proDiscount,
      SubscriptionTier.proPlus => proPlusDiscount,
    };
    return (price * (1 - discount)).round().clamp(1, price);
  }

  /// Yemek fiyatı: abonelik indirimi YOK (Pro avantajı daha çok ücretsiz
  /// yemek), yalnızca uzaktan ezme (`food:<id>`).
  int foodPrice(String id, int base) => priceOverrides['food:$id'] ?? base;

  factory HomeConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    double num0(String key, double fallback) => (json[key] as num?)?.toDouble() ?? fallback;
    int int0(String key, int fallback) => (json[key] as num?)?.toInt() ?? fallback;
    final decay = Map<HomeNeed, double>.of(defaults.decayPerHour);
    final rawDecay = json['decayPerHour'];
    if (rawDecay is Map) {
      for (final entry in rawDecay.entries) {
        final need = HomeNeed.fromId('${entry.key}');
        if (need != null && entry.value is num) decay[need] = (entry.value as num).toDouble();
      }
    }
    final prices = <String, int>{};
    final rawPrices = json['priceOverrides'];
    if (rawPrices is Map) {
      for (final entry in rawPrices.entries) {
        if (entry.value is num) prices['${entry.key}'] = (entry.value as num).toInt();
      }
    }
    final proOnly = <String>{
      for (final e in (json['proOnly'] is List ? json['proOnly'] as List : const [])) '$e',
    };
    final limited = <String, ({DateTime from, DateTime to})>{};
    final rawLimited = json['limited'];
    if (rawLimited is Map) {
      for (final entry in rawLimited.entries) {
        final v = entry.value;
        if (v is! Map) continue;
        final from = DateTime.tryParse('${v['from'] ?? ''}');
        final to = DateTime.tryParse('${v['to'] ?? ''}');
        if (from != null && to != null) limited['${entry.key}'] = (from: from, to: to);
      }
    }
    return HomeConfig(
      decayPerHour: decay,
      minLevel: num0('minLevel', defaults.minLevel),
      sleepMinutesToFull: num0('sleepMinutesToFull', defaults.sleepMinutesToFull),
      freeFoodsPerDay: int0('freeFoodsPerDay', defaults.freeFoodsPerDay),
      proFreeFoodsPerDay: int0('proFreeFoodsPerDay', defaults.proFreeFoodsPerDay),
      proPlusFreeFoodsPerDay: int0('proPlusFreeFoodsPerDay', defaults.proPlusFreeFoodsPerDay),
      proDiscount: num0('proDiscount', defaults.proDiscount),
      proPlusDiscount: num0('proPlusDiscount', defaults.proPlusDiscount),
      proSleepSpeed: num0('proSleepSpeed', defaults.proSleepSpeed),
      proPlusSleepSpeed: num0('proPlusSleepSpeed', defaults.proPlusSleepSpeed),
      proPlusDecayFactor: num0('proPlusDecayFactor', defaults.proPlusDecayFactor),
      priceOverrides: prices,
      proOnlyItems: proOnly,
      limitedItems: limited,
    );
  }
}
