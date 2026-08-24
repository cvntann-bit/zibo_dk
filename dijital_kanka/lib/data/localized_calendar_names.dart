import 'package:flutter/widgets.dart';

/// Uygulama genelinde tarih/gün GÖSTERİMİ için kullanılan, `intl` paketine
/// bilerek başvurmayan (bkz. CLAUDE.md "Yerelleştirme" bölümü — proje genelinde
/// tarih gösterimi için `intl` kullanılmıyor) küçük, sabit üç-dilli veri
/// listeleri. Her ekranın kendi başına taşıdığı `_turkishMonths`/`_formatDate`
/// kopyalarının (yalnızca Türkçe, dil değişince yanlış kalan) YERİNİ alır.
const List<String> monthNamesTr = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const List<String> monthNamesEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> monthNamesEs = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const List<String> monthNamesShortTr = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

const List<String> monthNamesShortEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> monthNamesShortEs = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Pazartesi'den (index 0, `DateTime.weekday == 1`) Pazar'a (index 6).
const List<String> weekdayNamesShortTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const List<String> weekdayNamesShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> weekdayNamesShortEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

List<String> monthNamesForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => monthNamesEn,
  'es' => monthNamesEs,
  _ => monthNamesTr,
};

List<String> monthNamesShortForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => monthNamesShortEn,
  'es' => monthNamesShortEs,
  _ => monthNamesShortTr,
};

List<String> weekdayNamesShortForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => weekdayNamesShortEn,
  'es' => weekdayNamesShortEs,
  _ => weekdayNamesShortTr,
};

/// "5 Ocak 2026" / "5 January 2026" / "5 enero 2026" — proje genelinde
/// geçmiş kayıt listelerinde kullanılan uzun tarih biçimi.
String formatLongDate(DateTime date, Locale locale) =>
    '${date.day} ${monthNamesForLocale(locale)[date.month - 1]} ${date.year}';

/// "5 Oca" / "5 Jan" / "5 ene" — grafik eksen etiketleri gibi kısa yerler için.
String formatShortAxisDate(DateTime date, Locale locale) =>
    '${date.day} ${monthNamesShortForLocale(locale)[date.month - 1]}';

/// `DateTime.weekday` (1=Pazartesi..7=Pazar) için kısa gün adı.
String weekdayShortName(DateTime date, Locale locale) =>
    weekdayNamesShortForLocale(locale)[date.weekday - 1];
