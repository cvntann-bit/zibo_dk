import 'package:flutter/widgets.dart' show Locale;

// Şükran Günlüğü'ndeki üç metin kutusuna, kullanıcı yazmaya başlamadan önce
// gösterilen ilham verici placeholder önerileri — kullanıcı isteği: "her gün
// değişen ilham verici öneriler".
//
// **2026 DÜZELTME — bu havuz İLK sürümde BİLEREK yalnızca Türkçe bırakılmıştı
// (`zibo_event_messages.dart`'ın "TR only for now" kararıyla AYNI gerekçe —
// kullanıcı yalnızca Türkçe örnek vermişti). Kullanıcı GERÇEK cihazda test
// edip "diğer dillere geçince de Türkçe kalıyor" diye bildirdi — bu, diğer
// TÜM söz havuzlarının (`motivation_pools.dart`/`zibo_messages.dart` vb.)
// zaten uyguladığı "uygulama dili neyse içerik de o dilde olsun" beklentisiyle
// tutarsızdı. Düzeltme: `motivation_pools.dart`'taki AYNI `xTr/xEn/xEs` +
// `xForLocale(Locale)` deseni — üç havuz da BİREBİR aynı uzunlukta (27),
// çeviriler kelimesi kelimesine DEĞİL, Zibo'nun sıcak tonunu o dilde doğal
// duracak şekilde koruyan bir UYARLAMA (motivation_pools.dart'ın aynı
// felsefesi).**
//
// Rotasyon deterministik gün-bazlı (bkz. [gratitudePromptForField]) — gerçek
// rastgelelik DEĞİL, `zibo_messages.dart`'taki söz havuzlarının index-tabanlı
// deseninden FARKLI olarak burada tekrar-önleme/dokunuşa tepki GEREKMİYOR
// (placeholder yalnızca kullanıcı yazmaya başlamadan önce görünüyor, normal
// TextField placeholder davranışıyla kayboluyor) — bu yüzden basit bir
// "günün sırasına göre havuzdan seç" yeterli. Üç alan AYNI ANDA farklı
// önerilerle dolsun diye her alan kendi sabit ofsetiyle (9 — 27 sözlük
// havuzun üçte biri) havuzda ilerliyor, üçü de HER GÜN birlikte değişiyor.
const List<String> gratitudePromptsTr = [
  'Sahip olduğun ama unuttuğun bir imkan...',
  'Doğada fark ettiğin güzel bir şey...',
  'Geçmişten bugüne şükrettiğin bir şey...',
  'Bugün seni gülümseten küçük bir an...',
  'Yanında olduğu için minnettar olduğun bir kişi...',
  'Bedeninin bugün senin için yaptığı bir şey...',
  'Bugün kolayca hallettiğin bir iş...',
  'Çocukluğundan şükrettiğin bir anı...',
  'Evinde/odanda sevdiğin küçük bir detay...',
  'Bugün tattığın güzel bir yemek/içecek...',
  'Sana destek olan bir dostluk...',
  'Öğrenmiş olduğun ve seni geliştiren bir ders...',
  'Bugün duyduğun güzel bir söz/müzik...',
  'Kolayca ulaşabildiğin, değerini bilmediğin bir kaynak (su, elektrik vb.)...',
  'Geçen hafta seni mutlu eden bir gelişme...',
  'Şu an sahip olduğun bir yetenek/beceri...',
  'Bugün birine yardım etme fırsatın oldu mu?...',
  'Sağlığınla ilgili şükrettiğin bir şey...',
  'Bir hayvanın/evcil dostunun sana verdiği mutluluk...',
  'Bugün gördüğün güzel bir manzara/gökyüzü...',
  'Ailenden şükrettiğin bir şey...',
  'Bugün kendine ayırdığın küçük bir an...',
  'Geçmişte zor gelip şimdi seni güçlendiren bir deneyim...',
  'Şu anki işinde/okulunda sevdiğin bir şey...',
  'Bugün seni güldüren bir şaka/olay...',
  'Kendinle ilgili gurur duyduğun bir özellik...',
  'Yarına dair umut verici bir beklenti...',
];

const List<String> gratitudePromptsEn = [
  'A resource you have but tend to forget...',
  'Something beautiful you noticed in nature...',
  'Something from your past you\'re grateful for...',
  'A small moment that made you smile today...',
  'Someone you\'re thankful to have by your side...',
  'Something your body did for you today...',
  'A task you handled with ease today...',
  'A childhood memory you\'re grateful for...',
  'A small detail you love about your home...',
  'A good meal or drink you enjoyed today...',
  'A friendship that supports you...',
  'A lesson you learned that helped you grow...',
  'A kind word or song you heard today...',
  'A resource you take for granted (water, electricity, etc.)...',
  'Something good that happened last week...',
  'A skill or talent you have right now...',
  'Did you get a chance to help someone today?...',
  'Something about your health you\'re grateful for...',
  'The joy a pet or animal brings you...',
  'A beautiful view or sky you saw today...',
  'Something about your family you\'re grateful for...',
  'A small moment you carved out for yourself today...',
  'A hard experience that ended up making you stronger...',
  'Something you enjoy about your work or studies...',
  'A joke or moment that made you laugh today...',
  'A quality about yourself you\'re proud of...',
  'A hopeful expectation for tomorrow...',
];

const List<String> gratitudePromptsEs = [
  'Un recurso que tienes pero sueles olvidar...',
  'Algo hermoso que notaste en la naturaleza...',
  'Algo de tu pasado por lo que estás agradecido...',
  'Un pequeño momento que te hizo sonreír hoy...',
  'Alguien por quien estás agradecido de tenerlo cerca...',
  'Algo que tu cuerpo hizo por ti hoy...',
  'Una tarea que resolviste fácilmente hoy...',
  'Un recuerdo de la infancia por el que estás agradecido...',
  'Un pequeño detalle que amas de tu hogar...',
  'Una buena comida o bebida que disfrutaste hoy...',
  'Una amistad que te apoya...',
  'Una lección que aprendiste y te ayudó a crecer...',
  'Una linda palabra o canción que escuchaste hoy...',
  'Un recurso que das por sentado (agua, electricidad, etc.)...',
  'Algo bueno que pasó la semana pasada...',
  'Una habilidad o talento que tienes ahora mismo...',
  '¿Tuviste la oportunidad de ayudar a alguien hoy?...',
  'Algo de tu salud por lo que estás agradecido...',
  'La alegría que te da una mascota o un animal...',
  'Una vista o un cielo hermoso que viste hoy...',
  'Algo de tu familia por lo que estás agradecido...',
  'Un pequeño momento que te dedicaste a ti mismo/a hoy...',
  'Una experiencia difícil que terminó haciéndote más fuerte...',
  'Algo que disfrutas de tu trabajo o tus estudios...',
  'Una broma o momento que te hizo reír hoy...',
  'Una cualidad tuya de la que te sientes orgulloso/a...',
  'Una expectativa esperanzadora para mañana...',
];

/// [locale]'e göre doğru dildeki havuzu döner — `zibo_messages.dart`'taki
/// `ziboMessagesForLocale` ile AYNI desen (per-pool TR geri düşüşü: bir dil
/// ileride boşaltılsa/eksik kalsa bile TÜM sistem Türkçe'ye düşmez).
List<String> gratitudePromptsForLocale(Locale locale) {
  final list = switch (locale.languageCode) {
    'en' => gratitudePromptsEn,
    'es' => gratitudePromptsEs,
    _ => gratitudePromptsTr,
  };
  return list.isEmpty ? gratitudePromptsTr : list;
}

/// [date], [fieldIndex]'e (0, 1 veya 2) ve [locale]'e göre havuzdan
/// deterministik bir öneri döner — aynı gün içinde üç alan da AYNI çağrıda
/// tutarlı, farklı önerilerle dolar; gün değişince (bir sonraki takvim
/// günü) üçü de birlikte döner; dil değişince (Ayarlar > Dil) konuşma
/// balonlarındaki AYNI "index sabit, metin o anki dile göre çözülür"
/// deseniyle ANINDA doğru dile geçer. Saf/test edilebilir bir fonksiyon.
String gratitudePromptForField(DateTime date, int fieldIndex, Locale locale) {
  // Yıl+ay+gün'den basit, monoton artan bir "gün sırası" — takvim ayının
  // gerçek gün sayısına duyarlı olmasına gerek yok, yalnızca HER takvim
  // gününde FARKLI (ve ertesi gün yine farklı) bir değer üretmesi yeterli.
  final dayOrdinal = date.year * 372 + date.month * 31 + date.day;
  final pool = gratitudePromptsForLocale(locale);
  final index = (dayOrdinal + fieldIndex * 9) % pool.length;
  return pool[index];
}
