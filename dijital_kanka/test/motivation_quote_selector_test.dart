import 'dart:math';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:dijital_kanka/data/motivation_pools.dart';
import 'package:dijital_kanka/data/zibo_event_messages.dart';
import 'package:dijital_kanka/models/mood.dart';
import 'package:dijital_kanka/utils/mood_note_keywords.dart';
import 'package:dijital_kanka/utils/motivation_quote_selector.dart';
import 'package:dijital_kanka/utils/zibo_event_signal.dart';

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

  // 2026 yeni özellik — Olay Tetiklemeli Özel Mesajlar (bkz. CLAUDE.md).
  group('zibo_event_messages.dart — havuz bütünlüğü + boyut aralığı', () {
    void checkEventPool(
      String label,
      List<String> pool, {
      required int min,
      required int max,
    }) {
      test(
        '$label: $min-$max aralığında ve tekrarsız',
        () {
          expect(pool.length, greaterThanOrEqualTo(min));
          expect(pool.length, lessThanOrEqualTo(max));
          expect(pool.toSet(), hasLength(pool.length));
        },
      );
    }

    checkEventPool(
      'goalCycleCompleted (Tr)',
      eventMessagesForLocale(ZiboEventType.goalCycleCompleted, const Locale('tr')),
      min: 10,
      max: 15,
    );
    checkEventPool(
      'streakBroken (Tr)',
      eventMessagesForLocale(ZiboEventType.streakBroken, const Locale('tr')),
      min: 10,
      max: 15,
    );
    checkEventPool(
      'costumeOrThemeUnlocked (Tr)',
      eventMessagesForLocale(
        ZiboEventType.costumeOrThemeUnlocked,
        const Locale('tr'),
      ),
      min: 5,
      max: 10,
    );
    checkEventPool(
      'loginStreakBonus (Tr)',
      eventMessagesForLocale(ZiboEventType.loginStreakBonus, const Locale('tr')),
      min: 5,
      max: 10,
    );

    test('EN/ES havuzları henüz boş — TR\'ye düşer (bkz. dosya dokümantasyonu)', () {
      for (final type in ZiboEventType.values) {
        final tr = eventMessagesForLocale(type, const Locale('tr'));
        final en = eventMessagesForLocale(type, const Locale('en'));
        final es = eventMessagesForLocale(type, const Locale('es'));
        expect(en, tr);
        expect(es, tr);
      }
    });
  });

  group('resolveMotivationQuoteText — event kaynağı', () {
    test('source == event iken doğru olay havuzundan çözer', () {
      final pool = eventMessagesForLocale(
        ZiboEventType.goalCycleCompleted,
        const Locale('tr'),
      );
      final pick = MotivationQuotePick(
        source: 'event',
        tag: ZiboEventType.goalCycleCompleted.name,
        index: 0,
      );
      expect(
        resolveMotivationQuoteText(pick, const Locale('tr'), const []),
        pool[0],
      );
    });
  });

  group('moodNoteKeywordBias', () {
    test('null/boş not için null döner', () {
      expect(moodNoteKeywordBias(null), isNull);
      expect(moodNoteKeywordBias(''), isNull);
      expect(moodNoteKeywordBias('   '), isNull);
    });

    test('düşük ruh hali kelimesi içeren bir not MoodPoolTag.low döner', () {
      expect(moodNoteKeywordBias('Bugün sınavdan çok yorgun geldim'), MoodPoolTag.low);
      expect(moodNoteKeywordBias('so tired after the exam'), MoodPoolTag.low);
      expect(moodNoteKeywordBias('estoy muy cansada hoy'), MoodPoolTag.low);
    });

    test('yüksek ruh hali kelimesi içeren bir not MoodPoolTag.high döner', () {
      expect(moodNoteKeywordBias('Bugün gerçekten çok mutluyum, başardım!'), MoodPoolTag.high);
      expect(moodNoteKeywordBias('I feel so happy and proud today'), MoodPoolTag.high);
      expect(moodNoteKeywordBias('me siento muy feliz hoy'), MoodPoolTag.high);
    });

    test('bilinen kelime içermeyen bir not null döner', () {
      expect(moodNoteKeywordBias('Bugün markete gittim, süt aldım.'), isNull);
    });

    test('hem düşük hem yüksek kelime aynı anda geçerse (çelişkili) null döner', () {
      expect(
        moodNoteKeywordBias('Çok yorgunum ama sınavı geçtiğim için mutluyum'),
        isNull,
      );
    });
  });

  group('pickMotivationQuote — anahtar kelime çıkarımı', () {
    test(
      'not, seçilen emoji ile AYNI yöndeyse davranış DEĞİŞMEZ (mevcut '
      'testlerle geriye dönük uyumlu)',
      () {
        // roll < timeWeight + moodWeight (mood dalı) düşecek şekilde
        // ayarlanmış sabit bir Random.
        final withoutNote = pickMotivationQuote(
          localNow: DateTime(2026, 1, 1, 10),
          locale: const Locale('tr'),
          latestMood: Mood.veryUnhappy,
          recentLowMoodRatio: 0.0,
          generalPool: const ['genel söz'],
          recentIds: const {},
          random: _ScriptedRandom([0.6], [3]),
        );
        final withMatchingNote = pickMotivationQuote(
          localNow: DateTime(2026, 1, 1, 10),
          locale: const Locale('tr'),
          latestMood: Mood.veryUnhappy,
          recentLowMoodRatio: 0.0,
          generalPool: const ['genel söz'],
          recentIds: const {},
          random: _ScriptedRandom([0.6], [3]),
          latestMoodNote: 'çok yorgunum',
        );
        expect(withMatchingNote.tag, withoutNote.tag);
        expect(withMatchingNote.tag, MoodPoolTag.low.name);
      },
    );

    test(
      'not, seçilen emoji ile ÇELİŞİYORSA mood havuzu notun etiketine göre '
      'çözülür (emoji yerine)',
      () {
        final pick = pickMotivationQuote(
          localNow: DateTime(2026, 1, 1, 10),
          locale: const Locale('tr'),
          latestMood: Mood.neutral,
          recentLowMoodRatio: 0.0,
          generalPool: const ['genel söz'],
          recentIds: const {},
          // roll'ün mood dalına düşmesi için (nötr, boost olmadan) yeterince
          // düşük — %55 zaman + boost'lu %33 ruh hali payının içine.
          random: _ScriptedRandom([0.6], [3]),
          latestMoodNote: 'sınavdan çok yorgun geldim',
        );
        expect(pick.source, 'mood');
        expect(pick.tag, MoodPoolTag.low.name);
      },
    );

    test(
      'çelişkili bir not (hem düşük hem yüksek kelime) hiçbir şeyi '
      'DEĞİŞTİRMEZ — emoji\'nin etiketi kullanılmaya devam eder',
      () {
        final pick = pickMotivationQuote(
          localNow: DateTime(2026, 1, 1, 10),
          locale: const Locale('tr'),
          latestMood: Mood.neutral,
          recentLowMoodRatio: 0.0,
          generalPool: const ['genel söz'],
          recentIds: const {},
          random: _ScriptedRandom([0.6], [3]),
          latestMoodNote: 'çok yorgunum ama başardığım için mutluyum',
        );
        expect(pick.tag, MoodPoolTag.neutral.name);
      },
    );
  });
}
