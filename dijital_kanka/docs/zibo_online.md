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
