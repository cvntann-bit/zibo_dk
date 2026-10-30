# Google Play politika güncellemeleri — Zibo'ya etkisi

Her "Geliştirici Güncellemesi" e-postası buraya özetlenir + Zibo'ya etkisi ölçülerek yazılır.
Ölçüm tabanı: `android/app/src/main/AndroidManifest.xml` izinleri, `targetSdk` (Flutter varsayılanı 36), `compileSdk 37`.

## 2026-10-29 e-postası (en az 30 gün uyum süresi)

### Zibo'yu ETKİLEMEYENLER (manifestten doğrulandı)
| Politika | Neden etkilemiyor |
|---|---|
| Yerel Ağ İzni (API 37+ beyan) | İzin yok. |
| Kişileri Yönetme İzni | Kişi izni yok. |
| AppFunctions API | Kullanılmıyor. |
| Konum (27 Oca 2027 zorunlu; API 37+'da konum düğmesi, FINE için beyan) | `ACCESS_COARSE/FINE_LOCATION` manifestte `tools:node="remove"` ile **siliniyor** (Appodeal adaptörleri ekliyordu). Yeni SDK/adaptör eklerken birleşik manifestte tekrar kontrol et. |
| Tüm Dosyalara Erişim (`MANAGE_EXTERNAL_STORAGE`) | Yok; yalnızca `READ_EXTERNAL_STORAGE` (maxSdk 32) + `WRITE_EXTERNAL_STORAGE` (maxSdk 29), fotoğraf seçimi sistem Photo Picker ile. |
| Erişilebilirlik API'si, SMS/Çağrı Kaydı, Kripto, Ödemeler (yapay zeka/ajan), Otomobil oyunları, Android XR | Kullanılmıyor. |
| Uygunluk kriterli abonelik indirimi (öğrenci planı vb.) | Zibo Pro/Pro+'ta böyle plan yok (`subscribe_model.md`). **İleride öğrenci/aile indirimi eklenirse** kriter, doğrulama ve sonrası fiyat açıkça yazılmalı. |

### DİKKAT / YAPILACAKLAR
- [ ] **Tüccar (trader) durumu beyanı — son tarih 1 ŞUBAT 2027** (e-postadaki "Kasım 2026" formun açılma zamanı; 2026-10-30'da
  Hesap ayrıntıları > Hakkınızda'da henüz görünmüyor). Yapılmazsa güncelleme engeli ve küresel kaldırma olabilir. Yol: Hesabı
  yönetme > Hesap ayrıntıları > Hakkınızda; tüccarsa her uygulama için Uygulama içeriği'nden onay + **Hizmet Şartları linki**.
  Google'ın ölçütleri düzenli IAP/abonelik/reklam gelirini örnek veriyor, yani Zibo tüccar örneklerine uyuyor. Yanlış "tüccar değil"
  beyanı hesap kapatma sebebi. **Kişisel hesapta tüccarsan telefon + ADRES 1 Mart 2027'den itibaren mağazada herkese görünür.**
  Kişisel hesapla devam mı, şirket hesabı mı: hukukçu/muhasebeciyle kullanıcı kararı. Kaynak: support.google.com/googleplay/android-developer/answer/17594752
- [ ] **Japonya yetkilendirmesi — son tarih 1 Aralık 2026**, yapılmazsa ödemeler **küresel** olarak bekletilir. Zibo Japonya'da
  yayında (178 ülke, 2026-10-30 doğrulandı). Yardım sayfası tetikleyici olarak "satış" diyor, eşik yok; salt dağıtımın yetip yetmediği
  açık değil. Davet e-posta / Play Console / Payments Center'a gelir: 2026-10-30'da Console ve Payments Center'da YOK, e-posta
  bakılmadı. İki parça: PSA = yalnızca "Continue" onayı; ISA (Japonya'ya satanlar) = ad, adres + son 5 yıla dair 2 evet/hayır soru.
  **Risk:** yeni satıcıda ilk Japon alıcıdan gelir geldiği an, ISA tamamlanmadıysa küresel ödeme durur. Seçenek: davet gelince
  doldurmak ya da Japonya'yı dağıtımdan çıkarmak (dil desteği yok). Kaynak: support.google.com/paymentscenter/answer/17595997
  **ERTELENDİ (kullanıcı, 2026-10-30):** "oradan kullanan yok", şimdilik işlem yapılmadı, Japonya yayında kaldı. Karar 1 Aralık'tan önce
  yeniden gözden geçirilecek; Japonya'dan satış gelirse ödeme durması riski açık (ölçülmedi, kullanıcı beyanı).
- [ ] **Uygulama kalitesi: bellek + kod optimizasyonu eşikleri — Şubat 2027 son tarih.** (Üretim panelinde 1.17.0 için "R8 optimizasyonu ile belleği ve performansı artırın" önerisi var, 2026-10-30.) DEX optimizasyonu %25
  tabanı için 2026-09-19'da reklam adaptörleri temizlendi (yalnızca AppLovin + Vungle). Bellek eşiği yeni →
  Play Console "Android vitals / Uygulama kalitesi" sayfasında Zibo'nun durumu ölçülecek.
- [ ] **Aileler İçin Kendi Kendini Onaylayan Reklam SDK Programı** artık yeni başvuru alıyor → Appodeal ve
  kullanılan adaptör sürümlerinin listede olup olmadığı SDK dizininden kontrol edilecek (çocuklar da kullanıyor;
  hedef kitle "herkes" kalsa da Aileler riski `zibo_home.md` / `zibo_online.md`'de not edildi).
- Fırsat: **Play Age Signals API** — yaşa göre özellik/içerik/güvenlik ayarı. Zibo Online (hazır ifadeler,
  ziyaret) ve reklam ayarları için ileride değerlendirilebilir; şimdilik iş yok.
- Hatırlatma: **Aldatıcı davranış — inceleme sürecini manipüle etmek yasak.** Faz S (yorum artırma) için zaten
  kural var: puan/yorum karşılığı ZC ödülü YOK (`project_review_boost`).
- `targetSdk` şu an 36. API 37'ye geçince yerel ağ / konum düğmesi kuralları devreye girer — o zaman bu
  dosyadaki "etkilemeyenler" tablosu tekrar doğrulanacak.

## Ödeme profili uyarıları (2026-10-30, Play Console'dan okundu)
Bildirim: "Ödeme hesabınızda ilgilenmeniz gereken acil bir sorun var". Ödeme profili sayfasında iki uyarı var, kazanç ₺62,65 (eşik ₺20 aşıldı):
- [ ] **Kırmızı — vergi bilgileri:** "Ödemenizin bir sonraki ödeme döngüsüne dahil edilmesi için lütfen vergi bilgilerinizi girin." Girilmezse ödeme yapılmaz.
- [ ] **Sarı — İrlanda vergi bilgileri:** Stopajın doğru tutarda kesilebilmesi için gönderilmesi isteniyor.
Yol: Hesabı yönetme > Ödeme profili > "Güncelle". **Kullanıcı kendisi doldurur** (vergi kimliği, kişisel bilgi). Payments Center'da üçüncü uyarı: Google Ads 303-794-1588 için yedek ödeme yöntemi. İrlanda stopajı için hangi formun gerektiği muhasebeciyle netleşmeli.
