import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        // `date` alanı (= belge id'si): tek alanlı indeks otomatik; documentId'ye ters sıralama ayrı indeks ister.
        .orderBy('date', descending: true)
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
        if (heavy.isNotEmpty && heavy.first['activity'] is Map) ...[
          const SizedBox(height: 20),
          _adsAndRevenue(heavy.first, today),
        ],
        if (heavy.isNotEmpty && heavy.first['subscribers'] is List) ...[
          const SizedBox(height: 20),
          _subscribers(heavy.first['subscribers'] as List),
        ],
        if (heavy.isNotEmpty && heavy.first['excluded'] is Map)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Senin hesapların hariç: ${_n((heavy.first['excluded'] as Map)['accounts'] as num?)} hesap, '
              '${_n((heavy.first['excluded'] as Map)['balance'] as num?)} ZC',
              style: const TextStyle(color: kInkSoft, fontSize: 12),
            ),
          ),
        if (heavy.isNotEmpty && heavy.first['suspects'] is List) ...[
          const SizedBox(height: 20),
          _suspects(heavy.first['suspects'] as List),
        ],
        const SizedBox(height: 16),
        const Text(
          'Coin ve üyelik sayıları günde bir (ilk saatlik çalışmada) güncellenir; aktif sayıları her saat. '
          'Reklam geliri henüz yok (Appodeal API anahtarı gerekiyor).',
          style: TextStyle(color: kInkSoft, fontSize: 12),
        ),
      ],
    );
  }

  String _try(num? v) => v == null ? '—' : '₺${v.toStringAsFixed(v >= 100 ? 0 : 2).replaceAll('.', ',')}';

  /// Reklam & gelir — dailyStats.js `activity` (gün kovaları) + `revenue`. Ağır sayım günde bir, günün ilk
  /// saatinde → en yeni TAM gün "dün".
  Widget _adsAndRevenue(Map<String, dynamic> heavyDay, Map<String, dynamic> today) {
    final activity = (heavyDay['activity'] as Map).cast<String, dynamic>();
    final keys = activity.keys.toList()..sort((a, b) => b.compareTo(a));
    final full = keys.length > 1 ? keys.sublist(1) : keys; // [0] = sayım anındaki yarım gün
    final y = (activity[full.first] as Map).cast<String, dynamic>();
    final revenue = (heavyDay['revenue'] as Map?)?.cast<String, dynamic>() ?? const {};
    final subs = (heavyDay['subs'] as Map?)?.cast<String, dynamic>() ?? const {};
    final week = full.take(7).toList().reversed.toList();
    final weekUsers = [for (final k in week) ((activity[k] as Map)['adUsers'] as num? ?? 0).toDouble()];
    final maxU = weekUsers.fold<double>(1, (m, v) => v > m ? v : m);

    // Appodeal (dailyStats.js `appodeal`, 6 saatte bir, son 8 gün) — günün belgesinde.
    final appodealDays = ((today['appodeal'] as Map?)?['days'] as Map?)?.cast<String, dynamic>();
    final adY = appodealDays?[full.first] as Map?;
    final ad7 = [for (final k in full.take(7)) appodealDays?[k] as Map?].whereType<Map>();
    final rev7 = ad7.fold<num>(0, (acc, d) => acc + (d['revenue'] as num? ?? 0));
    final imp7 = ad7.fold<num>(0, (acc, d) => acc + (d['impressions'] as num? ?? 0));
    final appodealError = today['appodealError'] as String?;
    String usd(num? v) => v == null ? '—' : '\$${v.toStringAsFixed(v < 1 ? 3 : 2)}';
    final (String, String, String?) adTile = appodealDays == null
        ? ('Reklam geliri', '—', appodealError ?? 'Appodeal secret eklenince gelir')
        : (
            'Reklam geliri',
            usd(adY?['revenue'] as num?),
            '${_n(adY?['impressions'] as num?)} gösterim · eCPM ${usd(adY?['ecpm'] as num?)}\n'
                '7 gün ${usd(rev7)} · ${_n(imp7)} gösterim',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reklam & gelir · dün (${full.first.substring(5)})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _tiles([
          ('Reklam izleyen kişi', _n(y['adUsers'] as num?), 'ödüllü: coin + Oyun Salonu'),
          ('Coin için reklam', _n(y['coinAds'] as num?), '${_n(y['coinAdUsers'] as num?)} kişi'),
          ('Oyun Salonu reklamı', _n(y['gameAds'] as num?), '${_n(y['gameAdUsers'] as num?)} kişi (ek hak)'),
          ('Coin satışı', _n(y['purchases'] as num?), '~${_try(y['purchaseTry'] as num?)} · 7 gün ~${_try(revenue['purchaseTry7d'] as num?)}'),
          (
            'Abonelik geliri',
            '~${_try(revenue['subsMonthlyTry'] as num?)}/ay',
            'Pro ${_n(subs['pro'] as num?)} · Pro+ ${_n(subs['proplus'] as num?)}'
                '${(subs['giftedForever'] as num? ?? 0) > 0 ? ' · süresiz hediye ${_n(subs['giftedForever'] as num?)}' : ''}',
          ),
          adTile,
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: stickerDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reklam izleyen kişi · 7 gün', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < week.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(_n(weekUsers[i]), style: const TextStyle(fontSize: 11, color: kInkSoft)),
                            const SizedBox(height: 2),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: (weekUsers[i] / maxU * 66).clamp(2, 66),
                              decoration: const BoxDecoration(
                                color: kGold,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(height: 1.5, color: kLine),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final k in week)
                    Expanded(
                      child: Text(k.substring(8), textAlign: TextAlign.center, style: const TextStyle(color: kInkSoft, fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Reklam izleyen kişi yalnızca Firestore'a iz bırakan ödüllü reklamları sayar (geçiş ve kostüm denemesi hariç); "
          "reklam geliri/gösterim Appodeal'dan (tüm reklam türleri; son 3 gün ağlar tarafından düzeltilebilir). ₺ tutarları liste fiyatı, Google payı (%15) düşülmemiş; abonelik hepsi aylık "
          'fiyatla (yıllık planlar ayrılamıyor) — üst sınır tahmini.',
          style: TextStyle(color: kInkSoft, fontSize: 12),
        ),
      ],
    );
  }

  /// Etkin aboneler (sahip hesapları hariç). Satın alma tarihi kayıtlı değil — "son doğrulama" = bitiş − 35 gün
  /// (Zibo her Play onayında bitişi 35 gün ileri atar): ilk alım ya da aboneliğin son doğrulandığı açılış.
  Widget _subscribers(List raw) {
    final items = raw.whereType<Map>().toList();
    String date(Object? iso) {
      final t = DateTime.tryParse('${iso ?? ''}')?.toLocal();
      return t == null ? '—' : _fmtTime(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⭐ Aboneler (${items.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const Text(
          'En son doğrulanan en üstte · satın alma tarihi kayıtlı değil (Play Console > Siparişler)',
          style: TextStyle(color: kInkSoft, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty) const Text('Etkin abone yok.', style: TextStyle(color: kInkSoft)),
        for (final m in items)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '${m['uid']}'));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('uid kopyalandı: ${m['uid']}')));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: stickerDecoration(borderWidth: 2, shadowOffset: const Offset(2, 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [m['name'], m['email']].whereType<String>().where((x) => x.isNotEmpty).join(' · ').isEmpty
                              ? '(adsız)'
                              : [m['name'], m['email']].whereType<String>().where((x) => x.isNotEmpty).join(' · '),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${m['tier'] == 'proplus' ? 'Pro+' : 'Pro'}${m['gift'] == true ? ' 🎁' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Text(
                    m['gift'] == true ? 'süresiz hediye' : 'son doğrulama ${date(m['lastConfirmed'])} · bitiş ${date(m['expiry'])}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'hesap açılışı ${date(m['createdAt'])} · son aktif ${date(m['lastActive'])}',
                    style: const TextStyle(color: kInkSoft, fontSize: 12),
                  ),
                  Text('${m['uid']}', style: const TextStyle(color: kInkSoft, fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static const _flagText = {
    'mismatch': 'Bakiye ≠ kazanılan − harcanan',
    'bigEarn': 'Satın alma dışı büyük kazanç',
    'fastEarn': 'Günde 1000+ ZC (satın alma hariç)',
  };

  /// Hile şüphesi: en yüksek bakiyeler + işaretli hesaplar (dailyStats.js `buildSuspects`).
  Widget _suspects(List raw) {
    final items = raw.whereType<Map>().toList();
    final flagged = items.where((m) => (m['flags'] as List?)?.isNotEmpty ?? false).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔍 Dikkat — yüksek bakiyeler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        Text(
          '$flagged işaretli · dokun = uid kopyala (Kullanıcı sekmesinde aratabilirsin)',
          style: const TextStyle(color: kInkSoft, fontSize: 12),
        ),
        const SizedBox(height: 8),
        for (final m in items) _suspectTile(m),
      ],
    );
  }

  Widget _suspectTile(Map m) {
    final flags = ((m['flags'] as List?) ?? const []).cast<String>();
    final uid = m['uid'] as String? ?? '';
    final who = [m['name'], m['email']].whereType<String>().where((x) => x.isNotEmpty).join(' · ');
    final providers = ((m['providers'] as List?) ?? const []).join(',');
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: uid));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('uid kopyalandı: $uid')));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: stickerDecoration(
          fill: flags.isEmpty ? kPaper : kGoldPale,
          borderWidth: 2,
          shadowOffset: const Offset(2, 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    who.isEmpty ? '(adsız · ${providers.isEmpty ? 'anonim' : providers})' : who,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${_n(m['balance'] as num?)} ZC', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            Text(
              'kazanılan ${_n(m['earned'] as num?)} · harcanan ${_n(m['spent'] as num?)} · '
              'satın alma ~${_n(m['purchased'] as num?)}${(m['gifted'] as num? ?? 0) > 0 ? ' · hediye ${_n(m['gifted'] as num?)}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${m['ageDays'] == null ? '' : '${m['ageDays']} günlük hesap · '}'
              '${m['earnPerDay'] == null ? '' : '~${_n(m['earnPerDay'] as num?)} ZC/gün · '}'
              'en büyük kazanç ${_n(m['maxOrganic'] as num?)}${m['maxOrganicReason'] == null ? '' : ' (${m['maxOrganicReason']})'}',
              style: const TextStyle(color: kInkSoft, fontSize: 12),
            ),
            for (final f in flags)
              Text('⚠️ ${_flagText[f] ?? f}', style: const TextStyle(color: kBad, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(uid, style: const TextStyle(color: kInkSoft, fontSize: 10)),
          ],
        ),
      ),
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

  /// Son 15 günün "24 saat aktif" değeri — tek seri, tek renk; dokununca değer. Her zaman 15 sabit
  /// yuva (veri az olsa da çubuk genişliği sabit kalsın); veri olmayan eski günler boş.
  Widget _activeChart(List<Map<String, dynamic>> days) {
    const slots = 15;
    final empty = slots - days.length;
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
                for (var i = 0; i < empty; i++) const Expanded(child: SizedBox()),
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
              const Text('15 gün önce', style: TextStyle(color: kInkSoft, fontSize: 11)),
              Text('${days.last['date'] ?? ''}'.substring(5), style: const TextStyle(color: kInkSoft, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
