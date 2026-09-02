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
