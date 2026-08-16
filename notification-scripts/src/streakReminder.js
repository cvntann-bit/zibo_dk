// 2. STREAK HATIRLATMASI — her gün 20:00 (Europe/Istanbul) tetiklenir (bkz.
// .github/workflows/streak-reminder.yml). Yalnızca kullanıcının aktif bir
// hedefi VE bugün henüz işaretlemediği bir hedefi varsa gönderilir.

const { db, istanbulDateKey, fetchAllUsers, sendToUser } = require('./common');

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
      await sendToUser(
        user,
        'streak_reminder',
        'Zibo',
        'Serini kaçırmak üzeresin! Bugünü işaretlemeyi unutma kanka.',
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
