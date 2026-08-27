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
//
// 2026 ÜÇÜNCÜ GÜNCELLEME — "TAM o saat mi?" kontrolü GitHub Actions'ın
// saatlik cron'unu sık sık geciktirmesi/atlaması yüzünden bildirimleri
// TAMAMEN durdurdu (bkz. dailyMotivation.js'teki aynı bulgu) — artık
// `pendingNotifyHours`/`markNotifyHoursSent` (common.js) ile "hedef saat
// GEÇTİ mi VE bugün için henüz işlenmedi mi?" sorulup gecikmeli bir
// tetiklemede de doğru şekilde yakalanıyor. Saat dilimine bakılmaksızın
// (aktif ya da değil) hedef saati geçen HER kullanıcı "bugün için işlendi"
// diye işaretleniyor — aksi halde hâlâ inaktif bir kullanıcı, aynı günün
// SONRAKİ bir çalıştırmasında ikinci bir bildirim daha alabilirdi.

const {
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
  userDateKey,
  pendingNotifyHours,
  markNotifyHoursSent,
} = require('./common');
const { re_engagement: RE_ENGAGEMENT_BODY } = require('./content');

const TARGET_LOCAL_HOURS = [11];

async function main() {
  const now = new Date();
  const twoDaysAgoMs = now.getTime() - 2 * 24 * 60 * 60 * 1000;
  const users = await fetchAllUsers();

  const eligible = users
    .map((user) => ({
      user,
      pending: pendingNotifyHours(user, 're_engagement', TARGET_LOCAL_HOURS, now),
    }))
    .filter((e) => e.pending.length > 0);

  await Promise.all(
    eligible.map(async ({ user, pending }) => {
      await markNotifyHoursSent(user, 're_engagement', userDateKey(user, now), pending);
      if (!user.lastActiveAt) return;
      // Firestore Timestamp (Admin SDK) -> Date.
      const lastActiveMs = user.lastActiveAt.toMillis
        ? user.lastActiveAt.toMillis()
        : new Date(user.lastActiveAt).getTime();
      if (lastActiveMs >= twoDaysAgoMs) return;
      const lang = await getLanguageCode(user.uid);
      await sendToUser(
        user,
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
