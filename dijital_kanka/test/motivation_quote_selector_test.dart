import 'dart:math';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/motivation_pools.dart';
import 'package:dijital_kanka/models/mood.dart';
import 'package:dijital_kanka/utils/motivation_quote_selector.dart';

/// Testte kontrollü bir sonuç dizisi döndüren sahte `Random` —
/// `wheel_prizes_test.dart`'taki `_FixedRandom` deseniyle AYNI amaç.
class _ScriptedRandom implements Random {
  _ScriptedRandom(this._doubles, [this._ints = const []]);

  final List<double> _doubles;
  final List<int> _ints;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  double nextDouble() {
    final value = _doubles[_doubleIndex % _doubles.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    if (_ints.isEmpty) return 0;
    final value = _ints[_intIndex % _ints.length];
    _intIndex++;
    return value;
  }

  @override
  bool nextBool() => false;
}

void main() {
  group('timeBucketFor', () {
    test('sınır saatleri doğru zaman dilimine düşer', () {
      DateTime at(int hour, [int minute = 0]) => DateTime(2026, 1, 1, hour, minute);

      expect(timeBucketFor(at(4, 59)), TimeBucket.night);
      expect(timeBucketFor(at(5, 0)), TimeBucket.morning);
      expect(timeBucketFor(at(11, 59)), TimeBucket.morning);
      expect(timeBucketFor(at(12, 0)), TimeBucket.afternoon);
      expect(timeBucketFor(at(17, 59)), TimeBucket.afternoon);
      expect(timeBucketFor(at(18, 0)), TimeBucket.evening);
      expect(timeBucketFor(at(21, 59)), TimeBucket.evening);
      expect(timeBucketFor(at(22, 0)), TimeBucket.night);
      expect(timeBucketFor(at(0, 0)), TimeBucket.night);
    });
  });

  group('moodPoolTagFor', () {
    test('beş Mood değeri + null doğru kategoriye eşlenir', () {
      expect(moodPoolTagFor(null), MoodPoolTag.neutral);
      expect(moodPoolTagFor(Mood.veryUnhappy), MoodPoolTag.low);
      expect(moodPoolTagFor(Mood.unhappy), MoodPoolTag.low);
      expect(moodPoolTagFor(Mood.neutral), MoodPoolTag.neutral);
      expect(moodPoolTagFor(Mood.happy), MoodPoolTag.high);
      expect(moodPoolTagFor(Mood.veryHappy), MoodPoolTag.high);
    });
  });

  group('recentLowMoodRatio', () {
    test('hiç kayıt yoksa 0.0 döner', () {
      expect(recentLowMoodRatio(const [], DateTime(2026, 1, 15)), 0.0);
    });

    test('pencere dışındaki eski kayıtları hariç tutar', () {
      final now = DateTime(2026, 1, 15);
      final entries = [
        // Pencerenin (14 gün) dışında — hariç tutulmalı.
        MoodEntry(date: DateTime(2025, 12, 1), mood: Mood.veryUnhappy),
        // Pencere içinde, ikisi düşük, biri yüksek → 2/3.
        MoodEntry(date: DateTime(2026, 1, 10), mood: Mood.unhappy),
        MoodEntry(date: DateTime(2026, 1, 12), mood: Mood.veryUnhappy),
        MoodEntry(date: DateTime(2026, 1, 14), mood: Mood.veryHappy),
      ];
      expect(recentLowMoodRatio(entries, now), closeTo(2 / 3, 0.0001));
    });
  });

  group('resolveMotivationQuoteText', () {
    test('time/mood/general kaynaklarının hepsi doğru havuzdan çözülür', () {
      const locale = Locale('tr');
      const generalPool = ['genel bir söz'];

      final timePick = MotivationQuotePick(source: 'time', tag: 'morning', index: 0);
      expect(
        resolveMotivationQuoteText(timePick, locale, generalPool),
        motivationMorningTr[0],
      );

      final moodPick = MotivationQuotePick(source: 'mood', tag: 'low', index: 3);
      expect(
        resolveMotivationQuoteText(moodPick, locale, generalPool),
        motivationLowMoodTr[3],
      );

      final generalPick = MotivationQuotePick(source: 'general', tag: '', index: 0);
      expect(
        resolveMotivationQuoteText(generalPick, locale, generalPool),
        'genel bir söz',
      );
    });

    test('havuz boyutundan büyük index güvenle % ile sarılır', () {
      const locale = Locale('tr');
      final pick = MotivationQuotePick(
        source: 'time',
        tag: 'morning',
        index: motivationMorningTr.length + 5,
      );
      expect(
        resolveMotivationQuoteText(pick, locale, const []),
        motivationMorningTr[5],
      );
    });

    test('İngilizce/İspanyolca havuzlar doldurulduktan sonra KENDİ metinlerini döner', () {
      // Havuzlar bu turda İngilizce/İspanyolca'ya çevrildi (bkz.
      // motivation_pools.dart) — artık Türkçe'ye DÜŞMÜYOR, gerçek çeviriyi
      // dönüyor. Per-pool geri düşüş mekanizması (bir havuz BOŞ kalırsa
      // Türkçe'ye düşme) kod tarafında hâlâ duruyor (bkz. `timeBucketQuotes`/
      // `moodPoolQuotes`'un `isEmpty` kontrolü) ama şu an test edecek boş
      // bir havuz kalmadığı için bu test yalnızca ÇEVİRİLERİN doğru
      // bağlandığını doğruluyor.
      final pick = MotivationQuotePick(source: 'mood', tag: 'high', index: 2);
      expect(
        resolveMotivationQuoteText(pick, const Locale('en'), const []),
        motivationHighMoodEn[2],
      );
      expect(
        resolveMotivationQuoteText(pick, const Locale('es'), const []),
        motivationHighMoodEs[2],
      );
      // Üçü de FARKLI metinler olmalı (aynı index, üç dilde de gerçekten
      // farklı içerik) — kopyala-yapıştır bir hata (ör. EN'in yanlışlıkla
      // TR'nin aynısı kalması) olursa bu assertion yakalar.
      expect(motivationHighMoodEn[2], isNot(equals(motivationHighMoodTr[2])));
      expect(motivationHighMoodEs[2], isNot(equals(motivationHighMoodTr[2])));
    });
  });

  group('pickMotivationQuote', () {
    test('sabit Random ile ağırlıklı kaynak seçimi deterministik olur', () {
      // total ağırlık 0.55+0.25+0.20=1.0 iken roll=0.1 → zaman dilimi.
      final timeSourcePick = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7), // sabah
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.0,
        generalPool: const ['genel'],
        recentIds: const {},
        random: _ScriptedRandom([0.1], [0]),
      );
      expect(timeSourcePick.source, 'time');
      expect(timeSourcePick.tag, 'morning');

      // roll=0.99 → genel (0.55+0.25=0.80'in ötesinde).
      final generalSourcePick = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7),
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.0,
        generalPool: const ['genel'],
        recentIds: const {},
        random: _ScriptedRandom([0.99], [0]),
      );
      expect(generalSourcePick.source, 'general');
    });

    test('tekrar-önleme: recentIds\'teki index atlanır', () {
      // Havuzda yalnızca 2 eleman varmış gibi davranan küçük bir genel
      // havuzla test ediyoruz; ilk index (0) hariç tutulunca ikinci
      // denemede farklı bir index (1) dönmeli.
      final scripted = _ScriptedRandom([0.99, 0.99], [0, 1]);
      final pick = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7),
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.0,
        generalPool: const ['a', 'b'],
        recentIds: const {'general::0'},
        random: scripted,
      );
      expect(pick.index, 1);
    });

    test('havuzun TAMAMI hariç tutulduğunda sonsuz döngüye girmeden bir sonuç döner', () {
      final pick = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7),
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.0,
        generalPool: const ['tek eleman'],
        recentIds: const {'general::0'}, // havuzdaki TEK index zaten hariç
        random: _ScriptedRandom([0.99], [0]),
      );
      // maxAttempts denemeden sonra exclusion yok sayılıp yine de bir
      // sonuç dönmeli — test'in kendisi TAMAMLANIYORSA (timeout/hang
      // olmadan) asıl garanti zaten kanıtlanmış olur.
      expect(pick.source, 'general');
      expect(pick.index, 0);
    });

    test('recentLowMoodRatio > 0.5 iken ruh hali payı artar', () {
      // roll=0.60: base ağırlıklarla (0.55/0.25/0.20) bu "general"a
      // düşerdi (0.55+0.25=0.80'in altında olduğu için aslında "mood"a
      // düşer — asıl fark: boost'lu haldeyken timeWeight küçülüp moodWeight
      // büyüdüğü için roll=0.52 gibi bir değer boost YOKKEN "general"a
      // (0.55+0.25=0.80 sonrası DEĞİL, 0.55 sonrası mood'a) düşer;
      // burada asıl doğrulanan boost'un timeWeight'i GERÇEKTEN küçülttüğü.
      final withoutBoost = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7),
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.0, // boost YOK — timeWeight tam 0.55
        generalPool: const ['genel'],
        recentIds: const {},
        random: _ScriptedRandom([0.53], [0]),
      );
      expect(withoutBoost.source, 'time'); // 0.53 < 0.55

      final withBoost = pickMotivationQuote(
        localNow: DateTime(2026, 1, 1, 7),
        locale: const Locale('tr'),
        latestMood: null,
        recentLowMoodRatio: 0.9, // boost VAR — timeWeight 0.55-0.05=0.50
        generalPool: const ['genel'],
        recentIds: const {},
        random: _ScriptedRandom([0.53], [0]),
      );
      expect(withBoost.source, 'mood'); // 0.53 artık timeWeight'in (0.50) ÜSTÜNDE
    });
  });

  // 2026 güncellemesi — 7 havuz × 3 dil çeviri/uyarlama sonrası: `zibo_
  // messages.dart`'a yeni söz eklenirken kurulan AYNI convansiyon (bkz.
  // CLAUDE.md "Profil" bölümündeki "İKİNCİ güncelleme" notu) — her havuzun
  // KENDİ İÇİNDE birebir tekrar İÇERMEDİĞİNİ VE üç dilin her birinin tam
  // 51 uzunlukta olduğunu doğrular. `.toSet().length` GERÇEK Dart string
  // eşitliğiyle çalıştığı için tırnak-tipi farklılıkları (tek/çift tırnak)
  // gibi salt metinsel `grep` kontrolünün kaçırabileceği yanlış-negatifleri
  // YAKALAMIYOR ama gerçek kopyala-yapıştır tekrarlarını güvenilir yakalar.
  group('motivation_pools.dart — havuz bütünlüğü', () {
    void checkPool(String label, List<String> pool) {
      test('$label: 51 uzunlukta ve tekrarsız', () {
        expect(pool, hasLength(51));
        expect(pool.toSet(), hasLength(51));
      });
    }

    checkPool('motivationMorningTr', motivationMorningTr);
    checkPool('motivationAfternoonTr', motivationAfternoonTr);
    checkPool('motivationEveningTr', motivationEveningTr);
    checkPool('motivationNightTr', motivationNightTr);
    checkPool('motivationLowMoodTr', motivationLowMoodTr);
    checkPool('motivationNeutralMoodTr', motivationNeutralMoodTr);
    checkPool('motivationHighMoodTr', motivationHighMoodTr);

    checkPool('motivationMorningEn', motivationMorningEn);
    checkPool('motivationAfternoonEn', motivationAfternoonEn);
    checkPool('motivationEveningEn', motivationEveningEn);
    checkPool('motivationNightEn', motivationNightEn);
    checkPool('motivationLowMoodEn', motivationLowMoodEn);
    checkPool('motivationNeutralMoodEn', motivationNeutralMoodEn);
    checkPool('motivationHighMoodEn', motivationHighMoodEn);

    checkPool('motivationMorningEs', motivationMorningEs);
    checkPool('motivationAfternoonEs', motivationAfternoonEs);
    checkPool('motivationEveningEs', motivationEveningEs);
    checkPool('motivationNightEs', motivationNightEs);
    checkPool('motivationLowMoodEs', motivationLowMoodEs);
    checkPool('motivationNeutralMoodEs', motivationNeutralMoodEs);
    checkPool('motivationHighMoodEs', motivationHighMoodEs);
  });
}
