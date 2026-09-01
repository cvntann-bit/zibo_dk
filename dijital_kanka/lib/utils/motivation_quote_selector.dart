import 'dart:math';

import 'package:flutter/material.dart' show Locale;

import '../data/motivation_pools.dart';
import '../data/zibo_event_messages.dart';
import '../models/mood.dart';
import 'mood_note_keywords.dart';
import 'zibo_event_signal.dart' show ZiboEventType;

/// Ana Sayfa'daki Zibo konuşma balonu için zaman dilimi + ruh hali duyarlı,
/// ağırlıklı söz seçim motoru — bkz. CLAUDE.md "Motivasyon Sözü Sistemi"
/// bölümü. Bu dosyadaki TÜM fonksiyonlar SAF (yan etkisiz) — `DateTime`/
/// `Random` her zaman parametre olarak geliyor, hiçbiri kendi başına
/// `DateTime.now()`/`Random()` çağırmıyor — `wheel_prizes.dart`'taki
/// `pickWeightedPrize` ile AYNI "test edilebilirlik" felsefesi.

/// Seçilen bir sözün KİMLİĞİ — metnin KENDİSİ değil (bkz. altta [resolveText]).
///
/// **Neden metin değil kimlik saklanıyor:** projede kurulu convansiyon
/// (`HomeScreen`'in eski `_messageIndex`'i, `MoneyScreen`/`GoalTrackingScreen`
/// vb.'nin `_quoteIndex`'i) bir sözü "hangi havuzun kaçıncı elemanı" olarak
/// saklayıp GÖSTERİM ANINDA o anki dile göre metni yeniden çözüyor — bu
/// sayede kullanıcı bir söz ekrandayken dili değiştirirse (Ayarlar > Dil)
/// konuşma balonu AYNI "konumdaki" sözün YENİ dildeki karşılığına ANINDA
/// geçiyor, `_currentQuote`'un TEXT'ini sabitlemiş olsaydık dil değişince
/// eski dildeki metin donup kalırdı. [source]/[tag]/[index] bu "konumu"
/// kodluyor, [resolveText] her `build()`'de o anki `locale`'e göre metni
/// tazeliyor.
class MotivationQuotePick {
  const MotivationQuotePick({
    required this.source,
    required this.tag,
    required this.index,
  });

  /// `'time'` | `'mood'` | `'general'` | `'event'` (bkz.
  /// `utils/zibo_event_signal.dart` — olay tetiklemeli özel mesajlar,
  /// normal ağırlıklı seçimi BAYPAS EDEN dördüncü bir kaynak).
  final String source;

  /// `source == 'time'` ise `TimeBucket.name`, `source == 'mood'` ise
  /// `MoodPoolTag.name`, `source == 'event'` ise `ZiboEventType.name`,
  /// `source == 'general'` ise boş string.
  final String tag;

  final int index;

  /// Tekrar-önleme takibi için kararlı bir anahtar — `"time:morning:12"` gibi.
  String get id => '$source:$tag:$index';
}

/// [pick]'in o anki [locale]'e göre GÖSTERİLECEK metnini çözer — [pick]
/// seçildiği anki dilden BAĞIMSIZ, her zaman GÜNCEL `locale`/[generalPool]'a
/// göre yeniden hesaplanır (bkz. sınıf dokümantasyonu). Havuz boyutu
/// [pick.index]'ten küçükse (ör. dil değişince farklı uzunlukta bir havuza
/// düşülürse) `%` ile güvenle sarılır — projenin diğer TÜM locale-portable
/// söz indekslerindeki AYNI güvenlik deseni.
String resolveMotivationQuoteText(
  MotivationQuotePick pick,
  Locale locale,
  List<String> generalPool,
) {
  final pool = switch (pick.source) {
    'time' => timeBucketQuotes(TimeBucket.values.byName(pick.tag), locale),
    'mood' => moodPoolQuotes(MoodPoolTag.values.byName(pick.tag), locale),
    'event' => eventMessagesForLocale(
      ZiboEventType.values.byName(pick.tag),
      locale,
    ),
    _ => generalPool,
  };
  if (pool.isEmpty) return '';
  return pool[pick.index % pool.length];
}

/// [localNow]'ın SAATİNE göre dört zaman dilimine ayırır — kullanıcının
/// AÇIK isteği "cihazın kendi saatine göre, sabit bir saat dilimi
/// kullanma" — bu yüzden [localNow] HER ZAMAN düz `DateTime.now()`'dan
/// (TrustedTimeProvider'ın anti-hile "doğrulanmış" saatinden DEĞİL, bkz.
/// CLAUDE.md'deki mimari kararı) gelmeli; farklı bir ülkeye seyahat eden
/// kullanıcı için de cihazın O ANKİ yerel saatini doğru yansıtır.
TimeBucket timeBucketFor(DateTime localNow) {
  final hour = localNow.hour;
  if (hour >= 5 && hour < 12) return TimeBucket.morning;
  if (hour >= 12 && hour < 18) return TimeBucket.afternoon;
  if (hour >= 18 && hour < 22) return TimeBucket.evening;
  return TimeBucket.night;
}

/// [mood]'u üç ruh hali havuzundan birine eşler — `Mood.isLow`/`isHighEnergy`
/// extension'larının (bkz. `models/mood.dart`) doğrudan üzerine kurulu.
/// [mood] `null` ise (kullanıcı hiç ruh hali kaydetmediyse) güvenli
/// varsayılan olarak `neutral` döner.
MoodPoolTag moodPoolTagFor(Mood? mood) {
  if (mood == null) return MoodPoolTag.neutral;
  if (mood.isLow) return MoodPoolTag.low;
  if (mood.isHighEnergy) return MoodPoolTag.high;
  return MoodPoolTag.neutral;
}

/// Son [windowDays] gün içindeki kaydedilmiş ruh hali kayıtlarının ne
/// kadarının "düşük" (bkz. `Mood.isLow`) olduğunu 0.0-1.0 arası bir oran
/// olarak döner — hiç kayıt yoksa `0.0`. **Bu bir yapay zeka DEĞİL** —
/// yalnızca `entries` üzerinde saf bir sayma/oranlama; kullanıcının
/// "gerçek bir yapay zeka değil, biriken veriye dayalı basit bir
/// ağırlıklandırma" isteğiyle birebir. [pickMotivationQuote]'a
/// `recentLowMoodRatio` olarak geçirilip mood havuzunun payını "hafifçe"
/// artırmak için kullanılıyor (bkz. altta).
double recentLowMoodRatio(
  List<MoodEntry> entries,
  DateTime localNow, {
  int windowDays = 14,
}) {
  final cutoff = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
  ).subtract(Duration(days: windowDays));
  final recent = entries.where((e) => !e.date.isBefore(cutoff)).toList();
  if (recent.isEmpty) return 0.0;
  final lowCount = recent.where((e) => e.mood.isLow).length;
  return lowCount / recent.length;
}

/// Bir kaynak havuzdan (zaman/ruh hali/genel) [recentIds]'te OLMAYAN bir
/// söz seçer — bulunamazsa (havuz çok küçük + neredeyse tamamı hariç
/// tutulmuşsa) hariç tutmayı YOK SAYIP yine de bir sonuç döner, ASLA
/// sonsuz döngüye girmez veya `null`/hata döndürmez (`HomeScreen`'in eski
/// `_pickNewMessageIndex`'indeki sabit-`Random` sonsuz-döngü riskinin AYNI
/// dersi — bkz. CLAUDE.md "Zibo'ya Art Arda Dokunma" bölümü).
MotivationQuotePick _pickFrom(
  String source,
  String tag,
  List<String> pool,
  Set<String> recentIds,
  Random random,
) {
  if (pool.isEmpty) {
    // Teorik olarak imkansız (zaman/ruh hali havuzları Türkçe geri
    // düşüşü sayesinde asla boş değil, genel havuz her zaman `zibo_
    // messages.dart`'ın en az 279 sözünü içerir) ama savunmacı bir son çare.
    return MotivationQuotePick(source: source, tag: tag, index: 0);
  }
  const maxAttempts = 20;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final index = random.nextInt(pool.length);
    final candidate = MotivationQuotePick(source: source, tag: tag, index: index);
    if (!recentIds.contains(candidate.id)) return candidate;
  }
  // maxAttempts denemede hariç tutmayı aşan bir index bulunamadı (havuz
  // küçük + neredeyse tamamı hariç) — hariç tutmayı yok sayıp yine de bir
  // sonuç dön.
  return MotivationQuotePick(
    source: source,
    tag: tag,
    index: random.nextInt(pool.length),
  );
}

/// Ana seçim fonksiyonu — üç kaynağı (zaman dilimi/ruh hali/genel) ağırlıklı
/// olarak karıştırıp TEK bir söz KİMLİĞİ döner (metin DEĞİL — bkz.
/// [MotivationQuotePick] dokümantasyonu, [resolveText] ile gösterim anında
/// çözülür). Ağırlıklar kullanıcının kendi ifadesiyle: **%50-60 zaman
/// dilimi, %20-30 ruh hali, kalan genel** — somut orta değerler seçildi
/// (%55/%25/%20) ve [recentLowMoodRatio] son 14 günün yarısından fazlası
/// "düşük" ise ruh hali payına "hafifçe" (+10 puan, zaman diliminden yarısı
/// + genelden yarısı düşülerek) bir kişiselleşme nüansı ekliyor
/// (kullanıcının 7. madde isteği).
///
/// **2026 yeni özellik — [latestMoodNote]'tan anahtar kelime çıkarımı
/// (bkz. `mood_note_keywords.dart`).** Kullanıcının notu ([moodNoteKeywordBias]
/// ile taranıp) SEÇTİĞİ emoji'den TÜRETİLEN etiketle (`moodPoolTagFor
/// (latestMood)`) ÇELİŞEN bir sinyal veriyorsa (ör. emoji "nötr" ama not
/// "sınavdan çok yorgun geldim" diyorsa), İKİ şey oluyor: (1) o özel notun
/// GÜNCELLİĞİ/özgüllüğü nedeniyle ruh hali havuzu artık emoji'nin DEĞİL
/// notun işaret ettiği etiketten (`effectiveMoodTag`) besleniyor, (2) ruh
/// hali payına [recentLowMoodRatio] ile AYNI büyüklükte (+8 puan) EK bir
/// "hafif" nüans daha ekleniyor — bu notun görmezden gelinmeyip GERÇEKTEN
/// bir sonuç doğurduğunu garantiliyor. Not YOKSA/boşsa VEYA emoji'yle
/// ZATEN AYNI yöndeyse VEYA kendi içinde çelişkiliyse (`moodNoteKeywordBias`
/// `null` döner) davranış TAMAMEN DEĞİŞMİYOR — mevcut testlerin hiçbiri
/// bu değişiklikten etkilenmedi.
MotivationQuotePick pickMotivationQuote({
  required DateTime localNow,
  required Locale locale,
  required Mood? latestMood,
  required double recentLowMoodRatio,
  required List<String> generalPool,
  required Set<String> recentIds,
  required Random random,
  String? latestMoodNote,
}) {
  const baseTimeWeight = 0.55;
  const baseMoodWeight = 0.25;
  const baseGeneralWeight = 0.20;

  final moodTag = moodPoolTagFor(latestMood);
  final keywordBias = moodNoteKeywordBias(latestMoodNote);
  final keywordConflict = keywordBias != null && keywordBias != moodTag;
  final effectiveMoodTag = keywordBias ?? moodTag;

  final ratioBoost = recentLowMoodRatio > 0.5 ? 0.10 : 0.0;
  final keywordBoost = keywordConflict ? 0.08 : 0.0;
  final moodBoost = ratioBoost + keywordBoost;
  final timeWeight = baseTimeWeight - moodBoost / 2;
  final moodWeight = baseMoodWeight + moodBoost;
  final generalWeight = baseGeneralWeight - moodBoost / 2;
  final total = timeWeight + moodWeight + generalWeight;

  final bucket = timeBucketFor(localNow);

  final roll = random.nextDouble() * total;
  if (roll < timeWeight) {
    final pool = timeBucketQuotes(bucket, locale);
    return _pickFrom('time', bucket.name, pool, recentIds, random);
  }
  if (roll < timeWeight + moodWeight) {
    final pool = moodPoolQuotes(effectiveMoodTag, locale);
    return _pickFrom('mood', effectiveMoodTag.name, pool, recentIds, random);
  }
  return _pickFrom('general', '', generalPool, recentIds, random);
}
