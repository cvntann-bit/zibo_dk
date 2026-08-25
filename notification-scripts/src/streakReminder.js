// 2. STREAK HATIRLATMASI — SAATTE BİR çalışan bir GitHub Actions
// çalıştırması, her kullanıcının KENDİ yerel saati 20:00 olduğunda gönderir
// (bkz. .github/workflows/streak-reminder.yml, TARGET_LOCAL_HOURS aşağıda).
// Yalnızca kullanıcının aktif bir hedefi VE bugün (KENDİ yerel takvim günü)
// henüz işaretlemediği bir hedefi varsa gönderilir.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.
//
// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu (Kolombiya'daki bir test
// kullanıcısı sabah 4'te bildirim aldı): gönderim artık sabit Europe/Istanbul
// saatine göre DEĞİL, `userLocalHour`/`userDateKey` (bkz. common.js) ile
// kullanıcının KENDİ saat dilimine göre yapılıyor — hem "şu an 20:00 mi"
// kontrolü hem "bugün" tanımı (hedef tamamlama tarihleri) artık kullanıcının
// yerel gününe göre.

const { db, fetchAllUsers, sendToUser, getLanguageCode, userLocalHour, userDateKey } = require('./common');
const { streak_reminder: STREAK_REMINDER_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [20];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users.filter((u) => TARGET_LOCAL_HOURS.includes(userLocalHour(u, now)));
  console.log(`${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte.`);

  await Promise.all(
    eligible.map(async (user) => {
      const dateKey = userDateKey(user, now);
      const goalsDoc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('goals')
        .get();
      if (!goalsDoc.exists) return;
      const goals = goalsDoc.data().goals || [];
      if (goals.length === 0) return;
      const hasUnmarkedGoal = goals.some(
        (g) => !(g.completedDates || []).some((d) => d.startsWith(dateKey)),
      );
      if (!hasUnmarkedGoal) return;
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'streak_reminder',
        'Zibo',
        STREAK_REMINDER_BODY[lang] || STREAK_REMINDER_BODY.tr,
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
