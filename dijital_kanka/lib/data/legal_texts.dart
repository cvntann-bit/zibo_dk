/// Gizlilik Politikası + Kullanım Koşulları — `zibo_messages.dart` gibi
/// diğer büyük içerik havuzlarıyla AYNI gerekçeyle ARB'YE DEĞİL, ayrı bir
/// veri dosyasına konuldu (bkz. CLAUDE.md "Yerelleştirme" bölümündeki
/// "uzun serbest metinler için ARB placeholder mekanizması gereksiz
/// dolaylılık eklerdi" kuralı).
///
/// **Bilinçli sınırlama — yalnızca TÜRKÇE, uygulama diline göre
/// DEĞİŞMİYOR.** Bu, diğer içerik havuzlarından (zibo_messages.dart vb.)
/// FARKLI bir karar: hukuki bir belgenin makine/hızlı çeviriyle üç dile
/// çevrilmesi, çevirideki bir belirsizliğin/hatanın GERÇEK hukuki sonuç
/// doğurabileceği bir alan — bu yüzden şimdilik TEK, yetkili bir Türkçe
/// sürüm tutuluyor (uygulamanın asıl pazarı/dili). EN/ES çevirisi
/// istenirse profesyonel bir çeviri turu olarak AYRICA ele alınmalı.
///
/// **KRİTİK — bu metin bir taslak, nihai hukuki danışmanlık DEĞİL.**
/// İçerik, uygulamanın GERÇEKTEN ne yaptığına (bkz. CLAUDE.md — Firebase
/// Auth/Firestore/Analytics/Messaging, AdMob, Google Sign-In, yerel
/// fotoğraf depolama) birebir dayanarak yazıldı. Veri Sorumlusu/Fikri
/// Mülkiyet maddelerindeki kimlik bilgisi (Mehmet Can Tan) kullanıcının
/// KENDİSİ tarafından AÇIKÇA verildi — asistan tarafından UYDURULMADI.
library;

const String privacyPolicyTr = '''
Son güncelleme: 21 Ağustos 2026

Bu Gizlilik Politikası, Zibo mobil uygulamasını ("Zibo", "uygulama") kullanırken hangi verilerin toplandığını, nasıl kullanıldığını ve haklarınızın neler olduğunu açıklar.

1. Veri Sorumlusu

Zibo uygulamasının geliştiricisi Mehmet Can Tan ("biz")'dir. Sorularınız için contact@getzibo.com adresinden bize ulaşabilirsiniz.

2. Topladığımız Veriler

a) Otomatik olarak oluşturulan veriler
Uygulamayı ilk açtığınızda, Firebase Authentication üzerinden isimsiz/anonim bir kullanıcı kimliği oluşturulur. Bu kimlik, hiçbir kişisel bilgi içermez ve yalnızca verilerinizi cihazınızda ve bulutta eşleştirmek için kullanılır.

b) Google ile bağlanırsanız
İsteğe bağlı olarak Google hesabınızı Zibo'ya bağlayabilirsiniz. Bu durumda Google hesabınızın e-posta adresi, verilerinizin (Zibo Coin bakiyeniz, hedefleriniz, ilerlemeniz) cihaz değişikliğinde kaybolmaması amacıyla saklanır.

c) Uygulama içinde girdiğiniz veriler
- İsim/takma ad ve hitap tercihiniz
- Profil fotoğrafınız (yalnızca CİHAZINIZDA saklanır, sunucularımıza YÜKLENMEZ — yalnızca dosyanın cihazdaki konumu senkronize edilir)
- Hedefleriniz, alışkanlık takip kayıtlarınız, para/birikim kayıtlarınız
- Şükran günlüğü, ruh hali takibi, rüya günlüğü ve manifest günlüğü girdileriniz (bunlar kişisel/özel içerik olabilir — yalnızca sizin görebilmeniz için saklanır, üçüncü taraflarla PAYLAŞILMAZ, reklam/analiz amacıyla KULLANILMAZ)
- Satın aldığınız/kazandığınız kostüm, tema ve Zibo Coin bilgileriniz

d) Otomatik teknik veriler
- Firebase Analytics aracılığıyla genel kullanım istatistikleri (hangi özelliklerin kullanıldığı, oturum süresi gibi anonimleştirilmiş/toplulaştırılmış veriler)
- Bildirim gönderebilmek için bir cihaz belirteci (FCM token)
- Google AdMob ve benzeri reklam ortakları aracılığıyla gösterilen reklamlarla ilgili reklam kimliği ve etkileşim verileri (bkz. Madde 5)

3. Verileri Neden Kullanıyoruz

- Uygulamanın temel işlevlerini (ilerlemenizin kaydedilmesi, cihazlar arası senkronizasyon) sağlamak
- Uygulamayı iyileştirmek için kullanım eğilimlerini anlamak
- Reklam göstermek (uygulamanın bir kısmı reklam destekli sunulmaktadır)
- Önemli hatırlatmalar için bildirim göndermek

Verilerinizi hiçbir zaman satmıyoruz veya pazarlama amacıyla üçüncü taraflara PAYLAŞMIYORUZ.

4. Verilerin Saklandığı ve İşlendiği Yerler

Verileriniz Google'ın Firebase altyapısında (Cloud Firestore, Authentication) saklanır. Her kullanıcı yalnızca KENDİ verisine erişebilecek şekilde güvenlik kuralları uygulanmıştır. Google'ın kendi gizlilik uygulamaları için: https://policies.google.com/privacy

5. Reklamlar

Uygulamada Google AdMob ve benzeri reklam ortakları aracılığıyla reklamlar gösterilir. Bu ortaklar, reklam kişiselleştirmesi için cihazınızın reklam kimliği gibi verileri kullanabilir. Google'ın reklam politikaları hakkında bilgi için: https://policies.google.com/technologies/ads

6. Verilerinizin Saklanma Süresi

Verileriniz, hesabınız aktif olduğu sürece saklanır. Hesabınızın silinmesini talep ederseniz (bkz. Madde 8), verileriniz makul bir süre içinde sistemlerimizden kalıcı olarak silinir.

7. Çocukların Gizliliği

Zibo, genel kullanıcı kitlesine yöneliktir ve bilerek 13 yaşından küçük çocuklardan veri toplamaz. 13 yaşından küçük bir çocuğun bize veri sağladığını düşünüyorsanız lütfen bizimle iletişime geçin, verileri derhal sileriz.

8. Haklarınız

6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK") ve ilgili mevzuat kapsamında; verilerinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, verilerinizin düzeltilmesini veya silinmesini isteme haklarına sahipsiniz. Bu haklarınızı kullanmak için contact@getzibo.com adresinden bizimle iletişime geçebilirsiniz.

9. Değişiklikler

Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içinde sizi bilgilendireceğiz.

10. İletişim

Sorularınız için: contact@getzibo.com
''';

const String termsOfServiceTr = '''
Son güncelleme: 21 Ağustos 2026

Bu Kullanım Koşulları, Zibo mobil uygulamasını ("Zibo", "uygulama") kullanımınızı düzenler. Uygulamayı indirip kullanarak bu koşulları kabul etmiş sayılırsınız.

1. Hizmetin Tanımı

Zibo; hedef takibi, alışkanlık oluşturma, günlük tutma (şükran, ruh hali, rüya, manifest) ve kişisel finans takibi gibi özellikler sunan bir kişisel gelişim uygulamasıdır. Uygulama, "Zibo" adlı bir maskotla desteklenen oyunlaştırılmış bir deneyim sunar.

2. Hesabınız

Uygulamayı kullanmaya başladığınızda otomatik olarak isimsiz bir hesap oluşturulur. İsteğe bağlı olarak bu hesabı bir Google hesabına bağlayarak verilerinizi başka bir cihazda kurtarabilirsiniz. Hesabınızın güvenliğinden (bağladığınız Google hesabının güvenliği dahil) siz sorumlusunuz.

3. Zibo Coin — Sanal Para Birimi

Zibo Coin, yalnızca Zibo uygulaması İÇİNDE kullanılabilen, GERÇEK PARASAL DEĞERİ OLMAYAN sanal bir birimdir.
- Zibo Coin nakde ÇEVRİLEMEZ, başka bir kullanıcıya AKTARILAMAZ ve uygulama dışında hiçbir şekilde KULLANILAMAZ.
- Zibo Coin uygulama içi görevler tamamlanarak, reklam izlenerek veya (mevcutsa) gerçek para karşılığında satın alınarak kazanılabilir.
- Hesabınızın sonlandırılması durumunda biriken Zibo Coin'ler ve diğer uygulama içi öğeler herhangi bir bedel ödenmeksizin geçersiz hale gelir.

4. Uygulama İçi Satın Almalar

Uygulama içinde gerçek para karşılığında Zibo Coin paketleri sunulması planlanmaktadır. Bu tür satın almalar, Google Play'in kendi Hizmet Şartları ve ödeme politikalarına tabidir. Satın alınan Zibo Coin'ler için iade politikası Google Play'in standart politikalarını takip eder.

5. Kullanıcı İçeriği

Günlüklerinize (şükran, ruh hali, rüya, manifest) yazdığınız metinler ve yüklediğiniz fotoğraflar size aittir. Bu içerikleri yalnızca size göstermek ve uygulama işlevselliğini (istatistikleriniz, geçmişiniz) sağlamak amacıyla saklarız; reklam veya pazarlama amacıyla İNCELEMEYİZ ya da KULLANMAYIZ.

6. Yasaklı Kullanımlar

Aşağıdaki davranışlar kesinlikle yasaktır:
- Uygulamayı tersine mühendislik yapmak veya değiştirilmiş (mod) sürümlerini kullanmak
- Coin ekonomisini istismar etmeye yönelik hileli yöntemler kullanmak
- Uygulamayı yasa dışı bir amaçla kullanmak
- Başka kullanıcıların hesaplarına yetkisiz erişim sağlamaya çalışmak

Bu koşulları ihlal eden hesaplar önceden bildirim yapılmaksızın askıya alınabilir veya sonlandırılabilir.

7. Fikri Mülkiyet

Zibo uygulaması, "Zibo" karakteri/maskotu, logosu, tasarımı ve tüm görsel/işitsel içerikleri Mehmet Can Tan'a aittir ve telif hakkı ile korunmaktadır. Uygulamayı kullanmanız, size bu içerikler üzerinde hiçbir mülkiyet hakkı vermez.

8. Garanti Reddi

Uygulama "olduğu gibi" ve "mevcut olduğu şekliyle" sunulmaktadır. Uygulamanın kesintisiz, hatasız çalışacağına dair hiçbir garanti verilmemektedir.

9. Sorumluluğun Sınırlandırılması

Yasaların izin verdiği azami ölçüde, uygulamanın kullanımından veya kullanılamamasından kaynaklanan hiçbir doğrudan veya dolaylı zarardan sorumlu tutulamayız.

10. Koşullardaki Değişiklikler

Bu koşulları zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içinde sizi bilgilendireceğiz. Değişikliklerden sonra uygulamayı kullanmaya devam etmeniz, güncellenmiş koşulları kabul ettiğiniz anlamına gelir.

11. Uygulanacak Hukuk

Bu koşullar Türkiye Cumhuriyeti kanunlarına tabidir.

12. İletişim

Sorularınız için: contact@getzibo.com
''';
