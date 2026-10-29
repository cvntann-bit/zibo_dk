// Yönetici panelinin Özet sekmesi için günlük sayılar — `stats/{YYYY-MM-DD}` (İstanbul günü).
// `hourlyAll.js`'in SON işi. Bkz. dijital_kanka/docs/admin_panel.md (A6). Kural: yalnız yönetici okur.
//
// İki kademe (maliyet — docs/unit_economics.md "zarar etme" kuralı):
//  1. HER saat: Firestore sayma sorguları (count aggregation, 1000 kayıt başına ~1 okuma) — toplam kullanıcı,
//     24 sa / 7 g / 30 g aktif (`users/{uid}.lastActiveAt`), bildirim alabilen (`fcmToken`). Günün belgesi
//     her saat güncellenir; gün bitince son değer o günün değeri olarak kalır.
//  2. GÜNDE BİR (günün belgesinde `heavyAt` yoksa): tüm kullanıcıların coinState + subscriptionState'i
//     (kullanıcı başına ~3 okuma) → dolaşımdaki ZC, toplam kazanılan/harcanan (panel günlük farkı hesaplar),
//     etkin Pro / Pro+ sayısı. collectionGroup toplamı KULLANILMADI: `gamePointsState` de `totalEarned`
//     taşıyor (karışırdı) ve koleksiyon-grubu indeksi elle açılmalıydı.

const admin = require('firebase-admin');
const { db, userDateKey } = require('./common');

const DAY_MS = 24 * 60 * 60 * 1000;
const CHUNK = 300;

async function count(query) {
  const snap = await query.count().get();
  return snap.data().count;
}

async function cheapCounts(now) {
  const users = db.collection('users');
  const since = (days) => admin.firestore.Timestamp.fromMillis(now.getTime() - days * DAY_MS);
  const [totalUsers, withToken, active1d, active7d, active30d] = await Promise.all([
    count(users),
    count(users.where('fcmToken', '!=', null)),
    count(users.where('lastActiveAt', '>=', since(1))),
    count(users.where('lastActiveAt', '>=', since(7))),
    count(users.where('lastActiveAt', '>=', since(30))),
  ]);
  return { totalUsers, withToken, active1d, active7d, active30d };
}

async function heavyCounts(now) {
  const userRefs = (await db.collection('users').select().get()).docs.map((d) => d.ref);
  const coin = { balance: 0, earned: 0, spent: 0, holders: 0 };
  const subs = { pro: 0, proplus: 0 };
  for (let i = 0; i < userRefs.length; i += CHUNK) {
    const chunk = userRefs.slice(i, i + CHUNK);
    const refs = chunk.flatMap((u) => [
      u.collection('state').doc('coinState'),
      u.collection('state').doc('subscriptionState'),
    ]);
    const snaps = await db.getAll(...refs);
    for (const snap of snaps) {
      if (!snap.exists) continue;
      const data = snap.data();
      if (snap.id === 'coinState') {
        coin.balance += Number(data.balance) || 0;
        coin.earned += Number(data.totalEarned) || 0;
        coin.spent += Number(data.totalSpent) || 0;
        coin.holders += 1;
      } else if (['pro', 'proplus'].includes(data.subscriptionTier)) {
        // Zibo'nun `SubscriptionProvider.tier` mantığı: süresi geçmişse free.
        const expiry = Date.parse(data.subscriptionExpiryDate || '');
        if (Number.isFinite(expiry) && expiry > now.getTime()) subs[data.subscriptionTier] += 1;
      }
    }
  }
  return { coin, subs, scannedUsers: userRefs.length };
}

async function main() {
  const now = new Date();
  const dateKey = userDateKey({ timeZone: 'Europe/Istanbul' }, now);
  const ref = db.collection('stats').doc(dateKey);
  const cheap = await cheapCounts(now);
  const update = { ...cheap, date: dateKey, updatedAt: admin.firestore.FieldValue.serverTimestamp() };

  const existing = await ref.get();
  if (!existing.exists || !existing.data().heavyAt) {
    const heavy = await heavyCounts(now);
    Object.assign(update, heavy, { heavyAt: admin.firestore.FieldValue.serverTimestamp() });
    console.log(
      `Günlük ağır sayım: kullanıcı=${heavy.scannedUsers} ZC dolaşımda=${heavy.coin.balance} ` +
        `Pro=${heavy.subs.pro} Pro+=${heavy.subs.proplus}`,
    );
  }
  await ref.set(update, { merge: true });
  console.log(
    `stats/${dateKey}: toplam=${cheap.totalUsers} token=${cheap.withToken} ` +
      `aktif 24s=${cheap.active1d} 7g=${cheap.active7d} 30g=${cheap.active30d}`,
  );
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { main };
