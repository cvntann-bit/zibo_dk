// 1. GÜNLÜK MOTİVASYON — Europe/Istanbul sabahında BİR KEZ tetiklenen bir
// GitHub Actions cron'u tarafından çağrılır (bkz.
// .github/workflows/daily-motivation.yml). Her kullanıcı günde bir kez,
// AYNI çalıştırmada rastgele seçilen bir sözle bildirim alır.
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
// o da 22 dakika GECİKMEYLE (09:00-10:45 penceresinin DIŞINA taşarak),
// script'in kendi "pencere dışı" koruması yüzünden HİÇ gönderim
// yapılmadan sessizce sonlandı. **Sonuç: GitHub Actions'ın schedule
// tetikleyicisi, yoğun/sık (saatte birden fazla) cron'lar için güvenilir
// DEĞİL.** Çözüm: günde TEK bir, yoğun-olmayan bir dakikada (bkz.
// workflow'daki `cron: '7 6 * * *'` — 09:07 Istanbul, GitHub'ın "yoğun"
// dediği :00/:15/:30/:45'in DIŞINDA) tetiklenen bir çalıştırma — "kullanıcıya
// göre FARKLI dakika" nüansı feda edildi (tüm kullanıcılar AYNI günlük
// çalıştırmada bildirim alıyor), ama bu, "her sabah GERÇEKTEN gelsin"
// önceliğine göre BİLİNÇLİ bir ödünleşim — daha önceki tasarım GÖRÜNÜŞTE
// daha kişiselleştirilmişti ama pratikte hiç çalışmıyordu.

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

// Sıkı bir "9:00-10:45" penceresi ARTIK YOK (tek tetikleme olduğu için
// gerek kalmadı) — yalnızca GitHub'ın çalıştırmayı KATASTROFİK şekilde geç
// (ör. saatler sonra, bir kesinti yüzünden) tetiklemesine karşı geniş bir
// güvenlik ağı: sabah 07:00 - öğlen 13:00 (Istanbul) dışındaysa gönderim
// yapılmaz (yanlışlıkla gece yarısı bir "günaydın" bildirimi gitmesin diye).
const SAFETY_MIN_MINUTE = 7 * 60; // 07:00
const SAFETY_MAX_MINUTE = 13 * 60; // 13:00

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
