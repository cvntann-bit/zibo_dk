# Zibo — Tanıtım Reeli (özellikler + kostümler)

`zibo_promo.html` — tek dosya, self-contained (~2,7 MB), sıfır dış kaynak. **Ekran kaydedip
CapCut'a atman için ham görüntü.** Ses YOK (seslendirmeyi sen CapCut'ta ekleyeceksin).

## İçerik / akış (~45 sn, otomatik oynar)

1. Intro — logo + "Zibo" + "Küçük adımlar, büyük değişim" (3 sn)
2. 9 özellik kartı (Hedef Takibi, Su Takibi, Şükran Günlüğü, Ruh Hali Takibi, Rüya Günlüğü,
   Manifest Günlüğü, Para ve Birikim, Odak Sayacı, Zibo Coin & Rozetler) — her biri ~2,2 sn
3. "Zibo'yu tarzına göre giydir" geçiş kartı (2 sn)
4. 10 kostüm — Hippi, Asker, Punk, Samuray, Gladyatör, Korsan, Astronot, Kral, Altın, Elmas
   Kaplama — her biri ~1,3 sn, spot ışığı + isim etiketiyle
5. "40+ kostüm ve tema" — mini kostüm yelpazesi (2,6 sn)
6. Son kart — logo + "Zibo — Dijital Kanka" + Play rozeti + **ÜCRETSİZ İNDİR** — burada durur (döngü yok)

Üstte ince bir ilerleme çubuğu var (Instagram story tarzı).

## Kontroller

- **Ekranın herhangi bir yerine dokun/tıkla** → o anki sahneyi atlayıp bir sonrakine geçer. Hiç
  dokunmazsan otomatik akar. İstersen tamamen ELLE ilerletip kendi konuşma temponla kayıt yapabilirsin.
- **"R" tuşu** → baştan başlatır (yeniden kayıt denemek için sayfayı yeniden yüklemene gerek yok).

## Nasıl kaydedilir

**En iyi kalite: kendi telefonunda.** `zibo_promo.html`'i telefonuna aktar (kendine e-posta/WhatsApp
ile gönder), telefon tarayıcısında aç, tam ekran yap, **telefonun kendi ekran kaydediciyle** (Android
Ayarlar > Ekran kaydedici) baştan sona kaydet. Native 9:16 çözünürlük, düzenlenebilir en temiz sonuç.

Masaüstünde de olur: tarayıcı penceresini dikey/telefon oranına (ör. 420×900) küçült, Windows'un
kendi ekran kaydediciyle (Win+Alt+R veya Xbox Game Bar) kaydet.

Kayıttan sonra **CapCut'a at** → seslendirme ekle → hız/kesme ile düzenle → gerekirse alt yazı ekle.

## Yeniden üretme / metni değiştirme

```
cd dijital_kanka
dart run tool/prep_promo_assets.dart    # görselleri küçültür -> tool/promo_assets.txt
dart run tool/build_promo_video.dart    # tool/promo_template.html + assets -> promo_video/zibo_promo.html
```

Özellik metinlerini/sırasını, kostüm seçimini veya sahne sürelerini değiştirmek için
`dijital_kanka/tool/promo_template.html`'deki `FEATURES` / `COSTUMES` / `buildScenes()` dizilerini
düzenle, sonra `build_promo_video.dart`'ı tekrar çalıştır.

## Not

Bu dosya `playable_ad/zibo_playable.html`'den FARKLI bir amaç için: o bir REKLAM AĞINA yüklenen
etkileşimli (playable) reklam; bu ise sadece ekran kaydı için otomatik oynayan bir tanıtım şeridi —
hiçbir ağa yüklenmiyor, sana özel ham materyal.
