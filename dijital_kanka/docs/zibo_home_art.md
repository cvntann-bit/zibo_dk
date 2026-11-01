# Zibo'nun Evi — görsel üretim rehberi (2026-11-01)

Kullanıcı kararları: Zibo Dünyası'nda **ev merkezde**. Oda oda ilerlenir. `asset_library/` mobilyaları **beğenilmedi** (kötü görünüyor, orantısız):
mobilya yeni üretilecek. Her odanın **arka planı, duvar kağıdı, deseni, boyası** ZC ile satılacak. Hedef **mini Sims**: asıl ZC harcama alanı,
ZC satın almaya gerçek bir sebep. `asset_library/` yalnızca geçici yer tutucu; küçük eşya (Fluent) ayrıca değerlendirilecek.

## Orantısızlık neden oldu, nasıl önlenir
Eşyalar farklı paketlerden, farklı kamerayla, Zibo düşünülmeden yapılmıştı. Çözüm:
1. **Önce ana sahne:** Oda, Zibo içindeyken tek görsel olarak üretilir. Stil, kamera ve ölçek buradan kilitlenir.
2. **Sonra parçalar:** Her eşya ana sahne referans verilerek tek tek, aynı kamerayla üretilir.
3. **Ölçek birimi Zibo'dur:** Boylar "Zibo boyu" (ZB) ile yazılır, uygulamada kodla sabitlenir.

## Sabit kurallar
- **Stil:** Zibo ile aynı, sinema animasyonu tarzı yumuşak 3B; yuvarlak köşeler, tombul oranlar, sıcak ışık. Düşük poligon yok.
- **Kamera:** Önden, göz hizasından hafif yukarı. Oda bebek evi kesiti gibi görünür. Bütün odalarda aynı.
- **Işık:** Sol üstten yumuşak ve sıcak; gölge sağa-aşağıya.
- **Tuval:** Oda 1080×1440. Zemin çizgisi yukarıdan %68'de. Üst %10 ve alt %12 arayüze bırakılır.
- **Eşya:** Saf beyaz zemin (sonra `tool/cutout_*` ile saydamlaştırılır), en uzun kenar en az 1024 px, tek nesne, zemin gölgesi yok. Üretimin tamamı bitince `cwebp`.

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
| Ana sahne (Zibo'lu) | — | 1 |
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
Referans: `store_assets/zibo_referans.png` her seferinde verilir. Ana sahne beğenilince o da referans olur.

**Stil kilidi (her prompt'a eklenir):**
`Stylized 3D animated-film look, soft Pixar-like shading, rounded chunky shapes, slightly oversized cute proportions, warm soft light from the upper left, clean high quality render.`

**Ana sahne:**
`[Stil kilidi] Cozy kitchen seen straight from the front like a dollhouse cross-section, eye level, slightly elevated camera, no perspective distortion, back wall and floor only. Vertical 3:4. The character from the reference stands in the center, same design and outfit, full body, feet on the floor. Beside him a rounded retro fridge 1.35 times his height, a low counter with a stove reaching his chest, a small round table and one chair. Plain warm cream painted wall, simple wooden floor. The floor line is at two thirds of the image height. Tidy, cheerful, for all ages.`

**Tek eşya (ana sahne + Zibo referans):**
`[Stil kilidi] Single [EŞYA] in exactly the same style, camera angle and lighting as the reference kitchen, front view slightly from above, isolated on a pure white background, no floor, no shadow, nothing else in the image, centered, full object visible.`

**Duvar kağıdı / zemin:**
`Seamless repeating tile texture, [DESEN], soft pastel colors matching a cozy 3D animated film kitchen, flat even lighting, no shadows, no perspective, edges tile perfectly, square.`

**Kaçın:** `text, letters, logo, watermark, extra fingers, different character, realistic photo, low poly, harsh shadows, wide-angle distortion, brand names.`

## Ekonomi taslağı (rakamlar kesin değil)
Referans: 110 ZC ≈ ₺16,99 (`coins_100`), kostüm 440–33.000 ZC. Fiyatlar `unit_economics.md` ile hesaplanır, uzaktan değişebilir olur.
- Boya 30–80 · duvar kağıdı 120–400 · zemin 150–500 · aksesuar 40–150 · mobilya 250–1.500 · nadir takım 3.000–8.000 ZC.
- Her odada bedava başlangıç takımı. Satılan şey süs: Zibo'nun bakımı ZC'siz de yürür. Yoksa çocuk kullanıcıda istismarcı görünür (`zibo_home.md`).
- Gerçek gelir sürümle ölçülür: ZC paketi satışı, harcanan ZC, oda başına satın alma.
