import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/trusted_time_service.dart';

/// Uygulamanın TÜM "güne bağlı" mekanizmalarının (Günlük Giriş Ödülleri,
/// Hedef Takibi'nin 7 günlük döngüsü, Su Takibi'nin günlük sıfırlanması,
/// Şükran/Ruh Hali/Manifest günlüklerinin günlük kilitleri) "bugün"ü
/// okuduğu TEK, güvenilir kaynak.
///
/// **Neden gerekli — gerçek kullanıcı raporu:** Bu mekanizmaların hepsi
/// eskiden doğrudan cihazın `DateTime.now()`'unu kullanıyordu; kullanıcı
/// telefonun tarihini elle İLERİ alarak "yeni bir gün geldi" sanıp aynı
/// günlük ödülü/streak'i tekrar tekrar tetikleyebiliyordu. Artık hiçbir
/// day-dependent provider doğrudan `DateTime.now()` çağırmıyor — hepsi
/// kendi (testler için zaten var olan) enjekte edilebilir `now:`
/// constructor parametresine, `main.dart`'ta `() => context.read<
/// TrustedTimeProvider>().now()` closure'ı alıyor.
///
/// **Strateji (iki katmanlı):**
/// 1. **Çevrimiçi:** Ağdan ([TrustedTimeService]) periyodik olarak (bkz.
///    [_resyncCooldown]) gerçek UTC zaman doğrulanır; her başarılı
///    doğrulama YENİ bir referans noktası olur ve kalıcı depoya yazılır.
/// 2. **Çevrimdışı (ya da iki doğrulama arası):** [now], cihaz saatine
///    HİÇ bakmaz — son doğrulanmış zamana MONOTONİK (işletim sisteminin
///    donanım saatine dayalı, cihazın TARİH ayarından TAMAMEN bağımsız —
///    `Stopwatch`) geçen süreyi ekleyerek bir değer hesaplar. Cihaz saati
///    ister GERİ ister İLERİ alınsın sonucu ETKİLEMEZ — yalnızca [now]
///    ilk doğrulama HİÇ tamamlanmadan (uygulamanın ilk açılışının ilk
///    anları) çağrılırsa cihaz saatine GEÇİCİ olarak düşülür.
///
/// **Bilinen sınır:** cihaz TAMAMEN çevrimdışıyken (ör. uçak modu) VE henüz
/// hiç doğrulama tamamlanmamışken (ör. ilk kurulum, hiç ağ görmeden) saat
/// ileri alınırsa, ilk doğrulama tamamlanana kadar bu geçici olarak
/// "kanar". Bu, herhangi bir platform API'si gerektirmeden (native uptime
/// sorgusu gibi) ulaşılabilecek en pratik korumadır — bkz. CLAUDE.md
/// "Firestore veri kalıcılığı, Anonymous Auth ve güvenilir zaman"
/// bölümündeki tam açıklama, kabul edilen risk VE bir önceki (İLERİYE
/// alınan saate karşı hiç işe yaramayan) hatalı tasarımın düzeltme geçmişi.
///
/// **2026 bug düzeltmesi — "Günlük Zibo Coin ödülü 1. günde takılı kalıyor"
/// gerçek kullanıcı raporu.** Kök neden: [_loadFromPrefs] KALICI DEPODAN
/// (bir ÖNCEKİ oturumdan kalma, saatler/günler eski olabilecek) bir
/// `_lastVerifiedUtc` yüklediği ANDA, [now] bunu SANKİ BU OTURUMDA
/// doğrulanmış gibi (`verified + _stopwatch.elapsed`, `_stopwatch` bu
/// oturumun başında sıfırdan başlamış olsa BİLE) kullanmaya başlıyordu —
/// yukarıdaki doküman "ilk doğrulama HİÇ tamamlanmadan" cihaz saatine
/// düşüleceğini söylüyor ama kod "kalıcı depodan bir değer okundu" ile
/// "BU oturumda gerçekten doğrulandı"yı birbirine KARIŞTIRIYORDU. Sonuç:
/// ağ senkronizasyonu bir cihazda/oturumda tutarlı şekilde başarısız
/// olursa (ör. soğuk başlangıçta henüz bağlanmamış Wi-Fi/mobil veri),
/// [now] GÜNLERCE dondurulmuş, eski bir tarihte KALABİLİYORDU — her gün
/// uygulama açıldığında "bugün" hep AYNI (eski) günü gösterip
/// `DailyRewardsProvider.todayIndex`'in asla ilerlememesine yol açıyordu.
/// **Düzeltme:** [_verifiedThisSession] eklendi — [now] artık yalnızca BU
/// OTURUMDA gerçekten bir ağ doğrulaması TAMAMLANDIYSA `verified +
/// _stopwatch.elapsed` kullanıyor; kalıcı depodan yüklenmiş ama BU
/// oturumda henüz tazelenmemiş bir değer varken (ki bu, [hasVerifiedTime]
/// `true` dönse bile GEÇERLİ bir durum) [now] güvenle cihaz saatine
/// düşüyor — TAM OLARAK yukarıdaki dokümantasyonun VAAT ETTİĞİ (ama kodun
/// UYGULAMADIĞI) davranış. Güvenlik özelliği (bir doğrulama BU oturumda
/// tamamlandıktan sonra cihaz saati bir daha ASLA danışılmaz) korunuyor.
class TrustedTimeProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// [timeService] verilmezse — testlerin VARSAYILAN kullanımı hariç —
  /// [uid]'e göre seçilir: [uid] varsa önce Firestore sunucu zaman damgasını
  /// deneyip başarısız olursa HTTP `Date` başlığına düşen bir
  /// [CompositeTrustedTimeService]; [uid] `null` ise (Firebase kullanılamıyor
  /// VEYA test ortamı) doğrudan [HttpDateTrustedTimeService] — bugüne kadarki
  /// davranışla birebir aynı, hiçbir regresyon yok.
  TrustedTimeProvider({TrustedTimeService? timeService, String? uid})
    : _timeService =
          timeService ??
          (uid == null
              ? const HttpDateTrustedTimeService()
              : CompositeTrustedTimeService([
                  FirestoreTrustedTimeService(),
                  const HttpDateTrustedTimeService(),
                ])) {
    WidgetsBinding.instance.addObserver(this);
    _loadFromPrefs();
  }

  static const _prefsKey = 'trustedTimeLastVerifiedUtc';

  // Ağdan yeniden doğrulama arası minimum bekleme — `now()` her provider
  // "bugün" okuduğunda ÇOK sık çağrıldığı için, her `syncIfNeeded()`
  // çağrısında gerçekten ağ isteği ATMAMAK amacıyla.
  static const _resyncCooldown = Duration(minutes: 10);

  final TrustedTimeService _timeService;
  final Stopwatch _stopwatch = Stopwatch()..start();

  DateTime? _lastVerifiedUtc;
  DateTime? _lastSyncAttemptAt;
  bool _syncing = false;

  // BU OTURUMDA (bu provider örneğinin ömrü boyunca) gerçekten bir ağ
  // doğrulaması TAMAMLANDI mı — [_lastVerifiedUtc] kalıcı depodan (ÖNCEKİ
  // bir oturumdan) yüklenmiş olması TEK BAŞINA bunu `true` yapmaz, bkz.
  // sınıfın başındaki "2026 bug düzeltmesi" dokümantasyonu.
  bool _verifiedThisSession = false;

  /// Uygulama en az bir kez ağdan doğrulama yapabildiyse `true` — yalnızca
  /// bilgi/hata ayıklama amaçlı, hiçbir provider bu değere göre dallanmaz
  /// (bkz. [now] — doğrulama yoksa zaten güvenli bir bootstrap'a düşer).
  bool get hasVerifiedTime => _lastVerifiedUtc != null;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      try {
        _lastVerifiedUtc = DateTime.parse(saved);
      } catch (_) {
        // Bozuk kayıtlı veri — yok say, ilk ağ doğrulaması düzeltecek.
      }
    }
    // İlk açılışta hemen bir doğrulama dene — `await` EDİLMİYOR (fire-and-
    // forget): provider'ın construction'ı ağ isteğini beklemeden tamamlanır
    // (diğer tüm provider'ların `_loadFromPrefs` deseniyle aynı "asenkron
    // yükleme bloklamaz" felsefesi), sonuç geldiğinde `notifyListeners()`
    // ile geriye bildirilir.
    unawaited(syncIfNeeded(force: true));
  }

  Future<void> _save() async {
    final verified = _lastVerifiedUtc;
    if (verified == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, verified.toIso8601String());
  }

  /// Uygulamanın HER YERDE "bugün" için okuması gereken TEK doğru an —
  /// `DateTime.now()`'un yerini alır, aynı sözleşmeyi (cihazın YEREL saat
  /// dilimine göre bir `DateTime`) korur ki `Goal.dateOnly` gibi mevcut
  /// "tarih-yalnızca" ayıklama mantığı değişmeden çalışmaya devam etsin.
  ///
  /// **Kritik: bir doğrulama VARSA cihazın saatine HİÇ bakılmaz.** Önceki
  /// sürüm "cihaz saati taban değerden ileriyse cihaz saatini kabul et"
  /// diye bir kural taşıyordu — bu, GERİYE alınan saate karşı koruyordu ama
  /// İLERİYE alınana karşı hiçbir işe yaramıyordu (kullanıcı saati ileri
  /// aldığında `deviceUtc` her zaman tabanın "ilerisinde" sayılıp doğrudan
  /// kabul ediliyordu — tam da önlenmek istenen açık). Gerçek bir kullanıcı
  /// testinde yakalandı: tarih ileri alınınca günlük ödüller/streak'ler
  /// hâlâ tekrar tetiklenebiliyordu. **Düzeltme:** bir doğrulama varsa
  /// SADECE `verified + geçen monotonik süre` kullanılır, cihaz saati asla
  /// tekrar danışılmaz — `Stopwatch` donanım saatine dayalı olduğu için
  /// (cihazın TARİH ayarından tamamen bağımsız) bu, kullanıcı saati ileri
  /// ya da geri alsın fark etmeksizin doğru kalır.
  DateTime now() {
    final verified = _lastVerifiedUtc;
    if (verified == null || !_verifiedThisSession) {
      // Henüz BU OTURUMDA hiçbir doğrulama tamamlanmadı — `verified` KALICI
      // DEPODAN (önceki, artık eski olabilecek bir oturumdan) yüklenmiş
      // olabilir, ama `_stopwatch` bu oturumun başında sıfırlandığı için o
      // değere GÜVENİLEMEZ (bkz. sınıfın başındaki "2026 bug düzeltmesi").
      // Cihaz saatine GEÇİCİ olarak düşülüyor; ilk senkron tamamlanır
      // tamamlanmaz (genelde bir saniyeden kısa sürede) düzelecek.
      return DateTime.now();
    }
    return verified.add(_stopwatch.elapsed).toLocal();
  }

  /// Ağdan yeniden doğrulamayı dener. [force] verilmedikçe cooldown
  /// içindeyse hiçbir şey yapmadan döner — bu yüzden `RootScreen`'in
  /// `initState`'i VE her `AppLifecycleState.resumed`'de (bkz. altta)
  /// güvenle/ucuza tekrar tekrar çağrılabilir.
  Future<void> syncIfNeeded({bool force = false}) async {
    if (_syncing) return;
    final last = _lastSyncAttemptAt;
    if (!force && last != null && DateTime.now().difference(last) < _resyncCooldown) {
      return;
    }
    _syncing = true;
    _lastSyncAttemptAt = DateTime.now();
    try {
      final network = await _timeService.fetchNetworkTime();
      if (network != null) {
        _lastVerifiedUtc = network;
        _verifiedThisSession = true;
        _stopwatch
          ..reset()
          ..start();
        notifyListeners();
        await _save();
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncIfNeeded());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
