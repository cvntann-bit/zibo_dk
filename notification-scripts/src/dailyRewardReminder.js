// 3. GÜNLÜK ÖDÜL HATIRLATMASI — SAATTE BİR çalışan bir GitHub Actions
// çalıştırması, her kullanıcının KENDİ yerel saati 15:00 olduğunda gönderir
// (bkz. .github/workflows/daily-reward-reminder.yml, TARGET_LOCAL_HOURS
// aşağıda).
//
// BİLİNEN SINIRLAMA: Şans Çarkı'nın Firestore'da kalıcı bir "bugün çevrildi
// mi" alanı YOK (bkz. CLAUDE.md "Şans Çarkı" — günlük çevirme sınırı
// bilinçli olarak yok), bu yüzden bu betik YALNIZCA Günlük Giriş Ödülü'nün
// (dailyRewards) claim durumunu kontrol edebiliyor, çark durumunu DEĞİL.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: bildirim her zaman Türkçe gidiyordu,
// kullanıcının arayüz diline göre değişmiyordu. Artık `getLanguageCode` ile
// kullanıcının dili çözülüp `content.js`'teki TR/EN/ES metinlerinden doğru
// olanı gönderiliyor.
//
// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu (Kolombiya'daki bir test
// kullanıcısı sabah 4'te bildirim aldı): gönderim artık sabit Europe/Istanbul
// saatine göre DEĞİL, `userLocalHour`/`userDateKey` (bkz. common.js) ile
// kullanıcının KENDİ saat dilimine göre yapılıyor.
//
// 2026 ÜÇÜNCÜ GÜNCELLEME — "TAM o saat mi?" kontrolü GitHub Actions'ın
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
const { daily_reward: DAILY_REWARD_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [15];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users
    .map((user) => ({
      user,
      pending: pendingNotifyHours(user, 'daily_reward', TARGET_LOCAL_HOURS, now),
    }))
    .filter((e) => e.pending.length > 0);
  console.log(
    `${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte ` +
      `(veya kaçırılmış bir dilimi yakalıyor).`,
  );

  await Promise.all(
    eligible.map(async ({ user, pending }) => {
      const dateKey = userDateKey(user, now);
      const markHandled = () => markNotifyHoursSent(user, 'daily_reward', dateKey, pending);
      const doc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('dailyRewards')
        .get();
      const claimedDates = (doc.exists && doc.data().claimedDates) || [];
      const claimedToday = claimedDates.some((d) => d.startsWith(dateKey));
      if (claimedToday) return markHandled();
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'daily_reward',
        'Zibo',
        DAILY_REWARD_BODY[lang] || DAILY_REWARD_BODY.tr,
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
