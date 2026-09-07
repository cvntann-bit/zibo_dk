# 006 — İçerik havuzları ARB'de değil Dart veri dosyalarında

## Context
Zibo'nun konuşma balonu, modül ekranları, motivasyon sistemi, olay mesajları vb. yüzlerce serbest
metin "söz" içeriyor. Uygulama 3 dilli (TR/EN/ES).

## Decision
- **UI "chrome" metinleri** (buton/başlık/tooltip/SnackBar) → ARB (`gen-l10n`).
- **Büyük "içerik havuzları"** → `lib/data/*.dart` sabit listeleri: `xTr` / `xEn` / `xEs` + `xForLocale(Locale locale)` yardımcı fonksiyonu (`switch (locale.languageCode)`, bilinmeyen dil → TR).

Örnekler: `zibo_messages.dart`, `motivation_pools.dart` (7 havuz × 3 dil), `zibo_event_messages.dart`,
`goal_quotes.dart`, `money_quotes.dart`, `water_quotes.dart`, `dream_quotes.dart`, `gratitude_quotes.dart`,
`mood_quotes.dart`, `manifest_quotes.dart`, `gratitude_prompts.dart`, `legal_texts.dart`.

## Neden
- Uzun serbest metin blokları için ARB placeholder mekanizması gereksiz dolaylılık eklerdi.
- Çeviriler kelimesi kelimesine DEĞİL — Zibo'nun sıcak/samimi tonunu o dilde doğal duracak şekilde koruyan bir UYARLAMA. Hitap: TR "Kanka", EN "buddy", ES "amigo".

## Sonuçlar / Kısıtlar
- **Üç dil BİREBİR aynı sayıda öğe içermeli** — söz seçimi index-tabanlı (`quotes[i % quotes.length]`); farklı uzunluklar yanlış eşleşmeye yol açar. `test/*` içinde `pool.toSet().length == pool.length` (tekrarsızlık) + eşit-uzunluk testleri kapsar. Yeni bir çeviri turu yaptıysan bu testleri çalıştır.
- **Söz döndürme STRING değil INDEX tabanlı** — her ekran `int _quoteIndex` saklar, `build()` içinde `xForLocale(Localizations.localeOf(context))[_quoteIndex % ...]` ile o anki dile göre çözer. Kullanıcı bir söz ekrandayken dil değiştirirse balon anında doğru dile geçer.
- **Yeni bir olay türü / havuz eklerken yalnızca TR'sini doldurup EN/ES'i boş bırakmak bir bug'dır** — `eventMessagesForLocale` boş havuzda TR'ye düşer → İspanyolca kullanıcı Türkçe metin görür. (Tam olarak bu bug yaşandı ve düzeltildi.)
- `applyAddressTerm(text, term, locale)` locale-aware — TR "Kanka" / EN "Buddy" / ES "Amigo" yer tutucusunu kullanıcının seçtiği terimle değiştirir. Boş terim → `RangeError` (guard var: `defaultAddressTerm`'e döner).
- Kaynaktaki `"..."` (çift) vs `'...'` (tek) tırnak farkı — ham metin FARKLI görünür ama Dart STRING DEĞERİ aynı olabilir. Duplicate kontrolü için `grep`/`sort|uniq`'e GÜVENME, gerçek Dart string eşitliğiyle test et.

## İlgili
`lib/l10n/CLAUDE.md` · `docs/ARCHITECTURE.md` §8
