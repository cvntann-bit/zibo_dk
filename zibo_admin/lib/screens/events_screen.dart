import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_log.dart';
import '../theme.dart';

/// Zibo Dünyası etkinlikleri: `events/{id}` — Zibo `EventsProvider` açılışta okur
/// (Zibo 1.18.0+, `dijital_kanka/docs/zibo_world_roadmap.md` Faz 6). Belge şekli Zibo'daki
/// `ZiboEvent.fromJson` ile AYNI olmalı. Şimdilik tek tür: `takvim` (her gün bir kutu).
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

const _langs = {'tr': '🇹🇷 Türkçe', 'en': '🇬🇧 English', 'es': '🇪🇸 Español'};

/// Zibo kataloğunda `eventOnly` olan eşyalar (`tool/generate_home_catalog.py` EVENT_ITEMS).
const _eventItems = {
  'salon:kose:cam': '🎄 Yılbaşı çamı',
  'salon:kose:kardan': '⛄ Kardan adam',
  'salon:puf:hediye': '🎁 Hediye kutuları',
};

String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _dm(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

class _EventsScreenState extends State<EventsScreen> {
  static final _col = FirebaseFirestore.instance.collection('events');

  final _title = {for (final l in _langs.keys) l: TextEditingController()};
  final _desc = {for (final l in _langs.keys) l: TextEditingController()};
  final _dailyZc = TextEditingController(text: '20');
  final _lastZc = TextEditingController(text: '200');
  final Set<String> _enabledLangs = {'tr', 'en', 'es'};
  String _lang = 'tr';
  DateTime _start = DateTime(DateTime.now().year, 12, 1);
  int _days = 25;
  String? _lastItem = 'salon:kose:cam'; // null = son gün de ZC
  bool _catchUp = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [..._title.values, ..._desc.values, _dailyZc, _lastZc]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _end => _start.add(Duration(days: _days - 1));

  int get _daily => int.tryParse(_dailyZc.text.trim()) ?? 0;
  int get _last => int.tryParse(_lastZc.text.trim()) ?? 0;

  List<Map<String, Object>> get _dayList => [
    for (var i = 0; i < _days; i++)
      if (i == _days - 1)
        _lastItem != null ? {'item': _lastItem!} : {'zc': _last}
      else
        {'zc': _daily},
  ];

  String? get _problem {
    if (!_enabledLangs.contains('tr')) return 'Türkçe başlık zorunlu (diğer diller yoksa Türkçe gösterilir).';
    for (final l in _enabledLangs) {
      if (_title[l]!.text.trim().isEmpty) return '${_langs[l]}: başlık boş (ya da dili kapat).';
    }
    if (_daily < 0 || _daily > 1000) return 'Günlük ZC 0–1000 arası olmalı.';
    if (_lastItem == null && (_last < 0 || _last > 1000)) return 'Son gün ZC 0–1000 arası olmalı.';
    return null;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _start = date);
  }

  Future<void> _publish() async {
    final problem = _problem;
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final totalZc = _dayList.fold<int>(0, (n, d) => n + ((d['zc'] as int?) ?? 0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği yayınla'),
        content: Text(
          '${_title['tr']!.text.trim()}\n${_dm(_start)} → ${_dm(_end)} ($_days gün)\n'
          'Kişi başı toplam: $totalZc ZC${_lastItem != null ? ' + ${_eventItems[_lastItem]}' : ''}\n'
          '${_catchUp ? 'Kaçırılan günler sonradan açılabilir.' : 'Yalnızca o günün kutusu açılır.'}\n\n'
          'Zibo 1.18.0+ kullanan herkes görür.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yayınla')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final ref = _col.doc();
      final doc = {
        'type': 'takvim',
        'enabled': true,
        'title': {for (final l in _enabledLangs) l: _title[l]!.text.trim()},
        'description': {
          for (final l in _enabledLangs)
            if (_desc[l]!.text.trim().isNotEmpty) l: _desc[l]!.text.trim(),
        },
        'start': _ymd(_start),
        'end': _ymd(_end),
        'catchUp': _catchUp,
        'days': _dayList,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.set(ref, doc);
      addAdminLog(
        batch,
        action: 'Etkinlik yayınlandı',
        target: 'events/${ref.id}',
        before: const {},
        after: {'title': _title['tr']!.text.trim(), 'start': _ymd(_start), 'end': _ymd(_end), 'totalZc': totalZc, 'lastItem': ?_lastItem},
      );
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yayınlandı ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yazılamadı: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setEnabled(DocumentReference<Map<String, dynamic>> ref, bool enabled) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(ref, {'enabled': enabled});
      addAdminLog(
        batch,
        action: enabled ? 'Etkinlik açıldı' : 'Etkinlik kapatıldı',
        target: 'events/${ref.id}',
        before: {'enabled': !enabled},
        after: {'enabled': enabled},
      );
      await batch.commit();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yazılamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _composer(),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _publish, child: Text(_busy ? 'Yazılıyor…' : 'Yayınla')),
        const SizedBox(height: 24),
        const Text('Etkinlikler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _history(),
      ],
    );
  }

  Widget _composer() {
    final l = _enabledLangs.contains(_lang) ? _lang : 'tr';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tür: Takvim — her gün bir kutu açılır', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final code in _langs.keys)
                FilterChip(
                  label: Text(_langs[code]!),
                  selected: _enabledLangs.contains(code),
                  onSelected: code == 'tr'
                      ? null
                      : (v) => setState(() {
                          v ? _enabledLangs.add(code) : _enabledLangs.remove(code);
                          if (v) _lang = code;
                        }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              for (final code in _langs.keys)
                if (_enabledLangs.contains(code)) ButtonSegment(value: code, label: Text(code.toUpperCase())),
            ],
            selected: {l},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
          const SizedBox(height: 10),
          TextField(
            key: ValueKey('ev-title-$l'),
            controller: _title[l],
            maxLength: 40,
            decoration: InputDecoration(labelText: 'Başlık (${l.toUpperCase()})', hintText: 'Yılbaşı takvimi'),
          ),
          TextField(
            key: ValueKey('ev-desc-$l'),
            controller: _desc[l],
            maxLength: 120,
            decoration: InputDecoration(labelText: 'Kısa açıklama (${l.toUpperCase()}, isteğe bağlı)'),
          ),
          const Divider(color: kLine, thickness: 1.5),
          Row(
            children: [
              const Text('Başlangıç: ', style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(child: Text('${_dm(_start)} → ${_dm(_end)}')),
              TextButton(onPressed: _pickStart, child: const Text('Tarih seç')),
            ],
          ),
          Row(
            children: [
              const Text('Gün sayısı: ', style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(
                child: Slider(
                  value: _days.toDouble(),
                  min: 3,
                  max: 31,
                  divisions: 28,
                  label: '$_days',
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
              ),
              Text('$_days'),
            ],
          ),
          const Divider(color: kLine, thickness: 1.5),
          TextField(
            controller: _dailyZc,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Her günün ödülü (ZC)', helperText: '0–1000'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          const Text('Son günün ödülü', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in _eventItems.entries)
                ChoiceChip(label: Text(e.value), selected: _lastItem == e.key, onSelected: (_) => setState(() => _lastItem = e.key)),
              ChoiceChip(label: const Text('💰 ZC'), selected: _lastItem == null, onSelected: (_) => setState(() => _lastItem = null)),
            ],
          ),
          if (_lastItem == null)
            TextField(
              controller: _lastZc,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Son gün ZC', helperText: '0–1000'),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kaçırılan günler sonradan açılabilsin'),
            subtitle: const Text('Kapalıysa yalnızca o günün kutusu açılır.'),
            value: _catchUp,
            onChanged: (v) => setState(() => _catchUp = v),
          ),
        ],
      ),
    );
  }

  Widget _history() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.orderBy('start', descending: true).limit(20).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Text('${snap.error}', style: const TextStyle(color: kBad));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('Henüz etkinlik yok.', style: TextStyle(color: kInkSoft));
        return Column(children: [for (final doc in docs) _tile(doc)]);
      },
    );
  }

  Widget _tile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime.tryParse('${d['start'] ?? ''}');
    final end = DateTime.tryParse('${d['end'] ?? ''}');
    final enabled = d['enabled'] == true;
    final (label, color) = !enabled
        ? ('Kapalı', kInkSoft)
        : end == null || end.isBefore(today)
        ? ('Bitti', kInkSoft)
        : (start != null && start.isAfter(today) ? ('Planlı', kWarn) : ('Yayında', kGood));
    final title = (d['title'] as Map?)?['tr'] ?? '(başlıksız)';
    final days = (d['days'] as List?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$title', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${start == null ? '?' : _dm(start)} → ${end == null ? '?' : _dm(end)} · $days gün · ${d['catchUp'] == false ? 'telafi yok' : 'telafi var'}',
                  style: const TextStyle(color: kInkSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              Switch(value: enabled, onChanged: (v) => _setEnabled(doc.reference, v)),
            ],
          ),
        ],
      ),
    );
  }
}
