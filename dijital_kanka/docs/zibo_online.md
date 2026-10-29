# Zibo Online — sosyal/çok oyunculu (UZUN VADELİ FİKİR, 2026-10-29)

Durum: kullanıcı "ilerleyen seviyelerde Zibo'yu online yapmayı düşünüyorum". Sıra: Zibo'nun Evi
(`docs/zibo_home.md`) → Admin paneli (`docs/admin_panel.md`) → bu. Kod YOK. Kapsam kullanıcıyla netleşecek.

## Olası özellikler (öneri, güvenli → riskli sırasıyla)
1. **Sıralamalar** (haftalık oyun puanı, seri) — `game_zibo.md` Faz 8 zaten planlı.
2. **Arkadaş kodu** ile arkadaş ekleme → arkadaşın **evini ziyaret et**, Zibo'suna kalp/hediye bırak, ona yemek ver.
3. **Hediyeleşme** (yemek, mobilya) — coin harcama + geri dönme sebebi.
4. **Ortak challenge'lar** (arkadaşlarla/herkesle haftalık hedef; admin panelinden açılır).
5. **Gerçek zamanlı mini oyun düellosu** (2048/Kule yarışı) — sunucu gerektirir, en pahalı.
6. **Serbest sohbet** — ÖNERİLMEZ (aşağıya bak).

## Kullanıcı seçimi (2026-10-29): 1 + 2 + 3 + 4 (sıralama, ev ziyareti, hediyeleşme, ortak challenge). Düello/sohbet YOK.

## Gider tahmini (2026-10-29 — TAHMİN, ölçüm değil; taban: DAU ~200, 24 sa 69–80K okuma/23–25K yazma, çoğu cron)
- **Ayrı sunucu GEREKMEZ.** Firestore + güvenlik kuralları yeter; arka plan işleri (haftalık sıralama hesabı,
  challenge kapanışı, hediye doğrulama) → GitHub Actions cron (mevcut düzen) ya da Cloud Functions ücretsiz kotası
  (ayda 2M çağrı). Ayrı sunucu yalnızca gerçek zamanlı düelloda gerekirdi (seçilmedi).
- Kullanıcı başı ek yük varsayımı: günde ~50 okuma + ~10 yazma (sıralama 1 belge; ev ziyareti 2–3 belge/ziyaret ×
  ~10; hediye 1 yazma + 1 okuma; challenge config 1 okuma + ilerleme yazması).
  | DAU | Ek okuma/gün | Ek yazma/gün | Aylık ek maliyet (tahmin) |
  |---|---|---|---|
  | 200 (bugün) | ~10K | ~2K | ~0 (Blaze ücretsiz kotası: 50K okuma / 20K yazma günlük) |
  | 1.000 | ~50K | ~10K | ~0–1 $ |
  | 10.000 | ~500K | ~100K | ~10–15 $ (~₺400–500) → DAU başı ~0,0013 $/ay |
- Tasarım kuralları: sıralama **önceden hesaplanmış tek belge** (herkes kendi puanını taramaz), ev görüntüsü tek
  "vitrin" belgesi, liste sayfaları sayfalı; Blaze bütçe uyarısı (₺300/ay) zaten kurulu.
- Asıl dikkat: **hile/coin basma** — hediye coin'i gönderenden düşmeden alıcıya geçmemeli → hediye doğrulama
  sunucu tarafında (Function/cron), istemciye güvenilmez.

## Riskler / kurallar
- **Çocuklar kullanıyor:** serbest yazışma = çocuk güvenliği, moderasyon yükü, Play Aileler/COPPA/KVKK riski.
  → Sohbet yerine **hazır ifadeler ve emoji tepkiler** ("Evin çok güzel! 🏡"), kullanıcı adı yerine Zibo adı +
  rastgele etiket, şikâyet/engelle düğmesi, profil fotoğrafı paylaşımı YOK.
- **Hesap:** çoğu kullanıcı anonim → arkadaşlık için anonim hesap yeterli (arkadaş kodu), ama veri kaybı riskine karşı
  Google bağlamayı teşvik et.
- **Maliyet:** her ziyaret/sıralama Firestore okuması → `unit_economics.md` ile hesapla; gerçek zamanlı düello için
  Cloud Functions/sunucu (Blaze bütçe koruması kurulu, deploy öncesi maliyet kontrolü).
- **Hile:** sıralama puanları sunucuda doğrulanmalı (oyunlarda `cap` gibi).

## Netleşecek
- "Online"dan kastın ne: arkadaş evini ziyaret mi, birlikte oyun mu, sıralama mı, sohbet mi?
