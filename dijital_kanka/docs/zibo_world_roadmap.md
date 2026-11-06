# Zibo Dünyası — uygulama yol haritası (1.18.0 büyük güncellemesi)

Durum: **plan (2026-11-02), kod yok.** Bu dosya taslakların uygulamaya nasıl geçeceğinin tek kaynağıdır; her faz bitince işaretlenir.
Kararlar ve gerekçeler: `zibo_world.md`. Görsel kurallar: `zibo_home_art.md`. Ekonomi: `unit_economics.md`.

Taslaklar (birebir hedef görünüm):
- Giriş ekranı: `docs/zibo_world_prototype/` — https://claude.ai/artifact/TLAUdqjmFvWYNvDAK45DA3
- Odalar, dekor, bakım: `docs/home_studio/` — https://claude.ai/artifact/Xsg9UadXjmGRobPkxnpXaE

## Değişmez ilkeler
- **1.18.0 tek büyük sürüm.** Ara sürüm yok; satın alma doğrulaması kaydı, uygulama içi mesaj kartı, tablet 840 dp de bu sürümle çıkar.
- **Her faz:** ayrı commit'ler, `flutter test` yeşil, **debug APK ile telefonda kontrol noktası**, kullanıcı onayı. AAB yalnızca Faz 10'da.
- **Görünüm taslakla aynı:** odalar kodla çizilir (Flutter `CustomPainter`), Zibo gerçek pozu, renk varyantı yeni görsel istemez.
- **Çocuk güvenliği:** ceza yok (Zibo ölmez/hastalanmaz), bakımın ortasında zorunlu reklam yok, her şeyin bedava bir yolu var, serbest sohbet yok.
- **Zarar etmemek:** her yeni ZC ödülü/fiyatı `unit_economics.md`'den geçer; fiyatlar ve hızlar uzaktan (`config/home`) değişebilir.
- Proje kuralları geçerli: katman bazlı klasörler (`lib/screens|widgets|providers|models|data`), ARB'ler TR/EN/ES, kullanılmayan ARB silinmez, `flutter analyze` yok.

---

## Faz 0 — Kararlar ve girdiler (kod öncesi)
| Konu | Durum | Not |
|---|---|---|
| Sıralama + Arkadaşlar 1.18.0'da mı? | **KARAR: HAYIR (2026-11-02)** | 1.19.0'a kaldı; 1.18.0'da kapılar "Yakında" |
| Sekme/dünya adı | Bekliyor | Geçici: "Zibo Dünyası" (alt çubuk), "Zibo'nun Evi" (başlık) |
| Yeni Zibo pozları | Kullanıcı üretecek | Küvette oturan, uyuyan (gözler kapalı), yemek yiyen. Gelene kadar mevcut pozlar |
| Sabun tüketilebilir mi? | **KARAR: bir kez alınır (2026-11-02)** | Ayrıca **sabunun şekli dekor ürünü** olarak satılır ve değiştirilir (kalp, yıldız, ördek, bulut…); köpük rengi sabun türünden, görünüm şekilden gelir |
| Uyku gerçek zamanlı mı? | **KARAR: gerçek zamanlı (2026-11-02)** | Uyutunca `sleep.startedAt` yazılır, enerji geçen süreye göre dolar (uygulama kapalıyken de); hız `config/home` (varsayılan taslak: 0→100 yaklaşık 60 dk) |
| Pro/Pro+ avantajı | **KARAR: kesinlikle olsun (2026-11-02)** | Ayrıntı taslağı `subscribe_model.md` "Zibo Dünyası avantajları"; kesin liste kullanıcı onayıyla |
| Yılbaşına yetişme | Bekliyor | 1 Aralık öncesi çıkarsa takvim uzaktan açılır |
| Ekonomi tablosu | Faz 9'dan önce | Kazanma ~100–120 ZC/gün aktif kullanıcı (tahmin: check-in 5 + görev 15 + 2 reklam 40 + günlükler ~15 + giriş ödülü ort. ~30 + takas) |

## Faz 1 — Veri modeli ve kabuk
**Hedef:** Oyunlar sekmesi Zibo Dünyası olur, mevcut oyunlar kaybolmadan içine taşınır.
- **Firestore**
  - İki ayrı state dokümanı (genel `state/{stateDoc}` sahip kuralı kapsar, yeni kural gerekmez; ikiye bölündü ki sık yazılan ihtiyaçlar dekor kaydını her seferinde yeniden yazmasın):
    - `users/{uid}/state/homeNeedsState` — `levels {hunger, hygiene, energy, fun}`, `updatedAt`, `sleepStartedAt|null`, `sleepStartEnergy`, `freeFoodDay`, `freeFoodsUsed`. (`stats` sayaçları Faz 4'te eklenecek.)
    - `users/{uid}/state/homeDecorState` — `equipped {oda: {kategori: itemId}}`, `owned ["oda:kategori:eşya"]`, `soaps [id]`, `soap`.
  - `config/home` (okuma: giriş yapmış herkes, yazma: `isAdmin()` — **kural Console'a yayınlandı 2026-11-03**): `decayPerHour`, `minLevel`, `sleepMinutesToFull`, ücretsiz yemek sayıları, Pro/Pro+ indirim ve hızları, `priceOverrides {"oda:kategori:eşya" | "food:id" | "soap:id": ZC}`.
  - `events/{id}` (Faz 6, kural Faz 6'da).
- **Modeller/veri:** `lib/models/home_item.dart` (oda, kategori türü, eşya, yemek, sabun), `lib/models/home_need.dart`, `lib/data/home_config.dart`, `lib/data/home_catalog.dart` — **üretilen dosya**: `tool/generate_home_catalog.py` taslaktaki (`docs/home_studio/index.html`) eşya, yemek ve sabun bloklarını okuyup yazar; taslak değişince betik yeniden çalıştırılır. Adlar şimdilik yalnız TR (çeviri Faz 5'te).
- **Provider'lar:** `HomeNeedsProvider` (ihtiyaçlar, `TrustedTimeProvider` ile zamanla düşer, alt sınır var), `HomeDecorProvider` (sahip/takılı, `CloudStateStore`), `HomeConfigProvider` (`GamesConfigProvider` deseni).
- **Coin:** `CoinProvider`'a `spendOnHomeItem({itemId, cost})`, `spendOnFood`, `spendOnSoap` (işlem nedeni sabit önekli: `Ev: `, `Ev yemeği: `, `Sabun: ` → ileride harcama analizi). `coinState` kuralı değişmez (tek yazım ≤ 33.000 ZC; en pahalı ev eşyası 1.500).
- **Kabuk:** `RootScreen` sekme 1 → `ZiboWorldScreen`; `GameHallScreen` Oyunlar kapısından push; `onGamesTap` çağrıları yeni yere bağlanır. `main.dart` MultiProvider + `test/` `_buildAppWithClock` provider listesi güncellenir (`test/CLAUDE.md`).
- **Durum (2026-11-02): kod tamam, testler yeşil** — 13 birim testi (`test/zibo_world_test.dart`). Ekran şimdilik iskelet: halkalar, boya renkli 2×2 oda kartları, Zibo en düşük ihtiyacın odasında, kapılar (Sıralama/Arkadaşlar kilitli). Oda kartları Faz 2'den beri oda ekranını açar. Kural yayınlandı (2026-11-03). Kalan: APK kontrolü.
- **Kontrol noktası (APK):** sekme açılıyor, boş ev iskeleti, Oyunlar kapısı → bugünkü Oyun Salonu sorunsuz, eski kullanıcı verisi duruyor.

## Faz 2 — Çizim motoru (taslak → Flutter)
**Hedef:** taslaktaki oda ve eşya çizimlerinin birebir Flutter karşılığı. En büyük iş.
- **Temel:** degrade (`LinearGradient` shader), desen (küçük `Picture` → `ImageShader`), parlama, yumuşak gölge, renk karıştırma (`mix`).
- **Eşya ressamları (~45):** buzdolabı ×3 model, ocak, dolap, masa ×2, sandalye/tabure, küvet ×3, lavabo ×2, ayna ×3, havlu, yatak ×3 (kanopi dahil), komodin, abajur ×4, gardırop, halı ×3, oyuncaklar, kanepe ×3 (arka/ön parça), TV ×3, ünite, sehpa ×3, lambader ×3, bitkiler, akvaryum, saat, raflar, sarkıt lamba ×3, tezgâh eşyaları, paspas ×3, ördek/gemi, duvar süsleri.
- **Desenler:** duvar kağıdı ×9, fayans ×5, zemin ×5, nevresim/örtü desenleri.
- **Oda ressamları ×4** + **katman düzeni:** `Stack` [oda arkası] → [Zibo pozu `Image`] → [ön parça: küvet önü, yorgan, kanepe oturağı, masa]. Bu "oturuyor gibi" hilesi yeni poz gerekmeden çalışır.
- **Performans:** her oda `RepaintBoundary` + `Picture` önbelleği; yalnızca dekor değişince yeniden çizim. Düşük segment cihazda kare hızı ölçülür.
- **Görsel doğrulama:** `flutter run -d web-server` + tarayıcıda taslakla yan yana (CLAUDE.md'deki web akışı). Tablet oranı kontrolü.
- **Kontrol noktası (APK):** 4 oda taslakla aynı görünüyor, renk/desen değişimi anlık.
- **Uygulanan yol (2026-11-03) — KARAR: `CustomPainter` yerine SVG metni + `flutter_svg`.** Taslağın SVG üreten JS'i Dart'a çevrildi (`lib/widgets/home_art/`): `svg_kit.dart` (mix/grad/shine/handle/feet/gölge), `furniture_art.dart` (73 eşya çizimi + 5 sabun şekli), `surface_art.dart` (duvar kağıdı/fayans/zemin/örtü/yorgan), `room_art.dart` (4 oda; Zibo'nun arkası ve önü ayrı SVG), `room_view.dart` (arka SVG → Zibo pozu → ön SVG). Neden: koordinatlar ve renkler taslakla birebir kalıyor, ~45 ressamı elle yazmaktan çok daha hızlı ve hatasız; `flutter_svg` zaten bağımlılık.
  - **Tuzak:** `flutter_svg` `<pattern>` öğesini web'de hiç çizmiyor (o SVG'nin tamamı boş kalıyor). Desenler `SvgKit.tiled` ile elle döşeniyor (`<clipPath>` + `<use>`); test `<pattern>` kullanımını yasaklıyor.
  - Bulanık gölge (`feGaussianBlur`) desteklenmiyor → kenarı yumuşak radyal degrade (`SvgKit.softEllipse`).
  - Zibo pozları taslaktakiyle aynı: `assets/images/home/zibo_{happy,pout,idle}.webp`.
  - Sabun şekli lavabonun sağ kenarında; rengi seçili sabun türünden.
  - Oda kartı → `HomeRoomScreen`: oda çizimi + kategori/eşya seçici (DENEME, kaydedilmez; satın alma Faz 5).
  - Önizleme: `lib/home_room_preview_main.dart` (Firebase'siz, 4 oda başlangıç + her kategorinin son eşyası; `flutter run -d web-server -t lib/home_room_preview_main.dart`).
  - Testler `test/home_art_test.dart`: her katalog eşyasının çizimi var, her eşya seçimiyle ve bakım modunda SVG iyi biçimli, Zibo katmanı (kanepe oturağı, yorgan) önde.
  - Kalan: telefonda performans ve görünüm kontrolü (APK).

## Faz 3 — Giriş ekranı
- Ev kesiti: çatı, tabela, baca, 2×2 küçük oda (önbellekten), alt çim.
- 4 ihtiyaç halkası (dokununca odaya), Zibo en düşük ihtiyacın odasında + konuşma balonu (TR/EN/ES cümle havuzu).
- Sağ sütun kapıları: **Oyunlar**, Etkinlikler (rozet), Sıralama, Arkadaşlar (1.18.0'da kapsam dışı kalırsa "Yakında").
- Etkinlik kartı (`EventsProvider`'dan; etkinlik yoksa gizli).
- Odaya geçiş: yakınlaştırma animasyonu, geri dönüş.
- Tablet: ev ve kapılar yan yana geniş düzen (`lib/utils/adaptive.dart`).
- **Kontrol noktası (APK):** gezinme akıcı, halkalar doğru, Zibo doğru odada.
- **Uygulandı (2026-11-03):** `ZiboWorldScreen` taslağın `houseSvg()`'si birebir: çatı, baca + duman, tabela (metin Flutter'da, çevrilir: `worldHouseSign`), ahşap çerçeve, çim; odalar `RoomThumb` (sahnenin y 120–1160 bandı) ile 2×2 — üst sıra mutfak · banyo, alt sıra yatak · salon, takılı dekorla.
  - Halkalar taslağın renkleri ve simgeleriyle; etiket `worldNeedPercent` ("Tokluk %35" / "Food 35%"). Dokununca o odanın ekranı.
  - Zibo en düşük ihtiyacın odasında; o ihtiyaç %30'un altındaysa somurtkan poz. Balon: en düşük ihtiyaç %70'in altındaysa o ihtiyacın cümlesi (dokununca oda açılır), değilse mutlu cümle. Cümle havuzu `lib/data/zibo_world_lines.dart` (TR/EN/ES, ihtiyaç başına 3 + mutlu 3; saat başı değişir).
  - Kapılar sağ sütunda taslağın simgeleriyle; Sıralama ve Arkadaşlar kilitli (1.18.0 dışı), Etkinlikler "Yakında" (Faz 6).
  - Odaya geçiş: odanın evdeki yerinden ölçek + solma (320 ms); "hareketi azalt" açıksa düz geçiş.
  - Etkinlik kartı Faz 6'ya kaldı (`EventsProvider` yok).
  - Tablet: içerik en fazla 640 dp, ortalanır.

> **Not (2026-11-03):** giriş ekranı kullanıcının üreteceği görsellerle yeniden yapılacak — fazlar bitince, düzeltmeler listesinde (`zibo_world.md` "DÜZELTME LİSTESİ").

## Faz 4 — Bakım oyunları
- **4a Besle (mutfak):** 57 yemek (Fluent → `assets/images/home/food/*.webp`, ~6 KB, toplam ~350 KB; simit/churros çizim), gruplar, tabağa koy, ağza sürükle (ya da dokun), çiğneme zıplaması, kırıntı + kalp parçacıkları, günde 3 ücretsiz (gün anahtarı `TrustedTimeProvider`), ZC ile özel yemek, isteğe bağlı ödüllü reklamla +1 (`AdService`, günlük sınır). **MIT lisans metni uygulamanın lisanslar ekranına** (`asset_library/LICENSE-fluent-emoji.txt`).
- **4b Banyo:** temizlik düştükçe kir lekeleri, sabunu sürükle → köpük + baloncuk, duş, havlu, parıltı; sabun türleri bir kez alınır (renkli köpük), **sabun şekli** banyo dekor kategorisi olarak satılır.
- **4c Uyut (gerçek zamanlı):** ışığı kapat → oda kararır, pencerede gece, abajur parlar, Z'ler; `sleep.startedAt` ile enerji uygulama kapalıyken de dolar; uyandır. İsteğe bağlı: "Zibo uyandı" bildirimi (FCM saatlik iş ya da yerel bildirim — yerel bildirimler şu an rafta).
- **4d Oyna (salon):** TV'de 7 oyun → bugünkü WebView oyunları; oyun bitince mutluluk artışı (`GamePointsProvider` sonucu üzerinden), TV boyutu modele göre.
- **Ortak:** parçacık sistemi (`Ticker` + `CustomPainter`), ses efektleri (yemek, köpük, duş, uyku — `SoundEffectsService`, yeni ses dosyaları), hafif titreşim, analytics olayları.
- **Rozetler (öneri, `add-badge` becerisiyle):** ilk besleme, 7 gün bakım, "Şef Zibo", "Mis gibi", "Uykucu".
- **Kontrol noktası (APK):** dört döngü baştan sona, ZC doğru düşüyor, uygulama kapatılıp açılınca durum korunuyor.
- **Uygulandı (2026-11-03):** `HomeRoomScreen` artık **Bakım / Dekor** sekmeli; sahne üstte sabit (sürükleme listeyi kaydırmaz), panel altta kayar. Efektler `lib/widgets/home_art/care_fx.dart` (taslağın efekt tuvali: kir, köpük, baloncuk, damla, parıltı, kırıntı, kalp, Z, ★ yazısı), kare başına `Ticker` — efekt yokken durur.
  - **4a Besle:** 55 Fluent yemek görseli `assets/images/home/food/` (~250 KB) + simit/churros kodla. Gruplar, fiyatsız yemekler günlük ücretsiz haktan düşer (`HomeNeedsProvider.useFreeFood`), fiyatlı olanlar `CoinProvider.spendOnFood` (abonelik indirimi yok, yalnız `food:<id>` uzaktan ezme). Tabaktan ağza sürükle ya da tabaktakine dokun → tokluk + çiğneme zıplaması + kırıntı + kalpler.
  - **4b Banyo:** kir lekesi sayısı temizlik eksiğine göre (3–12); sabun yalnız Zibo'nun gövdesinde köpürür; lekeler %75 silinince duş açılır (110 kare), sonra havlu → temizlik 100 + parıltı. Küvet kenarında köpük (sabun türünün rengi, gökkuşağı dahil). Sabun türü seçici: sahip olunmayan `spendOnSoap` ile bir kez alınır (Pro/Pro+ indirimli).
  - **4c Uyut:** gerçek zamanlı (`startSleep`/`wake`); oda kararır, pencerede ay ve yıldız, abajur parlar, Z'ler yükselir; enerji göstergesi saniyede bir tazelenir.
  - **4d Oyna:** salonda 7 oyun (uzaktan kapalı olan soluk); oyun bitip ★ kazanılınca mutluluk +25 ve "+N ★" yazısı.
  - Pozlar: mutfak (yerken/tok mutlu, <50 somurtkan, değilse bekleyen), banyo (temiz mutlu), yatak (uyurken bekleyen, dolunca mutlu), salon (oynayınca mutlu).
  - Lisans: Ayarlar → "Açık kaynak lisansları" (Flutter `LicensePage`), Fluent Emoji MIT metni `lib/data/third_party_licenses.dart`.
  - Testler: `test/home_room_screen_test.dart` (besle, yıka, uyut, dekor).
  - **Ertelenenler (düzeltme listesine):** yeni Zibo pozları, ses efektleri, ödüllü reklamla +1 yemek, rozetler, analytics olayları, yemek/eşya adlarının EN/ES çevirisi — HEPSİ ✅ 2026-11-06 (`docs/zibo_world.md` düzeltme listesi 1–3).

## Faz 5 — Dekor mağazası
- Oda başına kategoriler (mutfak 13, banyo 14 — sabun şekli dahil, yatak 12, salon 13; toplam 52 kategori, 279 eşya), modeller ve renkler `home_catalog.dart`'tan.
- Önce dene, sonra "Odadakileri al" (sepet), sahip olunanlar "Sende var", fiyat `config/home` ezmesi.
- Nadirlik dili kostümlerle aynı (1.15.0); Pro/Pro+ kararına göre özel ürünler.
- Sezonluk/sınırlı ürün altyapısı (tarih aralığı, `config/home`).
- **Kontrol noktası (APK):** satın alma, deneme, sahiplik, yeniden açılışta kalıcılık, ZC kuralı reddi yok.
- **Uygulandı (2026-11-03):** oda ekranının **Dekor** sekmesi mağaza oldu.
  - Eşya kartı: küçük resim (`lib/widgets/home_art/item_thumb.dart` — taslağın `thumb()`/`tileSvg()` ve `VB` kadrajları), ad, durum (Takılı / Sende var / fiyat), nadirlik çerçevesi ve etiketi (kostümlerle aynı `RarityStyle`; fiyattan: 1–100 Yaygın, 101–250 Nadir, 251–500 Epik, 501–1000 Efsanevi, 1000+ Mitik; ücretsiz başlangıç eşyasında kademe yok).
  - Sahip olunan eşyaya dokununca hemen ve ücretsiz takılır; sahip olunmayana dokununca odada DENENİR (kategori çipinde •).
  - Listenin üstünde sabit çubuk: bakiye, geri al, **"Odadakileri al · N ZC"** → tek `spendOnHomeItem` (neden `Ev: oda:kat:eşya,…`), sonra sahiplik + takma. ZC yetmezse "Yetersiz Zibo Coin".
  - Fiyat = `config/home` ezmesi + Pro %10 / Pro+ %20 indirim. `proOnly` (👑) ve `limited` (⏳, tarih aralığı) altyapısı `HomeConfig`'te.
  - Testler: `home_room_screen_test.dart` (dene → al → takılı, sahip olunana dönüş ücretsiz, ZC yetmezse alınmaz, vazgeç).
  - Ayrıca düzeltildi: bakım göstergesi çubuğu boş görünüyordu (doluluk kutusu 0 yükseklik); dar ekranda satın alma çubuğu taşıyordu.

## Faz 6 — Etkinlikler
- `events/{id}`: `type` (1.18.0'da yalnızca `takvim`), başlık/açıklama TR/EN/ES, `start`, `end`, `days[] {reward: zc|itemId}`, `enabled`. Kural: okuma giriş yapmış herkes, yazma `isAdmin()`.
- `EventsProvider`: aktif/yaklaşan etkinlik, gün açma (gün anahtarı `TrustedTimeProvider`, tekrar açma koruması ayrı bir `eventsState` dokümanında).
- Ödüller: ZC (`CoinProvider` nedenli kazanç, tek yazım sınırı içinde) ya da sezonluk dekor (Yılbaşı: çam, hediye, ışık, kardan adam — kodla çizim).
- **Yönetici uygulaması:** `events_screen.dart` (oluştur, tarih, ödül tablosu, aç/kapat) + `adminLog`.
- Sınır: yeni etkinlik **türü** ilk kez eklenirken sürüm gerekir.
- **Kontrol noktası (APK):** panelden açılan takvim uygulamada görünüyor, gün açılıyor, ödül geliyor.
- **Uygulandı (2026-11-03):**
  - Model `lib/models/zibo_event.dart` (`ZiboEvent.fromJson`: `type`, `enabled`, `title/description {tr,en,es}`, `start/end` 'YYYY-AA-GG' dahil, `catchUp` (varsayılan açık), `days [{zc} | {item: 'oda:kat:eşya'}]`; ZC gün başı en çok 1000). Bilinmeyen tür ve bozuk doküman yok sayılır.
  - `EventsProvider` (`lib/providers/events_provider.dart`): açılışta `events where enabled == true` bir kez okunur; gün hesabı güvenilir saat; açılan günler `state/eventsState` (`opened {eventId: [gün]}`); `open()` önce işaretler, ödülü çağıran uygular (çift ödül yok). Kaçırılan günler `catchUp` ile sonradan açılır; etkinlik bitince açılmaz.
  - Ödül: ZC → `CoinProvider.earnEventReward` (neden `Etkinlik: <id> gün N`); eşya → `HomeDecorProvider.markOwned`.
  - **Yılbaşı eşyaları (yalnız etkinlikten, mağazada satılmaz, `HomeItem.eventOnly`):** salon köşe `cam` (Yılbaşı çamı), `kardan` (Kardan adam), salon puf `hediye` (Hediye kutuları) — kodla çizim, `tool/generate_home_catalog.py` EVENT_ITEMS.
  - Ekran `lib/screens/events_screen.dart`: süren takvim (gün kutuları: açılabilir 🎁, açılmış ödül, kilitli 🔒, bugün kırmızı çerçeve), yaklaşanlar listesi, boş durum. Ödül penceresi (ZC ya da eşya küçük resmi).
  - Giriş ekranı: Etkinlikler kapısı ekranı açar + açılmayı bekleyen kutu rozeti; süren etkinlik varsa evin altında lacivert etkinlik kartı.
  - `firestore.rules`: `events/{id}` okuma giriş yapmış herkes, yazma `isAdmin()` — **Console'a yayınlandı 2026-11-03**.
  - **Yönetici uygulaması:** yeni "Etkinlik" sekmesi (`zibo_admin/lib/screens/events_screen.dart`): TR/EN/ES başlık + açıklama, başlangıç tarihi, gün sayısı (3–31), günlük ZC, son gün ödülü (Yılbaşı eşyalarından biri ya da ZC), telafi anahtarı, onay penceresinde kişi başı toplam ZC; liste + aç/kapat anahtarı; her yazım `adminLog` ile aynı batch'te.
  - Testler: `test/events_test.dart` (model, aktif/yaklaşan, tek açma, telafi, bitiş, Firestore filtresi, ekranda ZC + eşya ödülü).

## Faz 7 — Sıralama ve Arkadaşlar (KARAR: 1.19.0)
- **Sıralama:** haftalık oyun ★; istemci kendi puanını yazar, saatlik iş (`notification-scripts`) doğrular ve `leaderboards/{hafta}` tek belgesine ilk 100 + arkadaş görünümü yazar. Oyun başına üst sınırla hile kontrolü (`game_zibo.md` cap'leri). İsim "Zibo adı#etiket".
- **Arkadaşlar:** arkadaş kodu (ZB-XXXX), istek/kabul, ev vitrini belgesi (`users/{uid}/public/home`), ziyaret (kalp, yemek bırak), hediye (sunucuda doğrulanır, günde sınır), hazır ifadeler, şikâyet/engelle, rozet bildirimi.
- Kurallar ve maliyet: `zibo_online.md` (DAU 10k'da ~10–15 $/ay tahmini). Play Aileler ve çocuk güvenliği incelemesi.

## Faz 8 — Yönetici uygulaması ve istatistik
- `config/home` düzenleyici (fiyat, düşüş hızı, ücretsiz yemek, uyku hızı, sezonluk ürün aç/kapat).
- Etkinlik ekranı (Faz 6).
- `dailyStats.js`: ev harcaması (yemek/sabun/dekor ayrı), en çok satılan eşyalar, bakım sıklığı, ortalama ihtiyaçlar → Özet'e yeni kart.

## Faz 9 — Metin, ekonomi, kalite
- **ARB:** tahmini 300+ anahtar × 3 dil (eşya adları, kategoriler, konuşma balonları, etkinlik metinleri). İçerik havuzları `xTr/xEn/xEs` deseni.
- **Ekonomi:** kazanma/harcama dengesi, fiyat tablosu, ödüllü reklam sınırları, ZC paketi satın alma motivasyonu (ölçüm planı). `unit_economics.md` güncellenir.
- **Analytics olayları:** `home_open`, `room_open`, `care_feed/bath/sleep/play`, `decor_try`, `decor_buy`, `event_day_open`, `need_low_seen`.
- **Testler:** provider birim testleri (ihtiyaç düşüşü, saat manipülasyonu, ücretsiz yemek sıfırlanması, satın alma), ekran testleri (gezinme), mevcut 763 testin yeşil kalması.
- **Kalite:** düşük segment telefonda performans, tablet düzeni, erişilebilirlik (Semantics), AAB boyutu (hedef < +1,5 MB), bellek (Şubat 2027 Play eşiği, `play_policy_updates.md`).

## Faz 10 — Yayın
- Bekleyen işler: tablet yan menü 840 dp, uygulama içi mesaj kartı testi, satın alma doğrulaması gerçek test alımı.
- `pubspec` 1.18.0+57, AAB (`release-aab` becerisi), sürüm notları TR/EN/ES (≤ 500 karakter).
- Mağaza görselleri: Zibo Dünyası panoraması (`tool/CLAUDE.md`).
- Kademeli yayın önerisi: %20 → %100; Crashlytics ve yönetici Özet'i izlenir.
- Yayın sonrası: `config/home` ile fiyat ince ayarı, ilk etkinlik.

---

## Bağımlılıklar
`Faz 1 → 2 → 3 → 4 → 5`; `6` Faz 1'den sonra paralel ilerleyebilir (Yılbaşı için öne alınabilir); `8` her fazla birlikte; `9` sürekli; `7` ayrı sürüm.

## Kaba süre tahmini (TAHMİN, oturum sayısı)
| Faz | Oturum |
|---|---|
| 1 Veri + kabuk | 1–2 |
| 2 Çizim motoru | 4–6 |
| 3 Giriş ekranı | 1–2 |
| 4 Bakım oyunları | 3–4 |
| 5 Dekor mağazası | 2 |
| 6 Etkinlikler | 2 |
| 8–9 Panel, metin, test | 2–3 |
| 10 Yayın | 1 |
| **1.18.0 toplam (7 hariç)** | **~16–22** |
| 7 Sıralama + Arkadaşlar (1.19.0) | 4–6 |

## Ek A — Taslaktaki katalog (uygulamaya taşınacak)
- **Mutfak (13):** boya ×8, duvar kağıdı ×6, zemin ×5, buzdolabı ×10, ocak ×5, dolap ×5, tezgâh üstü ×6, masa ×5, masa örtüsü ×5, sandalye ×5, sarkıt lamba ×5, duvar süsü ×5, perde ×5.
- **Banyo (14):** boya ×8, fayans ×8, zemin ×5, küvet ×8, lavabo ×6, ayna ×6, havlu ×6, duş başlığı ×4, raf ×4, paspas ×6, oyuncak ×5, bitki ×3, duvar süsü ×4, sabun şekli ×5; ayrıca sabun türü ×5 (bir kez alınır).
- **Yatak odası (12):** boya ×8, duvar kağıdı ×7, zemin ×4, yatak ×6, nevresim ×6, komodin ×4, abajur ×5, gardırop ×4, perde ×5, halı ×6, oyuncak ×5, duvar süsü ×4.
- **Salon (13):** boya ×8, duvar kağıdı ×6, zemin ×4, kanepe ×6, TV ×4, TV ünitesi ×3, sehpa ×4, lambader ×4, halı ×5, perde ×5, köşe ×4, duvar süsü ×5, puf ×4.
- Sayılar `lib/data/home_catalog.dart`'tan (üretilen); her listede "yok"/başlangıç seçeneği dahil.
- **Yemek (57):** meyve-sebze 17, yemek 22, tatlı 13, içecek 5 (fiyat ve tokluk değerleri `home_studio` taslağında).
- **İhtiyaçlar:** tokluk (mutfak), temizlik (banyo), enerji (yatak), mutluluk (salon).

## Ek B — Açık riskler
- Çizim motoru taşıması uzun ve görsel birebirlik zor → oda oda onay.
- Tek büyük sürüm → hata etkisi geniş; kademeli yayın şart.
- Satın alma doğrulaması 1.18.0'a kadar canlıda değil.
- Yılbaşı etkinliği zamana sıkışabilir.
- Japonya yetkilendirmesi 1 Aralık, tüccar beyanı 1 Şubat 2027 (sürümden bağımsız).
