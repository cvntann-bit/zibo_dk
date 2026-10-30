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

## Eşya kataloğu fikirleri (2026-10-29, kullanıcı: "yeni mobilyalar, yemekler, banyo süngeri vs vs")
Sürekli yeni içerik = sürekli geri dönme sebebi + coin harcama. Kostümler gibi **sezonluk/sınırlı** ürünler.
- **Banyo:** sünger çeşitleri (deniz yıldızı, ayıcık), sabun/şampuan kokuları (çilek, nane — köpük rengi değişir),
  banyo ördeği, köpük banyosu, kese, havlu desenleri, bornoz.
- **Mutfak / yemek:** meyveler, tatlılar (dondurma, kek), ev yemekleri, içecekler; **yöresel/ülkeye göre**
  (TR: simit, baklava; ES: churros, paella — üç dil pazarına uygun), özel gün yemekleri (doğum günü pastası).
- **Mobilya:** yatak, koltuk, halı, lamba, saksı bitkisi, akvaryum, raf, tablo (kullanıcının rozetleri çerçevede?),
  oyun konsolu köşesi.
- **Sezonluk:** Yılbaşı ağacı, Ramazan/bayram süsleri, Cadılar Bayramı balkabağı, yaz havuzu — sınırlı süre.
- Her ürünün nadirlik seviyesi (kostüm nadirlik sistemiyle aynı dil, 1.15.0).

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

## Materyal beyin fırtınası (2026-10-30, kullanıcı: "satın alacağım ya da açık kaynak var mı") — KARAR YOK
Öneri: karma yol + tek stil hattı. Hiçbir hazır paket Zibo'yu içermez; asıl risk stil uyumsuzluğu ve satılan ürünün lisansı.
- **Zibo pozları + oda arka planları:** kullanıcı üretir (onboarding'deki referanslı üretim). Kostüm çözümü gereği ~12–15 poz.
- **Mobilya:** Kenney Furniture Kit (CC0, 140 dosya) + Quaternius paketleri (CC0 listeleniyor) → 3B kaynak, Blender'da render.
- **Yemek/sünger/küçük eşya:** Microsoft Fluent Emoji 3D (MIT olduğu ikincil kaynaklarda yazıyor, LICENSE dosyası okunmalı; marka içeren emojiler yok) +
  Quaternius Low Poly Food Pack (CC0 listeleniyor). Simit, baklava, churros, paella gibi yöresel ürünler kendimiz üretilir.
- **Tek stil hattı:** her kaynak `tool/` betiğinden geçer: aynı kalın kontur, gölge, renk tonu, boyut, WebP.
- **Satın alma ikinci planda:** CraftPix ticari kullanım diyor (lisans sayfası okunmalı). Freepik/Vecteezy'de satılan uygulama içi ürün gri alan: Freepik
  sticker'ı uygulamada "secondary only" sayıyor, satılık eşya için KULLANILMAMALI. Unity Asset Store başka motorda serbest diyor ama ilan bazında kontrol şart.
- **Boyut (tahmin):** bugün `assets/images` 14 MB, AAB ~98 MB. Eşya başına ~20–40 KB WebP → 200 eşya ~4–8 MB. Sezonluk içerik ileride uzaktan indirilebilir.
- **Kural:** her dış varlık için kaynak, lisans, tarih bir kayıt dosyasında tutulur (CC0/MIT dahil); çocuk uygulaması: telifli karakter/marka içeren paket yok.
- **Pilot sonucu (2026-10-30):** `docs/home_materials_pilot/index.html` (+ `img/`, `LICENSES.md`), yayın: https://claude.ai/artifact/J1BQhbhncUWzbLnqpdph5Z
  25 eşya, gerçek Zibo ile banyo/mutfak, ham ve kontürlü. Ölçüm: eşya başına ortalama 5,3 KB (3–10 KB, 170–460 px WebP), yani önceki 20–40 KB tahmini fazlaydı; tablet boyutunda artar.
  Fluent MIT `LICENSE` dosyasından, Kenney CC0 paket `License.txt`'den doğrulandı. Quaternius CC0 yalnızca OpenGameArt sayfasından.
  İzlenim: küçük eşya + yemek = Fluent (256 px sınırı, yöresel ürün yok, MIT metni lisans ekranına eklenmeli); mobilya = Kenney başlangıç için yeterli ama köşeli; Quaternius ikinci planda.
  Öneri: C (Karma). Kullanıcı kararı bekleniyor.
- **Daha geniş kütüphane araştırması (2026-10-30, kullanıcı: "çok fazla şey yok"):** Fluent 1.595 emoji (repodan ölçüldü). Kenney 30.000+ (eski forum notu, CC0; All-in-1 paketi var).
  Poly Pizza ~10.000+ düşük poligonlu model (üçüncü taraf sayısı; model bazında CC0 veya CC-BY, yalnızca CC0 süzülmeli ya da atıf eklenmeli). 3dicons 120–1.440 (kaynaklar çelişiyor, CC0).
  Ücretli: Synty (ticari oyun serbest, düzenlenmiş varlık yeniden satılamaz, 2B render ve mobil için lisans metni okunmalı), Envato Elements (Envato'ya göre lisans abonelik bitse de geçerli; uygulama içi eşya netleşmeli), Icons8 3D Fluency (ücretli; uygulama lisansı doğrulanmadı).
  Hazır kütüphane simit/baklava ve Zibo'ya özel eşyayı çözmez: asıl sınırsız kaynak referanslı üretim. Üretim aracının ticari kullanım koşulları ayrıca kontrol edilmeli.

## Etkileşimli taslak (2026-10-29)
`docs/home_prototype/index.html` (+ `img/`), yayın: https://claude.ai/artifact/L3y1mxe5W3j5o1ieQi5ihD — banyo (sünger/sabun köpüğü, duş, havlu), mutfak (yemeği ağza sürükle, 2 bedava öğün, sahte reklamla +1), yatak (lamba → uyku, enerji), salon (mobilya al → yerleşir), ihtiyaç göstergeleri, 3 günlük görev + ödül sandığı. Emoji/CSS geçici görseller; Zibo gerçek pozlar. Kullanıcı geri bildirimi buraya yazılacak.
