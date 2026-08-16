// 4. GERİ KAZANMA — her gün 11:00 (Europe/Istanbul) tetiklenir (bkz.
// .github/workflows/re-engagement.yml). `lastActiveAt` 2 günden eski olan
// kullanıcılara Zibo'nun sıcak tonunda özel bir mesaj gönderilir.

const { fetchAllUsers, sendToUser } = require('./common');

async function main() {
  const twoDaysAgoMs = Date.now() - 2 * 24 * 60 * 60 * 1000;
  const users = await fetchAllUsers();

  const eligible = users.filter((u) => {
    if (!u.lastActiveAt) return false;
    // Firestore Timestamp (Admin SDK) -> Date.
    const lastActiveMs = u.lastActiveAt.toMillis
      ? u.lastActiveAt.toMillis()
      : new Date(u.lastActiveAt).getTime();
    return lastActiveMs < twoDaysAgoMs;
  });

  await Promise.all(
    eligible.map((u) =>
      sendToUser(u, 're_engagement', 'Zibo', 'Seni özledim kanka, bir bakıver ne yaptığına 🧡'),
    ),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
