# Zibo Yeni Görsel Kimlik — "Çizgi Roman Çıkartması"

> **Durum:** Tasarım keşfi devam ediyor. Henüz HİÇBİR uygulama koduna dokunulmadı.
> Bu dosya, uygulamanın komple görsel yönünü değiştirme kararının temelini ve
> o ana kadar onaylanan/reddedilen her şeyi kaydeder — sayfa sayfa ilerlerken
> referans buradan alınır.

## Süreç kuralı (ÇOK ÖNEMLİ)

**Her ekran için önce statik bir HTML mockup (Artifact) hazırlanır, kullanıcı
onaylar, ANCAK ONDAN SONRA gerçek Flutter koduna geçilir.** Onay almadan
hiçbir widget/ekran koda dökülmez. Bu dosyadaki "Onaylanan" bölümleri kod
yazmaya başlamak için yeterli referanstır; "Açık sorular" bölümündeki
maddeler netleşmeden ilgili parçaya dokunulmaz.

Sayfa onay takibi → bkz. en alttaki **"Sayfa onay durumu"** tablosu.

## Seçilen yön: "Çizgi Roman Çıkartması" (Option C)

Üç aday stil arasından seçildi (diğer ikisi kesin REDDEDİLDİ, tekrar
gündeme getirilmeyecek):

- ~~Kil Oyuncak (Option A)~~ — kalın çizgi + düz köşeli gölge, "elle tutulur
  oyuncak" hissi. Reddedildi.
- ~~Yumuşak Şişirilmiş (Option B)~~ — çizgisiz, parlak/yumuşak gölgeli balon
  hissi. Reddedildi.
- **✅ Çizgi Roman Çıkartması (Option C)** — kalın siyah/koyu dış çizgi + düz
  doygun renkler + hafif noktalı doku fonu. Sticker/çıkartma hissi.

## Renk paleti

Mevcut uygulamanın bal/hardal/krem tabanı korunuyor, üstüne canlı bir mavi ve
enerjik bir mercan eklendi:

| Token | Hex | Kullanım |
|---|---|---|
| `--outline` | `#14110C` | Tüm kalın konturlar, gölgeler, kenarlıklar |
| `--gold` | `#F3B23C` | Ana vurgu (mevcut hardal/bal tonunun canlısı) |
| `--sky` | `#2F6FED` | İkincil vurgu, CTA butonları |
| `--coral` | `#FF6F59` | Enerjik vurgu (ödül rozetleri, uyarılar) |
| `--mint` | `#3FB88A` | Başarı/tamamlanma rengi |
| `--page-bg` / krem | `#FFF4DE`–`#FBF4E4` | Zemin |

**Kritik kural — tema uyumluluğu:** Mağazadaki satın alınabilir temalar
(`AppThemeOption`, `ColorScheme.fromSeed`) yalnızca **dolgu renklerini**
değiştirir. Yeni görsel dilde **kontur/gölge rengi (`--outline`) SABİT
kalmalı** — hangi tema seçili olursa olsun aynı siyah/koyu kontur kullanılır.
Yalnızca buton/chip/vurgu **dolgu** renkleri o an aktif `ColorScheme.primary`
vb. değerlerinden gelir. Bu ayrım netleşmeden hiçbir widget'a tema entegrasyonu
yapılmaz.

**Kritik bug (mockup'ta bulundu, koda geçerken tekrarlanmamalı):** Bir
ekranın/kartın kendi İÇ metni (ör. bir "her zaman açık zeminli" kart) sayfa
genelinin koyu-mod değişkenini kullanırsa, koyu modda metin rengi açılıp
zeminle aynı renk aralığına düşüp OKUNMAZ hale gelebilir. Böyle sabit-zeminli
her bileşen kendi SABİT (temaya/koyu-moda bağlı olmayan) metin rengini
taşımalı.

## Tipografi

- **Başlık/vurgu:** `Baloo 2` (600/700/800) — "Zibo" logosundaki balon
  harflerle aynı ruh. Yalnızca başlıklarda/CTA'larda, SEYREK kullanılır.
- **Gövde/UI metni:** `Nunito` (400/600/700/800) — yuvarlak terminaller,
  Baloo 2 ile uyumlu ama uzun metinde daha okunaklı.
- Google Fonts üzerinden yükleniyor (`fonts.googleapis.com`).

## Şekil dili

- Kalın kontur: `border: 3px solid var(--outline)` — kart, buton, konuşma
  balonu, chip'lerin HEPSİNDE tutarlı.
- Düz köşeli gölge (blur YOK): `box-shadow: Npx Npx 0 var(--outline)` —
  "basılabilir/kesilmiş sticker" hissi.
- Gradyan YOK — tüm dolgular düz/doygun renk.
- Zemin dokusu: hafif noktalı desen (`radial-gradient` ile tekrar eden küçük
  noktalar) — çizgi roman kağıdı hissi, dikkat dağıtmayacak kadar soluk.

## Denenip vazgeçilen teknikler

- **Karakterin etrafına sentetik siyah kontur eklemek** — iki farklı teknik
  denendi: (1) çoklu yön `drop-shadow` filtresi, (2) SVG `feMorphology`
  (dilate) ile büyütülmüş siyah silüet katmanı. İKİSİ DE gerçek karakter
  görselinde (`zibo_df_pose1.webp` vb.) bulanık/gri/kötü durdu. **Şu an
  karar: karakter görseli kendi hâliyle, ek kontur katmanı OLMADAN
  kullanılıyor.** İleride daha temiz bir teknik (ör. tasarımcı tarafından
  elle hazırlanmış bir kontur asseti) bulunursa yeniden değerlendirilebilir.

## Onaylanan: Ana Sayfa yerleşimi

Gerçek kod (`root_screen.dart`, `home_screen.dart`, `main_bottom_bar.dart`,
`z_floating_button.dart`) okunarak çıkarılan GERÇEK yapı korunuyor, yalnızca
görsel dili değişiyor:

**AppBar** (soldan sağa):
1. Gerçek Zibo logosu (`assets/images/zibo_logo_new.webp`, görsel — METİN
   DEĞİL)
2. *(sağda)* Coin bakiyesi (`CoinBalanceWidget` — ikon + sayı, sticker
   kutusu)
3. "+" Mağaza kısayolu ikonu
4. Ayarlar (dişli) ikonu

**Gövde** (üstten alta):
1. Üç köşe tetikleyicisi (DEĞİŞMEDİ, konumları aynı): sol üst Şans Çarkı,
   sağ üst Günlük Giriş Ödülleri, sağ orta Rozetler
2. Boşluk (üstteki köşe butonlarına yapışık durmasın diye)
3. Zibo karakteri (`ZiboAnimatedImage`, kostüme göre değişir) — kontur YOK
   (yukarıdaki not)
4. Konuşma balonu, üstünde/etrafında 3 mini buton (favori söz ⭐, paylaş 📤,
   özel mesaj ✏️) — mevcut `SpeechBubble` + `ShareZiboButton` +
   `FavoriteQuoteButton` + `CustomMessagesButton` bileşenlerinin yeniden
   derisi
5. "Zibo'ya dokun" ipucu metni — **balonun HEMEN altında**
6. Esnek boşluk (içerik azsa bile alt bar'a kadar dengeli dağılım)
7. **YENİ (henüz uygulamada YOK, önerilen özellik):** Su + Hedef mini
   widget'ları, yan yana iki kart, alt barın hemen üstünde

**Alt bar** (soldan sağa, gerçek kod sırası): Ana Sayfa, Hedefler, *(Z
butonu çentiği)*, Profil, **Mağaza (en sonda)**.

**Z butonu:** `z_floating_button.dart` — düz bir harf/portre DEĞİL, gerçek
kostüme göre değişen asset (`bottom_bar_z_coin.webp` / `_altintema` /
`_elmastema`). Bu davranış AYNEN korunur, yalnızca çerçevesi (kontur/gölge)
yeni dile uyarlanır.

## Onaylanan: Modül menüsü (Z butonu sheet'i)

Gerçek `modules_menu_sheet.dart` içeriği (7 modül, aynı sıra, aynı l10n
başlık/açıklama metinleri) korunuyor, yalnızca görsel dili değişiyor:

- Sheet, Ana Sayfa'nın üstüne açılır (arka plan hafif kararmış/soluklaşmış —
  gerçek `showModalBottomSheet` barrier'ının karşılığı).
- Z butonu (kostüme göre değişen gerçek asset), sheet açıkken ÜSTTE yarı
  görünür kalır — gerçek `FloatingActionButtonLocation.centerDocked`
  davranışının görsel karşılığı.
- Kalın kontur çubuk (drag handle) + 7 modül kartı, HER BİRİ: dolgu renkli
  (gold) + siyah konturlu ikon dairesi, başlık + tek satır açıklama, sağda
  köşeli ">" oku. Kart dili Ana Sayfa'daki mini widget'larla BİREBİR aynı
  token'ları kullanır.
- Liste kaydırılabilir (gerçek koddaki `SingleChildScrollView` — 7 kart tek
  ekrana sığmıyor), alt kenarda hafif bir soluklaşma bunu ima eder.
- Modül sırası (değişmez): Rüya Günlüğü → Şükran Günlüğü → Günlük Ruh Hali
  Takibi → Su Takibi → Manifest Günlüğü → Harcamalar ve Birikimler → Odak
  Sayacı.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/ede33013-a84f-429c-9f2d-9bbc7c893704).

## Kapsam dışı — kesinlikle DEĞİŞMEYECEK

Kullanıcı açıkça belirtti, bu redesign'a DAHİL DEĞİL:

- Şans Çarkı pop-up'ı (`WheelScreen`)
- Günlük Giriş Ödülleri pop-up'ı (`DailyRewardsScreen`)
- Rozet kutlama pop-up'ı (`BadgeCelebrationOverlay`) ve Rozetler Galerisi
  (`BadgesGalleryScreen`)

Bu üçü mevcut Material görünümüyle AYNEN kalır. İleride bu kapsam
genişletilmek istenirse önce burada AÇIKÇA onaylanmalı.

## Açık sorular (netleşmeden ilerlenmeyecek)

- **Su/Hedef mini widget'ları SABİT mi olsun, yoksa kullanıcı hangi
  modülün orada görüneceğini KENDİ mi seçsin?** — henüz karar verilmedi.
  Bu, görsel bir konu değil bir ÖZELLİK kapsamı kararı (sabit ise basit;
  kullanıcı seçimliyse tercih kaydı + Firestore senkronu gerekir).

## Sayfa onay durumu

| Ekran | Durum |
|---|---|
| Ana Sayfa | ✅ Onaylandı (bu dosyadaki yerleşimle) — koda dökülmeyi bekliyor |
| Hedefler sekmesi | ⏳ Henüz mockup yapılmadı |
| Profil sekmesi | ⏳ Henüz mockup yapılmadı |
| Mağaza sekmesi | ⏳ Henüz mockup yapılmadı |
| Alt bar + Z butonu (uygulama geneli bileşen) | ⏳ Ana Sayfa mockup'ında görsel dili belli ama ayrı bir Flutter implementasyon onayı gerekiyor |
| Modül menüsü (Z butonu sheet'i) | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Modül ekranları (Su/Hedef/Şükran/Rüya/Ruh Hali/Manifest/Para/Odak) | ⏳ Henüz mockup yapılmadı |
| Ayarlar ekranı | ⏳ Henüz mockup yapılmadı |
| Şans Çarkı / Günlük Ödül / Rozet pop-up'ları | 🚫 Kapsam dışı — değişmeyecek |
