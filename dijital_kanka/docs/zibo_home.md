# Zibo'nun Evi — besleme, bakım, günlük görevler (FİKİR AŞAMASI, 2026-10-29)

Durum: **BEKLEMEDE** — kullanıcının "otel işi" bitince başlanacak. Kod YOK.
İlgili: `docs/game_zibo.md` "Gelecek fikirler", `docs/unit_economics.md` (zarar etmemek), `docs/theme_new.md` (görsel dil).

## Kullanıcının istediği (2026-10-29)
- Zibo'yu besleme + günlük görevler.
- **Ev tasarımı**: odalar (banyo, mutfak, …), **mobilya tasarımı**, "en ince detaylarına kadar".
- **Yemek tasarımları** ve kullanıcının deyişiyle "çok fazla şey" — kapsam BÜYÜK, fazlara bölünecek.
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

## Kostüm × poz patlaması — çözüm (2026-10-29)
Sorun (kullanıcı): ~27+ kostüm × her bakım pozu = 200+ görsel. Çözüm önerisi:
- **Evde Zibo kostümsüz ("ev hâli")** — banyoda zaten soyunur, mutfakta önlük/mama önlüğü, yatakta pijama.
  Bakım pozları YALNIZCA kostümsüz Zibo için üretilir → toplam ~12–15 görsel (kirli, ıslak/köpüklü, küvette,
  havlulu, yemek yerken ×2, tok/mutlu, aç/üzgün, uykulu, uyuyor, pijamalı…).
- **Efektler katman, kostümden bağımsız:** çamur lekeleri, köpük/baloncuk, su damlaları, buhar, kırıntılar,
  "zzz" — kodla çizilir ya da tek şeffaf görsel, her pozun üstüne biner.
- **Kostüm evde de görünür ama yeni görsel istemez:** Salonda giyili kostümüyle mevcut poz döngüsü
  (`costumePoses`) aynen kullanılır; **Gardırop** mobilyası sahip olunan kostümleri askıda gösterir
  (mevcut `Costume.imageAsset` küçültülür). "Banyoya gir → kostüm çıkar → çıkınca geri giyer" geçişi.
- Kostüme özel bakım pozu yalnızca istisna (ör. en çok satan 2–3 kostüm, analitik verisine göre, sonra).

## Gelir kurgusu — kullanıcı (2026-10-29): "her şeyden ZC harcatabiliriz, reklam izletebiliriz"
Ev = uygulamanın ana **coin harcama + ödüllü reklam** alanı olacak. Öneri:
- **ZC harcama:** yemekler (tüketilir), sabun/şampuan/köpük çeşitleri (tüketilir), mobilya, oda açma, duvar
  kâğıdı/zemin, banyo oyuncakları (ördek vb.), özel tabaklar; Pro'ya özel ürünler (`subscribe_model.md`).
- **Ödüllü reklam (isteğe bağlı, kullanıcı seçer):** "Buzdolabı boş → reklam izle, 1 yemek al", "günlük ödül
  sandığını 2 katına çıkar", "sabun bitti → reklamla 1 sabun", "yeni mobilyayı 24 saat dene" (kostüm denemesi gibi).
- **Kurallar (zarar etmemek + politika):**
  - Bakım etkileşiminin ORTASINDA zorunlu geçiş reklamı YOK (banyo/yemek animasyonunu bölmek = kötü deneyim +
    Play "rahatsız edici reklam" politikası). Geçiş reklamları yalnızca merkezi `InterstitialPacer` kurallarıyla.
  - Her zaman **bedava bir yol** olsun (günde birkaç ücretsiz yemek/sabun) — Zibo'nun "acı çekmesi" ancak
    ödeyerek bitiyormuş gibi görünmesin (çocuklar oynuyor → istismarcı görünür, mağaza yorumları + Aileler riski).
  - Fiyatlar ve reklam sıklığı `docs/unit_economics.md` ile hesaplanır; rakamlar Firestore `config/` ile
    uzaktan ayarlanabilir olmalı (oyunlardaki `config/games` gibi).

## Faz önerisi (büyük kapsam → küçük dilimler, her biri ayrı sürüm)
1. **Çekirdek:** ihtiyaç göstergeleri + Banyo (sabun/köpük/duş/havlu) — tek oda, döngü doğrulanır.
2. **Mutfak + yemekler:** yemek görselleri (meyve, tatlı, ev yemeği…), buzdolabı, çiğneme animasyonu, coin'le alım.
3. **Günlük görevler + ödül sandığı** (eve ve modüllere bağlı).
4. **Yatak odası** (uyku/enerji), sonra **Salon/Bahçe**.
5. **Mobilya mağazası + dekorasyon** (sürükle-bırak yerleştirme).
Görsel üretim ihtiyacı (oda arka planları, mobilyalar, yemekler, Zibo pozları) her fazdan ÖNCE listelenip
kullanıcıyla planlanır — en büyük iş yükü kod değil görseller.

## Çalışma şekli
Oda oda: **taslak (mockup) → kullanıcı onayı → uygulama** (tema yeniden tasarımındaki gibi), her adım debug APK ile
telefonda/tablette denenir.

## Kullanıcıyla netleşecek sorular
1. Hangi odalar? (öneri ilk sürüm: Banyo + Mutfak; sonra Yatak odası, Salon, Bahçe)
2. Ev nerede açılır — Ana Sayfa'nın yerine mi, yeni bir sekme mi, Ana Sayfa'dan kapı mı?
3. Mobilyalar: sabit mi, kullanıcı kendi yerleştirebilsin mi (sürükle-bırak dekorasyon)?
4. Yeni Zibo pozlarını kim üretecek (kullanıcı mı, katmanlı çözüm mü)?
5. Yiyecek/sabun bedava mı, coin'le mi, Pro'ya özel ürün var mı?
