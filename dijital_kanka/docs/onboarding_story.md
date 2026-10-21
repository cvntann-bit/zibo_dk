# Zibo — Intro Hikâyesi (kullanıcı fikri, 2026-10-21)

Zibo birinci ağızdan anlatır. Görselleri kullanıcı üretir; metinler TR/EN/ES ARB'den gelir (görsel içinde yazı YOK).
Akış: Dil → Hikâye (S1–S5) → İsim → Karşılama → Uygulama. Her slaytta "Geç" olur. Mevcut kullanıcılar görmez (`onboardingState.completed`).

| # | Sahne / görsel | Metin (TR taslak — onay bekliyor) |
|---|---|---|
| S1 | **Görsel A:** dağınık oda, soluk renkler, Zibo yatakta elinde telefon, hipnoz olmuş gibi (soluk) | Altta konuşma balonu: "Eskiden düzensiz ve soluk bir hayatım vardı…" |
| S2 | Ara sahne (sakin/koyu, metin odaklı; A'nın karartılmış hâli olabilir) | "Ta ki… bir gün her şeyden sıkılıp, kendimin en iyi versiyonuna ulaşmaya karar verdiğim ana kadar." |
| S3 | **Görsel B:** AYNI dağınık oda/kadraj, hâlâ soluk ama Zibo PARLIYOR | "İşte o an her şey değişti." |
| S4 | **Görsel C:** AYNI kadraj, fade geçişle: pencereden güneş, her şey yerli yerinde, Zibo mutlu | "Sonra kendime bir söz verdim: bu yolda kendinin en iyi versiyonuna ulaşmaya karar veren herkesin kankası olacağım." |
| S5 | Yalnızca Zibo (mevcut poz yeterli), altta konuşma balonu | "Demek buradasın. O zaman başlayalım!" |
| — | İsim adımı | "Sana ne diye hitap edeyim?" |
| — | Karşılama (isim girildikten sonra) | "Tanıştığıma memnun oldum, {name}! Hadi başlayalım!" → uygulamaya giriş |

Görsel gereksinimleri: A, B, C AYNI kadraj/kompozisyon (A→B→C çapraz geçiş için); dikey ~1080×1350, tam kadraj (arka planlı); D (S5) için yeni görsel gerekmez.
Açık sorular: kısa öğretici nerede (hikâyeden sonra mı, uygulamaya girince ipucu baloncuklarıyla mı?), S2 görseli, geçiş hızı (otomatik/dokunma).

## Görsel üretim prompt'ları (A, B, C — aynı kadraj)

Referans: `store_assets/zibo_referans.png` (Zibo'nun 3 pozu). Üretici araca REFERANS olarak ver. A'yı üret, beğenince A'yı referans vererek B ve C'yi "aynı oda, aynı kamera, aynı Zibo konumu" diye türet.
Boyut: 4:5 dikey (1024×1280 üret → 1080×1350'ye ölçekle). Alt %28'i sakin bırak (uygulama konuşma balonunu/metni oraya çizer), önemli her şey üst %70'te.

**Zibo karakter kilidi (hepsinde aynı):** stylized 3D animated-film character; round bald head, honey-orange skin (#D18647 tones), very large teal-green eyes with heavy expressive brows, big floppy ears, small goatee tuft on chin, stocky chubby-muscular body, white ribbed tank top, brown-and-white striped shorts, grey sneakers, wooden bead bracelet on one wrist. Pixar-like soft shading, glossy eyes.

**Ortak sahne:** same small bedroom, same camera for A/B/C — eye-level slightly high 3/4 angle, wide shot; bed against the left wall, window on the right wall, desk with a lamp at the back; Zibo lying/sitting on the bed in the same place (upper-center-left of frame).

**A — soluk, dağınık:** [karakter kilidi]. Zibo lying on the bed holding a phone, face lit by cold blue phone light, half-closed glazed eyes (hypnotised, bored), his honey skin looks faded and desaturated. Messy room: unmade bed, clothes on the floor, pizza box, crumpled paper, tangled cables, closed curtains. Dull, desaturated grey-blue palette, dim lighting, low contrast, gloomy but gentle (not scary). Bottom 28% of the frame calm/empty floor.
**B — Zibo parlıyor:** SAME image as A (same room, same mess, same dull palette, same camera and Zibo position) but Zibo has just decided to change: a warm golden glow radiates from him, his skin is vivid honey-orange again, eyes wide, bright and determined, phone lowered; the only saturated colour in the frame is Zibo and his golden light; the room stays dull and messy.
**C — her şey yerli yerinde:** SAME camera and layout, now a tidy, bright morning: curtains open, strong warm sunlight streaming through the window with soft light rays, made bed, clothes folded, clean floor, plant on the desk, neat books, warm honey-and-blue palette; Zibo sitting happily on the bed in the same spot, big smile, relaxed and proud. Cheerful, cozy, vibrant.

**Negatif / kaçın:** text, letters, watermark, extra fingers, different character, different outfit, realistic human, horror/gloomy-scary look, wide-angle distortion, changed room layout between scenes.
**Tutarlılık ipucu:** önce A; B ve C'yi "edit/variation" olarak A'dan türet (yalnızca ışık, renk ve düzen değişsin). Zibo'nun yüzü/kıyafeti kayarsa referansı her seferinde yeniden ver.
