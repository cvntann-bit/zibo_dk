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
- [ ] **Tüccar (trader) durumu beyanı — Kasım 2026'dan itibaren zorunlu.** Zibo IAP + abonelik satıyor →
  Play Console'da beyan edilecek (kullanıcı yapar; birlikte bakılabilir). Console'da uyarı çıkınca hemen.
- [ ] **Japonya yetkilendirmesi — son tarih 1 Aralık 2026**, yapılmazsa ödemeler **küresel** olarak bekletilir.
  Zibo Japonya'da satış yapıyor mu (ülke/bölge listesi) Play Console'da kontrol edilecek; yapıyorsa form
  doldurulacak, gerekmiyorsa Japonya'yı dağıtımdan çıkarmak da seçenek (dil desteği yok: TR/EN/ES).
- [ ] **Uygulama kalitesi: bellek + kod optimizasyonu eşikleri — Şubat 2027 son tarih.** DEX optimizasyonu %25
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
Yol: Hesabı yönetme > Ödeme profili > "Güncelle". **Kullanıcı kendisi doldurur** (vergi kimliği, kişisel bilgi). İrlanda stopajı için hangi formun gerektiği muhasebeciyle netleşmeli.
