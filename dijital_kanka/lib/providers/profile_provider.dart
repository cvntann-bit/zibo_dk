import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/address_terms.dart';
import '../services/cloud_state_store.dart';
import '../utils/photo_file.dart';

/// Kullanıcının profil bilgilerini (isim + fotoğraf + Zibo ile ilk
/// tanışma tarihi + hitap tercihi) tutan tek kaynak. `CloudStateStore` ile
/// kalıcı — `GoalsProvider`/`CoinProvider` ile aynı desen (tek anahtarlı
/// JSON blob, Varyant A). Fotoğrafın kendisi `PhotoPickerService` ile
/// cihazda yerel olarak saklanır — Manifest Günlüğü'ndeki AYNI bilinçli
/// kapsam sınırlamasıyla (bkz. CLAUDE.md "Manifest Günlüğü" bölümü)
/// yalnızca dosya YOLU Firestore'a senkronize edilir, fotoğrafın kendisi
/// cihazlar arası taşınmaz.
class ProfileProvider extends ChangeNotifier {
  /// [now], diğer "güne bağlı" provider'larla (bkz. `GoalsProvider` vb.)
  /// aynı gerekçeyle enjekte edilebilir — [firstUsedAt] İLK KEZ ayarlanırken
  /// ve [daysSinceFirstUsed] hesaplanırken cihazın DOĞRUDAN saatine değil
  /// bu closure'a başvurulur (`main.dart`'ta `TrustedTimeProvider.now()`'a
  /// bağlanıyor).
  ProfileProvider({DateTime Function()? now, String? uid})
    : _now = now ?? DateTime.now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'profileState';

  final DateTime Function() _now;
  final CloudStateStore _store;

  String _name = '';
  String? _photoPath;
  DateTime? _firstUsedAt;
  String _addressTerm = defaultAddressTerm;

  String get name => _name;
  String? get photoPath => _photoPath;
  DateTime? get firstUsedAt => _firstUsedAt;
  String get addressTerm => _addressTerm;

  /// Bkz. `ThemeProvider.isReady` dokümantasyonu — aynı gerekçe, ama burada
  /// KRİTİK bir ek neden var: `ChangeNotifierProvider(create:)` TEMBEL
  /// olduğu için `ProfileProvider` genelde İLK KEZ tam da Onboarding'in isim
  /// adımında `setName`/`setAddressTerm` çağrıldığında oluşturuluyor —
  /// yapıcının fire-and-forget başlattığı `_loadFromPrefs()` o an henüz
  /// TAMAMLANMAMIŞ olabilir, ve SONRADAN tamamlanınca (kalıcı depoda henüz
  /// hiçbir şey yokken) `_name`'i boş dizeye GERİ YAZIP `setName`'in az önce
  /// yazdığı değeri sessizce silebilir. `_AppStartupGate`'in bu alan `true`
  /// olana kadar Onboarding'i GÖSTERMEMESİ, `ProfileProvider`'ın Onboarding
  /// başladığında ZATEN tam yüklenmiş olmasını garanti ederek bu yarışı
  /// baştan imkânsız kılıyor.
  bool _isReady = false;
  bool get isReady => _isReady;

  /// Zibo ile tanışıldığından bu yana geçen tam gün sayısı — bkz. "Zibo ile
  /// Bağ Seviyesi". [firstUsedAt] henüz yüklenmediyse (asenkron yükleme
  /// tamamlanmadan ÇOK kısa bir pencerede) `0` döner.
  int daysSinceFirstUsed() {
    final start = _firstUsedAt;
    if (start == null) return 0;
    final today = DateTime(_now().year, _now().month, _now().day);
    final startDay = DateTime(start.year, start.month, start.day);
    return today.difference(startDay).inDays;
  }

  Future<void> _loadFromPrefs() async {
    var data = await _store.load();
    var needsSave = false;
    if (data == null) {
      data = {};
    }
    if (data['firstUsedAt'] == null) {
      // İLK KEZ açılış — bugünü "Zibo ile tanışma günü" olarak sabitle.
      // Bir daha ASLA değişmez (sonraki her yüklemede zaten dolu bulunur).
      data['firstUsedAt'] = _now().toIso8601String();
      needsSave = true;
    }
    _name = data['name'] as String? ?? '';
    _photoPath = data['photoPath'] as String?;
    _firstUsedAt = DateTime.parse(data['firstUsedAt'] as String);
    final storedAddressTerm = data['addressTerm'] as String?;
    _addressTerm = (storedAddressTerm == null || storedAddressTerm.trim().isEmpty)
        ? defaultAddressTerm
        : storedAddressTerm;
    _isReady = true;
    notifyListeners();
    if (needsSave) await _store.save(data);
  }

  Future<void> _save() => _store.save({
    'name': _name,
    'photoPath': _photoPath,
    'firstUsedAt': _firstUsedAt?.toIso8601String(),
    'addressTerm': _addressTerm,
  });

  Future<void> setName(String value) async {
    final trimmed = value.trim();
    if (trimmed == _name) return;
    _name = trimmed;
    notifyListeners();
    await _save();
  }

  Future<void> setPhotoPath(String? path) async {
    if (path == _photoPath) return;
    _photoPath = path;
    notifyListeners();
    await _save();
  }

  /// **2026 bug düzeltmesi — Crashlytics'teki EN BÜYÜK tekrarlayan hata,
  /// bkz. CLAUDE.md "Manifest Günlüğü ↔ Profil fotoğrafı" bölümü.**
  /// "Cihazlar arası fotoğraf taşınmaz" sınırlaması yüzünden (yalnızca
  /// `photoPath` STRING'i Firestore'a senkronize ediliyor, dosya baytları
  /// DEĞİL) bir hesap değişiminden/eski oturumdan gelen kayıt, BU cihazda
  /// hiç var OLMAMIŞ bir dosyaya işaret edebilir — `manifest_journal_
  /// screen.dart`'taki `_SafeFileImage`/`profile_screen.dart`'taki
  /// `_hasReadablePhoto` bu durumda artık ÇÖKMÜYOR (kırık/kişi ikonuna
  /// düşüyor) ama `_photoPath` HÂLÂ o geçersiz path'i kalıcı olarak
  /// taşımaya devam ediyordu. `RootScreen`'in her açılış/öne-gelişinde
  /// (`AppStreakProvider`/`ManifestProvider.reconcileMissingPhotos()` ile
  /// AYNI "reconcile-on-resume" deseni) çağrılır — dosya artık diskte
  /// yoksa `_photoPath`'i kalıcı olarak `null`'a çevirir, ekran "kişi"
  /// ikonuna (fotoğraf HİÇ eklenmemiş durumla AYNI görünüme) döner.
  /// Fotoğraf GERİ GETİRİLMİYOR — yalnızca kırık referans temizleniyor.
  void reconcileMissingPhoto() {
    final path = _photoPath;
    if (path == null) return;
    // Boş (0 bayt) dosya da "kayıp" sayılır — bkz. `isReadablePhotoFile`.
    if (isReadablePhotoFile(path)) return;
    _photoPath = null;
    notifyListeners();
    unawaited(_save());
  }

  /// [value] boşsa (kullanıcı hitap kutusunu tamamen silerse) varsayılana
  /// döner — `applyAddressTerm`'in `term[0]` erişimi boş bir dizede
  /// çökeceği için `addressTerm` hiçbir zaman boş kalamaz.
  Future<void> setAddressTerm(String value) async {
    final trimmed = value.trim().isEmpty ? defaultAddressTerm : value.trim();
    if (trimmed == _addressTerm) return;
    _addressTerm = trimmed;
    notifyListeners();
    await _save();
  }
}
