// 4. GERİ KAZANMA — SAATTE BİR çalışan bir GitHub Actions çalıştırması, her
// kullanıcının KENDİ yerel saati 11:00 olduğunda kontrol eder (bkz.
// .github/workflows/re-engagement.yml, TARGET_LOCAL_HOURS aşağıda).
// `lastActiveAt` 2 günden eski olan kullanıcılara Zibo'nun sıcak tonunda
// özel bir mesaj gönderilir.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.
//
// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu (Kolombiya'daki bir test
// kullanıcısı sabah 4'te bildirim aldı): "2 gündür açılmadı mı" kontrolü
// zaten saat dilimi bağımsızdı (ham milisaniye farkı) — DEĞİŞMEDİ; yalnızca
// gönderim ANI artık sabit Europe/Istanbul yerine kullanıcının KENDİ yerel
// saatine göre (bkz. common.js'teki `userLocalHour`).

const { fetchAllUsers, sendToUser, getLanguageCode, userLocalHour } = require('./common');
const { re_engagement: RE_ENGAGEMENT_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [11];

async function main() {
  const now = new Date();
  const twoDaysAgoMs = now.getTime() - 2 * 24 * 60 * 60 * 1000;
  const users = await fetchAllUsers();

  const eligible = users.filter((u) => {
    if (!TARGET_LOCAL_HOURS.includes(userLocalHour(u, now))) return false;
    if (!u.lastActiveAt) return false;
    // Firestore Timestamp (Admin SDK) -> Date.
    const lastActiveMs = u.lastActiveAt.toMillis
      ? u.lastActiveAt.toMillis()
      : new Date(u.lastActiveAt).getTime();
    return lastActiveMs < twoDaysAgoMs;
  });

  await Promise.all(
    eligible.map(async (u) => {
      const lang = await getLanguageCode(u.uid);
      await sendToUser(
        u,
        're_engagement',
        'Zibo',
        RE_ENGAGEMENT_BODY[lang] || RE_ENGAGEMENT_BODY.tr,
      );
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
