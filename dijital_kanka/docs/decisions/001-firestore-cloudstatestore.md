# 001 — `CloudStateStore` ile çift kalıcılık

## Context
Uygulama başlangıçta tüm kullanıcı verisini yalnızca `SharedPreferences`'ta tutuyordu. Cihaz
değişince / uygulama silinince veri (özellikle satın alınan Zibo Coin) kayboluyordu. Kullanıcı en
kapsamlı kapsamı seçti: coin, hedefler, günlük ödüller, tüm modül verileri, kostüm/tema sahipliği,
tercihler — hepsi buluta.

## Decision
`lib/services/cloud_state_store.dart` — her provider'ın `_loadFromPrefs`/`_save`'inin YERİNE geçen
paylaşılan yardımcı. `load()` önce Firestore (`users/{uid}/state/{prefsKey}`), yoksa yerel veriyi
Firestore'a göç ettirir. `save()` HER ZAMAN önce yerele (eski JSON biçimi/anahtar korunur), sonra
Firestore'a.

## Neden
- Yerel yazı hem çevrimdışı güvenlik ağı hem de `uid == null` (test / Firebase yok) durumunda TEK gerçek kaynak.
- Eski anahtar/biçim korunduğu için ~150 mevcut provider testi HİÇ değişmeden çalışmaya devam etti.
- Firebase'in kendi yerel önbelleği + bizim `SharedPreferences` yedeğimiz = çevrimdışı dayanıklılık.

## Sonuçlar / Kısıtlar
- **`uid == null` iken davranış TAMAMEN eski** — saf `SharedPreferences`, Firestore'a hiç dokunulmaz. Her provider constructor'ı `uid`'i OPSİYONEL alır; hiçbir provider testi vermez.
- Yerel `SharedPreferences` anahtarları **uid'e göre SCOPE'LANMIŞ DEĞİL** — cihaz genelinde tüm hesaplar arasında paylaşılır. Bu yüzden "Çıkış Yap" akışı `clearLocalAccountData()` çağırmak ZORUNDA (yoksa migrasyon mantığı eski hesabın verisini yeni anonim oturuma "miras" bırakır).
- Firestore rules'u `coinState` için sıkılaştırmak (bkz. [005](005-coin-economy-client-authoritative.md)) TEHLİKELİ: `CloudStateStore.save()`'in try/catch'i `PERMISSION_DENIED`'i sessizce yutar → coin senkronu SESSİZCE durur, oyun içinde hiç hata görünmez.
- Yeni bir provider eklendiğinde bu desenle YAZ. Yeni bir `required` alan eklendiğinde "oku-zamanı-göç-et" (`_entryFromJson`'da varsayılan ata, sonraki `_save()`'de kalıcı olur) — ayrı migrasyon betiği YAZMA.

## İlgili
`docs/history/backend-auth-security-referral.md` · `docs/ARCHITECTURE.md` §4
