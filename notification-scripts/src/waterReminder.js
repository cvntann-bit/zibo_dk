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
//
// 2026 İKİNCİ GÜNCELLEME — "TAM o saat mi?" kontrolü GitHub Actions'ın
// saatlik cron'unu sık sık geciktirmesi/atlaması yüzünden bildirimleri
// TAMAMEN durdurdu (bkz. dailyMotivation.js'teki aynı bulgu) — artık
// `pendingNotifyHours`/`markNotifyHoursSent` (common.js) ile "hedef saat
// GEÇTİ mi VE bugün için henüz işlenmedi mi?" sorulup gecikmeli bir
// tetiklemede de doğru şekilde yakalanıyor.

const {
  db,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
  userDateKey,
  pendingNotifyHours,
  markNotifyHoursSent,
} = require('./common');
const { water_reminder: WATER_REMINDER_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [16];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users
    .map((user) => ({
      user,
      pending: pendingNotifyHours(user, 'water_reminder', TARGET_LOCAL_HOURS, now),
    }))
    .filter((e) => e.pending.length > 0);
  console.log(
    `${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte ` +
      `(veya kaçırılmış bir dilimi yakalıyor).`,
  );

  await Promise.all(
    eligible.map(async ({ user, pending }) => {
      const dateKey = userDateKey(user, now);
      const markHandled = () => markNotifyHoursSent(user, 'water_reminder', dateKey, pending);
      const doc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('waterState')
        .get();
      if (!doc.exists) return markHandled();
      const entries = doc.data().entries || [];
      const todayEntry = entries.find((e) => (e.date || '').startsWith(dateKey));
      const goalReached =
        todayEntry != null && todayEntry.unitCount >= todayEntry.goalUnitCount;
      if (goalReached) return markHandled();
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'water_reminder',
        'Zibo',
        WATER_REMINDER_BODY[lang] || WATER_REMINDER_BODY.tr,
      );
      await markHandled();
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
