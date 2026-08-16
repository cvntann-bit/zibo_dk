import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Mağaza > Temalar > "Premium/Animasyonlu" bölümündeki temaların arka
/// planına eklenen hafif parçacık animasyonu türü. `none` sıradan (statik
/// gradyan) temalar için — bkz. `AnimatedThemeOverlay`/`ThemeParticleEffect`
/// widget'ları, [AppThemeOption.isPremiumAnimated].
enum ThemeAnimationType {
  none,
  snow,
  galaxy,
  confetti,
  hearts,
  notes,
  tropical,
  petals,
}

/// Zibo Coin ile satın alınabilen, kod-tabanlı (görsel asset gerektirmeyen)
/// bir arayüz teması. Her tema hem açık hem koyu mod için AYRI bir gradyan
/// taşır — kullanıcı Ayarlar'daki açık/koyu mod anahtarını değiştirdiğinde,
/// o an aktif tema (varsa) otomatik olarak kendi uygun varyantına geçer
/// (bkz. `HomeScreen`'deki uygulama noktası, `ThemeProvider.isDarkMode`'a
/// göre `colorsFor` çağrılıyor).
class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.price,
    required this.lightColors,
    required this.darkColors,
    required this.lightPrimary,
    required this.lightPrimaryContainer,
    required this.darkPrimary,
    required this.darkPrimaryContainer,
    this.isStarryInDark = false,
    this.animationType = ThemeAnimationType.none,
  });

  /// Kalıcı depoda (SharedPreferences) sahiplik/aktiflik durumu bu id ile
  /// saklanır — `Costume.id` ile aynı gerekçeyle stabildir.
  final String id;

  /// Yalnızca dahili/geliştirme referansı — EKRANDA GÖSTERMEYİN, kullanıcı
  /// dil değiştirse bile bu hep Türkçe kalır. Görünen isim için
  /// [localizedName] kullanın (bkz. `Costume.localizedName` ile aynı desen).
  final String name;
  final int price;

  /// Gradyan durakları, açık modda sırayla uygulanır (en az 2 renk) —
  /// yalnızca Ana Sayfa'nın "hero" arka planı için (bkz. `HomeScreen`).
  final List<Color> lightColors;

  /// Gradyan durakları, koyu modda sırayla uygulanır.
  final List<Color> darkColors;

  /// Uygulama genelinin (butonlar, alt gezinme çubuğu, konuşma balonları,
  /// kartlar, TÜM sayfaların arka planı) `ColorScheme`'ini besleyen marka
  /// rengi — [lightColors]/[darkColors]'tan BİLEREK ayrı tutuluyor, çünkü
  /// gradyanın en koyu/canlı durakları (özellikle karanlık modda) buton
  /// metni/kontrastı için uygun değil; bunlar aynı renk ailesinin okunabilir
  /// bir türevi.
  final Color lightPrimary;
  final Color lightPrimaryContainer;
  final Color darkPrimary;
  final Color darkPrimaryContainer;

  /// Yalnızca "Gece Gökyüzü" teması için `true` — koyu varyantın üzerine
  /// sabit/deterministik bir yıldız deseni bindirilir (bkz.
  /// `StarryGradientBackground`).
  final bool isStarryInDark;

  /// `none` DEĞİLSE bu tema "Premium/Animasyonlu" — Mağaza'da ayrı bir
  /// bölümde, daha yüksek fiyatla listelenir (bkz. `isPremiumAnimated`) VE
  /// `AnimatedThemeOverlay` bu tema aktifken TÜM sayfaların üzerine canlı
  /// bir parçacık animasyonu (kar/galaksi/konfeti) bindirir — statik
  /// [isStarryInDark]'tan FARKLI bir mekanizma (o yalnızca Mağaza kartı VE
  /// Ana Sayfa'nın "hero" arka planında sabit bir desen çizer, bu ise
  /// uygulama genelinde SÜREKLİ hareket eden bir katmandır).
  final ThemeAnimationType animationType;

  /// Bu tema Mağaza'nın "Premium/Animasyonlu" bölümünde mi listelenmeli.
  bool get isPremiumAnimated => animationType != ThemeAnimationType.none;

  /// [isDark] moduna göre uygun gradyan renk listesini döner.
  List<Color> colorsFor(bool isDark) => isDark ? darkColors : lightColors;

  /// [id]'ye göre temanın o anki dildeki (TR/EN/ES) görünen adı — ARB'deki
  /// `themeName<Id>` anahtarlarından okunur (bkz. `Costume.localizedName`
  /// ile aynı desen).
  String localizedName(AppLocalizations l10n) {
    switch (id) {
      case 'sunset':
        return l10n.themeNameSunset;
      case 'ocean':
        return l10n.themeNameOcean;
      case 'forest':
        return l10n.themeNameForest;
      case 'night_sky':
        return l10n.themeNameNightSky;
      case 'golden_age':
        return l10n.themeNameGoldenAge;
      case 'winter_snow':
        return l10n.themeNameWinterSnow;
      case 'galaxy_stars':
        return l10n.themeNameGalaxyStars;
      case 'party_confetti':
        return l10n.themeNamePartyConfetti;
      case 'hearts_love':
        return l10n.themeNameHeartsLove;
      case 'music_notes':
        return l10n.themeNameMusicNotes;
      case 'tropical_paradise':
        return l10n.themeNameTropicalParadise;
      case 'cherry_blossom':
        return l10n.themeNameCherryBlossom;
      case 'lavender_garden':
        return l10n.themeNameLavenderGarden;
      case 'coral_reef':
        return l10n.themeNameCoralReef;
      case 'cherry_orchard':
        return l10n.themeNameCherryOrchard;
      case 'mint_greens':
        return l10n.themeNameMintGreens;
      case 'desert_dunes':
        return l10n.themeNameDesertDunes;
      case 'moonlight':
        return l10n.themeNameMoonlight;
      case 'copper_hills':
        return l10n.themeNameCopperHills;
      case 'emerald_valley':
        return l10n.themeNameEmeraldValley;
      case 'amethyst_cave':
        return l10n.themeNameAmethystCave;
      case 'dusty_rose_dream':
        return l10n.themeNameDustyRoseDream;
      default:
        return name;
    }
  }

  /// Uygulama genelinde `MaterialApp.theme`/`darkTheme` olarak kullanılacak
  /// tam `ColorScheme`. `ColorScheme.fromSeed`, tohum rengin yalnızca
  /// tonunu/doygunluğunu alıp açık/koyu moda uygun parlaklık tonlarını
  /// KENDİSİ hesapladığı için (girdinin kendi parlaklığından bağımsız),
  /// karanlık modda bile okunabilir bir `primary`/`surface` seti garanti
  /// eder — yalnızca marka renklerini (primary/primaryContainer) elle
  /// sabitliyoruz, geri kalan roller (surface, surfaceContainer, outline
  /// vb.) tohumdan tutarlı biçimde türüyor (`main.dart`'ın kendi varsayılan
  /// temasının `_lightColorScheme`/`_darkColorScheme`'i kurma şekliyle
  /// AYNI desen).
  ColorScheme colorScheme(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final primary = isDark ? darkPrimary : lightPrimary;
    final primaryContainer = isDark ? darkPrimaryContainer : lightPrimaryContainer;
    final onPrimary = primary.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
    final onPrimaryContainer = primaryContainer.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;

    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: onPrimaryContainer,
    );
  }
}
