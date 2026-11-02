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

## Netleşecekler
1. Sekmenin ve dünyanın adı.
3. Oyun Salonu: salondaki televizyondan açılıyor (taslak 2026-11-02). Ana menüde ayrıca kısayol olsun mu?
4. Yılbaşına yetişmek için etkinlikler evden önce mi?
