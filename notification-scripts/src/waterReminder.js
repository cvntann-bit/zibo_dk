// 5. SU HATIRLATMASI — SAATTE BİR çalışan bir GitHub Actions çalıştırması,
// her kullanıcının KENDİ yerel saati 16:00 olduğunda gönderir (bkz.
// .github/workflows/water-reminder.yml, TARGET_LOCAL_HOURS aşağıda).
// Yalnızca kullanıcı bugünkü (KENDİ yerel takvim günündeki) su hedefini
// HENÜZ tamamlamadıysa gönderilir — `users/{uid}/state/waterState` (bkz.
// lib/providers/water_provider.dart) içindeki `entries` listesinde bugüne
// ait bir kayıt YOKSA (hiç başlanmamış) VEYA varsa ama `unitCount <
// goalUnitCount`'sa (yarım kalmış) hatırlatma gider; `unitCount >=
// goalUnitCount`'sa (hedef zaten tamamlanmış) HİÇ gönderilmez.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu (Kolombiya'daki bir test kullanıcısı
// sabah 4'te bildirim aldı): gönderim artık sabit Europe/Istanbul saatine
// göre DEĞİL, `userLocalHour`/`userDateKey` (bkz. common.js) ile
// kullanıcının KENDİ saat dilimine göre yapılıyor.

const { db, fetchAllUsers, sendToUser, getLanguageCode, userLocalHour, userDateKey } = require('./common');
const { water_reminder: WATER_REMINDER_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [16];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users.filter((u) => TARGET_LOCAL_HOURS.includes(userLocalHour(u, now)));
  console.log(`${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte.`);

  await Promise.all(
    eligible.map(async (user) => {
      const dateKey = userDateKey(user, now);
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
