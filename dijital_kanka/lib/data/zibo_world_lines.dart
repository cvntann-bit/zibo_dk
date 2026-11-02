import 'package:flutter/material.dart';

import '../models/home_need.dart';

// Zibo Dünyası giriş ekranında Zibo'nun konuşma balonu (docs/zibo_world.md,
// docs/zibo_world_roadmap.md Faz 3). Zibo en düşük ihtiyacın odasında durur
// ve onu ister; her şey yolundaysa mutlu bir cümle söyler. Üç dilde doğal
// çeviriler, her listede BİREBİR aynı sayıda cümle (proje kuralı:
// içerik havuzları ARB'ye taşınmaz, `xForLocale(Locale)` deseni).

const ziboWorldNeedLinesTr = <HomeNeed, List<String>>{
  HomeNeed.hunger: ['Karnım acıktı, mutfağa gidelim!', 'Midem guruldadı kanka, bir şeyler atıştıralım mı?', 'Mutfaktan güzel kokular geliyor gibi…'],
  HomeNeed.hygiene: ['Biraz kirlendim, banyo zamanı!', 'Köpük köpük bir banyo iyi gelirdi.', 'Üstüm başım toz oldu, banyoya koşalım!'],
  HomeNeed.energy: ['Gözlerim kapanıyor, uyuyalım mı?', 'Esnemekten çenem ağrıdı, biraz uyusam?', 'Yatağım beni çağırıyor…'],
  HomeNeed.fun: ['Canım sıkıldı, oyun oynayalım!', 'Salonda bir oyun açalım mı?', 'Biraz eğlenmeye ne dersin kanka?'],
};
const ziboWorldNeedLinesEn = <HomeNeed, List<String>>{
  HomeNeed.hunger: ["I'm hungry, let's go to the kitchen!", 'My tummy is rumbling, buddy, snack time?', 'Something smells yummy in the kitchen…'],
  HomeNeed.hygiene: ['I got a bit messy, bath time!', 'A bubbly bath would feel so good.', "I'm all dusty, let's run to the bath!"],
  HomeNeed.energy: ["My eyes are closing, let's sleep?", "I can't stop yawning, maybe a nap?", 'My bed is calling me…'],
  HomeNeed.fun: ["I'm bored, let's play a game!", 'Shall we play a game in the living room?', 'How about some fun, buddy?'],
};
const ziboWorldNeedLinesEs = <HomeNeed, List<String>>{
  HomeNeed.hunger: ['¡Tengo hambre, vamos a la cocina!', 'Me ruge la panza, amigo, ¿picamos algo?', 'Algo huele rico en la cocina…'],
  HomeNeed.hygiene: ['Me ensucié un poco, ¡hora del baño!', 'Un baño con mucha espuma me vendría genial.', 'Estoy lleno de polvo, ¡corramos al baño!'],
  HomeNeed.energy: ['Se me cierran los ojos, ¿dormimos?', 'No paro de bostezar, ¿una siestita?', 'Mi cama me está llamando…'],
  HomeNeed.fun: ['Me aburro, ¡juguemos a algo!', '¿Jugamos algo en el salón?', '¿Qué tal un poco de diversión, amigo?'],
};

const ziboWorldHappyLinesTr = <String>['Her şey yolunda, evimiz çok güzel!', 'Bugün kendimi harika hissediyorum!', 'Odaları süslemeye ne dersin?'];
const ziboWorldHappyLinesEn = <String>["All good, our home is lovely!", 'I feel amazing today!', 'Want to decorate the rooms?'];
const ziboWorldHappyLinesEs = <String>['¡Todo bien, nuestra casa es preciosa!', '¡Hoy me siento genial!', '¿Decoramos las habitaciones?'];

/// [need] null ise mutlu cümle. [seed] aynı kaldıkça aynı cümle seçilir
/// (ekran her yenilendiğinde balon değişip durmasın).
String ziboWorldLineForLocale(Locale locale, HomeNeed? need, int seed) {
  final (needs, happy) = switch (locale.languageCode) {
    'en' => (ziboWorldNeedLinesEn, ziboWorldHappyLinesEn),
    'es' => (ziboWorldNeedLinesEs, ziboWorldHappyLinesEs),
    _ => (ziboWorldNeedLinesTr, ziboWorldHappyLinesTr),
  };
  final pool = need == null ? happy : needs[need]!;
  return pool[seed.abs() % pool.length];
}
