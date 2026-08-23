// 1. GÜNLÜK MOTİVASYON — Europe/Istanbul'da GÜNDE BİRDEN FAZLA (bkz.
// .github/workflows/daily-motivation.yml — şu an 4 ayrı cron tetikleyicisi)
// çalışan bağımsız GitHub Actions çalıştırmaları tarafından çağrılır. HER
// çalıştırma TÜM kullanıcılara, o ÇALIŞTIRMAYA özel rastgele seçilmiş bir
// sözle bildirim gönderir — yani bir kullanıcı günde kaç kez tetiklenirse
// (şu an 4) o kadar bildirim alır, her seferinde farklı bir söz.
//
// 2026 GÜNCELLEMESİ — TASARIM DEĞİŞİKLİĞİ (gerçek bir olayla bulundu):
// İlk sürüm 09:00-10:45 arası 15 dakikada bir (8 kez) tetiklenip her
// kullanıcının kendi hash'lenmiş "dilimine" denk gelen ÇALIŞTIRMADA
// gönderim yapıyordu (kullanıcıya göre FARKLI ama gün gün SABİT bir saat
// vermek için). Kullanıcının gerçek bir çalıştırmada "bildirim gelmedi"
// bildirmesiyle yapılan incelemede şu bulundu: GitHub, `0,15,30,45 6-7 * *
// *` gibi yoğun (:00/:15/:30/:45, GitHub'ın kendi dokümantasyonunda "en
// yoğun" diye işaretlenen dakikalar) bir cron'u GÜVENİLİR ŞEKİLDE
// ÇALIŞTIRMIYOR — o gün planlanan 8 tetiklemeden yalnızca 1'i gerçekleşti,
// o da 22 dakika GECİKMEYLE, script'in kendi "pencere dışı" koruması
// yüzünden HİÇ gönderim yapılmadan sessizce sonlandı. **Sonuç: GitHub
// Actions'ın schedule tetikleyicisi, YUVARLAK dakikalarda (:00/:15/:30/:45)
// planlanan cron'lar için güvenilir DEĞİL — sıklık değil, dakika seçimi
// asıl risk.** Çözüm (o zamanki TEK tetiklemeden farklı olarak artık DÖRT
// tetikleme var, ama HEPSİ yine YUVARLAK OLMAYAN dakikalarda —
// `pickSlot`/hash tabanlı "kullanıcıya göre farklı dakika" mantığı
// GERİ GETİRİLMEDİ, o karmaşıklık bu sefer de gerekmiyor): her biri kendi
// SABİT, yoğun-olmayan dakikasında (09:07/12:22/16:37/20:52) çalışan DÖRT
// BAĞIMSIZ, birbirinden habersiz basit çalıştırma — aynı "tek tetikleme,
// güvenilir dakika" ilkesi, yalnızca gün içine yayılmış DÖRT kopyası.

const {
  istanbulDateKey,
  istanbulMinutesOfDay,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
} = require('./common');
const { daily_motivation: MOTIVATION_QUOTES } = require('./content');

// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu: bildirimler kullanıcının arayüz dilinden
// BAĞIMSIZ, her zaman Türkçe gidiyordu. Artık HER kullanıcı için ayrı ayrı `getLanguageCode`
// ile dil çözülüp o dildeki söz havuzundan (bkz. content.js — TR/EN/ES, 8'er söz) rastgele
// bir söz seçiliyor — "tüm kullanıcılara aynı çalıştırmada aynı söz" tasarımı artık yalnızca
// "aynı çalıştırma" kısmında geçerli, söz her kullanıcının kendi dilinde.

// Sıkı, tetiklemeye-özel bir pencere YOK — yalnızca GitHub'ın çalıştırmayı
// KATASTROFİK şekilde geç (ör. saatler sonra, bir kesinti yüzünden)
// tetiklemesine karşı geniş bir güvenlik ağı: uyanık saatlerin (07:00-23:00
// Istanbul) DIŞINDaysa gönderim yapılmaz (yanlışlıkla gece yarısı bir
// bildirim gitmesin diye). Dört ayrı tetiklemenin (09:07/12:22/16:37/20:52)
// HEPSİ bu geniş pencerenin içinde kaldığı için tetiklemeye-özel dar bir
// kontrole gerek yok — GitHub birkaç dakika/saat geç çalıştırsa bile
// (yoğun olmayan dakikalarda seçildiği için bu ihtimal zaten düşük)
// bildirim yine de mantıklı bir saatte gider.
const SAFETY_MIN_MINUTE = 7 * 60; // 07:00
const SAFETY_MAX_MINUTE = 23 * 60; // 23:00

async function main() {
  const now = new Date();
  const dateKey = istanbulDateKey(now);
  const minutesOfDay = istanbulMinutesOfDay(now);
  if (minutesOfDay < SAFETY_MIN_MINUTE || minutesOfDay > SAFETY_MAX_MINUTE) {
    console.log(
      `Güvenlik penceresi dışı (minutesOfDay=${minutesOfDay}, dateKey=${dateKey}) — ` +
        `GitHub'ın çalıştırmayı beklenenden çok geç tetiklediği anlaşılıyor, gönderim atlandı.`,
    );
    return;
  }

  const users = await fetchAllUsers();
  console.log(`${users.length} kullanıcıya günlük motivasyon gönderiliyor (minutesOfDay=${minutesOfDay}).`);

  await Promise.all(
    users.map(async (u) => {
      const lang = await getLanguageCode(u.uid);
      const quotes = MOTIVATION_QUOTES[lang] || MOTIVATION_QUOTES.tr;
      const quote = quotes[Math.floor(Math.random() * quotes.length)];
      await sendToUser(u, 'daily_motivation', 'Zibo', quote);
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
