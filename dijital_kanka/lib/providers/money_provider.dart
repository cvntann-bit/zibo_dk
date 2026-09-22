import 'package:flutter/foundation.dart';

import '../models/money_entry.dart';
import '../services/cloud_state_store.dart';

/// Harcamalar/Birikimler/Gelen Para kategorilerindeki kayıtları tutan tek
/// kaynak. `CloudStateStore` ile kalıcı — `ThemeProvider`/`CostumeProvider`
/// gibi (tüm kategoriler tek bir belge/anahtar altında).
class MoneyProvider extends ChangeNotifier {
  MoneyProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'moneyEntries';

  final DateTime Function() _now;
  final CloudStateStore _store;

  final Map<MoneyCategory, List<MoneyEntry>> _entries = {
    for (final category in MoneyCategory.values) category: <MoneyEntry>[],
  };

  int _nextId = 0;

  /// İlgili kategorideki kayıtların salt okunur listesi.
  List<MoneyEntry> entriesFor(MoneyCategory category) =>
      List.unmodifiable(_entries[category]!);

  /// İlgili kategorideki kayıtların tutar toplamı — ham/para-birimi-kör bir
  /// toplam (bkz. `totalsByCurrencyFor` — kayıtlar birden fazla para birimi
  /// taşıyorsa GÖSTERİME uygun DEĞİL, yalnızca tek-para-birimli kullanım
  /// için hâlâ anlamlı; UI artık `totalsByCurrencyFor`'u kullanıyor).
  double totalFor(MoneyCategory category) =>
      _entries[category]!.fold(0, (sum, entry) => sum + entry.amount);

  /// TÜM kategorilerdeki (Harcamalar + Birikimler + Gelen Para) kayıtların
  /// toplam SAYISI — "Birikim Ustası" rozeti için (bkz. `module_mastery_
  /// badges.dart` — "toplam 20 kayıt", hangi kategoriden geldiği ÖNEMSİZ).
  int get totalEntryCount =>
      _entries.values.fold(0, (sum, list) => sum + list.length);

  /// Bugün (HANGİ kategoriden olursa olsun) en az bir kayıt eklenmiş mi —
  /// "Denge Ustası" (Gizli/Eğlenceli Rozetler, bkz. `hidden_badges.dart`)
  /// rozetinin YEDİ modül kontrolünden biri.
  bool get hasEntryToday {
    final now = _now();
    return _entries.values.any(
      (list) => list.any(
        (e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day,
      ),
    );
  }

  /// **2026 güncellemesi** — ilgili kategorideki kayıtları PARA BİRİMİNE
  /// göre gruplayıp her birinin kendi toplamını döner (ör.
  /// `{'TRY': 500, 'USD': 50}`) — kullanıcının açık isteği "otomatik kur
  /// çevirisi yapmaya çalışma, her para birimini kendi toplamıyla ayrı ayrı
  /// göster". Anahtar sırası GÜVENCE ALTINDA DEĞİL (`Map` ekleme sırası) —
  /// çağıran taraf (bkz. `MoneyCategoryCard`) gösterim için kendi
  /// sıralamasını uyguluyor.
  Map<String, double> totalsByCurrencyFor(MoneyCategory category) {
    final totals = <String, double>{};
    for (final entry in _entries[category]!) {
      totals[entry.currencyCode] = (totals[entry.currencyCode] ?? 0) + entry.amount;
    }
    return totals;
  }

  /// **Faz 5 (D3)** — kategori başına, PARA BİRİMİNE göre (bkz.
  /// [totalsByCurrencyFor]) aylık ORTALAMA tutar: toplam / (ilk kayıttan
  /// bugüne kadar geçen ay sayısı, en az 1). Zibo Pro+'a özel basit analiz
  /// kartları için.
  Map<String, double> averageMonthlyFor(MoneyCategory category) {
    final entries = _entries[category]!;
    if (entries.isEmpty) return {};
    final totals = totalsByCurrencyFor(category);
    final earliest = entries
        .map((e) => e.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = _now();
    final monthsSpanned =
        ((now.year - earliest.year) * 12 + (now.month - earliest.month) + 1)
            .clamp(1, 1 << 30);
    return {
      for (final entry in totals.entries) entry.key: entry.value / monthsSpanned,
    };
  }

  /// **Faz 5 (D3)** — Harcamalar kategorisinde, PARA BİRİMİ başına en çok
  /// harcanan KALEM (`MoneyEntry.name`'e göre gruplanmış toplam).
  /// `MoneyCategory`'nin yalnızca 3 sabit kovası (`expense`/`saving`/
  /// `income`) olduğu için "en çok harcanan kategori" burada kaydın ADI
  /// anlamına geliyor (ör. kullanıcı tekrar tekrar "Kira" yazdıysa o).
  Map<String, ({String name, double total})> topExpenseItemByCurrency() {
    final totalsByCurrencyAndName = <String, Map<String, double>>{};
    for (final entry in _entries[MoneyCategory.expense]!) {
      final byName = totalsByCurrencyAndName.putIfAbsent(
        entry.currencyCode,
        () => {},
      );
      byName[entry.name] = (byName[entry.name] ?? 0) + entry.amount;
    }
    final result = <String, ({String name, double total})>{};
    for (final currencyEntry in totalsByCurrencyAndName.entries) {
      var bestName = '';
      var bestTotal = -1.0;
      for (final nameEntry in currencyEntry.value.entries) {
        if (nameEntry.value > bestTotal) {
          bestTotal = nameEntry.value;
          bestName = nameEntry.key;
        }
      }
      result[currencyEntry.key] = (name: bestName, total: bestTotal);
    }
    return result;
  }

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded == null) return;
    try {
      _nextId = decoded['nextId'] as int;
      final byCategory = decoded['entries'] as Map<String, dynamic>;
      for (final category in MoneyCategory.values) {
        final rawList = byCategory[category.name] as List? ?? const [];
        _entries[category] = rawList.map(_entryFromJson).toList();
      }
      // Eski (kategori birleştirmeden ÖNCEki) kayıtlı veri ayrı bir
      // 'payment' (Ödemeler) listesi taşıyordu — "Harcamalar" ile aynı şeyi
      // ifade ettiği için artık ayrı değil, doğrudan harcamalara katılıyor.
      final legacyPayments = byCategory['payment'] as List? ?? const [];
      if (legacyPayments.isNotEmpty) {
        _entries[MoneyCategory.expense] = [
          ..._entries[MoneyCategory.expense]!,
          ...legacyPayments.map(_entryFromJson),
        ];
      }
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  /// Eski (tarih alanı eklenmeden ÖNCEki) kayıtlı veride 'date' yok — bu
  /// durumda göç anındaki "şimdi" kullanılır (bkz. `MoneyEntry.date`
  /// dokümantasyonu, yalnızca trend grafiğinin zaman eksenini etkiler).
  /// **2026 güncellemesi** — eski (para birimi alanı eklenmeden ÖNCEki)
  /// kayıtlı veride `currencyCode` yok, bu durumda 'TRY'ye düşülür
  /// (kullanıcının kendi önerdiği varsayılan — uygulamanın Para ve Birikim
  /// modülünün eski tek-global-para-birimi davranışıyla AYNI, bkz.
  /// `CurrencyProvider.defaultCurrencyCode`) — ayrı bir migrasyon betiği/
  /// Cloud Function GEREKMEDİ, bu satır her `_loadFromPrefs()`'te
  /// (yerelden VEYA Firestore'dan fark etmeksizin) çalışıp bir SONRAKİ
  /// `_save()`'de kalıcı hale geliyor, `date` alanının eklenmesindeki AYNI
  /// "oku-zamanı-göç-et" deseni.
  MoneyEntry _entryFromJson(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    final rawDate = map['date'] as String?;
    return MoneyEntry(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: rawDate != null ? DateTime.parse(rawDate) : _now(),
      currencyCode: map['currencyCode'] as String? ?? 'TRY',
    );
  }

  Future<void> _save() async {
    await _store.save({
      'nextId': _nextId,
      'entries': {
        for (final category in MoneyCategory.values)
          category.name: _entries[category]!
              .map(
                (e) => {
                  'id': e.id,
                  'name': e.name,
                  'amount': e.amount,
                  'date': e.date.toIso8601String(),
                  'currencyCode': e.currencyCode,
                },
              )
              .toList(),
      },
    });
  }

  void addEntry(
    MoneyCategory category, {
    required String name,
    required double amount,
    required String currencyCode,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || amount <= 0) return;
    _entries[category]!.add(
      MoneyEntry(
        id: '${_nextId++}',
        name: trimmed,
        amount: amount,
        date: _now(),
        currencyCode: currencyCode,
      ),
    );
    notifyListeners();
    _save();
  }

  void removeEntry(MoneyCategory category, String id) {
    _entries[category]!.removeWhere((entry) => entry.id == id);
    notifyListeners();
    _save();
  }

  /// Mevcut bir kaydın adını/tutarını/para birimini günceller — `date`/`id`
  /// korunur.
  void updateEntry(
    MoneyCategory category, {
    required String id,
    required String name,
    required double amount,
    required String currencyCode,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || amount <= 0) return;
    final entries = _entries[category]!;
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    entries[index] = MoneyEntry(
      id: id,
      name: trimmed,
      amount: amount,
      date: entries[index].date,
      currencyCode: currencyCode,
    );
    notifyListeners();
    _save();
  }
}
