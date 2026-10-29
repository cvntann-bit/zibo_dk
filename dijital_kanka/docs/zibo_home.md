# Zibo'nun Evi — besleme, bakım, günlük görevler (FİKİR AŞAMASI, 2026-10-29)

Durum: **BEKLEMEDE** — kullanıcının "otel işi" bitince başlanacak. Kod YOK.
İlgili: `docs/game_zibo.md` "Gelecek fikirler", `docs/unit_economics.md` (zarar etmemek), `docs/theme_new.md` (görsel dil).

## Kullanıcının istediği (2026-10-29)
- Zibo'yu besleme + günlük görevler.
- **Ev tasarımı**: odalar (banyo, mutfak, …), **mobilya tasarımı**, "en ince detaylarına kadar".
- Detaylı etkileşim animasyonları — örnek: *Zibo kirlendi → banyo yaptırırken sabunu üstüne sürtünce
  baloncuklar çıkıyor.*

## İlk teknik değerlendirme (Claude, öneri — kararlar kullanıcıyla verilecek)
- **Odalar:** her oda bir arka plan görseli + ayrı şeffaf PNG/WebP **mobilya parçaları** (yuvalara yerleşir) →
  mobilyalar Mağaza'da coin'le alınabilir / değiştirilebilir (yeni coin harcama alanı). Görsel dil mevcut
  "Çizgi Roman Çıkartması" temasıyla tutarlı olmalı.
- **Zibo:** mevcut 3B render poz görselleri. Yeni pozlar gerekir (kirli, ıslak, küvette, yemek yerken, uykulu,
  havluyla) — onboarding'deki gibi kullanıcı üretir ya da mevcut pozun üstüne katman (çamur lekeleri, köpük)
  bindirilir. Hareket: poz değişimi + esneme/zıplama dönüşümleri.
- **Banyo örneği uygulanabilir:** sabunu parmakla sürükle → sürtülen noktada köpük/baloncuk parçacıkları
  (Flutter `CustomPainter`), lekeler sürtüldükçe silinir → duş köpüğü durular → havlu kurular → Zibo mutlu pozu
  + ses. Mutfak: yemeği ağza sürükle → çiğneme pozu. Yatak odası: ışığı kapat → uyku.
- **İhtiyaç göstergeleri:** açlık / temizlik / enerji / mutluluk, zamanla yavaş düşer (`TrustedTimeProvider`).
  Çocuklar oynuyor → **ceza yok** (Zibo ölmez/hastalanmaz, sadece üzgün görünür).
- **Günlük görevler** bu döngüye bağlanır (ör. "Zibo'yu besle, banyo yaptır, su iç → ödül sandığı").
- **Teknoloji önerisi:** ev ekranı Flutter'da yerel (akıcılık + coin/kostüm/rozet entegrasyonu); oyunlar gibi
  WebView'a gerek yok. Karakter animasyonu için Rive ileride değerlendirilebilir.
- **Riskler:** AAB zaten ~98 MB → oda/mobilya görselleri WebP ve sıkı boyutlu olmalı; çocuklara açık
  hedefleme → Play Aileler politikası (pazarlama "herkes için" kalsın); yiyecek/sabun gibi tüketilebilirler
  coin ekonomisini etkiler → `unit_economics.md` ile dengelenmeli.

## Çalışma şekli
Oda oda: **taslak (mockup) → kullanıcı onayı → uygulama** (tema yeniden tasarımındaki gibi), her adım debug APK ile
telefonda/tablette denenir.

## Kullanıcıyla netleşecek sorular
1. Hangi odalar? (öneri ilk sürüm: Banyo + Mutfak; sonra Yatak odası, Salon, Bahçe)
2. Ev nerede açılır — Ana Sayfa'nın yerine mi, yeni bir sekme mi, Ana Sayfa'dan kapı mı?
3. Mobilyalar: sabit mi, kullanıcı kendi yerleştirebilsin mi (sürükle-bırak dekorasyon)?
4. Yeni Zibo pozlarını kim üretecek (kullanıcı mı, katmanlı çözüm mü)?
5. Yiyecek/sabun bedava mı, coin'le mi, Pro'ya özel ürün var mı?
