// 2. STREAK HATIRLATMASI — her gün 20:00 (Europe/Istanbul) tetiklenir (bkz.
// .github/workflows/streak-reminder.yml). Yalnızca kullanıcının aktif bir
// hedefi VE bugün henüz işaretlemediği bir hedefi varsa gönderilir.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.

const { db, istanbulDateKey, fetchAllUsers, sendToUser, getLanguageCode } = require('./common');
const { streak_reminder: STREAK_REMINDER_BODY } = require('./content');

async function main() {
  const dateKey = istanbulDateKey(new Date());
  const users = await fetchAllUsers();

  await Promise.all(
    users.map(async (user) => {
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
