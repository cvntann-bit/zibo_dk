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
