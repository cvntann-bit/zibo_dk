// 1. GÜNLÜK MOTİVASYON — SAATTE BİR (bkz. .github/workflows/daily-motivation.yml)
// çalışan TEK bir GitHub Actions çalıştırması, her kullanıcının KENDİ yerel
// saatine göre günde DÖRT kez (09/12/16/20 — bkz. TARGET_LOCAL_HOURS)
// gönderim yapar. Bir kullanıcının yerel saati bu dört değerden birine denk
// geldiğinde o çalıştırmada bir bildirim gönderilir; farklı diliminde olan
// kullanıcılar o saatte pas geçilip KENDİ saatleri geldiğinde yakalanır.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: Kolombiya'daki bir test kullanıcısı
// sabah 4'te bildirim aldığını bildirdi — kök neden, TÜM kullanıcılara sabit
// Europe/Istanbul saatine göre (kullanıcının GERÇEK konumu/saat dilimi hiç
// dikkate alınmadan) gönderim yapılmasıydı. Artık her kullanıcının
// `timeZone` alanına (bkz. PushNotificationService.touchLastActive) göre
// KENDİ yerel saati hesaplanıp (bkz. common.js'teki `userLocalHour` —
// IANA saat dilimi kullanıldığı için yaz/kış saati otomatik doğru) yalnızca
// hedef saatlerden birine denk gelenlere gönderim yapılıyor.
//
// **Önceki tasarım (dört AYRI, sabit-Istanbul-saatli cron tetikleyicisi,
// `SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE` güvenlik penceresiyle) TAMAMEN
// YERİNE bu SAATLİK + kullanıcı-bazlı filtreleme mantığı geçti** — eski
// "GitHub'ın çalıştırmayı çok geç tetiklemesine karşı geniş bir Istanbul
// penceresi" güvenlik ağına artık gerek yok, çünkü YENİ tasarım zaten
// yalnızca kullanıcının KENDİ hesaplanan yerel saati hedefe denk geldiğinde
// gönderim yapıyor — "yanlış saatte gönderim" riski tasarım gereği yok.

const { fetchAllUsers, sendToUser, getLanguageCode, userLocalHour } = require('./common');
const { daily_motivation: MOTIVATION_QUOTES } = require('./content');

// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu: bildirimler kullanıcının arayüz dilinden
// BAĞIMSIZ, her zaman Türkçe gidiyordu. Artık HER kullanıcı için ayrı ayrı `getLanguageCode`
// ile dil çözülüp o dildeki söz havuzundan (bkz. content.js — TR/EN/ES, 8'er söz) rastgele
// bir söz seçiliyor — "tüm kullanıcılara aynı çalıştırmada aynı söz" tasarımı artık yalnızca
// "aynı çalıştırma" kısmında geçerli, söz her kullanıcının kendi dilinde.

// Eski sabit Istanbul saatleriyle (09:07/12:22/16:37/20:52) AYNI ruhu
// koruyan dört hedef yerel saat — yalnızca artık HERKES için Istanbul değil,
// HERKESİN KENDİ yerel saatinde.
const TARGET_LOCAL_HOURS = [9, 12, 16, 20];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users.filter((u) => TARGET_LOCAL_HOURS.includes(userLocalHour(u, now)));
  console.log(
    `${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte — ` +
      `günlük motivasyon gönderiliyor.`,
  );

  await Promise.all(
    eligible.map(async (u) => {
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
