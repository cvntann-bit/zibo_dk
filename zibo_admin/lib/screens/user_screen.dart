import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gifts.dart';
import '../theme.dart';

/// Kullanıcı bul (davet kodu = uid, `ReferralProvider.referralCode`) → bilgi kartı → hediye.
class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserInfo {
  _UserInfo(this.uid, this.root, this.states);

  final String uid;
  final Map<String, dynamic>? root;
  final Map<String, Map<String, dynamic>?> states;

  Map<String, dynamic>? get coin => states['coinState'];
  Map<String, dynamic>? get sub => states['subscriptionState'];
  Map<String, dynamic>? get games => states['gamePointsState'];
  String get name => (states['profileState']?['name'] as String?)?.trim() ?? '';
  DateTime? get lastActive => (root?['lastActiveAt'] as Timestamp?)?.toDate();
  bool get unlimitedPlays => games?['unlimitedPlays'] == true;

  /// Zibo'nun `SubscriptionProvider.tier` mantığı: süresi geçmişse free.
  String get effectiveTier {
    final tier = sub?['subscriptionTier'] as String? ?? 'free';
    final expiry = DateTime.tryParse(sub?['subscriptionExpiryDate'] as String? ?? '');
    if (tier == 'free' || expiry == null || DateTime.now().isAfter(expiry)) return 'free';
    return tier;
  }
}

const _stateDocs = ['coinState', 'subscriptionState', 'gamePointsState', 'profileState', 'xpState'];
const _tierNames = {'free': 'Ücretsiz', 'pro': 'Pro', 'proplus': 'Pro+'};

String _fmtDate(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
}

class _UserScreenState extends State<UserScreen> {
  final _codeController = TextEditingController();
  _UserInfo? _user;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _find([String? uid]) async {
    final code = (uid ?? _codeController.text).trim();
    if (code.isEmpty || code.contains('/')) {
      setState(() => _message = 'Geçerli bir davet kodu (uid) gir.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(code);
      const server = GetOptions(source: Source.server);
      final results = await Future.wait([
        userRef.get(server),
        for (final name in _stateDocs) userRef.collection('state').doc(name).get(server),
      ]);
      final root = results.first;
      final states = {for (var i = 0; i < _stateDocs.length; i++) _stateDocs[i]: results[i + 1].data()};
      if (!root.exists && states['coinState'] == null) {
        setState(() {
          _user = null;
          _message = 'Bu kodla kullanıcı bulunamadı.';
        });
        return;
      }
      setState(() => _user = _UserInfo(code, root.data(), states));
    } catch (e) {
      setState(() => _message = 'Okunamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _snack(done);
      await _find(_user!.uid);
    } catch (e) {
      if (mounted) _snack('Yazılamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Gönder')),
        ],
      ),
    );
    return ok == true;
  }

  String get _who {
    final u = _user!;
    return u.name.isEmpty ? u.uid : '${u.name} (${u.uid.substring(0, 6)}…)';
  }

  Future<void> _giftCoins() async {
    final u = _user!;
    if (u.coin == null) {
      _snack('Bu kullanıcının bulutta coin kaydı yok — ZC verilemez.');
      return;
    }
    // Diyalog başına TEK id: aynı hediye iki kez uygulanamaz.
    final grantId = 'panel-${DateTime.now().millisecondsSinceEpoch}';
    final amount = await showDialog<int>(context: context, builder: (_) => const _CoinAmountDialog());
    if (amount == null || !mounted) return;
    final balance = (u.coin!['balance'] as num? ?? 0).toInt();
    if (!await _confirm('ZC hediye', '$_who\n\n+$amount ZC\nBakiye: $balance → ${balance + amount}')) return;
    await _run(() => grantCoins(uid: u.uid, coins: amount, grantId: grantId), '+$amount ZC gönderildi ✓');
  }

  Future<void> _giftSubscription() async {
    final u = _user!;
    final choice = await showDialog<(String, int?)>(context: context, builder: (_) => const _SubscriptionDialog());
    if (choice == null || !mounted) return;
    final (tier, days) = choice;
    final expiry = days == null ? kFarFutureExpiry : DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();
    final until = days == null ? 'süresiz' : '$days gün (${_fmtDate(DateTime.parse(expiry).toLocal())} bitiş)';
    final current = _tierNames[u.effectiveTier];
    if (!await _confirm('Üyelik hediye', '$_who\n\n$current → ${_tierNames[tier]}, $until')) return;
    final before = <String, Object?>{
      'subscriptionTier': u.sub?['subscriptionTier'],
      'subscriptionExpiryDate': u.sub?['subscriptionExpiryDate'],
    };
    await _run(
      () => grantSubscription(uid: u.uid, tier: tier, expiryIso: expiry, before: before),
      '${_tierNames[tier]} verildi ✓',
    );
  }

  Future<void> _toggleUnlimited() async {
    final u = _user!;
    final value = !u.unlimitedPlays;
    final text = value ? 'Oyun Salonu günlük hak sınırı KALKSIN' : 'Günlük hak sınırı geri gelsin';
    if (!await _confirm('Sınırsız oyun', '$_who\n\n$text')) return;
    await _run(
      () => setUnlimitedPlays(uid: u.uid, value: value, before: u.unlimitedPlays),
      value ? 'Sınırsız oyun açıldı ✓' : 'Sınırsız oyun kapatıldı ✓',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Davet kodu (uid)',
                  suffixIcon: IconButton(
                    tooltip: 'Yapıştır',
                    icon: const Icon(Icons.content_paste),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) _codeController.text = data!.text!.trim();
                    },
                  ),
                ),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: _busy ? null : _find, child: const Text('Bul')),
          ],
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_message!, style: const TextStyle(color: kBad, fontWeight: FontWeight.w700)),
          ),
        if (_user != null) ...[const SizedBox(height: 16), _infoCard(_user!), const SizedBox(height: 16), _giftCard(_user!)],
      ],
    );
  }

  Widget _infoCard(_UserInfo u) {
    final coin = u.coin;
    final sub = u.sub;
    final expiry = DateTime.tryParse(sub?['subscriptionExpiryDate'] as String? ?? '');
    final lastActive = u.lastActive;
    final recentlyActive = lastActive != null && DateTime.now().difference(lastActive).inMinutes < 30;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(u.name.isEmpty ? '(adsız)' : u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SelectableText(u.uid, style: const TextStyle(color: kInkSoft, fontSize: 12)),
          const Divider(color: kLine, thickness: 1.5),
          _row('Son aktif', lastActive == null ? '—' : _fmtDate(lastActive)),
          _row('Saat dilimi', u.root?['timeZone'] as String? ?? '—'),
          _row(
            'ZC',
            coin == null
                ? 'bulutta kayıt yok'
                : '${coin['balance']}  (kazanılan ${coin['totalEarned']} · harcanan ${coin['totalSpent']})',
          ),
          _row(
            'Üyelik',
            '${_tierNames[u.effectiveTier]}'
                '${u.effectiveTier != 'free' && expiry != null ? ' · bitiş ${_fmtDate(expiry.toLocal())}' : ''}',
          ),
          _row('Oyun ★', '${u.games?['points'] ?? 0}${u.unlimitedPlays ? ' · sınırsız oyun' : ''}'),
          _row('XP', '${u.states['xpState']?['totalXp'] ?? 0}'),
          if (recentlyActive)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kGoldPale, borderRadius: BorderRadius.circular(10)),
              child: const Text(
                'Son 30 dakikada aktif — uygulama açıksa hediye, kullanıcı Zibo\'yu TAMAMEN kapatıp '
                'açana kadar görünmez (açık oturumun eski bakiyesi kural gereği buluta yazılamaz).',
                style: TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: const TextStyle(color: kInkSoft))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _giftCard(_UserInfo u) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: stickerDecoration(fill: kGoldPale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🎁 Hediye ver', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _giftCoins,
            icon: const Icon(Icons.toll),
            label: const Text('Zibo Coin'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _giftSubscription,
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Pro / Pro+ üyelik'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _toggleUnlimited,
            icon: const Icon(Icons.all_inclusive),
            label: Text(u.unlimitedPlays ? 'Sınırsız oyunu kapat' : 'Sınırsız oyun aç'),
          ),
        ],
      ),
    );
  }
}

class _CoinAmountDialog extends StatefulWidget {
  const _CoinAmountDialog();

  @override
  State<_CoinAmountDialog> createState() => _CoinAmountDialogState();
}

class _CoinAmountDialogState extends State<_CoinAmountDialog> {
  final _controller = TextEditingController(text: '100');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _amount {
    final v = int.tryParse(_controller.text.trim());
    return v != null && v > 0 && v <= 100000 ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kaç ZC?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final v in [50, 100, 500, 1000])
                ActionChip(label: Text('$v'), onPressed: () => setState(() => _controller.text = '$v')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(helperText: '1 – 100.000'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: _amount == null ? null : () => Navigator.pop(context, _amount),
          child: const Text('Devam'),
        ),
      ],
    );
  }
}

class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog();

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  String _tier = 'pro';
  int? _days = 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Üyelik'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'pro', label: Text('Pro')),
              ButtonSegment(value: 'proplus', label: Text('Pro+')),
            ],
            selected: {_tier},
            onSelectionChanged: (s) => setState(() => _tier = s.first),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int?>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 gün')),
              ButtonSegment(value: 30, label: Text('30 gün')),
              ButtonSegment(value: null, label: Text('Süresiz')),
            ],
            selected: {_days},
            onSelectionChanged: (s) => setState(() => _days = s.first),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gerçek Play aboneliği olan kullanıcıda süre bitince Zibo açılışta Play\'den yeniden doğrular.',
            style: TextStyle(color: kInkSoft, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, (_tier, _days)), child: const Text('Devam')),
      ],
    );
  }
}
