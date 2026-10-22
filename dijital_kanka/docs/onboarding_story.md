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

## Görsel üretim prompt'ları (A, B, C — aynı kadraj) — ESKİ 4:5 SÜRÜM, aşağıdaki 9:16 REVİZE geçerli

Referans: `store_assets/zibo_referans.png` (Zibo'nun 3 pozu). Üretici araca REFERANS olarak ver. A'yı üret, beğenince A'yı referans vererek B ve C'yi "aynı oda, aynı kamera, aynı Zibo konumu" diye türet.
Boyut: 4:5 dikey (1024×1280 üret → 1080×1350'ye ölçekle). Alt %28'i sakin bırak (uygulama konuşma balonunu/metni oraya çizer), önemli her şey üst %70'te.

**Zibo karakter kilidi (hepsinde aynı):** stylized 3D animated-film character; round bald head, honey-orange skin (#D18647 tones), very large teal-green eyes with heavy expressive brows, big floppy ears, small goatee tuft on chin, stocky chubby-muscular body, white ribbed tank top, brown-and-white striped shorts, grey sneakers, wooden bead bracelet on one wrist. Pixar-like soft shading, glossy eyes.

**Ortak sahne:** same small bedroom, same camera for A/B/C — eye-level slightly high 3/4 angle, wide shot; bed against the left wall, window on the right wall, desk with a lamp at the back; Zibo lying/sitting on the bed in the same place (upper-center-left of frame).

**A — soluk, dağınık:** [karakter kilidi]. Zibo lying on the bed holding a phone, face lit by cold blue phone light, half-closed glazed eyes (hypnotised, bored), his honey skin looks faded and desaturated. Messy room: unmade bed, clothes on the floor, pizza box, crumpled paper, tangled cables, closed curtains. Dull, desaturated grey-blue palette, dim lighting, low contrast, gloomy but gentle (not scary). Bottom 28% of the frame calm/empty floor.
**B — Zibo parlıyor:** SAME image as A (same room, same mess, same dull palette, same camera and Zibo position) but Zibo has just decided to change: a warm golden glow radiates from him, his skin is vivid honey-orange again, eyes wide, bright and determined, phone lowered; the only saturated colour in the frame is Zibo and his golden light; the room stays dull and messy.
**C — her şey yerli yerinde:** SAME camera and layout, now a tidy, bright morning: curtains open, strong warm sunlight streaming through the window with soft light rays, made bed, clothes folded, clean floor, plant on the desk, neat books, warm honey-and-blue palette; Zibo sitting happily on the bed in the same spot, big smile, relaxed and proud. Cheerful, cozy, vibrant.

**Negatif / kaçın:** text, letters, watermark, extra fingers, different character, different outfit, realistic human, horror/gloomy-scary look, wide-angle distortion, changed room layout between scenes.
**Tutarlılık ipucu:** önce A; B ve C'yi "edit/variation" olarak A'dan türet (yalnızca ışık, renk ve düzen değişsin). Zibo'nun yüzü/kıyafeti kayarsa referansı her seferinde yeniden ver.


## REVİZE — 9:16 DİKEY prompt'lar (telefon için, GEÇERLİ)

Boyut: **9:16 dikey** (üretici ne verirse: 1080×1920 ya da 1152×2048). Uygulama görseli ekranı kaplayacak şekilde gösterir (BoxFit.cover); uzun telefonlarda (20:9) yanlar/üst-alt biraz kırpılabilir → **önemli her şeyi merkez %80 genişlikte ve dikeyde %8–%68 aralığında tut.** Üst %8 durum çubuğu payı, **alt %32 sakin zemin** (konuşma balonu + metin oraya biner).

**Ortak sahne (A/B/C'de BİREBİR aynı):** tall vertical 9:16 composition. Front view of a small bedroom seen straight on from slightly above: back wall in the upper part with a tall window on the right of the wall and a desk with a lamp at the far left; the single bed pushed against the back wall in the middle of the frame; Zibo on the bed, centered, occupying about the middle third of the image; open floor space in the foreground filling the bottom third (calm, no important objects). Same camera, same furniture positions in every scene.

**Prompt A (soluk, dağınık):**
> Vertical 9:16. [Zibo karakter kilidi]. Tall composition, front view of a small bedroom from slightly above; bed against the back wall in the middle, tall window on the back wall at right, desk with lamp at far left. Zibo lying on the bed holding a phone, face lit by cold blue phone light, half-closed glazed hypnotised eyes, his honey skin faded and desaturated. Messy room: unmade bed, clothes and a pizza box on the floor, crumpled paper, tangled cables, curtains closed. Dull desaturated grey-blue palette, dim low-contrast lighting, gloomy but gentle. Bottom third of the frame is empty floor, calm and uncluttered. No text.

**Prompt B (Zibo parlıyor):**
> Same exact image as A (same room, mess, dull palette, camera, furniture and Zibo position), vertical 9:16. Zibo has just decided to change: warm golden glow radiates from him, skin vivid honey-orange again, eyes wide, bright and determined, phone lowered. Zibo and his golden light are the only saturated colours; the room stays dull and messy. Bottom third empty floor. No text.

**Prompt C (her şey yerli yerinde):**
> Same camera and layout as A, vertical 9:16, now a tidy bright morning: curtains open, strong warm sunlight through the tall window with soft light rays crossing the room, made bed, folded clothes, clean floor, plant on the desk, neat books, warm honey-and-blue palette. Zibo sitting happily on the bed in the same spot, big smile, relaxed and proud. Cheerful, cozy, vibrant. Bottom third clean empty floor. No text.

Midjourney: sonuna `--ar 9:16`. Diğer araçlarda "vertical 9:16 aspect ratio" yaz; yine yatay çıkarsa "portrait orientation, 1080x1920" ekle.
Negatif: text, letters, watermark, extra fingers, different character or outfit, realistic human, horror look, horizontal composition, changed room layout between scenes.


## DURUM — altyapı HAZIR, gerçek uygulamaya BAĞLANMADI (2026-10-21)

Kullanıcı şu an meşgul; adım adım ilerlenecek, "ana dediği şeyler" bu dosyaya not edilir. **Kod `main`'de DEĞİL: `feature/intro-story` dalında** (uygulama davranışı değişmedi, eski onboarding aynen çalışıyor).

### Hazır olanlar (dalda)
- `lib/screens/onboarding/story_intro_screen.dart` — `StorySlides` (5 slayt, tam ekran, dokunarak ilerler, A→B→C çapraz solma, "Geç") + ince `StoryIntroScreen` sarmalayıcı.
- `lib/screens/onboarding/intro_flow_screen.dart` — `IntroFlowScreen` (hikâye → isim → bildirim izni → final), `IntroResult{name, notificationsGranted}`. Bildirim izninin GERÇEK isteği dışarıdan `requestNotificationPermission` callback'iyle verilir.
- `lib/widgets/zibo_bubble.dart` — çıkartma stilinde konuşma balonu (başlık/metin/ipucu).
- `lib/services/onboarding_analytics.dart` — olaylar: `onboarding_story_step{step}`, `onboarding_story_skipped{step}`, `onboarding_story_done`, `onboarding_name_done`, `onboarding_notif_result{granted}`, (bağlayınca) `onboarding_completed`.
- `lib/story_preview_main.dart` — YALNIZCA tarayıcı önizlemesi (`.claude/launch.json` → `zibo_story_preview`, port 8815; Android izin penceresini TAKLİT eder). Çalıştırma sonrası ilk yükleme yavaş: `curl .../main.dart.js` hazır olana kadar bekle; ekran görüntülerini proje DIŞINA yaz.
- Görseller: `assets/images/onboarding/story_a|b|c.webp` (**572×1024 yer tutucu**; yüksek çözünürlüklü asıllar gelince AYNI dosya adlarıyla değiştir; pubspec'e `assets/images/onboarding/` eklendi).
- ARB (TR/EN/ES): `onboardingStory1..5`, `onboardingStoryTapHint`, `onboardingMeetTitle(name)`, `onboardingNameBubble`, `onboardingNotifBody`, `onboardingNotifAllow/Later`, `onboardingFinaleAllowed/Declined`. (`onboardingNameStepTitle` DEĞİŞTİRİLMEDİ; yeni akış `onboardingNameBubble` kullanır.)
- Testler: `test/onboarding_story_test.dart` (3), `test/intro_flow_test.dart` (4) — geçiyor.

### Kullanıcının onayladığı kararlar
Metinler (TR) onaylandı. Slayt geçişi DOKUNARAK (otomatik değil), "Geç" her slaytta. S2 ara sahne = yeni görsel YOK, A karartılmış + metin ortada. S5 = yalnızca Zibo + balon. Bildirim izni Zibo'nun konuşma balonuyla, hikâyenin İÇİNDE istenir (isimden sonra, "Tanıştığıma memnun oldum, {isim}!" ile). Intro yalnızca YENİ kurulumlarda; Ayarlar'dan "Hikâyeyi tekrar izle" eklenecek. Kısa öğretici = Ana Sayfa'da 3 küçük ipucu balonu (Zibo'ya dokun, Z menüsü, mağaza), atlanabilir.

### Bağlama planı (sırayla; kullanıcı "başla" dediğinde)
1. Dalı `main`'e al: `OnboardingScreen` akışını Dil → `IntroFlowScreen` → uygulama olarak değiştir; 8 modül sayfasını + `_moduleIntros` kodunu kaldır (ARB anahtarlarını SİLME — proje konvansiyonu). İsim `ProfileProvider.setName` + `setAddressTerm`; `OnboardingProvider.completeOnboarding()`.
2. Gerçek izin: `NotificationService.requestPermission()` (Android 13+ POST_NOTIFICATIONS). **Açılışta bağlamsız yapılan FCM `requestPermission` (`push_notification_service.dart` ~79. satır) intro bitene kadar ERTELENMELİ** (çift soru olmasın); intro bildirimi reddettiyse tekrar tekrar sorma.
3. `test/widget_test.dart` `_pumpPastOnboarding`: dil → `storySkip` → isim → "Devam Et" → izin adımı "Şimdi Değil" → final "Hadi Başlayalım!"; eski "8 modül tanıtılır" testini yeni akışa çevir.
4. Mevcut kullanıcılar intro'yu GÖRMEMELİ (`onboardingState.completed` kontratı). Ayarlar'a "Hikâyeyi tekrar izle".
5. Ana Sayfa 3 ipucu baloncuğu (öğretici) — ayrı adım.
6. Yüksek çözünürlüklü görselleri koy; telefonda gerçek cihaz testi (balon/uzun ekran kırpması, klavye).
7. Analytics olayları Firebase'de doğrula; retention (gün-1/7) öncesi/sonrası kıyası (roadmap Faz 0 verisiyle).

### Açık / ince ayar
Yüksek çözünürlüklü A/B/C; S5 arka planı (şu an düz krem); balon kuyruğu (Zibo'ya doğru); yazı boyutu/geçiş hızı kullanıcı geri bildirimi bekliyor; gerçek uygulama temasında buton renkleri (önizleme teması farklı).


## BAĞLANDI (2026-10-22, main) — durum güncellemesi

Kullanıcı onayıyla (AAB yerine telefona APK kurup deneyecek) intro `main`'e BAĞLANDI: `OnboardingScreen` artık yalnızca **dil seçimi → `IntroFlowScreen`** (hikâye → isim → bildirim izni → final). 8 modül sayfası kaldırıldı (ARB anahtarları silinmedi). İsim → `ProfileProvider.setName` + `setAddressTerm`; `OnboardingProvider.completeOnboarding()`. Mevcut kullanıcılar (`onboardingState.completed`) görmez.
- Bildirim izni: `LocalNotificationService().requestPermission()` (Android 13+ sistem penceresi), intro'nun içinde Zibo balonuyla istenir. **"Şimdi Değil" ya da reddedilirse** `PushPermissionPreference.setDeclined(true)` (`introNotifDeclined`) yazılır ve açılıştaki FCM `requestPermission` (`PushNotificationService.initialize`) bu durumda ATLANIR (çift soru/seçimi yok sayma yok); anahtar yoksa (mevcut kullanıcılar) davranış değişmedi.
- Final metni "telefonunun ayarlarından açabilirsin" (Ayarlar'da genel bildirim anahtarı olmadığı için).
- Testler: `onboarding_story_test` (3), `intro_flow_test` (4), `push_permission_preference_test` (2), `widget_test` Onboarding + `_pumpPastOnboarding` yeni akışa uyarlandı.
- **Cihazda DENENECEK** (kullanıcı APK kuracak): hikâye geçişleri/uzun ekran kırpması, klavye, gerçek izin penceresi (İzin Ver / Reddet / Şimdi Değil), onboarding sonrası Ana Sayfa; mevcut kullanıcıda intro çıkmaması. Görseller hâlâ 572×1024 yer tutucu.
