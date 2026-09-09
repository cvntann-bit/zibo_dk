/// Gizlilik Politikası + Kullanım Koşulları — `zibo_messages.dart` gibi
/// diğer büyük içerik havuzlarıyla AYNI gerekçeyle ARB'YE DEĞİL, ayrı bir
/// veri dosyasına konuldu (bkz. CLAUDE.md "Yerelleştirme" bölümündeki
/// "uzun serbest metinler için ARB placeholder mekanizması gereksiz
/// dolaylılık eklerdi" kuralı).
///
/// **2026 güncellemesi — kullanıcı isteğiyle EN/ES çevirisi eklendi,
/// aşağıdaki "yalnızca Türkçe" kararı GERİ ÇEVRİLDİ.** Önceki karar
/// (bilerek, hukuki çeviri belirsizliğinin gerçek sonuç doğurabileceği
/// gerekçesiyle) TEK bir Türkçe sürüm tutuyordu — kullanıcı bu turda
/// AÇIKÇA "uygulama dili İngilizce/İspanyolca'ya değiştirilse bile bu
/// sayfalar hep Türkçe kalıyor, dil sistemine bağla" isteğiyle bu kararı
/// geri çevirdi. Çeviriler `zibo_messages.dart` gibi diğer içerik
/// havuzlarının "ton uyarlaması" (birebir değil, o dilde doğal duracak
/// şekilde) YAKLAŞIMINI İZLEMİYOR — bu bir hukuki/bilgilendirici belge
/// olduğu için çeviri SADAKATİ önceliklendirildi (madde madde, anlamca
/// birebir). Türkiye'ye özgü unsurlar (KVKK referansı gibi) EN/ES
/// sürümlerinde de KORUNDU — "Uygulanacak Hukuk" maddesi zaten dilden
/// bağımsız olarak Türk hukukunun geçerli olduğunu söylüyor, dolayısıyla
/// İngilizce/İspanyolca okuyucuya da bu AÇIKÇA belirtiliyor (genel bir
/// ifadeyle "silinip" gizlenmedi).
///
/// **KRİTİK — bu metin bir taslak, nihai hukuki danışmanlık DEĞİL.**
/// İçerik, uygulamanın GERÇEKTEN ne yaptığına (bkz. CLAUDE.md — Firebase
/// Auth/Firestore/Analytics/Messaging, AdMob, Google Sign-In, yerel
/// fotoğraf depolama) birebir dayanarak yazıldı. Veri Sorumlusu/Fikri
/// Mülkiyet maddelerindeki kimlik bilgisi (Mehmet Can Tan) kullanıcının
/// KENDİSİ tarafından AÇIKÇA verildi — asistan tarafından UYDURULMADI.
library;

import 'package:flutter/widgets.dart';

const String privacyPolicyTr = '''
Son güncelleme: 9 Eylül 2026

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

Uygulamada Appodeal mediasyon platformu ve onun reklam ortakları (AppLovin, Unity Ads, Vungle, BidMachine ve benzerleri) aracılığıyla reklamlar gösterilir. Bu ortaklar, reklam sunumu ve kişiselleştirmesi için cihazınızın reklam kimliği (Advertising ID), IP adresi ve uygulama kullanım verileri gibi bilgileri işleyebilir. Avrupa Ekonomik Alanı, Birleşik Krallık ve düzenlemeye tabi bazı bölgelerdeki kullanıcılara, reklam verisi işlenmeden önce bir rıza (consent) ekranı gösterilir. Appodeal'in gizlilik politikası için: https://www.appodeal.com/privacy-policy/ — Google'ın reklam politikaları için: https://policies.google.com/technologies/ads

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

const String privacyPolicyEn = '''
Last updated: September 9, 2026

This Privacy Policy explains what data is collected, how it is used, and what rights you have when using the Zibo mobile app ("Zibo", "the app").

1. Data Controller

The developer of the Zibo app is Mehmet Can Tan ("we", "us"). You can reach us with any questions at contact@getzibo.com.

2. Data We Collect

a) Automatically generated data
When you first open the app, an anonymous user identity is created via Firebase Authentication. This identity does not contain any personal information and is used only to match your data across your device and the cloud.

b) If you link your Google account
You may optionally link your Google account to Zibo. In this case, your Google account's email address is stored so your data (your Zibo Coin balance, goals, and progress) is not lost if you switch devices.

c) Data you enter within the app
- Your name/nickname and how you'd like to be addressed
- Your profile photo (stored ONLY ON YOUR DEVICE, never UPLOADED to our servers — only the file's location on your device is synced)
- Your goals, habit-tracking records, and money/savings entries
- Your gratitude journal, mood tracking, dream journal, and manifestation journal entries (these may be personal/private content — stored solely so you can see them, NEVER SHARED with third parties, NEVER USED for advertising or analytics)
- Your purchased/earned costumes, themes, and Zibo Coin information

d) Automatic technical data
- General usage statistics via Firebase Analytics (anonymized/aggregated data such as which features are used and session length)
- A device token (FCM token) so we can send notifications
- Advertising ID and interaction data related to ads shown through Google AdMob and similar ad partners (see Section 5)

3. Why We Use Your Data

- To provide the app's core functionality (saving your progress, syncing across devices)
- To understand usage trends so we can improve the app
- To show ads (part of the app is ad-supported)
- To send notifications for important reminders

We never sell your data or share it with third parties for marketing purposes.

4. Where Your Data Is Stored and Processed

Your data is stored on Google's Firebase infrastructure (Cloud Firestore, Authentication). Security rules are enforced so that each user can only access their OWN data. For Google's own privacy practices, see: https://policies.google.com/privacy

5. Advertising

The app displays ads through the Appodeal mediation platform and its ad partners (AppLovin, Unity Ads, Vungle, BidMachine and others). These partners may process data such as your device's Advertising ID, IP address and app usage information to deliver and personalize ads. Users in the European Economic Area, the United Kingdom and certain regulated regions are shown a consent screen before any advertising data is processed. For Appodeal's privacy policy, see: https://www.appodeal.com/privacy-policy/ — For Google's advertising policies, see: https://policies.google.com/technologies/ads

6. How Long We Keep Your Data

Your data is kept for as long as your account is active. If you request that your account be deleted (see Section 8), your data is permanently deleted from our systems within a reasonable period.

7. Children's Privacy

Zibo is intended for a general audience and does not knowingly collect data from children under 13. If you believe a child under 13 has provided us with data, please contact us and we will delete it immediately.

8. Your Rights

Under Turkey's Law on the Protection of Personal Data No. 6698 ("KVKK") and applicable data protection regulations, you have the right to learn whether your data is being processed, to request information about such processing if it is, and to request that your data be corrected or deleted. You can exercise these rights by contacting us at contact@getzibo.com.

9. Changes

We may update this policy from time to time. We will notify you within the app of any significant changes.

10. Contact

For questions: contact@getzibo.com
''';

const String privacyPolicyEs = '''
Última actualización: 9 de septiembre de 2026

Esta Política de Privacidad explica qué datos se recopilan, cómo se utilizan y cuáles son tus derechos al usar la aplicación móvil Zibo ("Zibo", "la aplicación").

1. Responsable del Tratamiento

El desarrollador de la aplicación Zibo es Mehmet Can Tan ("nosotros"). Puedes contactarnos para cualquier pregunta en contact@getzibo.com.

2. Datos que Recopilamos

a) Datos generados automáticamente
Al abrir la aplicación por primera vez, se crea una identidad de usuario anónima a través de Firebase Authentication. Esta identidad no contiene ninguna información personal y se utiliza únicamente para sincronizar tus datos entre tu dispositivo y la nube.

b) Si vinculas tu cuenta de Google
Puedes vincular opcionalmente tu cuenta de Google a Zibo. En este caso, se almacena la dirección de correo electrónico de tu cuenta de Google para que tus datos (tu saldo de Zibo Coin, tus objetivos, tu progreso) no se pierdan si cambias de dispositivo.

c) Datos que introduces dentro de la aplicación
- Tu nombre/apodo y tu preferencia de trato
- Tu foto de perfil (almacenada SOLO EN TU DISPOSITIVO, nunca SUBIDA a nuestros servidores — únicamente se sincroniza la ubicación del archivo en tu dispositivo)
- Tus objetivos, registros de seguimiento de hábitos y registros de dinero/ahorros
- Tus entradas del diario de gratitud, seguimiento del estado de ánimo, diario de sueños y diario de manifestación (este contenido puede ser personal/privado — se almacena únicamente para que tú puedas verlo, NUNCA SE COMPARTE con terceros, NUNCA SE USA con fines publicitarios o analíticos)
- La información de los disfraces, temas y Zibo Coin que compres o ganes

d) Datos técnicos automáticos
- Estadísticas de uso general a través de Firebase Analytics (datos anonimizados/agregados como qué funciones se usan y la duración de la sesión)
- Un identificador de dispositivo (token FCM) para poder enviarte notificaciones
- El identificador publicitario y datos de interacción relacionados con los anuncios mostrados a través de Google AdMob y socios publicitarios similares (ver Sección 5)

3. Por Qué Usamos tus Datos

- Para ofrecer las funciones principales de la aplicación (guardar tu progreso, sincronizar entre dispositivos)
- Para entender las tendencias de uso y así mejorar la aplicación
- Para mostrar anuncios (parte de la aplicación se ofrece con soporte publicitario)
- Para enviar notificaciones sobre recordatorios importantes

Nunca vendemos tus datos ni los compartimos con terceros con fines de marketing.

4. Dónde se Almacenan y Procesan tus Datos

Tus datos se almacenan en la infraestructura Firebase de Google (Cloud Firestore, Authentication). Se aplican reglas de seguridad para que cada usuario solo pueda acceder a SUS PROPIOS datos. Para conocer las prácticas de privacidad de Google: https://policies.google.com/privacy

5. Publicidad

La aplicación muestra anuncios a través de la plataforma de mediación Appodeal y sus socios publicitarios (AppLovin, Unity Ads, Vungle, BidMachine y otros). Estos socios pueden procesar datos como el identificador publicitario (Advertising ID) de tu dispositivo, tu dirección IP y datos de uso de la aplicación para mostrar y personalizar los anuncios. A los usuarios del Espacio Económico Europeo, el Reino Unido y ciertas regiones reguladas se les muestra una pantalla de consentimiento antes de procesar cualquier dato publicitario. Para la política de privacidad de Appodeal: https://www.appodeal.com/privacy-policy/ — Para las políticas publicitarias de Google: https://policies.google.com/technologies/ads

6. Cuánto Tiempo Conservamos tus Datos

Tus datos se conservan mientras tu cuenta esté activa. Si solicitas la eliminación de tu cuenta (ver Sección 8), tus datos se eliminarán de forma permanente de nuestros sistemas en un plazo razonable.

7. Privacidad de los Menores

Zibo está dirigida a un público general y no recopila conscientemente datos de menores de 13 años. Si crees que un menor de 13 años nos ha proporcionado datos, contáctanos y los eliminaremos de inmediato.

8. Tus Derechos

De acuerdo con la Ley de Protección de Datos Personales de Turquía N.º 6698 ("KVKK") y la normativa de protección de datos aplicable, tienes derecho a saber si tus datos están siendo procesados, a solicitar información sobre dicho procesamiento en caso afirmativo, y a solicitar la corrección o eliminación de tus datos. Puedes ejercer estos derechos contactándonos en contact@getzibo.com.

9. Cambios

Podemos actualizar esta política de vez en cuando. Te notificaremos dentro de la aplicación sobre cualquier cambio importante.

10. Contacto

Para preguntas: contact@getzibo.com
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

const String termsOfServiceEn = '''
Last updated: August 21, 2026

These Terms of Service govern your use of the Zibo mobile app ("Zibo", "the app"). By downloading and using the app, you agree to these terms.

1. Description of the Service

Zibo is a personal-development app offering features such as goal tracking, habit building, journaling (gratitude, mood, dreams, manifestation), and personal finance tracking. The app offers a gamified experience supported by a mascot character called "Zibo".

2. Your Account

An anonymous account is automatically created when you start using the app. You may optionally link this account to a Google account so you can recover your data on another device. You are responsible for the security of your account, including the security of any Google account you link to it.

3. Zibo Coin — Virtual Currency

Zibo Coin is a virtual unit that can only be used WITHIN the Zibo app and has NO REAL MONETARY VALUE.
- Zibo Coin CANNOT be converted to cash, CANNOT be transferred to another user, and CANNOT be used in any way outside the app.
- Zibo Coin can be earned by completing in-app tasks, watching ads, or (where available) purchasing it with real money.
- If your account is terminated, any accumulated Zibo Coin and other in-app items become void without any compensation.

4. In-App Purchases

The app is planned to offer Zibo Coin packages for purchase with real money. Such purchases are subject to Google Play's own Terms of Service and payment policies. The refund policy for purchased Zibo Coin follows Google Play's standard policies.

5. User Content

The text you write in your journals (gratitude, mood, dreams, manifestation) and the photos you upload belong to you. We store this content only to show it to you and to provide app functionality (your statistics, your history); we do NOT review or use it for advertising or marketing purposes.

6. Prohibited Uses

The following actions are strictly prohibited:
- Reverse-engineering the app or using modified ("mod") versions of it
- Using fraudulent methods to exploit the coin economy
- Using the app for any unlawful purpose
- Attempting to gain unauthorized access to other users' accounts

Accounts that violate these terms may be suspended or terminated without prior notice.

7. Intellectual Property

The Zibo app, the "Zibo" character/mascot, its logo, design, and all visual/audio content belong to Mehmet Can Tan and are protected by copyright. Using the app does not grant you any ownership rights over this content.

8. Disclaimer of Warranty

The app is provided "as is" and "as available". No warranty is given that the app will function uninterrupted or error-free.

9. Limitation of Liability

To the maximum extent permitted by law, we cannot be held liable for any direct or indirect damages arising from your use of, or inability to use, the app.

10. Changes to These Terms

We may update these terms from time to time. We will notify you within the app of any significant changes. Continuing to use the app after such changes means you accept the updated terms.

11. Governing Law

These terms are governed by the laws of the Republic of Turkey.

12. Contact

For questions: contact@getzibo.com
''';

const String termsOfServiceEs = '''
Última actualización: 21 de agosto de 2026

Estos Términos de Uso rigen tu utilización de la aplicación móvil Zibo ("Zibo", "la aplicación"). Al descargar y usar la aplicación, aceptas estos términos.

1. Descripción del Servicio

Zibo es una aplicación de desarrollo personal que ofrece funciones como seguimiento de objetivos, formación de hábitos, diarios (gratitud, estado de ánimo, sueños, manifestación) y seguimiento de finanzas personales. La aplicación ofrece una experiencia gamificada apoyada por un personaje mascota llamado "Zibo".

2. Tu Cuenta

Al empezar a usar la aplicación se crea automáticamente una cuenta anónima. Opcionalmente puedes vincular esta cuenta a una cuenta de Google para poder recuperar tus datos en otro dispositivo. Eres responsable de la seguridad de tu cuenta, incluida la seguridad de cualquier cuenta de Google que vincules a ella.

3. Zibo Coin — Moneda Virtual

Zibo Coin es una unidad virtual que solo puede utilizarse DENTRO de la aplicación Zibo y NO TIENE NINGÚN VALOR MONETARIO REAL.
- Zibo Coin NO PUEDE convertirse en efectivo, NO PUEDE transferirse a otro usuario y NO PUEDE utilizarse de ninguna manera fuera de la aplicación.
- Zibo Coin puede ganarse completando tareas dentro de la aplicación, viendo anuncios o (cuando esté disponible) comprándolo con dinero real.
- Si tu cuenta se cancela, los Zibo Coin acumulados y otros elementos dentro de la aplicación quedan sin efecto sin derecho a compensación alguna.

4. Compras Dentro de la Aplicación

Está previsto que la aplicación ofrezca paquetes de Zibo Coin para comprar con dinero real. Dichas compras están sujetas a los propios Términos de Servicio y políticas de pago de Google Play. La política de reembolso de los Zibo Coin comprados sigue las políticas estándar de Google Play.

5. Contenido del Usuario

Los textos que escribes en tus diarios (gratitud, estado de ánimo, sueños, manifestación) y las fotos que subes te pertenecen. Almacenamos este contenido únicamente para mostrártelo a ti y para ofrecer la funcionalidad de la aplicación (tus estadísticas, tu historial); NO lo revisamos ni lo usamos con fines publicitarios o de marketing.

6. Usos Prohibidos

Están estrictamente prohibidas las siguientes conductas:
- Realizar ingeniería inversa de la aplicación o utilizar versiones modificadas ("mod") de la misma
- Utilizar métodos fraudulentos para explotar la economía de monedas
- Utilizar la aplicación con fines ilegales
- Intentar obtener acceso no autorizado a las cuentas de otros usuarios

Las cuentas que infrinjan estos términos podrán suspenderse o cancelarse sin previo aviso.

7. Propiedad Intelectual

La aplicación Zibo, el personaje/mascota "Zibo", su logotipo, diseño y todo el contenido visual/sonoro pertenecen a Mehmet Can Tan y están protegidos por derechos de autor. El uso de la aplicación no te otorga ningún derecho de propiedad sobre este contenido.

8. Exclusión de Garantías

La aplicación se ofrece "tal cual" y "según disponibilidad". No se ofrece ninguna garantía de que la aplicación funcione de manera ininterrumpida o sin errores.

9. Limitación de Responsabilidad

En la medida máxima permitida por la ley, no podremos ser considerados responsables de ningún daño directo o indirecto derivado del uso, o de la imposibilidad de uso, de la aplicación.

10. Cambios en Estos Términos

Podemos actualizar estos términos de vez en cuando. Te notificaremos dentro de la aplicación sobre cualquier cambio importante. Si continúas usando la aplicación después de dichos cambios, se entenderá que aceptas los términos actualizados.

11. Ley Aplicable

Estos términos se rigen por las leyes de la República de Turquía.

12. Contacto

Para preguntas: contact@getzibo.com
''';

/// `zibo_messages.dart`'taki `moneyQuotesForLocale`/`ziboMessagesForLocale` ile
/// AYNI kalıp — desteklenmeyen bir dil kodu gelirse Türkçe'ye düşer.
String privacyPolicyForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => privacyPolicyEn,
  'es' => privacyPolicyEs,
  _ => privacyPolicyTr,
};

/// Bkz. [privacyPolicyForLocale] dokümantasyonu — aynı desen.
String termsOfServiceForLocale(Locale locale) => switch (locale.languageCode) {
  'en' => termsOfServiceEn,
  'es' => termsOfServiceEs,
  _ => termsOfServiceTr,
};
