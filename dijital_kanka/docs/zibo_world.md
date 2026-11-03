# Zibo Dünyası — oyunlar sekmesinin yerine gelen merkez (FİKİR, 2026-11-01)

Durum: **tasarım aşaması, kod yok.** Ad geçici. Bu dosya `zibo_home.md`, `zibo_online.md` ve `game_zibo.md`'deki büyük işleri
tek çatıda toplar; ayrıntılar o dosyalarda kalır. Kullanıcı: "çok daha derinden girip odaklanacağız bu kısma".

## Kullanıcının istediği (2026-11-01)
- Ana Sayfa'nın yanındaki **Oyunlar sekmesine basınca yepyeni bir yer açılacak**, hepsi onun içinde olacak.
- İçinde: **Oyunlar, Zibo'nun Evi, Etkinlikler, Sıralama tablosu, Arkadaşlar, arkadaş ekleme** ve benzerleri.
- **İkram düz bir özellik olmayacak:** sanal evcil hayvan bakım oyunu gibi derin olacak (kullanıcının örneği Pou).
- **Oyun Salonu, Zibo'nun Evi kısmına taşınacak.**
- **Etkinlik alanı açılacak:** eklemek istenen etkinlik online olarak değiştirilecek.

## Yapı önerisi
```
Alt çubuk: Ana Sayfa | Zibo Dünyası | Profil | Mağaza
Zibo Dünyası (kendi ekranı, kendi gezintisi)
├─ Zibo'nun Evi      bakım oyunu: mutfak, banyo, yatak odası, salon
│   └─ Oyun odası    bugünkü Oyun Salonu buraya taşınır
├─ Etkinlikler       panelden açılıp kapanan, güncellemesiz
├─ Sıralama          oyun ★ ve seri, arkadaşlar / ülke / dünya
└─ Arkadaşlar        arkadaş kodu, ev ziyareti, hediye
```

## Bakım oyunu ilkeleri
- Tür evcil hayvan bakımı; karakter, oda, ekran ve kurallar **Zibo'ya özgü** olur, Pou'nun görseli veya düzeni kopyalanmaz.
- Göstergeler: açlık, temizlik, enerji, mutluluk; zamanla yavaş düşer (`TrustedTimeProvider`).
- **Ceza yok:** Zibo ölmez, hastalanmaz, yalnızca üzgün görünür. Çocuklar kullanıyor (`zibo_home.md`).
- Oyunlardan kazan, evde harca döngüsü: ★ ve ZC yemek, sabun, mobilya, kostüme gider. Her zaman ücretsiz bir yol kalır.
- Yeni görsel ihtiyacı: ~12–15 kostümsüz Zibo pozu (kullanıcı üretir). Eşyalar `asset_library/`'den.

## Etkinlikler nasıl online değişir
- Firestore `events/{id}`: tür, başlangıç-bitiş, başlık (TR/EN/ES), ödüller, görseller. Yönetici uygulamasından düzenlenir, Zibo sürümü gerekmez.
- **Sınır:** uygulama yalnızca içinde kodu olan etkinlik TÜRLERİNİ çalıştırabilir (takvim, ortak hedef, oyun yarışı, puan katlama). Yeni bir tür ilk kez eklenirken sürüm gerekir; var olan türe yeni etkinlik eklemek gerekmez.
- Görseller: uygulamanın içindekiler ya da Firebase Storage'dan indirilen (maliyet hesaplanacak, `unit_economics.md`).
- İlk etkinlik adayı: Yılbaşı takvimi (`zibo_home.md`), 1 Aralık hedefi. Tarih sıkışık, karar gerekiyor.

## Önerilen sıra
1. **Kabuk:** Oyunlar sekmesi yeni merkez olur, mevcut oyunlar içine taşınır. Yeni içerik yok, kırılma riski düşük.
2. **Etkinlikler:** `events` altyapısı + yönetici ekranı + ilk etkinlik.
3. **Zibo'nun Evi:** önce mutfak ve bakım döngüsü, sonra banyo, yatak, salon.
4. **Sıralama**, sonra **Arkadaşlar** (`zibo_online.md`): sunucu doğrulaması, hile önleme ve çocuk güvenliği burada en ağır iş.

## Kurallar (değişmez)
- Sohbet yok, hazır ifadeler; profil fotoğrafı paylaşımı yok; şikâyet/engelle zorunlu.
- Sıralama puanları sunucuda doğrulanır; önceden hesaplanmış tek belge okunur.
- Bakım etkileşiminin ortasında zorunlu reklam yok; reklam kullanıcı seçimiyle.
- Her faz ayrı sürüm, önce taslak ve kullanıcı onayı, sonra kod.

## Kararlar (2026-11-01)
- **Ev merkezde:** Sekme açılınca Zibo evinde karşılar, diğer bölümler evin üstünde düğme olur.
- **Mini Sims:** Mobilya, boya, duvar kağıdı, zemin ZC ile satılır, oda oda ilerlenir. Üretim rehberi: `docs/zibo_home_art.md`.
- `asset_library/` mobilyaları beğenilmedi, yeni görsel üretilecek.
- **Stil kilitlendi (2026-11-02):** odalar kodla çizilir (`docs/kitchen_studio/`, https://claude.ai/artifact/VBTTTHp6ncR9UCrUpAA3ji), Zibo gerçek pozu. Ayrıntı `docs/zibo_home_art.md`.

## SÜRÜM KARARI (kullanıcı, 2026-11-02): 1.18.0 = Zibo Dünyası büyük güncellemesi
Ara sürüm yok; Zibo Dünyası hazır olunca tek büyük güncellemeyle çıkar. 1.18.0'da zaten bekleyenler de onunla gider:
satın alma doğrulaması kaydı (`purchase_verification.md`), uygulama içi mesaj kartı (`admin_panel.md`), tablet yan menü 840 dp.
Sonuç: bunlar Zibo Dünyası bitene kadar canlıya çıkmaz. Her adım yine debug APK ile telefonda denenir (`feedback_debug_apk_workflow`).

### Uygulama adımları (öneri sırası) — ayrıntılı faz planı: `docs/zibo_world_roadmap.md`
1. **Veri ve kabuk:** `HomeNeedsProvider` (4 ihtiyaç, `TrustedTimeProvider` ile zamanla düşer, ceza yok), `HomeDecorProvider` (oda başına sahip olunan/takılı eşya, `CloudStateStore` `homeDecorState`; ihtiyaçlar ayrı `homeNeedsState`). Alt çubukta Oyun Salonu sekmesi → `ZiboWorldScreen`; bugünkü `GameHallScreen` Oyunlar kapısından açılır.
2. **Oda çizimi:** taslaktaki SVG çizimleri Flutter `CustomPainter`'a taşınır (oda + eşya + desen + zemin). En büyük iş; görünüm taslakla aynı kalmalı.
3. **Giriş ekranı:** ev kesiti, ihtiyaç halkaları, Zibo'nun konuşma balonu, kapılar, etkinlik kartı.
4. **Bakım oyunları:** besle (Fluent görselleri `assets/` + lisans ekranı), köpükle yıka, uyut, salonda oyna.
5. **Dekor mağazası:** oda başına kategori ve renkler, ZC ile alma (`CoinProvider._spend`), fiyatlar uzaktan (`config/home`, yönetici uygulamasından).
6. **Etkinlikler:** `events` koleksiyonu + ilk tür (takvim) + yönetici uygulamasında düzenleme. 1.18.0 1 Aralık'tan önce çıkarsa Yılbaşı takvimi uzaktan açılabilir; sonra çıkarsa bu yıl kaçar.
7. **Sıralama ve Arkadaşlar:** sunucu doğrulaması, haftalık puan hesabı (saatlik iş), arkadaş kodu, şikâyet/engelle. En riskli kısım (kapsam kararı bekliyor, aşağıda).
8. **Metinler ve test:** TR/EN/ES ARB, `flutter test`, tablet görünümü, AAB.

### Kullanıcıdan gerekenler
- Yeni Zibo pozları: küvette oturan, uyuyan (gözler kapalı), yemek yiyen.
- ~~Kapsam~~ → Sıralama ve Arkadaşlar 1.19.0 (karar 2026-11-02).

### Riskler
- Büyük tek sürüm: hata çıkarsa her şey birden etkilenir → her adım ayrı commit, debug APK, testler.
- Satın alma doğrulaması gecikir: sahte satın almalar 1.18.0'a kadar görünmez kalır.
- Japonya yetkilendirmesi son tarihi 1 Aralık (`play_policy_updates.md`), sürümden bağımsız.

## Faz 0 kararları (kullanıcı, 2026-11-02)
- Sıralama ve Arkadaşlar **1.18.0'a girmiyor** → 1.19.0. 1.18.0'da kapılar "Yakında".
- Uyku **gerçek zamanlı**: uygulama kapalıyken de enerji dolar.
- Sabun **bir kez alınır**; **sabunun şekli dekor ürünü** olarak satılır ve değiştirilir.
- **Pro avantajı kesinlikle olacak** → `subscribe_model.md` "Zibo Dünyası avantajları".

## Giriş ekranı taslağı (2026-11-02)
`docs/zibo_world_prototype/index.html`, yayın: https://claude.ai/artifact/TLAUdqjmFvWYNvDAK45DA3. Oda çizimleri Ev Stüdyosu (`docs/home_studio/`) ile aynı koddan.
- **Üstte 4 ihtiyaç halkası** (tokluk, temizlik, enerji, mutluluk): dokununca ilgili odaya gider.
- **Ev kesiti:** çatılı ev, 2×2 oda (mutfak, banyo, yatak, salon). Zibo en düşük ihtiyacın odasında durur ve konuşma balonuyla söyler ("Karnım acıktı, mutfağa gidelim!"); balona ya da odaya dokununca oda açılır.
- **Sağda dikey kapılar:** Oyunlar, Etkinlikler (rozet 1), Sıralama, Arkadaşlar (rozet 2). Tek ekrana sığsın diye alttan sağa taşındı.
- **Oyunlar nerede (kullanıcı sorusu, 2026-11-02):** iki kapı. (1) Sağ sütunun en üstünde Oyunlar kapısı: bugünkü Oyun Salonu aynen (7 oyun, ★, Takas Gişesi) — ayrı sekme yerine Zibo Dünyası'nın içinde. (2) Salondaki televizyon: aynı liste, orada oynamak mutluluğu da doldurur. Gerekçe: oyunlar ★ ve oyun içi reklam gelirinin kaynağı; yalnız salona gömmek bulunmayı zorlaştırırdı.
- **Etkinlik kartı:** "Yılbaşı takvimi · 1 Aralık'ta başlıyor" — metin/tarih/ödül uzaktan.
- **Oda görünümü:** geri, oda adı, büyük bakım düğmesi (Besle/Banyo yap/Uyut/Oyna) + Dekor, ihtiyaç çubuğu.
- **Etkinlikler / Sıralama / Arkadaşlar** ekranları örnek veriyle (podyum, "Sen" satırı, arkadaş kodu ZB-7K4Q, hediye, ziyaret).
- Alt çubuk: Ana Sayfa | **Zibo Dünyası** | Profil | Mağaza.

## DÜZELTME LİSTESİ — fazlar bitince yapılacak (kullanıcı, 2026-11-03)
**2026-11-03, Faz 6 sonrası:** kullanıcı "komple bir düzen alacağız, beğenmediğim noktalar var, baştan sona düzenleyeceğiz" dedi → sıradaki iş bu liste + kullanıcının yeni maddeleri; ekran ekran (taslak → onay → uygulama).
Kullanıcı: "fazları bitirelim, düzeltmeleri en son yaparız". Fazlar sırayla sürer; aşağıdakiler en sona.
1. **Giriş ekranı görsel tabanlı olacak.** Kullanıcı görselleri KENDİSİ üretecek: Zibo'nun Evi, Oyun Salonu ve diğer yerler (etkinlik, sıralama, arkadaşlar…) bir dünya/kasaba sahnesinde. **Eve basınca ev ekranı** (bugünkü 2×2 oda kesiti ya da odalar), **Oyun Salonu'na basınca oyunlar** açılır. Bugünkü Faz 3 ev kesiti (`ZiboWorldScreen`) o zaman "ev ekranı"na dönüşür; hub görsel + dokunma alanları olur.
   - Görsel teslim biçimi henüz konuşulmadı (tek sahne + dokunma koordinatları mı, arka plan + her bina ayrı şeffaf PNG mi). Öneri: ayrı parçalar — tek binayı değiştirmek, kilitli/"yakında" soluk gösterim, dokununca zıplama ve tablet yerleşimi kolay.
   - Kilitli yerler (Sıralama, Arkadaşlar 1.19.0) görselde de "yakında" görünmeli.
2. **Faz 4'ten kalanlar:** yeni Zibo pozları (küvette oturan, uyuyan, yiyen — kullanıcı üretecek), bakım ses efektleri, ödüllü reklamla +1 ücretsiz yemek (`unit_economics.md`'ye göre), bakım rozetleri (`add-badge`), analytics olayları.
3. **Çeviri:** eşya, kategori, yemek ve sabun adları şimdilik yalnız Türkçe (katalog) — EN/ES.

## Netleşecekler
1. Sekmenin ve dünyanın adı.
3. ~~Oyun Salonu nerede?~~ → Oyunlar kapısı + salon televizyonu (2026-11-02 taslak, kullanıcı onayı bekleniyor).
4. Yılbaşına yetişmek için etkinlikler evden önce mi?
