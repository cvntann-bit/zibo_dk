import 'package:flutter/material.dart';

import '../utils/zibo_event_signal.dart';

/// Olay tetiklemeli özel Zibo mesajları — bkz. CLAUDE.md "Olay Tetiklemeli
/// Özel Mesajlar" bölümü. `motivation_pools.dart`'ın AYNI `xTr/En/Es` +
/// per-pool Türkçe geri düşüş deseni: şimdilik yalnızca Türkçe dolu,
/// İngilizce/İspanyolca BİLEREK BOŞ (`motivation_pools.dart`'ın İLK
/// sürümüyle AYNI, ileride ayrı bir çeviri turunda doldurulabilir —
/// `eventMessagesForLocale` her havuzu AYRI AYRI kontrol edip boşsa
/// Türkçe'ye düşer, tek bir dil eksik diye TÜMÜ Türkçe'ye düşmez).
///
/// **Bu havuzlar normal zaman/ruh hali havuzlarından TAMAMEN AYRI** —
/// `motivation_quote_selector.dart`'ın ağırlıklı seçimine hiç girmiyorlar,
/// yalnızca [pendingZiboEvent] BİR OLAY taşıdığında `HomeScreen.
/// _pickAndSetQuote()` tarafından DOĞRUDAN (rastgele ağırlıklandırma
/// ATLANARAK) kullanılıyorlar — bkz. o metodun dokümantasyonu.
const _goalCycleCompletedTr = <String>[
  'Yaptın! 7 gün boyunca hiç vazgeçmedin, bugün gerçekten gurur duyman gereken bir gün.',
  'Bir haftalık hedefini tamamladın — bu küçük bir şey değil, sen bunu başardın!',
  '7/7! Söz verdiğin şeyi tuttun, kendine bunu hatırlat.',
  'Bugün seninle çok gurur duyuyorum, bu döngüyü sonuna kadar taşıdın.',
  'Bir hedefi baştan sona tamamlamak cesaret ister — sen bunu gösterdin.',
  'Tebrikler! Bu hafta attığın her adım seni buraya getirdi.',
  'Vazgeçmeden 7 gün — bu senin disiplinin, unutma.',
  'Bugün kutlama günü! Hedefini tamamladın, kendine bir armağan hak ettin.',
  'Sen yaptın! Şimdi bu başarıyı bir sonrakine taşıma sırası.',
  'Bir döngüyü tamamlamak bile büyük bir adım, sen bunu yaptın Kanka.',
  'Bugün geriye dönüp bak: yedi gün önce başladığın yerden çok ileridesin.',
  'Harikaydın! Bu hedefi tamamladığın için gerçekten mutluyum.',
];

const _streakBrokenTr = <String>[
  'Bir gün kaçırmışsın, olsun — önemli olan pes etmemek. Bugün yeniden başlayalım.',
  'Herkesin böyle günleri olur, sen de istisna değilsin. Yarın diye bir şey var.',
  'Döngü sıfırlandı ama sen sıfırlanmadın — bugün yeni bir başlangıç.',
  'Bir gün atlamak seni tanımlamaz, devam etmen tanımlar.',
  'Kaçırdığın gün geçti, şimdi elindeki tek şey bugün — onu değerlendirelim mi?',
  'Kendine sert davranma, bir aksama her zaman toparlanabilir.',
  'Bazen hayat araya girer, bu normal. Bugün tekrar adım atmaya ne dersin?',
  'Bir düşüş bitiş değil, yalnızca kısa bir mola. Devam edelim.',
  'Seni suçlamıyorum Kanka, sadece hatırlatıyorum: yeniden başlamak her zaman mümkün.',
  'Döngü yeniden başladı, bu da yeni bir şans demek. Hazır mısın?',
  'Bir gün kaçırdın diye tüm çabaların boşa gitmedi, unutma.',
  'Bugün sıfırdan başlıyoruz ama sıfırdan güçlü bir şekilde.',
];

const _costumeOrThemeUnlockedTr = <String>[
  'Yeni bir görünüm kazandın! Nasıl duruyor, beğendin mi?',
  'Tebrikler, dolabına yeni bir parça eklendi!',
  'Bunu hak ettin — yeni stilinin tadını çıkar.',
  'Yepyeni bir Zibo karşında! Bu görünümü sana yakıştırdım.',
  'Yeni bir şey açtın, bu küçük bir kutlamayı hak ediyor.',
  'İşte bu! Koleksiyonun büyümeye devam ediyor.',
  'Yeni tarzını beğendim, sen ne düşünüyorsun?',
  'Bunu kazanmak için emek verdin, şimdi tadını çıkarma sırası.',
];

const _loginStreakBonusTr = <String>[
  'Vay be! Yedi gün boyunca beni hiç yalnız bırakmadın, bu gerçekten özel!',
  'Bugün büyük gün! Seri bonusun tam sana göre, harikasın!',
  'Bu ne kadar güzel bir seri! Seninle gurur duyuyorum, kutlamayı hak ettin!',
  'İnanılmazsın! Bu tempo ile devam edersen durduramayız seni!',
  'Büyük bonus, büyük başarı! Bugün gerçekten senin günün Kanka!',
  'Vay canına, bunu başardın! Seriyi bu şekilde sürdürmek kolay değil!',
  'Bugün kutlama zamanı! Bu seriyi hak ederek kazandın!',
  'Sen bir harikasın! Bu bonus tamamen senin emeğinin karşılığı!',
];

const _goalCycleCompletedEn = <String>[];
const _streakBrokenEn = <String>[];
const _costumeOrThemeUnlockedEn = <String>[];
const _loginStreakBonusEn = <String>[];

const _goalCycleCompletedEs = <String>[];
const _streakBrokenEs = <String>[];
const _costumeOrThemeUnlockedEs = <String>[];
const _loginStreakBonusEs = <String>[];

/// [type] olayı için [locale]'e göre söz havuzunu döner — havuz o dilde
/// boşsa (bkz. dosya dokümantasyonu) Türkçe'ye düşer.
List<String> eventMessagesForLocale(ZiboEventType type, Locale locale) {
  final trList = _poolFor(type, 'tr');
  final localizedList = _poolFor(type, locale.languageCode);
  return localizedList.isEmpty ? trList : localizedList;
}

List<String> _poolFor(ZiboEventType type, String languageCode) {
  return switch (languageCode) {
    'en' => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedEn,
      ZiboEventType.streakBroken => _streakBrokenEn,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedEn,
      ZiboEventType.loginStreakBonus => _loginStreakBonusEn,
    },
    'es' => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedEs,
      ZiboEventType.streakBroken => _streakBrokenEs,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedEs,
      ZiboEventType.loginStreakBonus => _loginStreakBonusEs,
    },
    _ => switch (type) {
      ZiboEventType.goalCycleCompleted => _goalCycleCompletedTr,
      ZiboEventType.streakBroken => _streakBrokenTr,
      ZiboEventType.costumeOrThemeUnlocked => _costumeOrThemeUnlockedTr,
      ZiboEventType.loginStreakBonus => _loginStreakBonusTr,
    },
  };
}
