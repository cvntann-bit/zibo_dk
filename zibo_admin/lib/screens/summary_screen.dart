import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Özet: `stats/{YYYY-MM-DD}` belgeleri — saatlik iş yazar
/// (`notification-scripts/src/dailyStats.js`). Sayılar saatte bir, coin/üyelik günde bir güncellenir.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

String _n(num? v) {
  if (v == null) return '—';
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String _fmtTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
}

class _SummaryScreenState extends State<SummaryScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  int? _selectedBar;

  Future<List<Map<String, dynamic>>> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('stats')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(15)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _selectedBar = null;
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Okunamadı: ${snap.error}', style: const TextStyle(color: kBad)));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final days = snap.data!;
        if (days.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz sayı yok — saatlik iş ilk kez çalışınca dolar.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(onRefresh: _refresh, child: _content(days));
      },
    );
  }

  Widget _content(List<Map<String, dynamic>> days) {
    final today = days.first;
    // Coin/üyelik günde bir yazılır — en yeni ağır sayımı ve ondan önceki günü bul.
    final heavy = days.where((d) => d['coin'] is Map).toList();
    final coinNow = heavy.isEmpty ? null : heavy.first['coin'] as Map;
    final coinPrev = heavy.length < 2 ? null : heavy[1]['coin'] as Map;
    num? delta(String key) => coinNow == null || coinPrev == null
        ? null
        : (coinNow[key] as num? ?? 0) - (coinPrev[key] as num? ?? 0);
    final subs = heavy.isEmpty ? null : heavy.first['subs'] as Map?;
    final updatedAt = (today['updatedAt'] as Timestamp?)?.toDate();

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text(
          'Son güncelleme: ${updatedAt == null ? '—' : _fmtTime(updatedAt)} · aşağı çekip yenile',
          style: const TextStyle(color: kInkSoft, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _tiles([
          ('Aktif · 24 saat', _n(today['active1d'] as num?), null),
          ('Aktif · 7 gün', _n(today['active7d'] as num?), null),
          ('Aktif · 30 gün', _n(today['active30d'] as num?), null),
          ('Toplam hesap', _n(today['totalUsers'] as num?), 'bildirim alabilen ${_n(today['withToken'] as num?)}'),
        ]),
        const SizedBox(height: 16),
        _activeChart(days.reversed.toList()),
        const SizedBox(height: 16),
        const Text('Coin ekonomisi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _tiles([
          ('Dolaşımdaki ZC', _n(coinNow?['balance'] as num?), '${_n(coinNow?['holders'] as num?)} hesapta'),
          ('Kazanılan · 1 gün', delta('earned') == null ? '—' : '+${_n(delta('earned'))}', null),
          ('Harcanan · 1 gün', delta('spent') == null ? '—' : _n(delta('spent')), null),
          ('Pro / Pro+', subs == null ? '—' : '${_n(subs['pro'] as num?)} / ${_n(subs['proplus'] as num?)}', 'süresi geçmemiş'),
        ]),
        if (coinPrev == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Günlük kazanılan/harcanan, ikinci günün sayımından sonra görünür.',
              style: TextStyle(color: kInkSoft, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Coin ve üyelik sayıları günde bir (ilk saatlik çalışmada) güncellenir; aktif sayıları her saat. '
          'Reklam geliri henüz yok (Appodeal API anahtarı gerekiyor).',
          style: TextStyle(color: kInkSoft, fontSize: 12),
        ),
      ],
    );
  }

  Widget _tiles(List<(String, String, String?)> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value, sub) in items)
              Container(
                width: width,
                padding: const EdgeInsets.all(14),
                decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: kInkSoft, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    if (sub != null) Text(sub, style: const TextStyle(color: kInkSoft, fontSize: 12)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Son 15 günün "24 saat aktif" değeri — tek seri, tek renk; dokununca değer.
  Widget _activeChart(List<Map<String, dynamic>> days) {
    final values = [for (final d in days) (d['active1d'] as num? ?? 0).toDouble()];
    final maxV = values.fold<double>(1, (m, v) => v > m ? v : m);
    final selected = _selectedBar ?? values.length - 1;
    final selDay = days[selected];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Günlük aktif (24 saat)', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(
            '${selDay['date'] ?? ''}: ${_n(values[selected])}',
            style: const TextStyle(color: kInkSoft, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedBar = i),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1), // 2px aralık
                          height: (values[i] / maxV * 116).clamp(2, 116),
                          decoration: BoxDecoration(
                            color: i == selected ? kInk : kGold,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1.5, color: kLine),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${days.first['date'] ?? ''}'.substring(5), style: const TextStyle(color: kInkSoft, fontSize: 11)),
              Text('${days.last['date'] ?? ''}'.substring(5), style: const TextStyle(color: kInkSoft, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
