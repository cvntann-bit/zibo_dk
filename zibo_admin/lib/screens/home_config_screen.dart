import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_log.dart';
import '../home_catalog_keys.dart';
import '../theme.dart';

/// Zibo'nun `HomeConfig.defaults`'unun AYNASI (`dijital_kanka/lib/data/home_config.dart`).
/// Zibo `config/home`'u bu varsayılanların üstüne alan alan uygular; panel de etkin
/// değeri göstermek için aynı birleştirmeyi yapar. **Zibo'da varsayılan değişirse burası da.**
const _defaults = <String, num>{
  'decayPerHour.hunger': 4,
  'decayPerHour.hygiene': 3,
  'decayPerHour.energy': 3,
  'decayPerHour.fun': 4,
  'minLevel': 10,
  'sleepMinutesToFull': 60,
  'freeFoodsPerDay': 3,
  'proFreeFoodsPerDay': 5,
  'proPlusFreeFoodsPerDay': 7,
  'adFoodsPerDay': 2,
  'proDiscount': 0.10,
  'proPlusDiscount': 0.20,
  'proSleepSpeed': 1.5,
  'proPlusSleepSpeed': 2.0,
  'proPlusDecayFactor': 0.75,
};

const _decimals = {'proDiscount', 'proPlusDiscount', 'proSleepSpeed', 'proPlusSleepSpeed', 'proPlusDecayFactor'};

const _labels = {
  'decayPerHour.hunger': 'Tokluk düşüşü (puan/saat)',
  'decayPerHour.hygiene': 'Temizlik düşüşü (puan/saat)',
  'decayPerHour.energy': 'Enerji düşüşü (puan/saat)',
  'decayPerHour.fun': 'Mutluluk düşüşü (puan/saat)',
  'minLevel': 'İhtiyaç tabanı (%)',
  'sleepMinutesToFull': 'Tam dinlenme süresi (dk)',
  'freeFoodsPerDay': 'Ücretsiz yemek · Ücretsiz',
  'proFreeFoodsPerDay': 'Ücretsiz yemek · Pro',
  'proPlusFreeFoodsPerDay': 'Ücretsiz yemek · Pro+',
  'adFoodsPerDay': 'Reklamla +1 yemek (günde)',
  'proDiscount': 'Dekor indirimi · Pro (0,10 = %10)',
  'proPlusDiscount': 'Dekor indirimi · Pro+',
  'proSleepSpeed': 'Uyku hızı · Pro (×)',
  'proPlusSleepSpeed': 'Uyku hızı · Pro+ (×)',
  'proPlusDecayFactor': 'Düşüş çarpanı · Pro+ (0,75 = %25 yavaş)',
};

const _sections = [
  ('İhtiyaçlar', ['decayPerHour.hunger', 'decayPerHour.hygiene', 'decayPerHour.energy', 'decayPerHour.fun', 'minLevel', 'sleepMinutesToFull']),
  ('Ücretsiz yemek', ['freeFoodsPerDay', 'proFreeFoodsPerDay', 'proPlusFreeFoodsPerDay', 'adFoodsPerDay']),
  ('Abonelik avantajları', ['proDiscount', 'proPlusDiscount', 'proSleepSpeed', 'proPlusSleepSpeed', 'proPlusDecayFactor']),
];

final _catalog = {for (final e in homeCatalogKeys) e.$1: e};

String _keyLabel(String key) => _catalog[key]?.$2 ?? key;

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// `config/home` düzenleyici (docs/zibo_world_roadmap.md Faz 8): ihtiyaç hızları,
/// ücretsiz yemek, abonelik avantajları; eşya fiyat ezmeleri, sınırlı süreli
/// (sezonluk) eşyalar ve Pro'ya özel eşyalar. Değişen ÜST alanlar `mergeFields`
/// ile bütün olarak yazılır (silinen anahtarlar da gider), diğerleri kalır.
class HomeConfigScreen extends StatefulWidget {
  const HomeConfigScreen({super.key});

  @override
  State<HomeConfigScreen> createState() => _HomeConfigScreenState();
}

class _HomeConfigScreenState extends State<HomeConfigScreen> {
  static final _doc = FirebaseFirestore.instance.doc('config/home');

  Map<String, num>? _numbers;
  final Map<String, num> _edited = {};
  Map<String, int> _prices = {};
  Map<String, int> _pricesOrig = {};
  Map<String, (DateTime, DateTime)> _limited = {};
  Map<String, (DateTime, DateTime)> _limitedOrig = {};
  List<String> _proOnly = [];
  List<String> _proOnlyOrig = [];
  Object? _loadError;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _numbers = null;
      _loadError = null;
      _edited.clear();
    });
    try {
      final snap = await _doc.get(const GetOptions(source: Source.server));
      final json = snap.data() ?? const <String, dynamic>{};
      final numbers = Map<String, num>.of(_defaults);
      for (final key in _defaults.keys) {
        final parts = key.split('.');
        final v = parts.length == 2 ? (json[parts[0]] is Map ? (json[parts[0]] as Map)[parts[1]] : null) : json[key];
        if (v is num) numbers[key] = v;
      }
      final prices = <String, int>{};
      if (json['priceOverrides'] is Map) {
        (json['priceOverrides'] as Map).forEach((k, v) {
          if (v is num) prices['$k'] = v.toInt();
        });
      }
      final limited = <String, (DateTime, DateTime)>{};
      if (json['limited'] is Map) {
        (json['limited'] as Map).forEach((k, v) {
          if (v is! Map) return;
          final from = DateTime.tryParse('${v['from'] ?? ''}');
          final to = DateTime.tryParse('${v['to'] ?? ''}');
          if (from != null && to != null) limited['$k'] = (from, to);
        });
      }
      final proOnly = [for (final e in (json['proOnly'] is List ? json['proOnly'] as List : const [])) '$e'];
      setState(() {
        _numbers = numbers;
        _prices = Map.of(prices);
        _pricesOrig = prices;
        _limited = Map.of(limited);
        _limitedOrig = limited;
        _proOnly = List.of(proOnly);
        _proOnlyOrig = proOnly;
      });
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  bool _mapEq<V>(Map<String, V> a, Map<String, V> b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  bool get _pricesChanged => !_mapEq(_prices, _pricesOrig);
  bool get _limitedChanged => !_mapEq(_limited, _limitedOrig);
  bool get _proOnlyChanged => _proOnly.toSet().length != _proOnlyOrig.toSet().length || !_proOnly.toSet().containsAll(_proOnlyOrig);
  int get _changeCount => _edited.length + (_pricesChanged ? 1 : 0) + (_limitedChanged ? 1 : 0) + (_proOnlyChanged ? 1 : 0);

  num _value(String key) => _edited[key] ?? _numbers![key]!;

  void _set(String key, num value) {
    setState(() {
      if (value == _numbers![key]) {
        _edited.remove(key);
      } else {
        _edited[key] = value;
      }
    });
  }

  void _discard() => setState(() {
    _edited.clear();
    _prices = Map.of(_pricesOrig);
    _limited = Map.of(_limitedOrig);
    _proOnly = List.of(_proOnlyOrig);
  });

  Map<String, Object> _limitedJson(Map<String, (DateTime, DateTime)> m) => {
    for (final e in m.entries) e.key: {'from': e.value.$1.toIso8601String(), 'to': e.value.$2.toIso8601String()},
  };

  List<String> _summary() => [
    for (final k in (_edited.keys.toList()..sort())) '${_labels[k]}: ${_numbers![k]} → ${_edited[k]}',
    if (_pricesChanged) 'Fiyat değişiklikleri: ${_pricesOrig.length} → ${_prices.length} eşya',
    if (_limitedChanged) 'Sınırlı süreli eşyalar: ${_limitedOrig.length} → ${_limited.length}',
    if (_proOnlyChanged) "Pro'ya özel eşyalar: ${_proOnlyOrig.length} → ${_proOnly.length}",
  ];

  Future<void> _review() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gözden geçir'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in _summary())
                Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(line, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              const Text('Zibo kullanıcıları bir sonraki açılışta yeni değerleri alır.', style: TextStyle(color: kInkSoft, fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yayınla')),
        ],
      ),
    );
    if (ok == true) await _publish();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final data = <String, Object>{};
      final fields = <String>{};
      for (final key in _edited.keys) {
        final parts = key.split('.');
        if (parts.length == 2) {
          // decayPerHour bütün harita olarak yazılır.
          data[parts[0]] = {
            for (final k in _defaults.keys.where((k) => k.startsWith('${parts[0]}.'))) k.split('.')[1]: _value(k),
          };
          fields.add(parts[0]);
        } else {
          data[key] = _edited[key]!;
          fields.add(key);
        }
      }
      if (_pricesChanged) {
        data['priceOverrides'] = Map.of(_prices);
        fields.add('priceOverrides');
      }
      if (_limitedChanged) {
        data['limited'] = _limitedJson(_limited);
        fields.add('limited');
      }
      if (_proOnlyChanged) {
        data['proOnly'] = List.of(_proOnly);
        fields.add('proOnly');
      }
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_doc, data, SetOptions(mergeFields: fields.toList()));
      addAdminLog(
        batch,
        action: 'Ayar değişti',
        target: 'config/home',
        before: {
          for (final k in _edited.keys) k: _numbers![k],
          if (_pricesChanged) 'priceOverrides': _pricesOrig,
          if (_limitedChanged) 'limited': _limitedJson(_limitedOrig),
          if (_proOnlyChanged) 'proOnly': _proOnlyOrig,
        },
        after: {for (final f in fields) f: data[f]},
      );
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yayınlandı ✓')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yazılamadı: $e')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<String?> _pickItem({bool Function((String, String, int, String))? where}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CatalogPicker(where: where),
    );
  }

  Future<void> _addPrice() async {
    final key = await _pickItem(where: (e) => e.$3 > 0 || e.$1.startsWith('food:'));
    if (key == null || !mounted) return;
    final price = await _askNumber(_keyLabel(key), _prices[key] ?? _catalog[key]?.$3 ?? 0);
    if (price != null) setState(() => _prices[key] = price.round());
  }

  Future<void> _addLimited() async {
    final key = await _pickItem();
    if (key == null || !mounted) return;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: now, end: now.add(const Duration(days: 14))),
      helpText: _keyLabel(key),
    );
    if (range == null) return;
    // Bitiş günü dahil: bitiş günü 23:59'a kadar satışta.
    setState(() => _limited[key] = (range.start, range.end.add(const Duration(hours: 23, minutes: 59))));
  }

  Future<void> _addProOnly() async {
    final key = await _pickItem(where: (e) => e.$4.isEmpty && !e.$1.startsWith('food:'));
    if (key == null || _proOnly.contains(key)) return;
    setState(() => _proOnly.add(key));
  }

  Future<num?> _askNumber(String title, num current, {bool decimal = false}) async {
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.numberWithOptions(decimal: decimal)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              final parsed = num.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (parsed != null && parsed >= 0) Navigator.pop(context, parsed);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('config/home okunamadı:\n$_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    if (_numbers == null) return const Center(child: CircularProgressIndicator());
    final changes = _changeCount;
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (final (title, keys) in _sections) _Section(title: title, children: [for (final k in keys) _numberRow(k)]),
                _Section(
                  title: 'Fiyat değişiklikleri',
                  subtitle: 'Eşyanın katalog fiyatı yerine bu fiyat kullanılır (abonelik indirimi üstüne uygulanır).',
                  trailing: IconButton(tooltip: 'Eşya ekle', icon: const Icon(Icons.add_circle_outline), onPressed: _addPrice),
                  children: [
                    if (_prices.isEmpty) const _Empty(),
                    for (final e in _prices.entries)
                      _KeyRow(
                        label: _keyLabel(e.key),
                        value: '${_catalog[e.key]?.$3 ?? '?'} → ${e.value} ZC',
                        changed: _pricesOrig[e.key] != e.value,
                        onTap: () async {
                          final price = await _askNumber(_keyLabel(e.key), e.value);
                          if (price != null) setState(() => _prices[e.key] = price.round());
                        },
                        onRemove: () => setState(() => _prices.remove(e.key)),
                      ),
                  ],
                ),
                _Section(
                  title: 'Sınırlı süreli eşyalar',
                  subtitle: 'Yalnız bu tarihler arasında mağazada görünür (⏳). Alan kullanıcıda kalır.',
                  trailing: IconButton(tooltip: 'Eşya ekle', icon: const Icon(Icons.add_circle_outline), onPressed: _addLimited),
                  children: [
                    if (_limited.isEmpty) const _Empty(),
                    for (final e in _limited.entries)
                      _KeyRow(
                        label: _keyLabel(e.key),
                        value: '${_date(e.value.$1)} – ${_date(e.value.$2)}',
                        changed: _limitedOrig[e.key] != e.value,
                        onRemove: () => setState(() => _limited.remove(e.key)),
                      ),
                  ],
                ),
                _Section(
                  title: "Pro'ya özel eşyalar",
                  subtitle: "Katalogdaki Altın Saray (Pro) ve Elmas (Pro+) serileri zaten özel; buraya ek eşya konabilir (👑).",
                  trailing: IconButton(tooltip: 'Eşya ekle', icon: const Icon(Icons.add_circle_outline), onPressed: _addProOnly),
                  children: [
                    if (_proOnly.isEmpty) const _Empty(),
                    for (final key in _proOnly)
                      _KeyRow(
                        label: _keyLabel(key),
                        value: '👑',
                        changed: !_proOnlyOrig.contains(key),
                        onRemove: () => setState(() => _proOnly.remove(key)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (changes > 0)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(color: kPaper, border: Border(top: BorderSide(color: kInk, width: 2.5))),
              child: Row(
                children: [
                  TextButton(onPressed: _publishing ? null : _discard, child: const Text('Geri al')),
                  const Spacer(),
                  FilledButton(
                    onPressed: _publishing ? null : _review,
                    child: Text(_publishing ? 'Yazılıyor…' : 'Gözden geçir ($changes)'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _numberRow(String key) {
    final value = _value(key);
    final decimal = _decimals.contains(key);
    final step = decimal ? (key.contains('Discount') ? 0.05 : 0.25) : (key == 'sleepMinutesToFull' ? 5 : 1);
    final changed = _edited.containsKey(key);
    num clean(num v) => decimal ? double.parse(v.toStringAsFixed(2)) : v.round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(_labels[key] ?? key, style: const TextStyle(fontSize: 15))),
          _StepButton(icon: Icons.remove, onTap: value - step < 0 ? null : () => _set(key, clean(value - step))),
          GestureDetector(
            onTap: () async {
              final v = await _askNumber(_labels[key] ?? key, value, decimal: decimal);
              if (v != null) _set(key, clean(v));
            },
            child: Container(
              width: 64,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: changed ? kGoldSoft : kCream, borderRadius: BorderRadius.circular(10)),
              child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: () => _set(key, clean(value + step))),
        ],
      ),
    );
  }
}

/// Katalogdan aranarak eşya seçimi.
class _CatalogPicker extends StatefulWidget {
  const _CatalogPicker({this.where});

  final bool Function((String, String, int, String))? where;

  @override
  State<_CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<_CatalogPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = [
      for (final e in homeCatalogKeys)
        if ((widget.where?.call(e) ?? true) && (q.isEmpty || e.$2.toLowerCase().contains(q) || e.$1.contains(q))) e,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Eşya ara (ör. kanepe, elma)'),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final e = items[i];
                  return ListTile(
                    dense: true,
                    title: Text(e.$2),
                    subtitle: Text(e.$1, style: const TextStyle(color: kInkSoft, fontSize: 12)),
                    trailing: Text([if (e.$4.isNotEmpty) e.$4, '${e.$3} ZC'].join(' · ')),
                    onTap: () => Navigator.pop(context, e.$1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.label, required this.value, required this.changed, required this.onRemove, this.onTap});

  final String label;
  final String value;
  final bool changed;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: changed ? FontWeight.w800 : FontWeight.w500))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: changed ? kGoldSoft : kCream, borderRadius: BorderRadius.circular(8)),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            IconButton(tooltip: 'Kaldır', icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Yok', style: TextStyle(color: kInkSoft)));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              ?trailing,
            ],
          ),
          if (subtitle != null) Text(subtitle!, style: const TextStyle(color: kInkSoft, fontSize: 12.5)),
          const Divider(color: kLine, thickness: 1.5),
          ...children,
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap == null ? kLine : kPaper,
          shape: BoxShape.circle,
          border: Border.all(color: kInk, width: 2),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? kInkSoft : kInk),
      ),
    );
  }
}
