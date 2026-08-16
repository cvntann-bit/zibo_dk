import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Uygulamanın "bugün"ü hesaplarken cihazın (kullanıcı tarafından
/// değiştirilebilir) yerel saatine değil, ağdan doğrulanmış bir zamana
/// başvurmasını sağlayan soyutlama — `AdService`/`NotificationService`/
/// `ShareService` ile AYNI desen (gerçek implementasyon + testte enjekte
/// edilen sahte).
abstract class TrustedTimeService {
  const TrustedTimeService();

  /// Ağdan güvenilir bir UTC zaman damgası almayı dener. Ağ yoksa/zaman
  /// aşımına uğrarsa/herhangi bir istisna oluşursa `null` döner — ASLA
  /// fırlatmaz (çağıran taraf, `null`ı "şimdilik doğrulanamadı, mevcut
  /// güvenilir taban kullanılmaya devam etsin" olarak yorumlar).
  Future<DateTime?> fetchNetworkTime();
}

/// Gerçek implementasyon: özel bir zaman API'sine (üçüncü parti, kesintiye
/// açık, ayrı bir kota/anahtar gerektirebilir) bağımlı olmadan, herhangi bir
/// HTTPS sunucusunun HER yanıtında protokol gereği (RFC 7231) bulunan
/// `Date` başlığını okuyor — hedef sunucu HTTPS'e cevap verebiliyorsa bu
/// başlık da gelir, yani pratikte %100'e yakın erişilebilirlik. Birden
/// fazla büyük/güvenilir sunucu sırayla deneniyor (biri engelliyse/yanıt
/// vermiyorsa diğerine geçilsin) — `NotificationService`'teki "asla
/// sessizce hiçbir şey yapmadan dönme" yerine burada "her adımda güvenli
/// şekilde bir sonrakine düş" dayanıklılık deseni uygulanıyor.
class HttpDateTrustedTimeService extends TrustedTimeService {
  const HttpDateTrustedTimeService();

  static const _hosts = ['www.google.com', 'www.cloudflare.com', 'www.apple.com'];
  static const _connectTimeout = Duration(seconds: 3);
  static const _overallTimeoutPerHost = Duration(seconds: 4);

  // HTTP `Date` başlığı her zaman RFC 7231 "IMF-fixdate" biçiminde:
  // "Wed, 21 Oct 2015 07:28:00 GMT" — `DateTime.parse` bunu anlamıyor
  // (yalnızca ISO 8601 bekliyor), bu yüzden `intl` ile elle ayrıştırılıyor
  // (proje zaten `intl`'e doğrudan bağımlı, ekstra paket gerekmiyor).
  static final _httpDateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US');

  @override
  Future<DateTime?> fetchNetworkTime() async {
    for (final host in _hosts) {
      final result = await _fetchFromHost(host);
      if (result != null) return result;
    }
    return null;
  }

  Future<DateTime?> _fetchFromHost(String host) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = _connectTimeout;
      final request = await client.headUrl(Uri.https(host)).timeout(_overallTimeoutPerHost);
      final response = await request.close().timeout(_overallTimeoutPerHost);
      final dateHeader = response.headers.value(HttpHeaders.dateHeader);
      if (dateHeader == null) return null;
      final withoutZone = dateHeader.replaceAll(RegExp(r'\s*GMT\s*$'), '').trim();
      return _httpDateFormat.parseUtc(withoutZone);
    } catch (_) {
      // Bu sunucu başarısız oldu (ağ yok, zaman aşımı, beklenmedik yanıt
      // biçimi vb.) — sıradaki sunucuyu dene.
      return null;
    } finally {
      // Bağlantı ne olursa olsun (başarı/hata/zaman aşımı) ZORLA kapatılır
      // — arkada asılı kalan bir soket/bağlantı bırakmamak için (bkz.
      // `flutter test`'te "pending timer" hatalarına yol açabilecek dayanıklı
      // olmayan ağ kodları konusundaki genel uyarı).
      client?.close(force: true);
    }
  }
}

/// Firestore'un kendi sunucu zaman damgasını (`FieldValue.serverTimestamp()`)
/// okuyan implementasyon — [HttpDateTrustedTimeService]'ten daha güvenilir
/// bir kaynak (gerçek bir Google altyapı bileşeni, HTTP `Date` başlığı gibi
/// dolaylı bir yan etkiye dayanmıyor). Paylaşılan bir `_serverTime/ping`
/// belgesine `merge: true` ile yazıp hemen ardından SUNUCUDAN (yerel
/// önbellekten değil — `GetOptions(source: Source.server)`) geri okuyor;
/// belgenin içeriği önemsiz, yalnızca sunucunun bu yazmaya atadığı zaman
/// damgası önemli. Yalnızca kimliği doğrulanmış (`request.auth != null`)
/// istekler yazabilir/okuyabilir (bkz. `firestore.rules`).
class FirestoreTrustedTimeService extends TrustedTimeService {
  FirestoreTrustedTimeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<DateTime?> fetchNetworkTime() async {
    try {
      final ref = _firestore.collection('_serverTime').doc('ping');
      await ref.set({'ts': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final snap = await ref.get(const GetOptions(source: Source.server));
      final ts = snap.data()?['ts'] as Timestamp?;
      return ts?.toDate().toUtc();
    } catch (_) {
      // Firestore erişilemiyor (ağ yok, kural reddi, henüz kimlik doğrulama
      // tamamlanmadı vb.) — `null` dönüp çağıran tarafın bir sonraki
      // kaynağa (bkz. `CompositeTrustedTimeService`) düşmesine izin ver.
      return null;
    }
  }
}

/// Birden fazla [TrustedTimeService]'i SIRAYLA dener, ilk `null` OLMAYAN
/// sonucu döner — hiçbiri başarılı olmazsa `null`. `main.dart`'ta [uid]
/// varken önce [FirestoreTrustedTimeService], o başarısız olursa (ör. henüz
/// Firestore kuralları/ağ hazır değilse) [HttpDateTrustedTimeService]'e
/// düşecek şekilde kullanılıyor — mevcut ÇALIŞAN HTTP-Date kaynağı ATILMIYOR,
/// yedek katman olarak kalıyor.
class CompositeTrustedTimeService extends TrustedTimeService {
  const CompositeTrustedTimeService(this._services);

  final List<TrustedTimeService> _services;

  @override
  Future<DateTime?> fetchNetworkTime() async {
    for (final service in _services) {
      final result = await service.fetchNetworkTime();
      if (result != null) return result;
    }
    return null;
  }
}
