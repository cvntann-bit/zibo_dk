import 'package:flutter/material.dart';

/// Zibo'nun "Çizgi Roman Çıkartması" dili — renkler etkileşimli taslakla
/// (`dijital_kanka/docs/admin_prototype/index.html`) birebir.
const kInk = Color(0xFF14110C);
const kInkSoft = Color(0xFF5B4E3A);
const kPaper = Color(0xFFFFFDF7);
const kCream = Color(0xFFFFF4DE);
const kLine = Color(0xFFE7D9BE);
const kGold = Color(0xFFF3B23C);
const kGoldSoft = Color(0xFFF6D488);
const kGoldPale = Color(0xFFF3E4C0);
const kGood = Color(0xFF3E8E4E);
const kWarn = Color(0xFFC7741B);
const kBad = Color(0xFFC2412F);

BoxDecoration stickerDecoration({
  Color fill = kPaper,
  double radius = 18,
  double borderWidth = 2.5,
  Offset shadowOffset = const Offset(3, 3),
}) {
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kInk, width: borderWidth),
    // Bulanıksız düz gölge — "kesilmiş sticker" hissi.
    boxShadow: [BoxShadow(color: kInk, offset: shadowOffset)],
  );
}

ThemeData buildAdminTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGold,
    primary: kInk,
    onPrimary: kPaper,
    secondary: kGold,
    onSecondary: kInk,
    surface: kCream,
    onSurface: kInk,
    error: kBad,
  );
  const outline = BorderSide(color: kInk, width: 2.5);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: kCream,
    // Siyah üst şerit — yönetici uygulamasını Zibo'dan ilk bakışta ayırt etmek için.
    appBarTheme: const AppBarTheme(
      backgroundColor: kInk,
      foregroundColor: kPaper,
      centerTitle: false,
      titleTextStyle: TextStyle(color: kPaper, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kPaper,
      indicatorColor: kGoldSoft,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kGold,
        foregroundColor: kInk,
        side: outline,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        side: outline,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kPaper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: outline),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: outline),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGold, width: 3),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kInk : kInkSoft),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kGold : kLine),
    ),
  );
}
