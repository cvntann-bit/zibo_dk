# Zibo Dünyası — kullanıcının üreteceği görseller (2026-11-03)

Kullanıcı görselleri kendisi üretip gönderecek; işleme (arka plan temizleme, kırpma, WebP) bizde
(`tool/CLAUDE.md`: `remove_bg.dart`, `crop_transparent.dart`). Prompt'lar İngilizce (üreticiler daha iyi anlıyor).
Durum sütunu gelen görsellerle güncellenir.

## Teslim kuralları
- **Zibo pozları:** tam boy, tam önden, ortada, **düz beyaz arka plan** (ya da şeffaf PNG), gölge yok, yazı yok.
  En az 1024 px yükseklik. Her prompt'a **referans görsel** olarak `assets/images/home/zibo_happy.webp` verilir
  (yüz ve oranlar bozulmasın). Mevcut pozlarla aynı ışık ve boyut.
- **Dünya görselleri:** her bina AYRI görsel (beyaz arka plan ya da şeffaf), hepsi aynı kamera açısı ve ışıkta,
  ~1024×1024. Arka plan sahnesi binasız, dikey 1440×2560 (9:16). Görselde YAZI olmaz (etiketler uygulamada,
  3 dilde). Kilitli yerler (Sıralama, Arkadaşlar) uygulamada soluk + kilitle gösterilir, ayrı görsel gerekmez.

## Ortak stil kilidi — Zibo (her poz prompt'unun başına)
```
Zibo, exactly the same character as the reference image: a small chubby humanoid with smooth peach-orange skin,
a big round bald head, large floppy ears, big teal eyes with thick brows, a tiny goatee, white ribbed tank top,
brown-and-white striped baggy shorts, grey sneakers, a brown bead bracelet. Pixar-style 3D render, soft studio
lighting, front view, centered, plain pure white background, no shadow, no text.
```

## A. Bakım pozları (öncelik sırası)
| # | Dosya | Nerede | Prompt (stil kilidinden sonra) | Durum |
|---|---|---|---|---|
| 1 | `zibo_sleep` | Yatak odası, uyurken (yorgan göğsüne kadar örter) | `Sleeping peacefully, eyes fully closed, gentle smile, head tilted to one side resting on his folded hands like a pillow, relaxed droopy ears, upper body upright, full body.` | ✅ 2026-11-03 |
| 2 | `zibo_yawn` | Yatak odası, yorgun (enerji düşük) | `Very sleepy and yawning, eyes half closed, one hand covering his wide open mouth, droopy ears, slightly slouched, full body standing.` | ✅ 2026-11-03 |
| 3 | `zibo_bath_happy` | Banyo, küvette temiz (alt gövde küvetin arkasında kalır) | `Sitting cross-legged as if in a bathtub (do NOT draw any bathtub or water), wearing only his striped shorts, both arms raised happily, a few soap bubbles on his head, big joyful smile, slightly shiny wet skin, full body.` | ✅ 2026-11-03 |
| 4 | `zibo_bath_pout` | Banyo, küvette kirli | `Sitting cross-legged as if in a bathtub (do NOT draw any bathtub or water), wearing only his striped shorts, arms crossed, grumpy pout, eyebrows frowning, full body.` | ✅ 2026-11-03 |
| 5 | `zibo_eat_open` | Mutfak, yemek beklerken (masa önde) | `Sitting upright as if at a dining table (do NOT draw a table), mouth wide open eagerly waiting to be fed, sparkling excited eyes, both hands near his chest, full body.` | ✅ 2026-11-03 |
| 6 | `zibo_eat_chew` | Mutfak, yerken | `Sitting upright as if at a dining table (do NOT draw a table), happily chewing with puffed cheeks, eyes closed in delight, one hand on his tummy, full body.` | ✅ 2026-11-03 |
| 7 | `zibo_play` | Salon, kanepede oyun oynarken | `Sitting as if on a sofa (do NOT draw a sofa), excitedly playing a video game, holding a purple game controller with both hands, leaning forward, big open-mouth grin, full body.` | ✅ 2026-11-03 |
| 8 | `zibo_wave` | Giriş ekranı / konuşma balonu | `Standing, cheerfully waving hello with his right hand raised high, big friendly smile, full body.` | ✅ 2026-11-03 |

## B. Zibo Dünyası giriş ekranı (düzeltme listesi madde 1)
**Ortak stil kilidi — binalar:**
```
Cute cartoon building for a kids mobile app world map, chunky rounded shapes, soft gradients and glossy
highlights, thick dark outline like a sticker, warm cheerful colors, 3/4 front view from slightly above,
same camera angle and lighting for every building, isolated on a plain pure white background, no text,
no letters, no people.
```
| # | Dosya | Açılınca | Prompt (stil kilidinden sonra) | Durum |
|---|---|---|---|---|
| 9 | `world_bg` | — (arka plan) | `Vertical 9:16 landscape background for a kids app world map: soft blue sky with puffy clouds, rolling green hills, a winding light sand path connecting five empty round grassy plots, small flowers and bushes, no buildings, no text.` (bina stil kilidi KULLANILMAZ) | ✅ 2026-11-03 |
| 10 | `world_home` | Ev ekranı (2×2 oda) | `A cozy two-story cottage with a terracotta roof, a chimney with a puff of smoke, round windows with warm light, a yellow front door, a tiny flower garden.` | ✅ 2026-11-03 |
| 11 | `world_games` | Oyun Salonu | `A playful arcade hall shaped like a giant retro game console, purple and teal, glowing star-shaped neon sign without letters, joystick on the roof.` | ✅ 2026-11-03 |
| 12 | `world_events` | Etkinlikler | `A festive striped circus tent in red and yellow with bunting flags, a big gift box with a bow beside the entrance.` | ✅ 2026-11-03 |
| 13 | `world_leaderboard` | Sıralama (1.19.0, kilitli) | `A small round stadium with a three-step podium on top and a big shiny golden trophy.` | ✅ 2026-11-03 |
| 14 | `world_friends` | Arkadaşlar (1.19.0, kilitli) | `A friendly park pavilion café with a striped awning, two benches, a big round tree and a heart-shaped sign without letters.` | ✅ 2026-11-03 |

## C. Zibo'nun Evi bakım rozetleri (düzeltme listesi madde 2) — ✅ onaylandı ve teslim alındı 2026-11-06
Yeni rozet kategorisi **"Zibo'nun Evi"** (`BadgeCategory.home`). Mevcut rozetlerle aynı stil: yuvarlak parlak madalyon,
metal çerçeve + taş süsler, ortada tek 3D ikon (Zibo YOK). Beyaz arka plan JPG/PNG, ≥1024×1024; kırpma/şeffaflık bizde.
Görselde YAZI, HARF, SAYI olmaz (rozet adı uygulamada 3 dilde).

**Ortak stil kilidi — rozetler (her prompt'un başına):**
```
Round glossy mobile game achievement badge, a thick polished metallic rim decorated with small faceted gem studs,
soft glowing inner disc, one single cute 3D icon in the center, small sparkles, vibrant saturated colors,
Pixar-style 3D render, front view, centered, isolated on a plain pure white background, no text, no letters,
no numbers, no characters, square 1024x1024.
```

| # | Dosya | Rozet (TR) | Koşul | ZC | Prompt (stil kilidinden sonra) | Durum |
|---|---|---|---|---|---|---|
| 1 | `ev_ilk_lokma_rozet` | İlk Lokma | Zibo'yu ilk kez besle | 15 | `Warm peach-orange rim with amber gems; in the center a shiny red apple with one cute bite taken out, a small green leaf, tiny crumbs and sparkles.` | ✅ 2026-11-06 |
| 2 | `ev_sef_rozet` | Şef Zibo | Zibo'yu 50 kez besle | 40 | `Gold rim with ruby red gems and golden laurel leaves; in the center a puffy white chef hat above a small steaming copper soup pot with a wooden spoon.` | ✅ 2026-11-06 |
| 3 | `ev_mis_gibi_rozet` | Mis Gibi | Zibo'yu 20 kez yıka (havluyla bitir) | 40 | `Light aqua-turquoise rim with pearl gems; in the center a happy yellow rubber duck sitting in a pile of white soap foam with rainbow-tinted bubbles and a pink soap bar.` | ✅ 2026-11-06 |
| 4 | `ev_uykucu_rozet` | Uykucu | Zibo'yu 15 kez uyutup dinlendir | 40 | `Lavender-purple rim with amethyst gems; in the center a fluffy white pillow with a soft blue striped nightcap resting on it, a tiny crescent moon and twinkling stars above.` | ✅ 2026-11-06 |
| 5 | `ev_bakici_rozet` | Sevgi Dolu Bakıcı | 7 farklı günde Zibo'ya bakım yap (besle/yıka/uyut) | 75 | `Rose-gold rim with pink diamond gems; in the center a tiny cozy cottage with a red roof and a big glowing heart-shaped window, small hearts floating around.` | ✅ 2026-11-06 |
| 6 | `ev_dekorator_rozet` | Ev Dekoratörü | Evine 10 dekor eşyası satın al | 50 | `Coral and teal rim with turquoise gems; in the center a small cute armchair next to a paint roller dripping mint paint and a little potted plant.` | ✅ 2026-11-06 |

**İşleme:** `tool/cut_round_badges.py` (çevredeki parçacıklar atılır, yalnız daire kalır, 512 px WebP). **Kod notları:** sayaçlar `HomeNeedsProvider`'a (`feedCount`, `bathCount`, `sleepCount`, `careDays`) — uyku yalnız
en az %30 enerji kazanıp uyanınca sayılır (ışığı aç/kapa ile kasılmasın); dekor sayısı `HomeDecorProvider` sahiplik
listesinden (başlangıç eşyaları hariç). Toplam ödül 260 ZC (tek seferlik; `unit_economics.md`'ye göre zararsız).

## Öncelik
Önce A1–A6 (bakım oyunlarında hemen kullanılır), sonra B (giriş ekranı yeniden yapımı), A7–A8 en son.

## Teslim alındı (2026-11-03)
14 görselin hepsi geldi (masaüstü `zibo_world/`, beyaz zeminli JPG). `tool/process_world_images.py` ile işlendi:
kenara bağlı düz beyaz şeffaf (renkli beyaz — tişört — korunur; eşik min≥242 ve renk farkı ≤10), 2 px kenar
yumuşatma + beyaz hale temizleme, içeriğe kırpma, kayıplı WebP. Köşe alfası 0 ölçüldü; koyu zeminde hale yok.
- Pozlar → `assets/images/home/zibo_<ad>.webp` (900 px yükseklik).
- Binalar → `assets/images/world/world_<ad>.webp` (en uzun kenar 1024), arka plan `world_bg.webp` 1440×2580.
- Kullanım: bakım pozları `HomeRoomScreen._pose` (mutfak: tabakta yemek → `eat_open`, yerken `eat_chew`;
  banyo: `bath_happy`/`bath_pout`, kutu oranı .93; yatak: uyurken `sleep`, enerji <%50 `yawn`; salon: `play`),
  giriş ekranında `wave` (ihtiyaç <%30 ise `pout`).
