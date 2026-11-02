# Zibo'nun Evi — görsel üretim rehberi (2026-11-01)

> **STİL KİLİTLENDİ (kullanıcı, 2026-11-02): "tam olarak aklımdaki şey bu" → kodla çizilmiş oda (`docs/kitchen_studio/`).**
> Oda, mobilya, boya, duvar kağıdı ve zemin vektör olarak kodla çizilir; Zibo gerçek 3B pozu. Görsel üretici denemeleri (3B, 2B, 2.5B) reddedildi,
> aşağıdaki prompt bölümleri yalnızca tarihçe. Kurallar: tam önden kamera, yumuşak degrade + parlama, yuvarlak tombul şekiller, zemin çizgisi 800/1200,
> her eşya renk parametresiyle çizilir (renk varyantı = yeni çizim değil). Flutter'da `CustomPainter` ile yeniden yazılır (`flutter_svg` desen/pattern desteklemediği için SVG doğrudan taşınmaz).

Kullanıcı kararları: Zibo Dünyası'nda **ev merkezde**. Oda oda ilerlenir. `asset_library/` mobilyaları **beğenilmedi** (kötü görünüyor, orantısız):
mobilya yeni üretilecek. Her odanın **arka planı, duvar kağıdı, deseni, boyası** ZC ile satılacak. Hedef **mini Sims**: asıl ZC harcama alanı,
ZC satın almaya gerçek bir sebep. `asset_library/` yalnızca geçici yer tutucu; küçük eşya (Fluent) ayrıca değerlendirilecek.

## Orantısızlık neden oldu, nasıl önlenir
Eşyalar farklı paketlerden, farklı kamerayla, Zibo düşünülmeden yapılmıştı. Çözüm:
1. **Önce ana sahne:** Oda Zibo'suz, tek görsel olarak üretilir (üretici araçlar Zibo'nun yüzünü bozuyor). Stil ve kamera buradan kilitlenir, gerçek Zibo pozu üstüne konup ölçek kontrol edilir.
2. **Sonra parçalar:** Her eşya ana sahne referans verilerek tek tek, aynı kamerayla üretilir.
3. **Ölçek birimi Zibo'dur:** Boylar "Zibo boyu" (ZB) ile yazılır, uygulamada kodla sabitlenir.

## Sabit kurallar
- **Stil (kullanıcı kararı 2026-11-01):** Önden, 2B çizgi film. Temiz koyu kontur, düz renkler, basit gölgeleme, canlı palet. Yumuşak 3B deneme beğenilmedi ("aklımdaki bu değil").
- **Kamera:** Tam önden, perspektifsiz. Bütün odalarda aynı.
- **Açık risk:** Zibo 3B render, oda 2B. Uyum ilk denemede gerçek pozla kontrol edilecek. Tüm pozları 2B çizmek 200+ görsel demek, önerilmez.
- **Tuval:** Oda 1080×1440. Zemin çizgisi yukarıdan %68'de. Üst %10 ve alt %12 arayüze bırakılır.
- **Eşya:** Saf beyaz zemin (sonra `tool/cutout_*` ile saydamlaştırılır), en uzun kenar en az 1024 px, tek nesne, zemin gölgesi yok. Üretimin tamamı bitince `cwebp`.

## Deneme sonuçları
- 2026-11-01, 3B oda: reddedildi. Zibo yüzü bozuldu, ölçek tutmadı.
- 2026-11-01, 2B oda (önden): stil umut verici. Gerçek 3B Zibo pozu üstüne kondu, düz ve kalın konturlu hali karşılaştırıldı; Görselde masa kadraj dışına taşıyor, zemin ~%62'den başlıyor. **Kullanıcı: "aklımdaki bu değil".** Stil hâlâ açık, kullanıcıdan örnek görsel istendi.
- Mobilya değiştirme modeli: oda arka planı boş, her mobilya yuvası aynı taban noktası ve boy sınırıyla ayrı saydam görsel; satın alınan eşya depoya girer, kullanıcı yuvaya takar. Yeni eşya kataloğa eklenir, görsel uygulamada yoksa sürüm ya da uzaktan indirme gerekir.

## Güncel stil yönü (2026-11-01, kullanıcı: "2B ama 3B şeklinde, Zibo gibi")
Düzen 2B oyun gibi tam önden, görünüm Zibo gibi 3B render (2.5B). Bu bölüm yukarıdaki 2B stil kilidinin yerine geçer.
Stil kilidi: `Polished 3D cartoon render, same material and lighting style as the reference character, smooth glossy surfaces, soft subsurface look, vivid saturated colors, chunky rounded toy-like shapes, seen perfectly straight from the front like a 2D side-view game, orthographic, no perspective.`
Fark: ilk 3B denemedeki soluk bej yerine canlı renk, tam önden kamera, görselde karakter yok.
Deneme 3 (2026-11-01): canlı sarı duvar, parlak zemin, tam önden mutfak. Gerçek Zibo pozu konturSUZ üstüne kondu, stil ve ışık uyumu iyi. Kullanıcı onayı bekleniyor.

## Ev Stüdyosu: mutfak + banyo (2026-11-02)
`docs/home_studio/index.html` (kitchen_studio'nun yerine geçer), yayın: https://claude.ai/artifact/Xsg9UadXjmGRobPkxnpXaE
- **Banyo dekor:** boya (üst duvar), fayans (alt duvar: karo, metro, pul, kabarcık), zemin (karo, mozaik, dama, ahşap), küvet (ayaklı, modern, yuvarlak; renkli), lavabo, ayna (oval, kare, kemer), havlu. Yuvarlak pencere, duş başlığı, şampuan rafı, ördek, paspas sabit.
- **Banyo yap:** Zibo küvette (yalnızca üst gövde, küvetin önü üstte çizilir), kir lekeleri; sabunu Zibo'nun üstünde sürükle → köpük + yükselen baloncuklar, lekeler silinir; duş → damlalar, köpük erir; havlu → parıltı + mutlu poz. Temizlik göstergesi. Kirli/temiz için mevcut pout/happy pozları.
- Uygulamaya geçerken: sabun/köpük türleri ZC ürünü olabilir; temizlik zamanla düşer (`TrustedTimeProvider`); yeni poz ihtiyacı: küvette oturan Zibo (şu an ayakta poz küvetle kesiliyor).

## Mutfak: besleme + çeşitlendirme (2026-11-02)
- **Besle:** Zibo masada (masanın önü Zibo'nun üstünde çizilir). Yemeğe dokun → tabağa gelir; tabaktan ağza sürükle (ya da tabaktakine dokun) → çiğneme zıplaması, kırıntı, kalpler, tokluk artar. Günde 3 ücretsiz (elma, muz, havuç), diğerleri ZC: simit 10, churros 12, çorba 12, pizza 15, hamburger 18, pasta 20, dondurma 14, süt 8. Yemekler de kodla çizildi (yöresel: simit TR, churros ES). Tokluk: <50 pout, orta idle, yerken/dolu happy.
- **Dekor 14 kategori:** boya; duvar kağıdı; zemin; buzdolabı ×10 (retro 6 renk, ikiz ×2 — altın 1.500 ZC, mini ×2); ocak ×5; dolap ×5; tezgâh üstü (tencere ×2, kahve makinesi, meyve kâsesi, mikser); masa (yuvarlak ×3, kare ×2); masa örtüsü (kareli, puantiye, çiçekli, yıldızlı); sandalye (×3 + tabure ×2); sarkıt lamba (kubbe ×2, cam küre, kafes); duvar süsü (kavanoz rafı, tabak rafı, saat, tablo); perde ×5.
- **Yemekler Fluent kütüphanesinden (kullanıcı, 2026-11-02):** 4 grup, 57 yemek (meyve-sebze 17, yemek 22, tatlı 13, içecek 5). Fluent 3D PNG konturSUZ kullanıldı (kodla çizilmiş odaya daha iyi oturuyor); simit ve churros kodla çizildi (Fluent'te yok). Elenenler: alkollü içecekler, domuz eti olabilecekler (bacon, sosisli). Ücretsiz: elma, muz, havuç. Uygulamaya girerse MIT metni lisanslar ekranına eklenecek (`asset_library/LICENSE-fluent-emoji.txt`).
- Kalan çeşitlendirme: banyo (paspas, bitki, duvar süsü, sabunluk, ördek renkleri). Poz ihtiyacı: yemek yiyen/çiğneyen Zibo.

## Salon (2026-11-02) — Oyun Salonu eve taşındı
- **13 kategori:** boya; duvar kağıdı ×6; zemin ×4; kanepe (klasik ×2, yuvarlak ×2, kapitone ×2 — 0–1.400 ZC); televizyon (retro tüplü ×2, ince, dev ekran — 0–1.200 ZC); TV ünitesi ×3; sehpa (yuvarlak ×2, dikdörtgen, cam); lambader (klasik ×2, küre, kavisli); halı; perde ×5; köşe (deve tabanı, kaktüs, akvaryum); duvar süsü (tablo, saat, kitap rafı, yıldız ışıkları); puf (puf ×2, armut koltuk).
- Zibo kanepede oturuyor gibi: kanepe arkası Zibo'nun arkasında, oturağı önünde çizilir (küvet/yorgan hilesinin aynısı).
- **Oyna:** 7 Oyun Salonu oyunu gerçek kapak görselleriyle listelenir; seçince televizyon ekranında oyun görseli açılır, yıldızlar uçar, bitince +★ ve mutluluk +25. Gerçek uygulamada oyun TV'den tam ekran açılır (bugünkü WebView). Ekran boyu TV modeline göre değişir (büyük TV satma sebebi).
- Mutluluk: düşük = pout, orta = idle, oynarken/dolu = happy.

## Yatak odası (2026-11-02) + ürün çeşitliliği kuralı
Kullanıcı: "ürünleri çeşitlendireceğiz unutma". **Kural: her odada çok kategori, her kategoride birkaç model ve renk.** Mutfak ve banyo da aynı çeşitlendirme turundan geçecek (pencere, perde, raf, saksı, saat, lamba; banyo: paspas, sabunluk, bitki, duvar süsü…).
- **Yatak odası, 13 kategori:** boya; duvar kağıdı (bulut, ay-yıldız, yıldız, puantiye, kalp, çizgi); zemin (ahşap, balık sırtı, koyu, lila karo); yatak (klasik ×2, bulut başlıklı ×2, kanopi ×2 — 0–1.200 ZC); nevresim (düz, yıldızlı gece, kalpli, puantiye, kareli, bulutlu); komodin ×4; abajur (klasik ×2, mantar, ay, yıldız); gardırop ×4; perde ×5; halı (oval, yuvarlak, yıldız, halısız); oyuncak (ayıcık ×2, top, roket); duvar süsü (yıldız ışıkları, tablo, kitap rafı).
- **Uyut:** Zibo yatakta (yalnız baş ve omuz, yorgan üstte çizilir). Işığı kapat → oda kararır, pencerede ay ve yıldız, abajur parlar, Z'ler yükselir, enerji dolar; Işığı aç → mutlu poz. Yorgun = pout, uyurken = idle.
- **Poz ihtiyacı:** uyuyan (gözleri kapalı) Zibo, küvette oturan Zibo. Şu an mevcut pozlar kullanılıyor.

## Kodla çizim denemesi (2026-11-01)
Kullanıcı üç üretim denemesini de beğenmedi ("aklımdaki bu değil") ve benim çizmemi istedi. `docs/kitchen_studio/index.html`, yayın: https://claude.ai/artifact/VBTTTHp6ncR9UCrUpAA3ji
Oda ve eşyalar SVG ile çizildi, Zibo gerçek poz. Boya, duvar kağıdı, zemin, buzdolabı, ocak, dolap, masa, sandalye seçilir, önce denenir sonra ZC ile alınır. Artısı: renk varyantı yeni görsel gerektirmez, her ekranda keskin, orantı sabit. Eksisi: görsel üretici kadar detaylı değil. Kullanıcı yorumu bekleniyor.

**Görsel üretici bağlama:** MCP kataloğunda özel görsel üretim bağlayıcısı bulunamadı (Adobe var, üretim yeteneği doğrulanmadı). Alternatif: görsel API'si + yerel betik; anahtar ortam değişkeninde kalır, sohbete yazılmaz. Sağlayıcının ticari kullanım koşulları ve görsel başı ücreti seçimden önce kontrol edilir.

## Oda katmanları (arkadan öne)
| Katman | Satılır mı? | Üretim |
|---|---|---|
| Boya | Evet | **Görsel yok**, kodla renk: 12+ renk bedavaya yakın içerik |
| Duvar kağıdı | Evet | Kesintisiz desen 512×512, kod tekrarlar |
| Zemin | Evet | Kesintisiz desen 512×512, kod tekrarlar |
| Süpürgelik, pencere, perde | Evet | Saydam parça |
| Mobilya yuvaları | Evet | Saydam parça |
| Zibo | Kostüm ayrı | Mevcut sistem + bakım pozları |
| Ön plan eşyaları | Evet | Saydam parça |

Yerleştirme: ilk sürümde **sabit yuvalar** (her yuvaya varyant seçilir), serbest sürükleme sonraki sürüm.

## Mutfak (ilk oda) üretim listesi
| Parça | Boy (ZB) | Adet |
|---|---|---|
| Ana sahne (Zibo'suz) | — | 1 |
| Buzdolabı | 1,35 | 3 |
| Tezgah + ocak | 0,65 | 3 |
| Üst dolap | 0,45 | 2 |
| Masa | 0,55 | 3 |
| Sandalye | 0,6 | 3 |
| Pencere + perde | 0,8 | 3 |
| Aksesuar (saat, saksı, tablo, raf) | 0,2–0,4 | 6 |
| Duvar kağıdı deseni | — | 6 |
| Zemin deseni | — | 4 |
| Zibo: aç, yemek yiyor ×2, tok, mutlu | 1 | 5 |

Toplam ~39 görsel. **Toplu üretime geçmeden önce deneme seti:** ana sahne + 1 buzdolabı + 1 masa.

## Prompt'lar
Ana sahne referanssız üretilir, beğenilince sonraki her prompt'a referans verilir.

**Stil kilidi (her prompt'a eklenir):**
`Flat 2D cartoon illustration for a cute mobile pet game, clean bold dark outlines, simple flat colors with soft cel shading, bright cheerful palette, storybook style.`

**Ana sahne:**
`[Stil kilidi] Cozy kitchen seen straight from the front, flat side-on view, no perspective, back wall and floor only. Vertical 3:4. A tall rounded retro fridge on the left, a low counter with a stove in the middle against the wall, a small round table with one chair on the right, everything fully inside the frame. Plain pastel yellow painted wall, simple wooden floor. The floor starts at two thirds of the image height. Empty space in the center for a character. No characters, no people, no animals. Tidy, cheerful, for all ages.`

**Tek eşya (ana sahne referans):**
`[Stil kilidi] Single [EŞYA] in exactly the same style as the reference kitchen, flat front view, isolated on a pure white background, no floor, no shadow, nothing else in the image, centered, full object visible.`

**Duvar kağıdı / zemin:**
`Seamless repeating tile texture, [DESEN], flat 2D cartoon style with soft pastel colors, even lighting, no shadows, no perspective, edges tile perfectly, square.`

**Kaçın:** `text, letters, logo, watermark, extra fingers, characters, realistic photo, 3D render, low poly, perspective, brand names.`

## Ekonomi taslağı (rakamlar kesin değil)
Referans: 110 ZC ≈ ₺16,99 (`coins_100`), kostüm 440–33.000 ZC. Fiyatlar `unit_economics.md` ile hesaplanır, uzaktan değişebilir olur.
- Boya 30–80 · duvar kağıdı 120–400 · zemin 150–500 · aksesuar 40–150 · mobilya 250–1.500 · nadir takım 3.000–8.000 ZC.
- Her odada bedava başlangıç takımı. Satılan şey süs: Zibo'nun bakımı ZC'siz de yürür. Yoksa çocuk kullanıcıda istismarcı görünür (`zibo_home.md`).
- Gerçek gelir sürümle ölçülür: ZC paketi satışı, harcanan ZC, oda başına satın alma.
