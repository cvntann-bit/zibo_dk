import 'package:flutter/foundation.dart';

import '../models/coin_economy.dart';
import '../services/cloud_state_store.dart';

/// Bir gün kutucuğunun 7 günlük döngüdeki görsel/etkileşim durumu.
/// `GoalDayStatus`'tan farklı olarak "kaçırılmış" (missed) diye ayrı bir
/// durum YOK — bir gün kaçırılırsa [DailyRewardsProvider.reconcileForToday]
/// zaten tüm döngüyü sıfırlayıp bugünden yeniden başlattığı için, güncel
/// döngüde bugünden ÖNCEKİ bir gün her zaman ya alınmış (claimed) ya da hiç
/// var olmamış (önceki bir döngüye ait) olur.
enum DailyRewardDayStatus {
  /// Ödülü zaten alınmış (geçmişte veya bugün).
  claimed,

  /// Bugünün tarihi — henüz alınmadıysa tek dokunulabilir kutucuk.
  today,

  /// Tarihi henüz gelmemiş — kilitli, dokunulamaz.
  upcoming,
}

/// Kullanıcının 7 günlük "Günlük Giriş Ödülleri" döngüsünü tutan tek
/// kaynak. Mimari `GoalsProvider`'daki tek bir hedefin döngüsüyle BİREBİR
/// AYNI desen (gerçek takvim tarihine bağlı `cycleStartDate` + o döngüde
/// alınmış tarihlerin kümesi) — ama burada kullanıcının oluşturduğu birden
/// çok hedef yok, uygulama genelinde TEK bir global döngü var, bu yüzden
/// `Goal` gibi ayrı bir model sınıfına gerek kalmadı.
///
/// Coin ödülü vermek bu provider'ın işi değil — `GoalsProvider`/
/// `WaterProvider` ile aynı gerekçeyle coin sistemine bağımlı değil;
/// [claimToday] o günün ödül miktarını (veya alınamadıysa `null`) döner,
/// gerçekten eklemek çağıran widget'ın sorumluluğunda
/// (`CoinProvider.earnDailyLoginReward`).
///
/// [now] parametresi testte sahte bir saat enjekte edebilmek için var —
/// `GoalsProvider`/`WaterProvider`/`GratitudeProvider` ile aynı desen.
class DailyRewardsProvider extends ChangeNotifier {
  DailyRewardsProvider({DateTime Function() now = DateTime.now, String? uid})
    : _now = now,
      _store = CloudStateStore(prefsKey: _prefsKey, uid: uid) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'dailyRewards';
  static const _daysPerCycle = 7;

  final DateTime Function() _now;
  final CloudStateStore _store;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Cihazın bugünkü tarihi (saat bileşeni olmadan).
  DateTime get today => _dateOnly(_now());

  DateTime _cycleStartDate = _dateOnly(DateTime.now());
  Set<DateTime> _claimedDates = {};

  Future<void> _loadFromPrefs() async {
    final decoded = await _store.load();
    if (decoded != null) {
      try {
        _cycleStartDate = DateTime.parse(decoded['cycleStartDate'] as String);
        _claimedDates = (decoded['claimedDates'] as List)
            .map((d) => DateTime.parse(d as String))
            .toSet();
      } catch (_) {
        // Bozuk/eski formatlı kayıtlı veri — sessizce varsayılan (bugün
        // başlayan boş bir döngü) ile devam et.
      }
    } else {
      // İlk kurulum: döngü bugünden başlasın (constructor'daki varsayılan
      // `DateTime.now()` yerine enjekte edilen [_now] kullanılsın diye).
      _cycleStartDate = today;
    }
    // Yükleme sonrası, uygulama kapalıyken kaçırılmış günler varsa hemen
    // yakala — `reconcileForToday` zaten `notifyListeners`/`_save` çağırıyor.
    reconcileForToday();
    notifyListeners();
  }

  Future<void> _save() async {
    await _store.save({
      'cycleStartDate': _cycleStartDate.toIso8601String(),
      'claimedDates': _claimedDates.map((d) => d.toIso8601String()).toList(),
    });
  }

  /// Bugünün döngüdeki 0-tabanlı gün indeksi. Döngü sınırları içindeyse
  /// (0..6) [statusForIndex]/[claimToday] bunu doğrudan kullanır;
  /// [reconcileForToday] bu değer sınırların dışına çıktığında (döngü
  /// tamamlanıp bir sonraki güne geçildiğinde) devreye girer.
  int get todayIndex => today.difference(_cycleStartDate).inDays;

  bool get isTodayClaimed => _claimedDates.contains(today);

  /// Bugün henüz alınmadıysa ve döngünün geçerli günündeyse o günün ödül
  /// miktarını döner (henüz alınmış bir tema/kostüm satın alma metotlarının
  /// aksine burada gösterecek bir şey olmayabilir — `null` = bugün için
  /// gösterilecek bir miktar yok, ör. döngü henüz reconcile edilmemiş).
  int? get todayAmount {
    final idx = todayIndex;
    if (idx < 0 || idx >= CoinEconomy.dailyLoginRewards.length) return null;
    return CoinEconomy.dailyLoginRewards[idx];
  }

  /// [index] (0-6) için o günün durumunu döner — grid'i çizmek için.
  DailyRewardDayStatus statusForIndex(int index) {
    final date = _cycleStartDate.add(Duration(days: index));
    if (_claimedDates.contains(date)) return DailyRewardDayStatus.claimed;
    if (date.isAtSameMomentAs(today)) return DailyRewardDayStatus.today;
    return DailyRewardDayStatus.upcoming;
  }

  /// Bugünden önce, güncel döngü içinde kaçırılmış (işaretlenmemiş) bir gün
  /// varsa YA DA döngü tamamlanıp 7 günlük pencere tamamen geride kaldıysa
  /// (kullanıcı 7. günü aldıktan sonraki bir gün tekrar açtıysa), döngüyü
  /// bugünden yeniden Gün 1 olarak başlatır. Bu TEK metot hem "gün kaçırma"
  /// hem "döngü tamamlanınca otomatik yeni döngü" gereksinimini karşılıyor
  /// — `GoalsProvider._reconcileGoal`'dan farkı, burada "tamamlanmış döngü,
  /// pencere geride kaldı" durumunun da aynı sıfırlamayı tetiklemesi (Goal'da
  /// bu, `toggleToday` içinde 7/7 anında ayrıca ele alınıyordu; burada daha
  /// basit tek bir kontrolle birleştirildi çünkü kalıcı bir "tamamlanma
  /// geçmişi" — `GoalCompletion` gibi — bu özellik için istenmedi).
  ///
  /// Uygulama her açıldığında/öne geldiğinde VE popup her açıldığında bir
  /// kez çağrılması yeterli. Sıfırlama olduysa `true` döner.
  bool reconcileForToday() {
    final idx = todayIndex;
    // `idx < 0` normalde HİÇ olmamalı (bugünün, döngü başlangıcından ÖNCE
    // olması demek) — ama gerçek bir kullanıcı raporuyla bulunan bug: bu,
    // `TrustedTimeProvider`'ın ağdan HENÜZ doğrulama yapmadığı "bootstrap"
    // anında cihazın kendi (yanlış/ileri ayarlı olabilen) saatine geçici
    // olarak düşmesi yüzünden, döngünün BİR KEZ yanlışlıkla GELECEKTEKİ bir
    // tarihle başlatılmış olabileceği anlamına gelir. Eski kod bu durumu da
    // "sıfırlanması gereken" sayıp `_claimedDates`'i SİLİYORDU — bu da ağ
    // saati düzelir düzelmez (aynı oturumda veya bir sonraki açılışta)
    // kullanıcının AZ ÖNCE aldığı ödülün kaybolmasına, ve ertesi her gün
    // yeniden "1. gün" olarak açılmasına yol açıyordu (`idx` gerçek zaman
    // poisoned tarihe ulaşana kadar HEP negatif kalıyordu). Doğru davranış:
    // hiçbir şeyi silmeden BEKLEMEK — `GoalsProvider._reconcileGoal`'ın
    // `while (cursor.isBefore(today))` deseni bu anomaliye zaten doğal
    // olarak bağışık (döngü `cycleStartDate >= today` iken hiç başlamıyor),
    // buradaki `idx` tabanlı yaklaşım bunu AYRICA, açıkça kontrol etmeli.
    if (idx < 0) return false;

    var shouldReset = idx >= _daysPerCycle;
    if (!shouldReset) {
      for (var i = 0; i < idx; i++) {
        final date = _cycleStartDate.add(Duration(days: i));
        if (!_claimedDates.contains(date)) {
          shouldReset = true;
          break;
        }
      }
    }
    if (!shouldReset) return false;

    _cycleStartDate = today;
    _claimedDates = {};
    notifyListeners();
    _save();
    return true;
  }

  /// Bugünün ödülünü talep eder. Yalnızca döngünün geçerli günü bugünse VE
  /// henüz alınmadıysa etkilidir; kazanılan miktarı döner (alınamadıysa
  /// `null`) — gerçekten coin eklemek çağıran widget'ın sorumluluğunda.
  int? claimToday() {
    final idx = todayIndex;
    if (idx < 0 || idx >= CoinEconomy.dailyLoginRewards.length) return null;
    if (_claimedDates.contains(today)) return null;

    _claimedDates.add(today);
    final amount = CoinEconomy.dailyLoginRewards[idx];
    notifyListeners();
    _save();
    return amount;
  }
}
