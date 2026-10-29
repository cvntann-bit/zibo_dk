import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_log.dart';
import '../theme.dart';

/// Uygulama içi mesaj kartı: `inAppMessages/{id}` — Zibo açılışta okur, Ana Sayfa'da kart
/// olarak BİR KEZ gösterir (`InAppMessageProvider`, Zibo 1.18.0+). Belge şekli Zibo'daki
/// `InAppMessage.fromJson` ile AYNI olmalı.
class InAppMessageScreen extends StatefulWidget {
  const InAppMessageScreen({super.key});

  @override
  State<InAppMessageScreen> createState() => _InAppMessageScreenState();
}

const _langs = {'tr': '🇹🇷 Türkçe', 'en': '🇬🇧 English', 'es': '🇪🇸 Español'};
const _audiences = {'all': 'Herkes', 'free': 'Ücretsiz', 'pro': 'Pro / Pro+'};
const _durations = [3, 7, 14, 30];
const _emojis = ['📣', '🎉', '🎁', '✨', '🏆', '❤️', '🔥', '📅'];
const _titleMax = 60;
const _bodyMax = 500;

String _fmt(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
}

class _InAppMessageScreenState extends State<InAppMessageScreen> {
  static final _col = FirebaseFirestore.instance.collection('inAppMessages');

  final _title = {for (final l in _langs.keys) l: TextEditingController()};
  final _body = {for (final l in _langs.keys) l: TextEditingController()};
  final _onlyUid = TextEditingController();
  final Set<String> _enabledLangs = {'tr'};
  String _lang = 'tr';
  String _emoji = '📣';
  String _audience = 'all';
  int _days = 7;
  DateTime? _startAt; // null = hemen
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [..._title.values, ..._body.values, _onlyUid]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _activeLang => _enabledLangs.contains(_lang) ? _lang : (_enabledLangs.isEmpty ? 'tr' : _enabledLangs.first);

  Map<String, Map<String, String>> get _texts => {
    for (final l in _enabledLangs) l: {'title': _title[l]!.text.trim(), 'body': _body[l]!.text.trim()},
  };

  String? get _problem {
    if (_enabledLangs.isEmpty) return 'En az bir dil seç.';
    for (final l in _enabledLangs) {
      if (_title[l]!.text.trim().isEmpty || _body[l]!.text.trim().isEmpty) {
        return '${_langs[l]}: başlık ve metin dolu olmalı (ya da dili kapat).';
      }
    }
    return null;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startAt ?? now));
    if (time == null) return;
    setState(() => _startAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _publish() async {
    final problem = _problem;
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final onlyUid = _onlyUid.text.trim();
    final start = _startAt ?? DateTime.now();
    final end = start.add(Duration(days: _days));
    final who = onlyUid.isEmpty
        ? '${_audiences[_audience]} · ${_enabledLangs.map((l) => _langs[l]).join(', ')}'
        : 'YALNIZCA: $onlyUid';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesaj kartını yayınla'),
        content: Text(
          '$who\n${_startAt == null ? 'Şimdi' : _fmt(start)} → ${_fmt(end)} ($_days gün)\n\n'
          'Her kullanıcı Zibo\'yu açınca Ana Sayfa\'da BİR KEZ görür.',
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
      final batch = FirebaseFirestore.instance.batch();
      batch.set(ref, {
        'createdAt': FieldValue.serverTimestamp(),
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'emoji': _emoji,
        'audience': _audience,
        'texts': _texts,
        if (onlyUid.isNotEmpty) 'onlyUid': onlyUid,
      });
      addAdminLog(
        batch,
        action: 'Mesaj kartı yayınlandı',
        target: 'inAppMessages/${ref.id}',
        before: const {},
        after: {
          'audience': onlyUid.isEmpty ? _audience : 'uid:$onlyUid',
          'langs': _texts.keys.toList(),
          'start': start.toIso8601String(),
          'days': _days,
        },
      );
      await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yayınlandı ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yazılamadı: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop(DocumentReference<Map<String, dynamic>> ref, DateTime oldEnd) async {
    try {
      final now = Timestamp.now();
      final batch = FirebaseFirestore.instance.batch();
      batch.update(ref, {'endAt': now});
      addAdminLog(
        batch,
        action: 'Mesaj kartı durduruldu',
        target: 'inAppMessages/${ref.id}',
        before: {'endAt': oldEnd.toIso8601String()},
        after: {'endAt': now.toDate().toIso8601String()},
      );
      await batch.commit();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Durdurulamadı: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _composer(),
        const SizedBox(height: 16),
        const Text('Önizleme (Zibo\'da)', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _preview(),
        const SizedBox(height: 16),
        FilledButton(onPressed: _busy ? null : _publish, child: Text(_busy ? 'Yazılıyor…' : 'Yayınla')),
        const SizedBox(height: 8),
        TextField(
          controller: _onlyUid,
          decoration: const InputDecoration(
            labelText: 'Yalnızca bu hesap (isteğe bağlı)',
            helperText: 'Zibo davet kodu — önce kendinde denemek için. Boşsa kitleye gider.',
            isDense: true,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Mesaj kartları', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _history(),
      ],
    );
  }

  Widget _composer() {
    final l = _activeLang;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final code in _langs.keys)
                FilterChip(
                  label: Text(_langs[code]!),
                  selected: _enabledLangs.contains(code),
                  onSelected: (v) => setState(() {
                    v ? _enabledLangs.add(code) : _enabledLangs.remove(code);
                    if (v) _lang = code;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Seçilmeyen dildeki kullanıcı kartı GÖRMEZ.', style: TextStyle(color: kInkSoft, fontSize: 12)),
          if (_enabledLangs.isNotEmpty) ...[
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                for (final code in _langs.keys)
                  if (_enabledLangs.contains(code)) ButtonSegment(value: code, label: Text(code.toUpperCase())),
              ],
              selected: {l},
              onSelectionChanged: (s) => setState(() => _lang = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              key: ValueKey('iam-title-$l'),
              controller: _title[l],
              maxLength: _titleMax,
              decoration: InputDecoration(labelText: 'Başlık (${l.toUpperCase()})'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              key: ValueKey('iam-body-$l'),
              controller: _body[l],
              maxLength: _bodyMax,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: 'Mesaj (${l.toUpperCase()})'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const Divider(color: kLine, thickness: 1.5),
          const Text('Simge', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final e in _emojis)
                ChoiceChip(
                  label: Text(e, style: const TextStyle(fontSize: 18)),
                  selected: _emoji == e,
                  onSelected: (_) => setState(() => _emoji = e),
                ),
            ],
          ),
          const Divider(color: kLine, thickness: 1.5),
          const Text('Kitle', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final e in _audiences.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _audience == e.key,
                  onSelected: (_) => setState(() => _audience = e.key),
                ),
            ],
          ),
          const Divider(color: kLine, thickness: 1.5),
          Row(
            children: [
              const Text('Başlangıç: ', style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(child: Text(_startAt == null ? 'Şimdi' : _fmt(_startAt!))),
              if (_startAt != null) TextButton(onPressed: () => setState(() => _startAt = null), child: const Text('Şimdi')),
              TextButton(onPressed: _pickStart, child: const Text('Planla')),
            ],
          ),
          Row(
            children: [
              const Text('Süre: ', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final d in _durations)
                      ChoiceChip(
                        label: Text('$d gün'),
                        selected: _days == d,
                        onSelected: (_) => setState(() => _days = d),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Süre içinde Zibo\'yu açan kullanıcı görür; süre bitince kimseye gösterilmez.',
            style: TextStyle(color: kInkSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Zibo'daki `InAppMessageCard` görünümünün kaba kopyası.
  Widget _preview() {
    final l = _activeLang;
    final title = _title[l]!.text.trim();
    final body = _body[l]!.text.trim();
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: stickerDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kGoldSoft,
                shape: BoxShape.circle,
                border: Border.all(color: kInk, width: 2.5),
              ),
              child: Text(_emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 10),
            Text(
              title.isEmpty ? 'Başlık' : title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body.isEmpty ? 'Mesaj…' : body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 14),
            FilledButton(onPressed: () {}, child: const Text('Tamam')),
          ],
        ),
      ),
    );
  }

  Widget _history() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.orderBy('createdAt', descending: true).limit(20).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Text('${snap.error}', style: const TextStyle(color: kBad));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('Henüz mesaj kartı yok.', style: TextStyle(color: kInkSoft));
        return Column(children: [for (final doc in docs) _tile(doc)]);
      },
    );
  }

  Widget _tile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final now = DateTime.now();
    final start = (d['startAt'] as Timestamp?)?.toDate();
    final end = (d['endAt'] as Timestamp?)?.toDate();
    final (label, color) = end == null || !end.isAfter(now)
        ? ('Bitti', kInkSoft)
        : (start != null && start.isAfter(now) ? ('Planlı', kWarn) : ('Yayında', kGood));
    final texts = (d['texts'] as Map?) ?? const {};
    final first = (texts['tr'] ?? (texts.isEmpty ? null : texts.values.first)) as Map?;
    final onlyUid = d['onlyUid'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
      child: Row(
        children: [
          Text('${d['emoji'] ?? '📣'}', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${first?['title'] ?? '(başlıksız)'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${onlyUid != null ? 'yalnız ${onlyUid.substring(0, onlyUid.length.clamp(0, 6))}…' : _audiences[d['audience']] ?? d['audience']}'
                  ' · ${texts.keys.join('/')}'
                  '${start == null ? '' : ' · ${_fmt(start)}'}${end == null ? '' : ' → ${_fmt(end)}'}',
                  style: const TextStyle(color: kInkSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              if (label != 'Bitti' && end != null)
                TextButton(onPressed: () => _stop(doc.reference, end), child: const Text('Durdur')),
            ],
          ),
        ],
      ),
    );
  }
}
