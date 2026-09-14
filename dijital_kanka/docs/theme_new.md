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

**Kullanıcı bir ekranı onayladığı ANDA bu dosya SORULMADAN güncellenir** —
ilgili "Onaylanan: ..." bölümü eklenir/genişletilir ve alttaki tablo satırı
işaretlenir. Ayrıca commit + push edilir (bkz. `feedback_auto_commit_push`
memory'si — bu da aynı kapsamda).

Mockup'larda gerçek asset yerine emoji/placeholder kullanılması (ör. 🪙
yerine gerçek coin görseli, düz bir çubuk yerine gerçek logo) ÖNEMLİ
DEĞİL — bunlar koda geçerken zaten var olan gerçek Flutter assetleriyle
otomatik yer değiştirir. Onaylanan şey yerleşim/boşluk/renk/tipografi/kart
yapısıdır, placeholder görsel DEĞİL.

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

**Tek marka rengi kuralı (2026-09-15'te netleşti):** Zibo'yu Zibo yapan renk
bal/hardal sarısıdır. Önceki taslaklarda eklenen ek vurgu renkleri (mavi,
mercan, yeşil) paletten tamamen ÇIKARILDI. **Her yerde — genel vurgu/CTA'lar
VE anlam taşıyan durum göstergeleri (ör. bir günün durumu, bir kategori)
DAHİL — tek bir renk ailesi kullanılır.** Farklı durumlar birbirinden renk
TONU/DOYGUNLUĞU değişimiyle, kontur-only/dolgu ayrımıyla ve ikon farkıyla
ayrılır; asla farklı bir HUE (mavi, kırmızı, yeşil vb.) eklenerek değil.

| Token | Hex | Kullanım |
|---|---|---|
| `--outline` | `#14110C` | Tüm kalın konturlar, gölgeler, kenarlıklar — SABİT, temadan bağımsız |
| `--accent` (= `--gold` varsayılan temada) | `#F3B23C` | Tek vurgu rengi — doygun/dolu durum: "tamamlandı/aktif/seçili" |
| `--accent-soft` | `#F6D488` | Vurgunun açık tonu — ikincil dolgu, hafif vurgu |
| `--accent-muted` | `#C9A46B` | Vurgunun donuk/koyu tonu — "kaçırıldı/pasif/olumsuz" durumlar (ayrı bir hue DEĞİL, aynı ailenin donuk ucu) |
| `--accent-pale` | `#F3E4C0` (çoğu yerde düşük opaklıkla) | En soluk ton — "henüz gelmedi/etkin değil" |
| `--page-bg` / krem | `#FFF4DE`–`#FBF4E4` | Zemin |

**Kritik kural — tema uyumluluğu:** Mağazadaki satın alınabilir temalar
(`AppThemeOption`, `ColorScheme.fromSeed`) yalnızca **dolgu renklerini**
değiştirir. Yeni görsel dilde **kontur/gölge rengi (`--outline`) SABİT
kalmalı** — hangi tema seçili olursa olsun aynı siyah/koyu kontur kullanılır.
`--accent` ve türevleri (`-soft`/`-muted`/`-pale`) o an aktif
`ColorScheme.primary`'den türetilir (varsayılan temada bal sarısı) — yani
kullanıcı örneğin mavi bir tema satın alırsa TÜM vurgu tonları (dolu/soluk/
donuk) o mavinin türevleri olur, ama uygulamanın HİÇBİR yerinde vurgu rengiyle
alakasız SABİT ikinci bir hue (elle yazılmış mavi/mercan/yeşil) YER ALMAZ. Bu
ayrım netleşmeden hiçbir widget'a tema entegrasyonu yapılmaz.

**Not:** Skor/istatistik göstergelerinde (ör. Profil'deki 0–10 skor halkası)
uygulamanın GERÇEK kodu şu an kırmızı→amber→yeşil sabit bir renk skalası
kullanıyor (`lib/widgets/circular_score_gauge.dart` — tema'dan bağımsız,
skora göre sabit gradyan). Bu, görsel yenilemenin kapsamı DIŞINDA bir veri-
görselleştirme kararı olduğu için mockup'larda da aynı tek-vurgu kuralına
uydurulup dolgu YÜZDESİYLE (halkanın ne kadarının dolu olduğu) gösteriliyor;
gerçek koda geçişte bu noktanın ayrıca konuşulması gerekir.

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

## Onaylanan: Hedefler sekmesi

Gerçek `goal_tracking_screen.dart` + `goal_card.dart` yapısı korunuyor,
yalnızca görsel dili değişiyor:

- **AppBar**: bu sekmeye ÖZGÜ ek bir ikon var — "Tamamlanan Hedefler" (kupa),
  yalnızca Hedefler sekmesindeyken görünür (gerçek koddaki koşullu
  görünürlükle birebir). Sıra: Coin bakiyesi → Tamamlanan Hedefler → "+"
  Mağaza kısayolu → Ayarlar.
- **İçerik** (tek kaydırılabilir liste, üstten alta): Zibo karakteri (200px,
  `ziboGoalTrackingImage` key'i, Ana Sayfa'dakiyle AYNI kostüm/poz mantığı) →
  hedefe özel söz balonu (Ana Sayfa'dan FARKLI olarak yalnızca SAĞ ÜST
  köşede paylaş butonu var, favori/özel-mesaj butonları YOK) → her hedef
  için bir kart → en altta kesikli konturlu "+ Hedef Ekle" butonu.
- **Gün durumu renkleri** (gerçek `GoalDayStatus` enum'ıyla birebir, 4 durum
  — 2026-09-15'te tek-vurgu kuralına göre GÜNCELLENDİ, mavi/mercan artık
  YOK): `done` = doygun `--accent` dolgu + ✓ ikonu, `today` = beyaz/krem
  zemin + kalın `--accent` kontur (dolgu YOK) + gün numarası (tıklanabilir
  TEK durum — dolgusuz olması onu diğerlerinden ayırır), `missed` =
  `--accent-muted` (donuk/kahverengimsi sarı) dolgu + ✕ ikonu, `upcoming` =
  `--accent-pale` (çok soluk, düşük opaklık) + soluk numara. Dört durum artık
  HUE değil dolgu-yoğunluğu + kontur-only ayrımıyla birbirinden ayrılıyor. Bu
  eşleme ileride başka bir "durum göstergesi" gerektiren ekranda (varsa) da
  aynı şekilde kullanılmalı — tutarlılık için.
- Alt bar sırası ve Z butonu Ana Sayfa'dakiyle birebir aynı, yalnızca aktif
  sekme göstergesi Hedefler'e kaymış durumda.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/5aec360e-6b62-4597-8399-7ca121697af2).

## Onaylanan: Mağaza — "Coin Al" sekmesi

Gerçek `store_screen.dart` yapısı korunuyor (yalnızca "Coin Al" segmenti bu
turda mockup'landı — Kostümler/Temalar segmentleri henüz AYRI onay bekliyor,
aşağıdaki tabloya bak):

- Başlık ("Mağaza") + 3 segmentli kontrol (`SegmentedButton` karşılığı) —
  aktif segment altın dolgu + "basılmış" gölge, pasifler düz beyaz.
- **Reklamsız Zibo** bölümü → tek kart (taç ikonu, başlık, alt metin, sağda
  fiyat pili — gerçek fiyat 189,90 TL).
- **Ücretsiz** bölümü → Reklam İzle kartı (gerçek ödül: 20 ZC).
- **Coin Paketleri** ızgarası → 2 sütun, her kartta gerçek miktar/bonus/fiyat
  (`coin_packages.dart`'tan birebir: 100/250/500/1000/5000/10000 ZC paketleri,
  her biri kendi bonus + TL fiyatıyla). 6 paketten fazlası sığmadığı için
  liste kaydırılabilir (alt kenarda soluklaşma ipucu).

**Onaylandı** — [mockup](https://claude.ai/code/artifact/9080e9f0-d2f6-4ae1-b0bc-f0fecf12d09b).

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
| Hedefler sekmesi | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Profil sekmesi | ⏳ Henüz mockup yapılmadı |
| Mağaza — Coin Al segmenti | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Mağaza — Kostümler segmenti | ⏳ Henüz mockup yapılmadı |
| Mağaza — Temalar segmenti | ⏳ Henüz mockup yapılmadı |
| Alt bar + Z butonu (uygulama geneli bileşen) | ⏳ Ana Sayfa mockup'ında görsel dili belli ama ayrı bir Flutter implementasyon onayı gerekiyor |
| Modül menüsü (Z butonu sheet'i) | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Modül ekranları (Su/Hedef/Şükran/Rüya/Ruh Hali/Manifest/Para/Odak) | ⏳ Henüz mockup yapılmadı |
| Ayarlar ekranı | ⏳ Henüz mockup yapılmadı |
| Şans Çarkı / Günlük Ödül / Rozet pop-up'ları | 🚫 Kapsam dışı — değişmeyecek |
