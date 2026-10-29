import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_log.dart';
import '../theme.dart';

/// Zibo'nun `GamesConfig.defaults`'unun AYNASI (`dijital_kanka/lib/data/games_config.dart`).
/// Zibo `config/games`'i bu varsayılanların üstüne alan alan uygular; panel de etkin
/// değeri göstermek için aynı birleştirmeyi yapar. **Zibo'da varsayılan değişirse burası da.**
const _defaultDailyPlays = {'free': 3, 'pro': 5, 'plus': 8};
const _defaultMaxAdPlays = 2;
const _defaultGames = <String, Map<String, num>>{
  'kule': {'perFloor': 2, 'perfectBonus': 1, 'cap': 250},
  'hafiza': {'ptsEasy': 100, 'ptsMid': 180, 'ptsHard': 300, 'mult2': 0.6, 'mult1': 0.3, 'cap': 300},
  '2048': {'scoreDiv': 20, 'bonus256': 50, 'bonus1024': 100, 'bonus2048': 200, 'cap': 600, 'maxUndo': 3},
  'yakala': {'perScore': 1, 'cap': 400},
  'tren': {'perCoin': 5, 'cap': 600},
  'tugla': {'perBrick': 1, 'cap': 400},
  'zipla': {'perCoin': 5, 'cap': 600},
};

const _gameNames = {
  'kule': 'Kule',
  'hafiza': 'Hafıza',
  '2048': '2048',
  'yakala': 'Yakala',
  'tren': 'Tren',
  'tugla': 'Tuğla',
  'zipla': 'Zıpla',
};

const _fieldNames = {
  'cap': 'Tur tavanı ★',
  'perFloor': 'Kat başına ★',
  'perfectBonus': 'Mükemmel bonusu',
  'ptsEasy': 'Kolay seviye ★',
  'ptsMid': 'Orta seviye ★',
  'ptsHard': 'Zor seviye ★',
  'mult2': '2 yıldız çarpanı',
  'mult1': '1 yıldız çarpanı',
  'scoreDiv': 'Skor böleni',
  'bonus256': '256 bonusu',
  'bonus1024': '1024 bonusu',
  'bonus2048': '2048 bonusu',
  'maxUndo': 'Geri alma hakkı',
  'perScore': 'Skor başına ★',
  'perCoin': 'Coin başına ★',
  'perBrick': 'Tuğla başına ★',
};

const _tierNames = {'free': 'Ücretsiz', 'pro': 'Pro', 'plus': 'Pro+'};

/// `config/games` düzenleyici: değerler noktalı yollarla düz tutulur
/// ('dailyPlays.free', 'games.tren.cap', 'games.tren.enabled').
class GamesConfigScreen extends StatefulWidget {
  const GamesConfigScreen({super.key});

  @override
  State<GamesConfigScreen> createState() => _GamesConfigScreenState();
}

class _GamesConfigScreenState extends State<GamesConfigScreen> {
  static final _doc = FirebaseFirestore.instance.doc('config/games');

  Map<String, Object>? _original;
  final Map<String, Object> _edited = {};
  Object? _loadError;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _original = null;
      _loadError = null;
      _edited.clear();
    });
    try {
      final snap = await _doc.get(const GetOptions(source: Source.server));
      setState(() => _original = _effectiveValues(snap.data()));
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  static Map<String, Object> _effectiveValues(Map<String, dynamic>? json) {
    final out = <String, Object>{
      for (final e in _defaultDailyPlays.entries) 'dailyPlays.${e.key}': e.value,
      'maxAdPlaysPerGame': _defaultMaxAdPlays,
      for (final g in _defaultGames.entries) ...{
        'games.${g.key}.enabled': true,
        for (final f in g.value.entries) 'games.${g.key}.${f.key}': f.value,
      },
    };
    if (json == null) return out;
    final plays = json['dailyPlays'];
    if (plays is Map) {
      plays.forEach((k, v) {
        if (v is num) out['dailyPlays.$k'] = v;
      });
    }
    if (json['maxAdPlaysPerGame'] is num) out['maxAdPlaysPerGame'] = json['maxAdPlaysPerGame'] as num;
    final games = json['games'];
    if (games is Map) {
      games.forEach((id, fields) {
        if (fields is! Map) return;
        fields.forEach((k, v) {
          if (v is num || v is bool) out['games.$id.$k'] = v as Object;
        });
      });
    }
    return out;
  }

  Object _value(String path) => _edited[path] ?? _original![path]!;

  void _set(String path, Object value) {
    setState(() {
      if (value == _original![path]) {
        _edited.remove(path);
      } else {
        _edited[path] = value;
      }
    });
  }

  String _label(String path) {
    final parts = path.split('.');
    if (parts[0] == 'dailyPlays') return 'Günlük hak · ${_tierNames[parts[1]] ?? parts[1]}';
    if (parts[0] == 'maxAdPlaysPerGame') return 'Reklamla ek hak';
    final field = parts[2] == 'enabled' ? 'Açık' : (_fieldNames[parts[2]] ?? parts[2]);
    return '${_gameNames[parts[1]] ?? parts[1]} · $field';
  }

  static String _show(Object v) => v is bool ? (v ? 'açık' : 'KAPALI') : '$v';

  Future<void> _review() async {
    final changes = _edited.keys.toList()..sort();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gözden geçir'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${_label(p)}\n', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: _show(_original![p]!), style: const TextStyle(color: kInkSoft)),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                          text: _show(_edited[p]!),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: kGood),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Zibo kullanıcıları bir sonraki açılışta yeni değerleri alır.',
                style: TextStyle(color: kInkSoft, fontSize: 13),
              ),
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
      // Yalnızca değişen alanlar yazılır; merge iç içe haritaları alan alan birleştirir,
      // dokunulmayan alanlar (ör. exchangeLadder) olduğu gibi kalır.
      final update = <String, Object>{};
      _edited.forEach((path, value) {
        final parts = path.split('.');
        var node = update;
        for (final key in parts.take(parts.length - 1)) {
          node = node.putIfAbsent(key, () => <String, Object>{}) as Map<String, Object>;
        }
        node[parts.last] = value;
      });
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_doc, update, SetOptions(merge: true));
      addAdminLog(
        batch,
        action: 'Ayar değişti',
        target: 'config/games',
        before: {for (final p in _edited.keys) p: _original![p]},
        after: Map.of(_edited),
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

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('config/games okunamadı:\n$_loadError', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          ),
        ),
      );
    }
    if (_original == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Section(
                  title: 'Oyun Salonu · günlük haklar',
                  children: [
                    for (final tier in _defaultDailyPlays.keys) _numberRow('dailyPlays.$tier', min: 0),
                    _numberRow('maxAdPlaysPerGame', min: 0),
                  ],
                ),
                for (final id in _defaultGames.keys)
                  _Section(
                    title: _gameNames[id] ?? id,
                    trailing: Switch(
                      value: _value('games.$id.enabled') as bool,
                      onChanged: (v) => _set('games.$id.enabled', v),
                    ),
                    children: [
                      for (final f in _defaultGames[id]!.keys) _numberRow('games.$id.$f', min: 0),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_edited.isNotEmpty)
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: kPaper,
                border: Border(top: BorderSide(color: kInk, width: 2.5)),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _publishing ? null : () => setState(_edited.clear),
                    child: const Text('Geri al'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _publishing ? null : _review,
                    child: Text(_publishing ? 'Yazılıyor…' : 'Gözden geçir (${_edited.length})'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _numberRow(String path, {required num min}) {
    final value = _value(path) as num;
    final isDecimal = value is double || _original![path] is double;
    final step = isDecimal ? 0.1 : (path.endsWith('.cap') ? 10 : 1);
    final changed = _edited.containsKey(path);
    num clean(num v) => isDecimal ? double.parse(v.toStringAsFixed(2)) : v.round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(_label(path).split(' · ').last, style: const TextStyle(fontSize: 15))),
          _StepButton(
            icon: Icons.remove,
            onTap: value - step < min ? null : () => _set(path, clean(value - step)),
          ),
          GestureDetector(
            onTap: () => _typeValue(path, value, isDecimal, min, clean),
            child: Container(
              width: 64,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: changed ? kGoldSoft : kCream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: () => _set(path, clean(value + step))),
        ],
      ),
    );
  }

  Future<void> _typeValue(String path, num current, bool isDecimal, num min, num Function(num) clean) async {
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_label(path)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              final parsed = num.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (parsed != null && parsed >= min) Navigator.pop(context, parsed);
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) _set(path, clean(result));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
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
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              ?trailing,
            ],
          ),
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
