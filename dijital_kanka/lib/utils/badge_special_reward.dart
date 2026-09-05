import 'dart:math';

import '../data/app_themes.dart';
import '../data/costumes.dart';
import '../models/app_theme_option.dart';
import '../models/costume.dart';

/// "İlk Paylaşım"/"Hayalperest" gibi tema hediyesi taşıyan rozetlerin
/// (bkz. `data/badge_gift_rewards.dart`'taki `BadgeGiftReward.theme()`
/// girdileri) verdiği ödül — kullanıcının henüz SAHİP OLMADIĞI STANDART
/// (Premium/Animasyonlu OLMAYAN — [AppThemeOption.isPremiumAnimated]
/// `false`) temalardan RASTGELE biri hediye edilir (çağıran taraf
/// `AppThemeProvider.markOwned(theme.id)` ile sahipliği kalıcı hâle
/// getirir) — mağazadan asla SATIN ALINMADAN. **BİLEREK yalnızca STANDART
/// temalarla sınırlı** (kullanıcının isteği: "standart temalardan biri
/// hediye eder") — Premium/Animasyonlu temalar (650-900 ZC, en pahalı/en
/// özel kademe) bu ücretsiz hediye havuzunun DIŞINDA tutuluyor.
///
/// Saf/test edilebilir bir seçim fonksiyonu — enjekte edilebilir [random],
/// `wheel_prizes.dart`'taki `pickWeightedPrize` ile AYNI felsefe (gerçek
/// rastgelelik üretim kodunda, testte deterministik bir sahte enjekte
/// edilebilir). Kullanıcı sahip OLMADIĞI hiçbir standart tema kalmadıysa
/// (teorik olarak nadir ama imkansız değil — yalnızca 15 standart tema var)
/// `null` döner, hiçbir şey verilmez — çağıran taraf bu durumda sessizce
/// hiçbir ödül duyurmamalı.
AppThemeOption? pickRandomUnownedStandardTheme(
  Set<String> ownedThemeIds, {
  Random? random,
}) {
  final candidates = appThemes
      .where(
        (theme) => !theme.isPremiumAnimated && !ownedThemeIds.contains(theme.id),
      )
      .toList();
  if (candidates.isEmpty) return null;
  final r = random ?? Random();
  return candidates[r.nextInt(candidates.length)];
}

/// Instagram Takip Ödülü'nün kostüm hediyesi — `costumes.dart`'ın fiyata
/// göre sıralı listesinin (ucuzdan pahalıya, bkz. o dosyanın dokümantasyonu)
/// İLK ÜÇTE BİRİNDEN ("düşük fiyatlı kostümler"), henüz SAHİP OLUNMAMIŞ
/// birini rastgele seçer. [pickRandomUnownedStandardTheme] ile AYNI saf/
/// test edilebilir desen. Uygun (ucuz + sahip olunmayan) kostüm kalmadıysa
/// `null` döner.
Costume? pickRandomUnownedLowPricedCostume(
  Set<String> ownedCostumeIds, {
  Random? random,
}) {
  final cutoff = (costumes.length / 3).ceil();
  final candidates = costumes
      .take(cutoff)
      .where((c) => !ownedCostumeIds.contains(c.id))
      .toList();
  if (candidates.isEmpty) return null;
  final r = random ?? Random();
  return candidates[r.nextInt(candidates.length)];
}
