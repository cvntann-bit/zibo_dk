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

## Onaylanan: Rüya Günlüğü modülü

Gerçek kod bu modülü **İKİ AYRI ekran** olarak kuruyor — bir liste ekranı
(`DreamJournalScreen`) ve tıklayınca açılan **tam sayfa** bir form
(`DreamEntryFormScreen`, bottom sheet DEĞİL). İkisi de sade push AppBar'ı
kullanıyor (geri oku + başlık); Su Takibi'nin aksine liste ekranında EK bir
ikon YOK.

- **Liste ekranı**: Zibo maskotu (`ziboDreamJournalImage`, 🌙 temalı) + 5
  sn'de bir dönen söz balonu → kesikli-kenarlı "Yeni Rüya Ekle" butonu →
  rüya kartları listesi (başlık + tarih, sağda ok). Boşsa "Henüz bir rüya
  yazmadın. Bugün gördüğün bir rüya var mı?" Karta dokunmak, o rüyayı
  DÜZENLEME modunda forma açar (ayrı bir salt-okunur detay görünümü YOK).
- **Ruh hali korelasyonu — otomatik ikinci satır (2026 özelliği)**: o günün
  Ruh Hali kaydı "düşük" İSE VE rüya metninde olumsuz anahtar kelime
  (kabus/kork/kaçtım/düştüm vb.) geçiyorsa, tarihin altına italik "O gün
  ruh halin de düşüktü 😔" satırı otomatik eklenir. Basit kelime taraması,
  yapay zeka değil — ama görsel olarak bu ikinci satır durumu mockup'ta
  gösterildi, koda geçerken korunmalı.
- **Form ekranı**: yalnızca 2 alan — "Başlık" (tek satır) ve "Rüyanı
  anlat..." (çok satırlı, 6-12 satır). Tarih seçici YOK, her zaman "şu an"
  damgalanır, düzenlemede de tarih DEĞİŞMEZ. Kaydet butonu ikisi de doluyken
  aktif olur (validasyon hata mesajı yok, sadece disabled/enabled). Silme
  ikonu (🗑️) **SADECE düzenleme modunda** AppBar'da görünür (yeni eklerken
  yok) — basınca "Rüyayı sil?" / "Bu rüya kalıcı olarak silinecek." onay
  penceresi açılır.
- **Kaydetmede coin ödülü/tebrik penceresi YOK** — Su Takibi'nden farklı
  olarak sessizce kaydedip geri döner. (Dolaylı olarak toplam 15 kayda
  ulaşınca "Rüya Yorumcusu" rozeti +40 ZC veriyor ama bu ekranın kendi
  UI'ında hiç görünmüyor.)
- **Günde sınırsız kayıt** eklenebilir (Su Takibi/Şükran'ın aksine günlük
  limit YOK). Fotoğraf ekleme ve paylaşım özelliği de YOK.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/59125ae4-e139-4f16-b077-df688a18c511).

## Onaylanan: Şükran Günlüğü modülü

Gerçek `gratitude_journal_screen.dart` yapısı korunuyor — **TEK ekran**
(Rüya Günlüğü'nün aksine ayrı bir form sayfası YOK), sade push AppBar'ı,
ek ikon yok.

- **Günde SADECE 1 kayıt.** Bugün zaten tamamlandıysa 3 alanlı form
  kartının YERİNE bir "tamamlandı" özeti geçer: büyük check ikonu + "Bugün
  tamamlandı!" başlığı + "3 şükran cümleni yazdın ve 5 Zibo Coin kazandın.
  Yarın tekrar gel!" metni + sağ üstte düzenle (✏️) ikonu; altında ayraç,
  ardından 3 cevabın TAMAMI etiketleriyle birlikte tekrar gösterilir (genel
  "tamamlandı" mesajı değil, gerçek girilen metinler).
- **Renk istisnası**: gerçek kodda check ikonu SABİT bir yeşil (#4CAF50) —
  temaya bağlı değil. Tek-vurgu kuralımız gereği bu YEŞİL yerine `--accent`
  (altın) kullanılacak; bu bilinçli bir sapma, gerçek koddaki rengi
  KOPYALAMAYIN.
- **Tamamlanmadığında** görünen form: 3 ayrı `TextField` ("1./2./3. Şükran
  cümlen" etiketleri), her birinin ipucu metni HER GÜN otomatik değişen
  sabit bir söz havuzundan gelir (rastgele değil, tarihe göre sabit, 3 alan
  farklı söz gösterir). Kaydet butonu üçü de doluyken aktif olur.
- **"Geçmiş Kayıtlar" listesi BUGÜNÜ DE İÇERİR** — özet karttan AYRI olarak
  bugünün kaydı listenin en üstünde de tekrar görünür, oradan da
  düzenlenebilir. Her satır check ikonu + tarih + ok; dokununca bir
  düzenleme penceresi (AlertDialog, 3 alan önceden dolu + Kapat/Kaydet)
  açılır — bu düzenleme akışının onay penceresi YOK, direkt kaydeder.
- Seri/streak göstergesi, fotoğraf ekleme, paylaşım özelliği — HİÇBİRİ YOK.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/1de5853f-c643-41b6-b0fd-3fde68adc084).

## Onaylanan: Ruh Hali Takibi modülü

Gerçek `mood_tracking_screen.dart` yapısı korunuyor — **TEK ekran**, sade
push AppBar'ı, ek ikon yok, **kaydet butonu da YOK**: bir emojiye dokunmak
o günün ruh hali olarak ANINDA kaydedilir (onay penceresi yok, aynı gün
sınırsız değiştirilebilir, üzerine yazılır).

- **Kasıtlı renk istisnası (kullanıcı onaylı)**: 5 ruh hali seviyesinin
  sabit kırmızı→turuncu→sarı→açık yeşil→yeşil ("trafik ışığı") skalası
  AYNEN korunuyor — bu, Mağaza/Temalar'daki çok renkli önizlemeler gibi,
  gerçek anlam taşıyan bir veri gösterimi sayıldığı için tek-vurgu
  kuralının DIŞINDA bırakıldı. Skala: Çok kötü `#E53935` / Kötü `#FB8C00` /
  Nötr `#FDD835` / İyi `#9CCC65` / Çok iyi `#43A047`. Bu renkler seçili
  emojinin halka/parlama rengi, 7 günlük şeritteki noktalar VE geçmiş
  listesindeki ikon arka planında tutarlı şekilde kullanılır.
- **Not alanı** yalnızca bir mood seçildikten SONRA görünür (önce hiç yok),
  opsiyonel, odaktan çıkınca kaydedilir (her tuşta değil).
- **"Son 7 Gün"** kartı: emojisiz, sadece 7 renkli nokta (gün kısaltması +
  o günün rengi, kayıt yoksa boş/soluk kontur) — hızlı trend görünümü.
  **"Geçmiş"** ayrı bir kart: TÜM zamanların tam kronolojik listesi (renkli
  tonlu ikon + emoji + tarih + varsa not, en fazla 3 satır). Takvim/ay
  görünümü YOK, grafik/chart YOK.
- **Ödül coin DEĞİL, sessiz +5 XP** — yalnızca günün İLK seçiminde, hiçbir
  tebrik penceresi/Zibo Coin yok. Zibo'nun kendisi (poz/söz balonu) seçilen
  ruh haline tepki VERMİYOR — jenerik, mood-bağımsız bir söz havuzundan.
- Streak göstergesi, fotoğraf, paylaşım — HİÇBİRİ YOK.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/cee67483-571c-4aa1-8fe9-93977de3482f).

## Onaylanan: Manifest Günlüğü modülü

Gerçek `manifest_journal_screen.dart` yapısı korunuyor — **TEK ekran**,
sade push AppBar'ı, ek ikon yok. Form her zaman BOŞ açılır ve her
kayıttan SONRA da boşalıp aynı ekranda kalır — Rüya gibi ayrı bir form
sayfası YOK, Şükran gibi "tamamlandı" kilidi de YOK: **günde sınırsız
kayıt** eklenebilir.

- **Fotoğraf + metin İKİSİ de zorunlu** — ikisi de doluyken Kaydet aktif
  olur. Fotoğraf kutusu büyük bir kare (diğer kartlardan daha yuvarlak
  köşeli), boşken ortalanmış ikon+ipucu metni ("Bir fotoğraf seç"), doluyken
  sağ altta küçük bir "düzenle" rozeti — üzerine TEKRAR dokunmak YENİ bir
  fotoğrafla DEĞİŞTİRİR, ayrı bir "kaldır/sil" kontrolü YOK.
- **Kaydet butonu bilerek TAM GENİŞLİK DEĞİL** — içeriği kadar dar, sola
  yaslı. Diğer modüllerin çoğundan farklı, gerçek koddaki davranış.
- **Ödül günde 1 kez**: günün İLK kaydında `showInfoDialog` ile "+5 Zibo
  Coin kazandın!", aynı gün sonraki kayıtlarda ise sadece "Bugünün girişi
  kaydedildi." (coin yok). Kayıtların kendisi ise sınırsız.
- **"Geçmiş Kayıtlar"** — 2 sütunlu bir "vizyon panosu" ızgarası (kare
  fotoğraf üstte + altında en fazla 2 satır metin + tarih, kartlar
  belirgin şekilde dar-uzun). Karta dokunmak yalnızca büyütülmüş
  SALT-OKUNUR bir pencere açar (fotoğraf + tam metin + Kapat) — düzenleme
  veya silme YOK, kayıtlar kalıcı. Boşsa "Henüz bir kayıt yok. Bugün ilk
  vizyonunu ekle!"
- Fotoğraf yalnızca CİHAZDA saklanır (buluta yüklenmez, sadece dosya yolu
  senkronlanır) — bu bir uygulama detayı, tasarıma yansıması gerekmiyor.
  Streak göstergesi ve paylaşım özelliği YOK.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/edcd4d28-1151-45c1-9a42-954719574847).

## Onaylanan: Para ve Birikim modülü

Gerçek `money_screen.dart` yapısı korunuyor — **TEK ekran, sekme YOK**.
AppBar'da tek ikon: para birimi seçici (💱), Ayarlar'daki Dil/Görünüm
seçim sayfasıyla AYNI görsel deseni açar (47 para birimi listesi).

- **3 sabit kategori kartı** art arda (kategori/alt-kategori YOK, sadece bu
  3 sabit tür): 💸 Harcamalar / 📈 Birikimler / 💰 Gelen Para. Her kartın
  kendi başlığında "Toplam: {tutar}" (kendi rengiyle) — **tek bir birleşik
  "Bakiye" rakamı YOK**. Çoklu para birimi kullanılırsa toplamlar
  BİRBİRİNE ÇEVRİLMEDEN "₺500 + $50" şeklinde yan yana yazılır.
- **Kasıtlı renk istisnası** (Ruh Hali ile aynı mantık, tekrar
  sorulmadan uygulandı): kırmızı `#E53935` (harcama) / yeşil `#43A047`
  (birikim) / mavi `#1E88E5` (gelen para) — gerçek finansal anlam taşıyan
  sabit renkler, tema/vurgudan bağımsız, aynen korunuyor.
- Her kart içinde: satır listesi (ad + işaretli renkli tutar, ör.
  "-₺500,00") + her satırın sonunda ✕ ikonu (**anında siler, onay
  penceresi YOK**) + alttan kesikli "+ Ekle" butonu. Satıra dokunmak
  DÜZENLEME penceresini açar (Ad/Tutar/Para Birimi alanları, Vazgeç/Tamam
  — 3 kart da AYNI pencereyi kullanır). Tarih otomatik "şu an", kullanıcı
  seçemez ve satırlarda GÖSTERİLMEZ (yalnızca grafikte kullanılır).
- **"Mevcut Durum" grafik kartı** (en altta): kategori dağılımı/pasta
  grafik DEĞİL — 3 kategorinin zaman içinde BİRİKEN toplamını gösteren 3
  renkli çizgi. Üstünde Günlük/Haftalık geçiş + (birden fazla para birimi
  varsa) para birimi seçici; altında 3 renkli nokta + etiket lejantı.
- Bu modülde **coin ödülü YOK** — yalnızca rozet sistemi (toplam 20 kayda
  ulaşınca "Birikim Ustası", +45 ZC). Birikim hedefi/streak göstergesi de
  YOK. Zibo bu ekranda paylaşım butonuyla (📤) birlikte görünüyor, diğer
  modüllerdeki gibi jenerik söz döngüsü var, veriye tepki vermiyor.

**Onaylandı** — [mockup](https://claude.ai/code/artifact/92193076-296c-43e1-8eaf-be0e403ec477).

## Onaylanan: Odak Sayacı modülü

Gerçek `focus_timer_screen.dart` yapısı korunuyor — **TEK ekran, ama İKİ
TAMAMEN AYRI görünüm**: kurulum ekranı (mod seçici + Başlat) ve Başlat'a
basınca açılan tam ekran SİYAH "karanlık mod". Bu mockup yalnızca KURULUM
ekranını sticker temasına taşıyor.

- **Karanlık mod BİLEREK DEĞİŞMEDİ** — kullanıcının bu redesign'dan ÖNCEKİ,
  bağımsız isteği ("başladığında ekran kapkaranlık olsun, sadece sayaç
  gözüksün, dikkat dağıtıcı hiçbir şey olmasın"). `Scaffold.backgroundColor`
  sabit siyah kalıyor (bir testte doğrulanıyor) — yalnızca altın parlayan
  halka + sayaç + soluk "Bitir ve Kaydet" metni, mod seçici/toplam süre
  kartı gibi HİÇBİR ŞEY görünmüyor. Dokunulmayacak.
- **Zibo maskotu + söz balonu YENİ eklendi** — gerçek koddaki ŞU ANKİ
  kurulum ekranında bu hiç yoktu, diğer 7 modülle tutarlılık için eklendi
  (jenerik, odaklanma temalı, ilerlemeye tepki vermeyen bir söz havuzu).
- **Mod seçici**: 4 sabit seçenek (Serbest/15/25/45 dk) sticker pill'lere
  dönüştü — tek seçim, seçili olan altın dolgu alıyor.
- **Büyük sayaç halkası**: Profil'in "İstatistiklerim" puan halkasıyla
  (`CircularScoreGauge`) AYNI görsel dil — kalın sabit kontur + iç "zımba"
  dairesi + ortada kalın rakam. Kurulum ekranında HER ZAMAN "00:00"
  gösteriyor (mod ne olursa olsun, henüz başlamadığı için) — gerçek
  ilerleme/dolum yalnızca (değişmeyen) karanlık moddaki halkada oluyor.
- **Başlat butonu TAM GENİŞLİK** — Manifest Günlüğü'nün bilerek dar
  butonunun AKSİNE, gerçek kod burada zaten tam genişlik kullanıyor,
  mockup bunu koruyor.
- **"Toplam Odak Süren" kartı**: tek satır, etiket solda + biriken toplam
  süre (sa:dk:sn) sağda kalın/tabular rakamlarla.

**Onaylandı** — [mockup](https://claude.ai/artifact/QiNofQrxMaXBJUssm1sTp6).

## Onaylanan: "Bizi Google Play'de Puanla" penceresi (2026-09-24)

Yeni bileşen (`lib/widgets/rate_prompt_dialog.dart`) — mutlu anlarda
rastgele çıkan ortada açılır pencere, Ayarlar'daki eski "Bizi Puanla" alt
penceresinden (`rate_us_sheet.dart`) AYRI.

- **Görsel**: `zibo_df_pose3.webp` (yanaklarını tutan mutlu Zibo) kartın
  üstünden taşıyor — kart sticker kontur + düz gölge, ✕ sağ üstte sticker
  daire.
- **İçerik**: Baloo2 başlık "Zibo'yla Aran Nasıl?", kısa açıklama, 5 kalın
  konturlu sticker yıldız (dolu = `primary`, boş = `primary`'nin soluk tonu),
  "Bir yıldıza dokun" ipucu, tam genişlik "Google Play'de Puanla" butonu,
  "Daha Sonra" ve küçük altı çizili "Zaten puanladım".
- **Davranış**: yıldız veya Puanla → Play Store + bir daha çıkmaz; Daha
  Sonra / ✕ → 5 gün bekleme; Zaten puanladım → bir daha çıkmaz.
- **Tetikleme**: 7 günlük hedef, para/birikim girişi, Manifest/Şükran
  kaydı, su hedefi, rozet — her birinde %20 şans, ilk 2 kullanım günü yok,
  kutlama/bilgi penceresi kapandıktan sonra (7 günlük hedefte o seferki
  reklamın yerine). Kurallar `lib/utils/rate_prompt_trigger.dart`'ta.

**Onaylandı** — [mockup](https://claude.ai/artifact/Qf33JAT5BwXqEkiuHU3cBr).

## Onaylanan: Manifest süsleme editörü — 1. aşama, tek fotoğraf (2026-09-24)

`lib/screens/manifest_editor_screen.dart` + `lib/widgets/manifest_frame_view.dart`.
Giriş: kayıt detayındaki "🎨 Süsle ve Paylaş" ve fotoğraflı kayıt sonrası
pencerede "🎨 Hemen Süsle".

- **Tuval**: 4:5 / 1:1 / 9:16; fotoğraf yoksa niyet yazısı bal sarısı zemin
  üzerinde. Dışa aktarma 1080px genişlikte PNG (4:5 → 1080×1350).
- **Çerçeveler**: Yok, Polaroid (tarih · niyet), Film, Washi ücretsiz;
  **Altın** ve **Yıldızlı** 250 ZC ile bir kez açılır (kullanıcı kararı).
  Kilitli çerçeve önizlenir, kaydetmek/paylaşmak için açılması gerekir.
  Çerçeve renkleri temadan bağımsız (çıktı her temada aynı).
- **Sticker**: 5 ücretsiz Zibo pozu + emoji; **kostümlü Zibo sticker'ları
  yalnızca sahip olunan kostümlerden** (kullanıcı kararı). Sürükle, iki
  parmakla büyüt/döndür, köşe tutamacıyla büyüt, ✕ ile sil.
- **Yazı**: hazır olumlamalar (`manifestAffirmationsForLocale`) + serbest
  yazı, 3 renk, kalın konturlu sticker yazısı.
- **Filigran**: Pro olmayan kullanıcının görselinde köşede küçük "zibo";
  Pro/Pro+'ta yok (kullanıcı kararı).
- **Sonraki aşamalar**: kolaj (aşağıda, tamamlandı), aylık otomatik pano (bekliyor).

**Onaylandı** — [mockup](https://claude.ai/artifact/21kf1TZT3sDKqgrpkc1Pew).

## Onaylanan: Manifest kolajı — 2. aşama (2026-09-24)

Aynı editörün kolaj modu: `ManifestEditorScreen.collage`. Giriş: Manifest
ekranında vizyon panosu başlığının yanındaki "🧩 Kolaj Yap" (ücretsiz
kullanıcının 30 günlük geçmiş sınırına uyar — yalnızca görünen kayıtlar).

- **Şablonlar** (hepsi ücretsiz): 2'li alt alta, 2'li yan yana, 3'lü (1
  büyük + 2 küçük), 4'lü, 6'lı, Polaroid Duvarı (eğik, beyaz kenarlı).
  `lib/data/manifest_frames.dart` → `CollageTemplate`.
- **Kutular**: açılışta en yeni fotoğraflı manifestlerle, sonra yazı-only
  olanlarla otomatik dolar. Dokununca seçici: manifest kayıtları
  (fotoğrafsız olanlar sarı yazı kartı) + telefon galerisi. Kutu içinde
  parmakla kaydırma, iki parmakla yakınlaştırma. Boş kutu dışa aktarımda
  ipucu yazısı olmadan düz renk çıkar.
- **Arka plan**: Krem, Bal, Altın, Gece, Noktalı.
- **Sticker/yazı/boyut/filigran/dışa aktarma**: tek fotoğraf editörüyle ortak.
- Soruların varsayılanları (kullanıcı mockup'ı olduğu gibi onayladı): galeri
  dahil, yazı kutusu var, şablonlar ücretsiz.

**Onaylandı** — [mockup](https://claude.ai/artifact/D6AbNAeHSW4NCCVMnmakkD).

## Onaylanan: Ek çerçeveler ve emoji sticker'ları (2026-09-24)

Çerçeve sayısı 6 → 16, emoji 7 → 42 (`lib/data/manifest_frames.dart`,
`lib/widgets/manifest_frame_view.dart`). Eski çerçevelerin id'leri aynı
(satın alınanlar korunur); tepsi sırası önce ücretsizler.

- **Yeni ücretsiz**: Kalpli, Defter (çizgili sayfa + tarih), Albüm (kraft +
  foto köşelikleri), Pop (çizgi roman noktaları + "WOW!"), Pul (tırtıklı).
- **Yeni ücretli (ZC)**: Çiçekli 250, Neon 300, Gece Gökyüzü 300, Zibo'lu 350
  (köşeden bakan `zibo_df_pose3`), Kraliyet 400.
- **Renk kuralı istisnası (kullanıcı onayı)**: çerçeveler kullanıcının
  görseli sayıldığı için Çiçekli (pembe) ve Kraliyet (bordo) arayüzün tek
  vurgu rengi kuralının DIŞINDA — bu istisna yalnızca çıktı görselindeki
  çerçeveler için, uygulama arayüzüne taşınmaz.
- **Emoji**: Sticker sekmesinde başlıklı gruplar — Zibo, Manifest & şans,
  Sevgi, Doğa, Hedef & başarı, Kutlama (`ManifestEmojiGroup`).

**Onaylandı** — [mockup](https://claude.ai/artifact/7NbtXQqxnpiHbbEq5ZLT5p).

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
| Ana Sayfa | ✅ Koda döküldü (`home_screen.dart` + paylaşılan chrome) |
| Hedefler sekmesi | ✅ Koda döküldü (`goal_tracking_screen.dart`/`goal_card.dart`) |
| Profil sekmesi | ✅ Koda döküldü (`profile_screen.dart` + `StickerRowCard` ailesi) |
| Mağaza — Coin Al segmenti | ✅ Koda döküldü (`store_screen.dart`) |
| Mağaza — Kostümler segmenti | ✅ Koda döküldü (`costume_card.dart`) |
| Mağaza — Temalar segmenti | ✅ Koda döküldü (`theme_option_card.dart`) |
| Alt bar + Z butonu (uygulama geneli bileşen) | ✅ Koda döküldü (`main_bottom_bar.dart`/`z_floating_button.dart` — çentiksiz düz bar, mockup'taki gibi) |
| Modül menüsü (Z butonu sheet'i) | ✅ Koda döküldü (`modules_menu_sheet.dart`) |
| Modül ekranı — Su Takibi | ✅ Koda döküldü (`water_tracking_screen.dart`) |
| Modül ekranı — Rüya Günlüğü | ✅ Koda döküldü (`dream_journal_screen.dart`/`dream_entry_form_screen.dart`) |
| Modül ekranı — Şükran Günlüğü | ✅ Koda döküldü (`gratitude_journal_screen.dart`) |
| Modül ekranı — Ruh Hali Takibi | ✅ Koda döküldü (`mood_tracking_screen.dart`) |
| Modül ekranı — Manifest Günlüğü | ✅ Koda döküldü (`manifest_journal_screen.dart`) |
| Modül ekranı — Para ve Birikim | ✅ Koda döküldü (`money_screen.dart`/`money_category_card.dart`/`money_trend_chart.dart`) |
| Modül ekranı — Odak Sayacı | ✅ Koda döküldü (`focus_timer_screen.dart`, karanlık mod hariç) |
| Ayarlar ekranı | ✅ Koda döküldü (`settings_screen.dart`) |
| "Bizi Google Play'de Puanla" penceresi | ✅ Koda döküldü (`rate_prompt_dialog.dart` + `rate_prompt_trigger.dart`) |
| Manifest süsleme editörü (tek fotoğraf) | ✅ Koda döküldü (`manifest_editor_screen.dart` + `manifest_frame_view.dart`) |
| Manifest kolajı | ✅ Koda döküldü (`ManifestEditorScreen.collage`) |
| Şans Çarkı / Günlük Ödül / Rozet pop-up'ları | 🚫 Kapsam dışı — değişmeyecek |
