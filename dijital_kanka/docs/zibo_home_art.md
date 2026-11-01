# Zibo'nun Evi — görsel üretim rehberi (2026-11-01)

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
