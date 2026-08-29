// 2. STREAK HATIRLATMASI — SAATTE BİR çalışan bir GitHub Actions
// çalıştırması, her kullanıcının KENDİ yerel saati 21:00 olduğunda gönderir
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
//
// 2026 ÜÇÜNCÜ GÜNCELLEME — "TAM o saat mi?" kontrolü GitHub Actions'ın
// saatlik cron'unu sık sık geciktirmesi/atlaması yüzünden bildirimleri
// TAMAMEN durdurdu (bkz. dailyMotivation.js'teki aynı bulgu) — artık
// `pendingNotifyHours`/`markNotifyHoursSent` (common.js) ile "hedef saat
// GEÇTİ mi VE bugün için henüz işlenmedi mi?" sorulup gecikmeli bir
// tetiklemede de doğru şekilde yakalanıyor.
//
// 2026 DÖRDÜNCÜ GÜNCELLEME — kullanıcı raporu: "bildirimler 3 kez birden ve
// düzensiz geliyor". Kök neden BURADA değil, 5 bildirim türünün
// `TARGET_LOCAL_HOURS`'ları arasındaki ÇAKIŞMALARDA bulundu (bkz.
// dailyMotivation.js'in `[9, 12, 16, 20]`'si ile bu dosyanın eski `[20]`'si
// TAM AYNI saatte çakışıyordu — aynı kullanıcı aynı yerel saatte HEM
// motivasyon HEM streak bildirimi alıyordu). Saat `20` → `21`'e taşındı
// (motivasyonun son diliminden yalnızca 1 saat sonra — TAM çakışmadan çok
// daha iyi, ayrıca "günün sonuna yaklaşırken son şans" anlamına da daha
// uygun) — bkz. CLAUDE.md "Push Bildirimleri" bölümündeki tam çakışma
// haritası ve yeni saat planı.

const {
  db,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
  userDateKey,
  pendingNotifyHours,
  markNotifyHoursSent,
} = require('./common');
const { streak_reminder: STREAK_REMINDER_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [21];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users
    .map((user) => ({
      user,
      pending: pendingNotifyHours(user, 'streak_reminder', TARGET_LOCAL_HOURS, now),
    }))
    .filter((e) => e.pending.length > 0);
  console.log(
    `${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte ` +
      `(veya kaçırılmış bir dilimi yakalıyor).`,
  );

  await Promise.all(
    eligible.map(async ({ user, pending }) => {
      const dateKey = userDateKey(user, now);
      const markHandled = () => markNotifyHoursSent(user, 'streak_reminder', dateKey, pending);
      const goalsDoc = await db
        .collection('users')
        .doc(user.uid)
        .collection('state')
        .doc('goals')
        .get();
      if (!goalsDoc.exists) return markHandled();
      const goals = goalsDoc.data().goals || [];
      if (goals.length === 0) return markHandled();
      const hasUnmarkedGoal = goals.some(
        (g) => !(g.completedDates || []).some((d) => d.startsWith(dateKey)),
      );
      if (!hasUnmarkedGoal) return markHandled();
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
        'streak_reminder',
        'Zibo',
        STREAK_REMINDER_BODY[lang] || STREAK_REMINDER_BODY.tr,
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
