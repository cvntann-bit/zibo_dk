# `lib/l10n/` — Yerelleştirme kuralları

Resmi Flutter `gen-l10n`. Config: `l10n.yaml` (`arb-dir: lib/l10n`, template `app_tr.arb`, çıktı
`AppLocalizations`). Üç dil: TR (template/kaynak) / EN / ES. `LocaleProvider` (`SharedPreferences`,
varsayılan TR).

## Zorunlu adımlar

- **ARB'ye anahtar ekledikten sonra kod derlemeden ÖNCE `flutter gen-l10n` çalıştır.** `flutter test` bunu otomatik tetiklemez → "getter isn't defined" derleme hatası alırsın.
- Üç ARB dosyası da senkron olmalı — her anahtar TR + EN + ES'de bulunmalı.
- **Kullanılmayan ARB anahtarını SİLME** (proje konvansiyonu). Kod-seviyesi ölü fonksiyonlar silinebilir.

## ARB'ye ait OLMAYAN metinler — `lib/data/*.dart` içinde

Büyük "içerik havuzları" (Zibo'nun sözleri, motivasyon havuzları, olay mesajları, modül sözleri,
gratitude prompt'ları, legal metinler) ARB'de DEĞİL. Desen: `xTr` / `xEn` / `xEs` const listeleri +
`xForLocale(Locale locale)` (`switch (locale.languageCode)`, bilinmeyen → TR). Detay/gerekçe →
`docs/decisions/006-content-pools-in-dart.md`.

Dosyalar: `zibo_messages.dart`, `motivation_pools.dart`, `zibo_event_messages.dart`, `goal_quotes.dart`,
`money_quotes.dart`, `water_quotes.dart`, `dream_quotes.dart`, `gratitude_quotes.dart`, `mood_quotes.dart`,
`manifest_quotes.dart`, `gratitude_prompts.dart`, `legal_texts.dart`.

### Havuz kuralları
- **Üç dil BİREBİR aynı sayıda öğe** (index-tabanlı seçim; farklı uzunluk = yanlış eşleşme). `test/` içinde `pool.toSet().length == pool.length` (tekrarsızlık) + eşit-uzunluk testleri var — çeviri turundan sonra ÇALIŞTIR.
- Çeviri = **uyarlama**, kelimesi kelimesine değil. Zibo'nun sıcak/samimi tonu korunur. Hitap: TR "Kanka" / EN "buddy" / ES "amigo".
- **Yeni bir havuz/olay türü eklerken YALNIZCA TR'sini doldurup EN/ES'i boş bırakmak BUG'dır** — `xForLocale` boş havuzda TR'ye düşer, İspanyolca kullanıcı Türkçe metin görür. (`zibo_event_messages.dart` tam bu yüzden düzeltildi.)
- Duplicate kontrolü: `"..."` (çift) vs `'...'` (tek) tırnak farkı ham metinde FARKLI görünür ama Dart string DEĞERİ aynı olabilir — `grep`/`uniq`'e güvenme, gerçek string eşitliğiyle test et.

## Söz döndürme INDEX tabanlı (STRING değil)

Her söz-gösteren ekran `int _quoteIndex` saklar, `build()`'de
`xForLocale(Localizations.localeOf(context))[_quoteIndex % pool.length]` ile o anki dile göre çözer.
Kullanıcı ekranda bir söz varken dil değiştirirse balon anında doğru dile geçer. `motivation_quote_
selector.dart`'ta bu `MotivationQuotePick{source, tag, index}` kimliği olarak taşınır, `resolveMotivationQuoteText`
her `build()`'de metni yeniden çözer.

## Hitap Tercihi — `applyAddressTerm(text, term, locale)`

`lib/utils/address_term.dart` — locale-aware. `term == defaultAddressTerm` ('Kanka') iken metni
olduğu gibi döner (hızlı yol); değilse locale'e göre "Kanka"/"Buddy"/"Amigo" yer tutucusunu (büyük +
küçük harf ayrı `replaceAll`) seçilen terimle değiştirir. Boş terim `RangeError` fırlatır → guard
var (`ProfileProvider.setAddressTerm` boş girdide `defaultAddressTerm`'e döner). 8 söz-gösteren ekran
bunu uygular. `notification_provider.dart` kapsam dışı (özellik zaten rafta).

## Locale-bağımlı özel durumlar

- **Gizlilik Politikası / Kullanım Koşulları** (`legal_texts.dart`) — TR/EN/ES üç dilde de var (`privacyPolicyForLocale` / `termsOfServiceForLocale`). Ama URL'de (`getzibo.com/privacy`) da yayınlanması gerekiyor (Play Data Safety formu için) — ayrı proje.
- **Bildirim betikleri** (`notification-scripts/src/content.js`) kendi TR/EN/ES kopyalarını taşır — Dart ARB'den okumaz. Kullanıcı dili `users/{uid}/state/languageCode`'dan.
- Saat dilimi: yerel bildirimler için `Europe/Istanbul` hardcoded (özellik rafta). Push betikleri kullanıcının KENDİ saat dilimini kullanır.
