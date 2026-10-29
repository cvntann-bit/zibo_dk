import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin_log.dart';
import '../theme.dart';

/// Duyuru (push bildirimi): panel `broadcasts/{id}` yazar, saatlik iş
/// (`notification-scripts/src/sendBroadcasts.js`) gönderir — "Hemen" = bir sonraki saat başı (+07 dk).
class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

const _langs = {'tr': '🇹🇷 Türkçe', 'en': '🇬🇧 English', 'es': '🇪🇸 Español'};
const _audiences = {'all': 'Herkes', 'pro': 'Pro / Pro+', 'inactive7': '7+ gündür gelmeyen'};
const _titleMax = 80;
const _bodyMax = 400;

String _fmt(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  static final _col = FirebaseFirestore.instance.collection('broadcasts');

  final _title = {for (final l in _langs.keys) l: TextEditingController()};
  final _body = {for (final l in _langs.keys) l: TextEditingController()};
  // Bilerek boş: yönetici uygulamasının uid'i telefondaki Zibo hesabıyla aynı DEĞİL (token'ı yok —
  // 2026-10-29 ilk testte "atlandı=1" böyle çıktı). Zibo > Davet Et'teki kod yapıştırılır.
  final _testUid = TextEditingController();
  final Set<String> _enabledLangs = {'tr'};
  String _lang = 'tr';
  String _audience = 'all';
  DateTime? _sendAfter; // null = hemen
  bool _busy = false;
  int? _tokenCount;

  @override
  void initState() {
    super.initState();
    _loadReach();
  }

  @override
  void dispose() {
    for (final c in [..._title.values, ..._body.values, _testUid]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Bildirim alabilen cihaz sayısı (fcmToken'ı olan kullanıcılar) — kaba ulaşım tahmini.
  Future<void> _loadReach() async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNull: false)
          .count()
          .get();
      if (mounted) setState(() => _tokenCount = agg.count);
    } catch (_) {}
  }

  Map<String, Map<String, String>> get _texts => {
    for (final l in _enabledLangs)
      if (_title[l]!.text.trim().isNotEmpty && _body[l]!.text.trim().isNotEmpty)
        l: {'title': _title[l]!.text.trim(), 'body': _body[l]!.text.trim()},
  };

  String? get _problem {
    for (final l in _enabledLangs) {
      if (_title[l]!.text.trim().isEmpty || _body[l]!.text.trim().isEmpty) {
        return '${_langs[l]}: başlık ve metin dolu olmalı (ya da dili kapat).';
      }
    }
    if (_enabledLangs.isEmpty) return 'En az bir dil seç.';
    return null;
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _sendAfter ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_sendAfter ?? now));
    if (time == null) return;
    setState(() => _sendAfter = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit({required bool test}) async {
    final problem = _problem;
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final testUid = _testUid.text.trim();
    if (test) {
      if (testUid.isEmpty || testUid.contains('/')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test için Zibo davet kodunu gir.')));
        return;
      }
      // Token'ı olmayan hesaba gönderim sessizce "atlandı" olur — sıraya almadan önce söyle.
      final snap = await FirebaseFirestore.instance.collection('users').doc(testUid).get();
      if (!mounted) return;
      if (snap.data()?['fcmToken'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bu hesabın bildirim token'ı yok (Zibo bu kodla açık değil ya da bildirim izni kapalı).")),
        );
        return;
      }
    }
    final when = test || _sendAfter == null ? 'bir sonraki saat başı (+07 dk)' : _fmt(_sendAfter!);
    final who = test ? 'YALNIZCA test hesabı: $testUid' : '${_audiences[_audience]} · ${_enabledLangs.map((l) => _langs[l]).join(', ')}';
    final reach = !test && _tokenCount != null ? '\nBildirim alabilen cihaz (toplam): $_tokenCount' : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(test ? 'Test duyurusu' : 'Duyuruyu gönder'),
        content: Text('$who\nZaman: $when$reach\n\n«${_title['tr']!.text.trim().isNotEmpty ? _title['tr']!.text.trim() : _texts.values.first['title']}»'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(test ? 'Teste gönder' : 'Sıraya al')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final ref = _col.doc();
      final data = <String, Object?>{
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'sendAfter': test || _sendAfter == null ? Timestamp.now() : Timestamp.fromDate(_sendAfter!),
        'audience': _audience,
        'texts': _texts,
        if (test) 'testUid': testUid,
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.set(ref, data);
      addAdminLog(
        batch,
        action: test ? 'Test duyurusu' : 'Duyuru sıraya alındı',
        target: 'broadcasts/${ref.id}',
        before: const {},
        after: {
          'audience': test ? 'test:$testUid' : _audience,
          'langs': _texts.keys.toList(),
          'sendAfter': test || _sendAfter == null ? 'hemen' : _sendAfter!.toIso8601String(),
        },
      );
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıraya alındı ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yazılamadı: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.data()?['status'] != 'pending') throw StateError('Artık beklemede değil (gönderiliyor/gönderildi).');
        tx.update(ref, {'status': 'canceled'});
        tx.set(
          newAdminLogRef(),
          adminLogEntry(
            action: 'Duyuru iptal',
            target: 'broadcasts/${ref.id}',
            before: {'status': 'pending'},
            after: {'status': 'canceled'},
          ),
        );
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İptal edilemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _composer(),
        const SizedBox(height: 16),
        _preview(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _submit(test: true),
                child: const Text('Önce teste gönder'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(test: false),
                child: const Text('Gönder'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _testUid,
          decoration: const InputDecoration(
            labelText: 'Test hesabı — Zibo davet kodun',
            helperText: "Zibo > Davet Et'teki kod",
            isDense: true,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Son duyurular', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _history(),
      ],
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final l in _langs.keys)
                FilterChip(
                  label: Text(_langs[l]!),
                  selected: _enabledLangs.contains(l),
                  onSelected: (v) => setState(() {
                    v ? _enabledLangs.add(l) : _enabledLangs.remove(l);
                    if (v) _lang = l;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Seçilmeyen dildeki kullanıcılara GİTMEZ.',
            style: TextStyle(color: kInkSoft, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_enabledLangs.isNotEmpty) ...[
            SegmentedButton<String>(
              segments: [
                for (final l in _langs.keys)
                  if (_enabledLangs.contains(l)) ButtonSegment(value: l, label: Text(l.toUpperCase())),
              ],
              selected: {_enabledLangs.contains(_lang) ? _lang : _enabledLangs.first},
              onSelectionChanged: (s) => setState(() => _lang = s.first),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final l = _enabledLangs.contains(_lang) ? _lang : _enabledLangs.first;
                return Column(
                  children: [
                    TextField(
                      key: ValueKey('title-$l'),
                      controller: _title[l],
                      maxLength: _titleMax,
                      decoration: InputDecoration(labelText: 'Başlık (${l.toUpperCase()})'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey('body-$l'),
                      controller: _body[l],
                      maxLength: _bodyMax,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: 'Metin (${l.toUpperCase()})'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                );
              },
            ),
          ],
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
          if (_tokenCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Bildirim alabilen cihaz (toplam): $_tokenCount',
                style: const TextStyle(color: kInkSoft, fontSize: 12),
              ),
            ),
          const Divider(color: kLine, thickness: 1.5),
          Row(
            children: [
              const Text('Zaman: ', style: TextStyle(fontWeight: FontWeight.w800)),
              Expanded(child: Text(_sendAfter == null ? 'Hemen (≤ 1 saat)' : _fmt(_sendAfter!))),
              if (_sendAfter != null)
                TextButton(onPressed: () => setState(() => _sendAfter = null), child: const Text('Hemen')),
              TextButton(onPressed: _pickTime, child: const Text('Planla')),
            ],
          ),
          const Text(
            'Saat herkes için aynı anda (senin saatinle) — gece gönderme.',
            style: TextStyle(color: kInkSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final l = _enabledLangs.contains(_lang) ? _lang : (_enabledLangs.isEmpty ? 'tr' : _enabledLangs.first);
    final title = _title[l]!.text.trim();
    final body = _body[l]!.text.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
            child: const Text('Z', style: TextStyle(fontWeight: FontWeight.w900, color: kInk)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zibo · şimdi', style: TextStyle(color: Colors.white60, fontSize: 12)),
                Text(
                  title.isEmpty ? 'Başlık' : title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(body.isEmpty ? 'Metin…' : body, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
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
        if (docs.isEmpty) return const Text('Henüz duyuru yok.', style: TextStyle(color: kInkSoft));
        return Column(
          children: [
            for (final doc in docs) _historyTile(doc),
          ],
        );
      },
    );
  }

  Widget _historyTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = d['status'] as String? ?? '?';
    final (label, color) = switch (status) {
      'pending' => ('Bekliyor', kWarn),
      'sending' => ('Gönderiliyor', kWarn),
      'sent' => ('Gönderildi', kGood),
      'canceled' => ('İptal', kInkSoft),
      _ => ('Hata', kBad),
    };
    final texts = (d['texts'] as Map?) ?? const {};
    final first = (texts['tr'] ?? (texts.isEmpty ? null : texts.values.first)) as Map?;
    final sendAfter = (d['sendAfter'] as Timestamp?)?.toDate();
    final test = d['testUid'] != null;
    final counts = status == 'sent'
        ? 'gönderildi ${d['sentCount'] ?? 0} · atlandı ${d['skippedCount'] ?? 0} · hata ${d['failedCount'] ?? 0}'
        : (d['error'] as String? ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${test ? '🧪 ' : ''}${first?['title'] ?? '(başlıksız)'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${test ? 'test' : _audiences[d['audience']] ?? d['audience']} · ${texts.keys.join('/')}'
                  '${sendAfter == null ? '' : ' · ${_fmt(sendAfter)}'}',
                  style: const TextStyle(color: kInkSoft, fontSize: 12),
                ),
                if (counts.isNotEmpty) Text(counts, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              if (status == 'pending')
                TextButton(onPressed: () => _cancel(doc.reference), child: const Text('İptal')),
            ],
          ),
        ],
      ),
    );
  }
}
