// 5. SU HATIRLATMASI — her gün 16:07 (Europe/Istanbul) tetiklenir (bkz.
// .github/workflows/water-reminder.yml). Yalnızca kullanıcı bugünkü su
// hedefini HENÜZ tamamlamadıysa gönderilir — `users/{uid}/state/waterState`
// (bkz. lib/providers/water_provider.dart) içindeki `entries` listesinde
// bugüne ait bir kayıt YOKSA (hiç başlanmamış) VEYA varsa ama `unitCount <
// goalUnitCount`'sa (yarım kalmış) hatırlatma gider; `unitCount >=
// goalUnitCount`'sa (hedef zaten tamamlanmış) HİÇ gönderilmez.

const { db, istanbulDateKey, fetchAllUsers, sendToUser, getLanguageCode } = require('./common');
const { water_reminder: WATER_REMINDER_BODY } = require('./content');

async function main() {
  const dateKey = istanbulDateKey(new Date());
  const users = await fetchAllUsers();

  await Promise.all(
    users.map(async (user) => {
      const doc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('waterState')
        .get();
      if (!doc.exists) return;
      const entries = doc.data().entries || [];
      const todayEntry = entries.find((e) => (e.date || '').startsWith(dateKey));
      const goalReached =
        todayEntry != null && todayEntry.unitCount >= todayEntry.goalUnitCount;
      if (goalReached) return;
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'water_reminder',
        'Zibo',
        WATER_REMINDER_BODY[lang] || WATER_REMINDER_BODY.tr,
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
