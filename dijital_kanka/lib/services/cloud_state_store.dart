import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir provider'ın kalıcı durumunu (bir `Map<String, dynamic>` olarak) hem
/// yerel `SharedPreferences`'ta HEM Firestore'da tutan paylaşımlı yardımcı.
/// `AdService`/`NotificationService` ile AYNI "gerçek implementasyon,
/// testte enjekte edilebilir" felsefesi — ama bir servis değil, her
/// provider'ın kendi `_loadFromPrefs`/`_save`'inin YERİNE GEÇEN küçük bir
/// sarmalayıcı.
///
/// **Neden gerekli — gerçek kullanıcı isteği:** Uygulamanın TÜM kullanıcı
/// verisi (coin bakiyesi, hedefler, günlük ödüller, kostüm/tema sahipliği
/// vb.) eskiden yalnızca cihazın yerel `SharedPreferences`'ında tutuluyordu
/// — bu hem cihaza kilitliydi (yeniden kurulum/cihaz değişimi = veri kaybı)
/// hem de kökten (root) erişimle/kayıt düzenleyici uygulamalarla elle
/// değiştirilebilirdi. Artık `Firebase Anonymous Auth`'tan gelen bir `uid`
/// varsa veri Firestore'da (`users/{uid}/state/{prefsKey}`) da tutuluyor;
/// `uid` yoksa (Firebase kullanılamıyor — ör. web önizlemesi, ilk açılışta
/// ağ sorunu) sessizce saf-yerel moda düşülüyor.
///
/// **Kalıcı bir yerel yedek — Firestore'un yerini ALMIYOR, ONA EK.** Her
/// [save] çağrısı HER ZAMAN önce yerele yazar (Firestore geçici olarak
/// erişilemez olsa bile veri hiç kaybolmaz) — bu ayrıca [uid] `null`
/// olduğunda (Firebase yok) ve testlerde (bkz. altta) TEK doğru davranışı
/// sağlıyor.
///
/// **Migrasyon otomatik:** [load], Firestore'da bu [prefsKey] için HİÇ veri
/// yoksa (kullanıcının bu güncellemeden ÖNCEki yerel verisi olabilir) yerel
/// veriyi okuyup Firestore'a yazar — kullanıcı mevcut ilerlemesini
/// KAYBETMEDEN buluta geçer.
///
/// **Test-güvenliği:** [uid] `null` bırakılırsa (testlerin VARSAYILAN
/// kullanımı — hiçbir provider testi `uid` VERMİYOR) bu sınıf tamamen
/// `SharedPreferences`'a düşer, Firestore'a hiç dokunmaz — mevcut TÜM
/// provider testleri hiçbir değişiklik gerektirmeden çalışmaya devam eder.
class CloudStateStore {
  CloudStateStore({required this.prefsKey, this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? (uid == null ? null : FirebaseFirestore.instance);

  /// Mevcut `SharedPreferences` anahtarıyla AYNI (ör. `'coinState'`) —
  /// geriye dönük uyumluluk ve yerel yedek için.
  final String prefsKey;

  /// `Firebase Anonymous Auth`'tan gelen kullanıcı kimliği. `null` ise
  /// Firestore hiç kullanılmaz (saf-yerel mod).
  final String? uid;

  final FirebaseFirestore? _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore!.collection('users').doc(uid).collection('state').doc(prefsKey);

  /// Kalıcı durumu okur. Öncelik: Firestore (varsa) → yoksa yereldeki eski
  /// veriyi Firestore'a göç ettirip onu döner → Firestore'a hiç
  /// ulaşılamıyorsa (ağ yok/hata) yerele düşer. [uid] `null` ise doğrudan
  /// yerelden okur.
  Future<Map<String, dynamic>?> load() async {
    if (uid == null) return _loadLocal();
    try {
      final snap = await _doc.get();
      if (snap.exists) return snap.data();
      // Firestore'da bu kullanıcı için HENÜZ veri yok — İLK KEZ: yereldeki
      // (varsa) eski veriyi göç ettir.
      final local = await _loadLocal();
      if (local != null) await _doc.set(local);
      return local;
    } catch (_) {
      // Ağ yok/Firestore hatası — sessizce yerele düş, uygulamanın
      // çökmesindense/askıda kalmasındansa çevrimdışı çalışması tercih
      // edilir.
      return _loadLocal();
    }
  }

  /// Kalıcı durumu yazar — HER ZAMAN önce yerele (Firestore erişilemez
  /// olsa bile veri kaybolmasın), ardından [uid] varsa Firestore'a.
  Future<void> save(Map<String, dynamic> data) async {
    await _saveLocal(data);
    if (uid == null) return;
    try {
      await _doc.set(data);
    } catch (_) {
      // Ağ yok — Firestore SDK'sının kendi offline yazma kuyruğu (varsayılan
      // olarak açık kalıcılık) zaten devam eder; bu yalnızca ekstra
      // güvenlik, veri zaten yerelde duruyor.
    }
  }

  Future<Map<String, dynamic>?> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // `prefs.getString` bile fırlatabilir — bu anahtar Firestore
      // migrasyonundan ÖNCE farklı bir türle (`setBool`/`setStringList` vb.)
      // yazılmış olabilir (bkz. `ThemeProvider`/`LocaleProvider`'daki ÇOK
      // ESKİ skaler biçim göçü); bu yüzden okuma da try içinde.
      final saved = prefs.getString(prefsKey);
      if (saved == null) return null;
      return jsonDecode(saved) as Map<String, dynamic>;
    } catch (_) {
      // Bozuk/eski formatlı kayıtlı veri — sessizce yoksay, uygulamanın
      // çökmesindense veri kaybı tercih edilir (mevcut provider'ların
      // hepsindeki AYNI kural).
      return null;
    }
  }

  Future<void> _saveLocal(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(data));
  }
}
