import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/manifest_entry.dart';
import '../services/cloud_state_store.dart';

/// Manifest Günlüğü'ndeki kayıtları tutan tek kaynak. `DreamJournalProvider`
/// ile aynı "id ile ayrı ayrı biriken kayıtlar" deseni — bir güne BİRDEN
/// FAZLA giriş eklenebilir (kullanıcı isterse aynı gün içinde defalarca yeni
/// bir fotoğraf+niyet kaydedebilir), hiçbir giriş bir öncekinin üzerine
/// YAZILMAZ. Coin ödülü ise `WaterProvider`'daki [rewardClaimed] deseniyle
/// aynı gerekçeyle GÜN düzeyinde ayrı takip ediliyor (bkz. [addEntry]) —
/// entry düzeyinde değil, çünkü artık günde birden fazla entry olabiliyor.
class ManifestProvider extends ChangeNotifier {
  /// [now], diğer günlük modüllerle aynı gerekçeyle enjekte edilebilir:
  /// testte "gün değişince ödül yeniden kazanılabilir" davranışını gerçek
  /// saatin geçmesini beklemeden doğrulayabilmek için.
  ManifestProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'manifestEntries';

  final DateTime Function() _now;
  final CloudStateStore _store;
  final List<ManifestEntry> _entries = [];
  final Set<DateTime> _rewardClaimedDates = {};
  int _nextId = 0;

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Tüm kayıtlar (bugün dahil), en yeni en üstte — vizyon panosu galerisi
  /// bunu kullanır. Aynı günde birden fazla giriş varsa id (artan sırada
  /// atanır) ikincil, kesin sonuç veren bir sıralama anahtarı olarak
  /// kullanılıyor (bkz. `DreamJournalProvider.dreams` dokümantasyonu).
  List<ManifestEntry> get history {
    final sorted = List<ManifestEntry>.of(_entries)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return int.parse(b.id).compareTo(int.parse(a.id));
      });
    return List.unmodifiable(sorted);
  }

  /// Bugünün coin ödülü daha önce verildi mi — bkz. `addEntry`
  /// dokümantasyonu, bir kez `true` olunca gün bitene kadar öyle kalır
  /// (kaç yeni giriş eklenirse eklensin).
  bool get isTodayRewardClaimed => _rewardClaimedDates.contains(_today);

  /// Bugün en az bir giriş eklenmiş mi — "Denge Ustası" (Gizli/Eğlenceli
  /// Rozetler, bkz. `hidden_badges.dart`) rozetinin YEDİ modül
  /// kontrolünden biri. [isTodayRewardClaimed]'dan FARKLI — ödül daha önce
  /// alınmış olsa bile (ör. dün alındıysa bugün henüz alınmamıştır) bugüne
  /// ait GERÇEK bir kayıt olup olmadığını soruyor.
  bool get hasEntryToday => _entries.any((e) => e.date == _today);

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    if (data == null) {
      // ÇOK ESKİ format: düz bir liste (map değil, `CloudStateStore` bunu
      // okuyamaz) — günde TEK kayıt, id yok, ödül durumu entry'nin kendi
      // 'rewardClaimed' alanındaydı. Bulunursa yeni sarmalanmış map
      // biçimine göç ettirilir (bkz. `GratitudeProvider`/`CostumeProvider`
      // ile aynı gerekçeli göç deseni).
      final legacyList = await _loadLegacyRawList();
      if (legacyList != null) {
        data = _legacyListToMap(legacyList);
        await _store.save(data);
      }
    }
    if (data == null) return;
    try {
      _entries.clear();
      _rewardClaimedDates.clear();
      _nextId = data['nextId'] as int? ?? 0;
      final rawEntries = data['entries'] as List? ?? const [];
      _entries.addAll(
        rawEntries.map(
          (raw) => ManifestEntry(
            id: (raw as Map<String, dynamic>)['id'] as String,
            date: DateTime.parse(raw['date'] as String),
            photoPath: raw['photoPath'] as String,
            intentionText: raw['intentionText'] as String,
          ),
        ),
      );
      final claimedRaw = data['rewardClaimedDates'] as List? ?? const [];
      _rewardClaimedDates.addAll(claimedRaw.map((s) => DateTime.parse(s as String)));
      notifyListeners();
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce boş listeyle devam et.
    }
  }

  Future<List<dynamic>?> _loadLegacyRawList() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return null;
    try {
      final decoded = jsonDecode(saved);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _legacyListToMap(List<dynamic> decoded) {
    var id = 0;
    final entries = <Map<String, dynamic>>[];
    final claimedDates = <String>[];
    for (final raw in decoded) {
      final map = raw as Map<String, dynamic>;
      final date = map['date'] as String;
      entries.add({
        'id': '${id++}',
        'date': date,
        'photoPath': map['photoPath'] as String,
        'intentionText': map['intentionText'] as String,
      });
      if (map['rewardClaimed'] as bool? ?? false) {
        claimedDates.add(date);
      }
    }
    return {'nextId': id, 'entries': entries, 'rewardClaimedDates': claimedDates};
  }

  Future<void> _save() async {
    await _store.save({
      'nextId': _nextId,
      'entries': _entries
          .map(
            (e) => {
              'id': e.id,
              'date': e.date.toIso8601String(),
              'photoPath': e.photoPath,
              'intentionText': e.intentionText,
            },
          )
          .toList(),
      'rewardClaimedDates': _rewardClaimedDates.map((d) => d.toIso8601String()).toList(),
    });
  }

  /// Yeni bir fotoğraf + niyet metni kaydeder — bir öncekinin YERİNE
  /// GEÇMEZ, ayrı bir kayıt olarak eklenir (aynı gün içinde istendiği kadar
  /// çağrılabilir). [photoPath] veya [intentionText] (trim sonrası) boşsa
  /// hiçbir şey yapmadan `false` döner.
  ///
  /// Dönen `bool`, bu kaydın coin ödülünü İLK KEZ hak edip etmediğini
  /// belirtir — çağıran taraf (bkz. `ManifestJournalScreen`)
  /// `WaterTrackingScreen`'in `incrementUnit()` kullanma deseniyle AYNI
  /// şekilde, yalnızca `true` döndüğünde `CoinProvider.earnManifestJournal()`
  /// çağırır. Bugün zaten bir kez ödül alındıysa (bkz. [isTodayRewardClaimed])
  /// sonraki yeni girişler başarıyla kaydedilir ama `false` döner —
  /// kullanıcı aynı gün istediği kadar yeni giriş ekleyebilir, ama coin
  /// yalnızca bir kez verilir.
  bool addEntry({required String photoPath, required String intentionText}) {
    final text = intentionText.trim();
    if (photoPath.trim().isEmpty || text.isEmpty) return false;

    final today = _today;
    final alreadyClaimed = _rewardClaimedDates.contains(today);
    _entries.add(
      ManifestEntry(id: '${_nextId++}', date: today, photoPath: photoPath, intentionText: text),
    );
    if (!alreadyClaimed) _rewardClaimedDates.add(today);
    notifyListeners();
    _save();
    return !alreadyClaimed;
  }
}
