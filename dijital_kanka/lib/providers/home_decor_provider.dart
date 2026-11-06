import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/home_catalog.dart';
import '../models/home_item.dart';
import '../services/cloud_state_store.dart';

/// Zibo'nun Evi dekoru: oda başına takılı eşyalar, satın alınanlar ve sabun
/// türleri. docs/zibo_world_roadmap.md Faz 1.
///
/// Fiyatı 0 olan eşyalar (her odanın başlangıç takımı) herkese açık sayılır.
/// ZC düşümü burada değil, çağıran tarafta (`CoinProvider.spendOnHomeItem`)
/// yapılır; ödeme başarılıysa [markOwned] çağrılır.
class HomeDecorProvider extends ChangeNotifier {
  HomeDecorProvider({String? uid, FirebaseFirestore? firestore})
    : _store = CloudStateStore(prefsKey: _prefsKey, uid: uid, firestore: firestore) {
    _ready = _loadFromPrefs();
  }

  static const _prefsKey = 'homeDecorState';
  static const defaultSoap = 'pembe';

  final CloudStateStore _store;
  final Map<String, Map<String, String>> _equipped = {};
  final Set<String> _owned = {};
  // Satın alınanlar (etkinlik ödülleri hariç) — Ev Dekoratörü rozeti.
  final Set<String> _bought = {};
  final Set<String> _soaps = {defaultSoap};
  String _soap = defaultSoap;

  late final Future<void> _ready;
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Kayıt yüklenince tamamlanır (testler bekler).
  Future<void> get ready => _ready;

  static String key(HomeRoom room, String category, String itemId) => '${room.id}:$category:$itemId';

  static HomeRoomDef roomDef(HomeRoom room) => homeRooms.firstWhere((r) => r.room == room);

  HomeItem? _item(HomeRoom room, String category, String itemId) => roomDef(room).category(category)?.item(itemId);

  bool isOwned(HomeRoom room, String category, String itemId) {
    final item = _item(room, category, itemId);
    if (item == null) return false;
    // Odanın başlangıç eşyası katalogda fiyatlı olabilir (banyo boyası
    // `gok`) — yine de herkesin.
    return item.price == 0 ||
        roomDef(room).defaults[category] == itemId ||
        _owned.contains(key(room, category, itemId));
  }

  /// Takılı eşyanın kimliği; kayıt yoksa ya da eşya katalogdan kalktıysa
  /// başlangıç eşyası.
  String equipped(HomeRoom room, String category) {
    final def = roomDef(room);
    final id = _equipped[room.id]?[category];
    if (id != null && isOwned(room, category, id)) return id;
    return def.defaults[category] ?? def.category(category)!.items.first.id;
  }

  HomeItem equippedItem(HomeRoom room, String category) => _item(room, category, equipped(room, category))!;

  /// Yalnızca sahip olunan eşya takılabilir.
  bool equip(HomeRoom room, String category, String itemId) {
    if (!isOwned(room, category, itemId)) return false;
    (_equipped[room.id] ??= {})[category] = itemId;
    notifyListeners();
    _save();
    return true;
  }

  /// Satın alınan dekor eşyası sayısı (Ev Dekoratörü rozeti; sabunlar ve
  /// etkinlik ödülleri hariç).
  int get purchasedDecorCount => _bought.length;

  /// [bought] false: etkinlik kutusundan gelen ödül (satın alma sayılmaz).
  void markOwned(HomeRoom room, String category, String itemId, {bool bought = true}) {
    if (_item(room, category, itemId) == null) return;
    _owned.add(key(room, category, itemId));
    if (bought) _bought.add(key(room, category, itemId));
    notifyListeners();
    _save();
  }

  String get selectedSoap => _soap;

  bool isSoapOwned(String soapId) {
    for (final soap in homeSoaps) {
      if (soap.id == soapId) return soap.price == 0 || _soaps.contains(soapId);
    }
    return false;
  }

  void markSoapOwned(String soapId) {
    _soaps.add(soapId);
    notifyListeners();
    _save();
  }

  bool selectSoap(String soapId) {
    if (!isSoapOwned(soapId)) return false;
    _soap = soapId;
    notifyListeners();
    _save();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final data = await _store.load();
    if (data != null) {
      try {
        final equipped = data['equipped'];
        if (equipped is Map) {
          for (final room in equipped.entries) {
            if (room.value is! Map) continue;
            _equipped['${room.key}'] = {for (final c in (room.value as Map).entries) '${c.key}': '${c.value}'};
          }
        }
        _owned.addAll(((data['owned'] as List?) ?? const []).map((e) => '$e'));
        _bought.addAll(((data['bought'] as List?) ?? const []).map((e) => '$e'));
        _soaps.addAll(((data['soaps'] as List?) ?? const []).map((e) => '$e'));
        final soap = data['soap'] as String?;
        if (soap != null && isSoapOwned(soap)) _soap = soap;
      } catch (_) {
        // Bozuk kayıt: başlangıç takımıyla devam.
      }
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() => _store.save({
    'equipped': _equipped,
    'owned': _owned.toList()..sort(),
    'bought': _bought.toList()..sort(),
    'soaps': _soaps.toList()..sort(),
    'soap': _soap,
  });
}
