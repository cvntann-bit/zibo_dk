/// Para ve Birikim modülünde seçilebilecek para birimleri. Yalnızca
/// GÖRÜNTÜLEME amaçlı (bir kur dönüşümü/gerçek zamanlı kur API'si YOK —
/// kullanıcı hangi para biriminde takip ettiğini seçiyor, tutarlar olduğu
/// gibi o birimin sembolüyle gösteriliyor). Kod (`code`) ISO 4217; `name`
/// bilerek İngilizce/evrensel isim (uygulamanın diğer para birimi kodlarını
/// [PackagePrice]/mağaza fiyatlarında olduğu gibi çevirmeme convansiyonuyla
/// tutarlı) — yalnızca seçim listesinde tanınabilirlik için.
class CurrencyOption {
  const CurrencyOption({required this.code, required this.symbol, required this.name});

  final String code;
  final String symbol;
  final String name;
}

const List<CurrencyOption> currencies = [
  CurrencyOption(code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar'),
  CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyOption(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  CurrencyOption(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
  CurrencyOption(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
  CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  CurrencyOption(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
  CurrencyOption(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
  CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  CurrencyOption(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
  CurrencyOption(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
  CurrencyOption(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
  CurrencyOption(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
  CurrencyOption(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
  CurrencyOption(code: 'DKK', symbol: 'kr', name: 'Danish Krone'),
  CurrencyOption(code: 'PLN', symbol: 'zł', name: 'Polish Złoty'),
  CurrencyOption(code: 'CZK', symbol: 'Kč', name: 'Czech Koruna'),
  CurrencyOption(code: 'HUF', symbol: 'Ft', name: 'Hungarian Forint'),
  CurrencyOption(code: 'RON', symbol: 'lei', name: 'Romanian Leu'),
  CurrencyOption(code: 'UAH', symbol: '₴', name: 'Ukrainian Hryvnia'),
  CurrencyOption(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  CurrencyOption(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
  CurrencyOption(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
  CurrencyOption(code: 'QAR', symbol: 'ر.ق', name: 'Qatari Riyal'),
  CurrencyOption(code: 'KWD', symbol: 'د.ك', name: 'Kuwaiti Dinar'),
  CurrencyOption(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
  CurrencyOption(code: 'ILS', symbol: '₪', name: 'Israeli New Shekel'),
  CurrencyOption(code: 'COP', symbol: 'CO\$', name: 'Colombian Peso'),
  CurrencyOption(code: 'ARS', symbol: 'AR\$', name: 'Argentine Peso'),
  CurrencyOption(code: 'CLP', symbol: 'CL\$', name: 'Chilean Peso'),
  CurrencyOption(code: 'PEN', symbol: 'S/', name: 'Peruvian Sol'),
  CurrencyOption(code: 'UYU', symbol: '\$U', name: 'Uruguayan Peso'),
  CurrencyOption(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  CurrencyOption(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
  CurrencyOption(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
  CurrencyOption(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  CurrencyOption(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  CurrencyOption(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  CurrencyOption(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
  CurrencyOption(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee'),
  CurrencyOption(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
  CurrencyOption(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  CurrencyOption(code: 'KES', symbol: 'KSh', name: 'Kenyan Shilling'),
  CurrencyOption(code: 'MAD', symbol: 'د.م.', name: 'Moroccan Dirham'),
  CurrencyOption(code: 'TWD', symbol: 'NT\$', name: 'New Taiwan Dollar'),
  CurrencyOption(code: 'AZN', symbol: '₼', name: 'Azerbaijani Manat'),
  CurrencyOption(code: 'GEL', symbol: '₾', name: 'Georgian Lari'),
];

/// [code] listede yoksa (bozuk/eski kalıcı veri) varsayılan olarak TRY döner.
CurrencyOption currencyByCode(String code) => currencies.firstWhere(
  (currency) => currency.code == code,
  orElse: () => currencies.first,
);
