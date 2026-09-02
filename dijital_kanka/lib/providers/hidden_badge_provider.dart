import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/cloud_state_store.dart';

/// Gizli/Eğlenceli Rozetler'in "Gece Kuşu"/"Erken Kuş" sayaçlarını tutan tek
/// kaynak — bkz. CLAUDE.md "Rozet Sistemi" bölümü. `CoinProvider`/
/// `AppStreakProvider` ile AYNI `CloudStateStore` (Varyant A) deseni.
///
/// **BİLEREK `TrustedTimeProvider`/`AppStreakProvider`'ın AKSİNE cihazın
/// KENDİ saatini ([DateTime.now]) kullanıyor, GÜVENLİK-KRİTİK bir zaman
/// kaynağına BAĞLI DEĞİL.** `AppStreakProvider`'ın kendi dokümantasyonu
/// "güne bağlı" mekanizmaların (Günlük Giriş Ödülleri, Hedef Takibi, İstikrar
/// Rozetleri'nin streak eşikleri) HEPSİNİN `TrustedTimeProvider.now()`
/// KULLANMASI gerektiğini söylüyor — ama BU provider'ın ölçtüğü şey ("cihazın
/// GÜNÜN HANGİ SAATİNDE olduğu") kavramsal olarak FARKLI bir soru:
/// `motivation_quote_selector.dart`'taki `timeBucketFor`'un AYNI gerekçesiyle
/// ("kullanıcı FARKLI bir saat dilimine SEYAHAT ederse `TrustedTimeProvider`'ın
/// doğrulanmış-UTC-çıpası yeni yerel saate otomatik UYMAYABİLİR, bu özellik
/// ise kullanıcının O ANKİ GERÇEK yerel saatini yansıtmalı") — kullanıcının
/// AÇIK isteği ("cihaz saatine göre", İKİ kez tekrarlandı) de bununla TUTARLI.
/// **Kabul edilen ödünleşim:** bu, `AppStreakProvider`'daki "cihaz saatini
/// ileri/geri alarak manipüle edilemez" garantisini TAŞIMIYOR — bir kullanıcı
/// cihaz saatini gece yarısına ayarlayıp uygulamayı 30 kez (farklı takvim
/// GÜNÜ göstererek) açarsa bu rozeti erken kazanabilir. Bu, "gizli/eğlenceli"
/// kategorisinin (777 ZC'lik ödülüne rağmen) bilinçli olarak DÜŞÜK-RİSKLİ/
/// eğlence odaklı kabul edilen bir özellik olduğu, ve kullanıcının AÇIKÇA bu
/// davranışı İSTEDİĞİ için kabul edildi — `Coin Ekonomisi Güvenliği`
/// bölümündeki genel "client-authoritative ekonomi" risk kabulüyle AYNI
/// kategoride.
class HiddenBadgeProvider extends ChangeNotifier {
  HiddenBadgeProvider({
    String? uid,
    FirebaseFirestore? firestore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _store = CloudStateStore(
         prefsKey: _prefsKey,
         uid: uid,
         firestore: firestore,
       ) {
    _loadFromPrefs();
  }

  static const _prefsKey = 'hiddenBadgeState';
  final DateTime Function() _now;
  final CloudStateStore _store;

  final Set<DateTime> _nightOwlDays = {};
  final Set<DateTime> _earlyBirdDays = {};
  bool _isReady = false;

  bool get isReady => _isReady;

  /// Cihaz saatine göre gece yarısı (00:00) ile sabah 05:00 arası
  /// uygulamanın açıldığı TOPLAM FARKLI gün sayısı — "Gece Kuşu" rozeti
  /// (bkz. `hidden_badges.dart`) 30'a ulaşınca kazanılır.
  int get nightOwlDaysCount => _nightOwlDays.length;

  /// Cihaz saatine göre sabah 06:00-08:00 arası uygulamanın açıldığı TOPLAM
  /// FARKLI gün sayısı — "Erken Kuş" rozeti 30'a ulaşınca kazanılır.
  int get earlyBirdDaysCount => _earlyBirdDays.length;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadFromPrefs() async {
    try {
      final data = await _store.load();
      if (data != null) {
        final rawNightOwl = data['nightOwlDays'] as List? ?? const [];
        final rawEarlyBird = data['earlyBirdDays'] as List? ?? const [];
        _nightOwlDays
          ..clear()
          ..addAll(rawNightOwl.map((s) => DateTime.parse(s as String)));
        _earlyBirdDays
          ..clear()
          ..addAll(rawEarlyBird.map((s) => DateTime.parse(s as String)));
      }
    } catch (_) {
      // Bozuk/okunamayan veri — sıfırdan başla, diğer provider'lardaki AYNI
      // "asla çökme" güvenlik ağı.
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _save() {
    return _store.save({
      'nightOwlDays': _nightOwlDays.map((d) => d.toIso8601String()).toList(),
      'earlyBirdDays': _earlyBirdDays.map((d) => d.toIso8601String()).toList(),
    });
  }

  /// Uygulama her açıldığında/öne geldiğinde çağrılır (`RootScreen.initState`
  /// postFrameCallback'i + `didChangeAppLifecycleState`'in `resumed` dalı —
  /// `AppStreakProvider.recordOpenForToday()` ile AYNI tetikleme deseni).
  /// Cihazın O ANKİ saatine göre hangi pencereye ([00:00, 05:00) VEYA
  /// [06:00, 08:00)) denk geldiğini kontrol edip, denk geliyorsa BUGÜNÜ
  /// (gerçek takvim tarihini, saat dilimi içindeki İKİNCİ/ÜÇÜNCÜ bir açılış
  /// tekrar SAYILMASIN diye) ilgili kümeye ekler — `Set.add` zaten aynı
  /// tarih için idempotent, ayrı bir "bugün zaten sayıldı mı" kontrolüne
  /// gerek yok.
  void recordOpenForCurrentTime() {
    final now = _now();
    final hour = now.hour;
    final today = _dateOnly(now);
    var changed = false;
    if (hour >= 0 && hour < 5) {
      changed = _nightOwlDays.add(today);
    } else if (hour >= 6 && hour < 8) {
      changed = _earlyBirdDays.add(today);
    }
    if (changed) {
      notifyListeners();
      unawaited(_save());
    }
  }
}
