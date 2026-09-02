import 'dart:math';

import '../data/app_themes.dart';
import '../models/app_theme_option.dart';

/// "Tam Gardırop" rozetinin (`ZiboBadgeDefinition.hasSpecialReward`) özel
/// ödülü — bkz. CLAUDE.md "Rozet Sistemi" > "Koleksiyon Rozetleri" bölümü.
/// Kullanıcının netleştirmesi ("özel hediyemiz o — rastgele bir tema hediye
/// etsin"): standart ZC ödülüne EK olarak, kullanıcının henüz SAHİP OLMADIĞI
/// temalardan RASTGELE biri hediye edilir (çağıran taraf `AppThemeProvider.
/// markOwned(theme.id)` ile sahipliği kalıcı hâle getirir) — mağazadan asla
/// SATIN ALINMADAN.
///
/// Saf/test edilebilir bir seçim fonksiyonu — enjekte edilebilir [random],
/// `wheel_prizes.dart`'taki `pickWeightedPrize` ile AYNI felsefe (gerçek
/// rastgelelik üretim kodunda, testte deterministik bir sahte enjekte
/// edilebilir). Kullanıcı TÜM temalara ZATEN sahipse (teorik olarak
/// neredeyse imkansız — bu rozet zaten TÜM kostümlere sahip olmayı
/// gerektiriyor, temalar TAMAMEN AYRI bir ekonomi/koşul olduğu için asla
/// garanti edilmiyor) `null` döner, hiçbir şey verilmez — çağıran taraf bu
/// durumda sessizce hiçbir ödül duyurmamalı.
AppThemeOption? pickRandomUnownedTheme(
  Set<String> ownedThemeIds, {
  Random? random,
}) {
  final candidates = appThemes
      .where((theme) => !ownedThemeIds.contains(theme.id))
      .toList();
  if (candidates.isEmpty) return null;
  final r = random ?? Random();
  return candidates[r.nextInt(candidates.length)];
}
