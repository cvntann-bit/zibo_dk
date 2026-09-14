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

## Onaylanan: Profil sekmesi

Gerçek `profile_screen.dart` yapısı korunuyor — AppBar diğer 3 sekmeyle
BİREBİR aynı (bu sekmeye özgü ek ikon yok), gövde tek kaydırılabilir liste,
gerçek sırasıyla (19 bölüm):

1. **Profil fotoğrafı** — kullanıcının kendi galeri fotoğrafı, Zibo maskotu
   DEĞİL (`CircleAvatar` + kamera rozeti). **Koşullu** "Kurucu Üye" rozeti
   sol üstte, yalnızca `founder_badge` kostümü sahiplenilmişse görünür
   (satın alınamaz, sadece sunucu tarafından verilir).
2. İsim alanı (borderless text field, ortalanmış).
3. **Seviye kartı** — "Lv. N" + XP progress bar.
4. **Instagram takip kartı** — koşullu, ödül talep edilince kalıcı olarak
   kayboluyor, bir daha hiç görünmez.
5. **"İstatistiklerim"** — 4 SABİT kategori kartı (Para Yönetimi / Şükür ve
   Manifest / İstikrar / Öz Saygı ve Sağlık), sıra ve başlıklar gerçek
   kodla birebir. Her kart ya sparkline + skor halkası (0–10) gösterir ya da
   — veri yoksa — aynı yükseklikte tek satır boş-durum metni. Kategoriler
   artık renkle DEĞİL yalnızca ikonla (💰✨🚩❤️) ayrılıyor (bkz. "Renk
   paleti" — tek vurgu kuralı); skor halkası da kırmızı→amber→yeşil yerine
   tek renk + dolgu yüzdesiyle gösteriliyor.
6. Geçmiş Ay İstatistikleri satırı.
7. **"Zibo ile Bağın"** bölüm başlığı → Bağ Seviyesi, En Uzun Seri Rekoru
   satırları.
8. **Odak Süresi satırı** — diğerlerinden farklı olarak dokunulamaz (sağ ok
   yok), yalnızca bilgi amaçlı.
9. **Kostüm Dolabı** kartı — sahip olunan TÜM kostümlerin küçük önizleme
   şeridi (giyili olan değil, koleksiyonun tamamı).
10. Zibo Coin Özeti, Hitap Tercihi, Favori Sözler, Profil Kartını Paylaş,
    Arkadaşını Davet Et satırları (davet durumu koşullu: kod kullanıldıysa
    alt metin değişir).
11. **Kurucu Üye promosyon kartı** — koşullu, yalnızca rozet hakkı hâlâ
    mevcutsa VE Google hesabı bağlı değilse görünür.
12. Google hesabı bağlama satırı (liste sonu).

Alt bar sırası ve Z butonu diğer sekmelerle birebir aynı, yalnızca aktif
sekme göstergesi Profil'e kaymış durumda.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/a07659db-0329-4083-9b0c-5600f4ecc2b1).

## Onaylanan: Mağaza — "Kostümler" sekmesi

Gerçek `_CostumesSection` yapısı korunuyor — AppBar ve segmentli kontrol
"Coin Al" ile BİREBİR aynı (yalnızca "Kostümler" segmenti aktif). Gövde: tek
düz `GridView`, 2 sütun, gruplama/kategori/nadir seviyesi YOK — 16 kostüm,
`costumes.dart`'taki sırayla (ucuzdan pahalıya, 440 ZC → 33.000 ZC).

- **3 kart durumu** (gerçek `CostumeCard` ile birebir):
  - **Kilitli**: görsel %45 opaklık + sağ üstte kilit rozeti, altında fiyat
    (🪙 + ZC) ve tam genişlik "Satın Al" butonu (altın dolgu). Kartın
    yalnızca butonu tıklanabilir, kartın geneli DEĞİL.
  - **Sahip olunan (giyili değil)**: tam opaklık görsel, kilit rozeti yok,
    altında nötr (beyaz zemin, siyah kontur) "Sahip olunan" rozeti. Kartın
    HERHANGİ bir yerine dokunmak anında giydirir.
  - **Giyili**: aynı, ama kart konturu SİYAH yerine `--accent` (altın) ve
    daha kalın; rozet de altın dolgulu "Giyili" olarak değişir. Karta tekrar
    dokunmak anında ÇIKARIR (varsayılan Zibo görünümüne döner) — ayrı bir
    "sıfırla" butonu yok, onay penceresi de yok.
- **Satın alma akışı**: onay penceresi YOK, "Satın Al"a basınca anında
  düşer. Yetersiz coin → mevcut paylaşılan `showInfoDialog` ile "Yetersiz
  Zibo Coin"; başarılı → yine `showInfoDialog` ile "{isim} satın alındı!".
  İkisi de zaten var olan dialog bileşeni — bu turda yalnızca görsel dili
  yeniliyoruz, akışa dokunmuyoruz.
- "Kurucu Üye" (`founder_badge`) rozeti bu ızgarada HİÇ görünmez — satın
  alınamaz, ayrı bir mekanizmayla (Google hesabı bağlama promosyonu)
  kazanılıyor.
- AppBar'da "+" mağaza kısayolu ikonunun HER sekmede (Mağaza'nın kendisi
  dahil) göründüğü bu turda fark edildi — daha önce onaylanan "Coin Al"
  mockup'ında eksikti, geriye dönük düzeltildi.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/055bf163-abca-4428-94d0-56fdc57ad4d4).

## Onaylanan: Mağaza — "Temalar" sekmesi

Gerçek `_ThemesGrid` yapısı korunuyor — AppBar ve segmentli kontrol diğer
iki segmentle BİREBİR aynı (yalnızca "Temalar" aktif). Gövde: Kostümler ile
AYNI kart deseni (tek düz `GridView`, 2 sütun, başlık/gruplama YOK — eski
"Standart/Premium" iki ayrı başlıklı ızgara 2026'da kaldırıldı), 22 tema,
`app_themes.dart`'taki sırayla (ucuzdan pahalıya, 250 ZC → 900 ZC).

- **Kritik istisna — renkli önizleme kutuları BİLEREK çok renkli**: her
  kartın üst kısmındaki gradyan kutusu o temanın GERÇEK `lightColors`
  değerlerini gösteriyor. Bu, sayfanın en üstündeki "tek vurgu rengi"
  kuralını İHLAL ETMİYOR — o kural bizim KENDİ arayüz aksanımız (buton,
  rozet, ikon, kontur) için geçerli; burada önizlenen çok renklilik
  kullanıcının satın alabileceği GERÇEK farklı ürünlerin (temaların) doğru
  temsili, bir tasarım tercihi değil. Kartın kendi yapısal konturu/gölgesi
  yine SABİT kalıyor (siyah kontur, altın rozet/buton) — yalnızca İÇERİK
  (önizlenen tema örneği) çok renkli.
- **3 kart durumu** Kostümler ile birebir aynı desen (kilitli/sahip
  olunan/aktif — kilitli: önizleme %55 opaklık + kilit rozeti + fiyat +
  "Satın Al"; sahip olunan: nötr rozet, karta dokunmak uygular; aktif: kalın
  altın kontur + altın rozet), **TEK fark rozet metni**: kostümde "Giyili",
  temada **"Aktif"**.
- **"Premium" rozeti**: yalnızca animasyonlu 7 temada (Parti Konfeti, Kalpli
  Tema, Kış Teması, Çiçekli Tema, Nota Teması, Tropikal Tema, Galaksi) sol
  üstte ayrıca görünen küçük ✨ rozeti — kilit rozetinden bağımsız bir ikinci
  işaret, ekranda hafif hareket efekti olduğunu belirtiyor.
- Satın alma akışı Kostümler ile birebir aynı: onay penceresi YOK, anında
  düşer, `showInfoDialog` ile "Yetersiz Zibo Coin" / "{isim} teması satın
  alındı!". **Satın almak otomatik giydirmez** — uygulamak için karta tekrar
  dokunmak gerekir (Kostümler'de olmayan bir ekstra adım).
- **Ücretsiz/varsayılan tema YOK** — en ucuz tema 250 ZC. Hiçbir tema
  giyilmemişken uygulamanın kendi sabit bal/hardal teması kullanılıyor, bu
  ızgarada bir kart olarak temsil edilmiyor.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/7a17c1d0-297b-43d9-b8f7-6335bb824f58).

## Onaylanan: Ayarlar ekranı

Gerçek `settings_screen.dart` yapısı korunuyor. **Bu ekran diğerlerinden
FARKLI bir AppBar kullanıyor** — paylaşılan sekme AppBar'ı (logo/coin/mağaza
kısayolu) YOK, çünkü bu bir `push` ekranı (bottom-nav sekmesi değil): sade
geri oku + "Ayarlar" başlığı.

Gövde **3 başlıklı bölüm**, her biri Profil'deki gibi satır-başına-ayrı-kart
DEĞİL — TEK kart içinde ince çizgilerle ayrılmış satırlar (gerçek koddaki
`Card` + `Divider` deseni):

1. **"Genel"**: Görünüm (Açık/Koyu/Sistemi Takip Et seçim sayfası açar) →
   Ses Efektleri (switch, satırın HERHANGİ bir yerine dokunmak açar/kapatır)
   → Dil (Görünüm ile BİREBİR aynı seçim-sayfası deseni, ek olarak her
   satırda bayrak rozeti) → Ana Ekran Widget'ları → Google hesabı satırı
   (bağlıysa "Google Hesabın" + e-posta, değilse "Google ile Bağla" + bu
   durumda ayrıca "Kurucu Üye Rozeti Kazan" promosyon kartı — Profil'de
   zaten tasarlanan AYNI bileşen) → **yalnızca bağlıyken** Çıkış Yap (onay
   penceresi VAR) + Hesap Değiştir (onay YOK) buton satırı.
2. **"Destek"**: Bize Ulaşın (mailto) → Bizi Puanlayın (5 yıldızlı alt
   sayfa, herhangi bir yıldıza dokunmak doğrudan Play Store'a yönlendirir,
   uygulama içinde puan kaydedilmez).
3. **"Uygulama Hakkında"**: Sürüm (tıklanamaz, sadece bilgi) → Web Sitesi →
   Gizlilik Politikası → Kullanım Koşulları (ikisi de harici link DEĞİL,
   gerçek yerelleştirilmiş metni uygulama içinde gösteriyor).

**Şu an render EDİLMEYEN, mockup'a da eklenmeyen kısımlar**:
`notificationsFeatureEnabled = false` olduğu için bildirim ayarları kartı ve
"geçici" bildirim test paneli tamamen yok — bayrak ileride açılırsa ayrı bir
onay turu gerekir. Veri yönetimi / hesap silme / uygulamayı paylaş satırı da
gerçek kodda hiç yok.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/c830d59e-174b-43d8-916d-7998295061c7).

## Onaylanan: Su Takibi modülü

Gerçek `water_tracking_screen.dart` yapısı korunuyor. Sade push AppBar'ı
(geri oku + "Su Takibi" başlığı), **AMA diğer modüllerde OLMAYAN ek bir
ayar ikonu** taşıyor (🎛️, tooltip "Günlük Su Hedefi") — bu ekrana özgü
bilinçli bir istisna, koda geçerken de korunmalı.

- **Gövde**: Zibo maskotu (200px, `ziboWaterImage` key'i, diğer modüllerle
  aynı kostüm/poz mantığı) + altında dönen bir söz balonu (30 sabit sözden
  biri, 5 sn'de bir değişir, İLERLEMEYE tepki VERMEZ) → ilerleme kartı →
  "Geçmiş" bölümü.
- **İlerleme kartı — KRİTİK görsel detay**: çubuk/halka DEĞİL. Hedef sayısı
  kadar (kullanıcı ayarlayabilir, varsayılan 8 bardak = 2000 ml) ayrı ayrı
  dokunulabilir daire ızgarası. Boş daireye dokunmak doldurur, **DOLU
  daireye dokunmak geri alır** — bu, undo mekanizmasının ta kendisi, ayrı
  bir "geri al" butonu YOK. Üstte "5/8 bardak" (sol) + "1250 ml / 2000 ml"
  (sağ, soluk) metin satırı. Hedef tamamlanınca altına ✅ + "Bugün su
  hedefini tamamladın, harikasın kanka!" satırı eklenir VE aynı anda
  paylaşılan `showInfoDialog` ile "+5 Zibo Coin kazandın!" mesajı açılır —
  bu ödül günde bir kez, sonradan bir daire kapatılsa bile geri alınmaz.
- **"Günlük Su Hedefi" ayar penceresi** (AppBar'daki 🎛️ ikonuyla açılır):
  birim seçici (Bardak/Şişe, segmentli buton), "1 birim = kaç ml?" +/-
  steppera (25 ml adım), ayraç, hedef sayısı +/- steppera (1 adım), Vazgeç/
  Kaydet. Ayarlar ekranındaki seçim sayfalarından FARKLI, kendine özgü bir
  bileşen.
- **"Geçmiş" bölümü**: yalnızca GEÇMİŞ günleri listeler (bugün İÇERMEZ, o
  yukarıdaki kartta), satırlar tıklanamaz/silinemez — her satır o günün TEK
  bir özet metni ("{tarih} tarihinde hedef tamamlandı" veya "{tarih}:
  {sayı}/{hedef}"), saat saat kayıt YOK. Boşsa "Henüz geçmiş kayıt yok."
- Sıvı seviyesi yükselen bir illüstrasyon YOK — yalnızca iki ikon durumu
  (boş/dolu) arasında geçiş var, mockup'ta da eklenmedi.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/dd155c01-ed84-4667-9fd0-b6a5096815c3).

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
| Profil sekmesi | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Mağaza — Coin Al segmenti | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Mağaza — Kostümler segmenti | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Mağaza — Temalar segmenti | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Alt bar + Z butonu (uygulama geneli bileşen) | ⏳ Ana Sayfa mockup'ında görsel dili belli ama ayrı bir Flutter implementasyon onayı gerekiyor |
| Modül menüsü (Z butonu sheet'i) | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Modül ekranı — Su Takibi | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Modül ekranları — Rüya/Şükran/Ruh Hali/Manifest/Para/Odak (6 kaldı) | ⏳ Henüz mockup yapılmadı |
| Ayarlar ekranı | ✅ Onaylandı — koda dökülmeyi bekliyor |
| Şans Çarkı / Günlük Ödül / Rozet pop-up'ları | 🚫 Kapsam dışı — değişmeyecek |
