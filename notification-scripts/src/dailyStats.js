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
//  3. Aynı ağır taramada: sahibin hesapları (EXCLUDED_EMAILS) toplamlardan ÇIKARILIR (ayrıca `excluded`'da
//     raporlanır) ve hile şüphesi listesi (`suspects`) çıkarılır — panel Özet'te "Dikkat" bölümü.
//     E-posta/ad yalnızca Firestore'a (kural: yalnız yönetici okur) yazılır, Actions log'una YAZILMAZ.
//
// Ağır sayım mantığı değişince HEAVY_VERSION'ı artır → aynı gün içinde bir sonraki çalıştırma yeniden sayar.

const admin = require('firebase-admin');
const { db, auth, userDateKey } = require('./common');

const DAY_MS = 24 * 60 * 60 * 1000;
const CHUNK = 300;
const HEAVY_VERSION = 4;

// Sahibin kendi (test/hediye) hesapları — yüksek bakiyeleri "dolaşımdaki ZC"yi şişirmesin (kullanıcı, 2026-10-29).
const EXCLUDED_EMAILS = ['cvntann@gmail.com', 'zuleturquia@gmail.com'];
// E-postaya bağlı OLMAYAN sahip hesapları (aynı test cihazının eski/anonim uid'leri, test satın almaları) —
// kullanıcı 2026-10-29'da Özet > Dikkat listesinden "benim" diye onayladı.
const EXCLUDED_UIDS = [
  'V7YvzBBhOkhV2phM1RmoW8ENSAG3',
  'gexFCXfAsudZgDFmXL6Xk0bv66S2',
  'd918GHIJ3fgCc4qTI6BQr7Q3YRh2',
];

// Hile şüphesi eşikleri. Meşru en büyük tek kazanç (satın alma HARİÇ) = 777 ZC rozet ödülü (zcReward);
// satın alma en çok 10500 (coins_10000 + bonus). `transactions` yalnızca son 200 işlemi tutar → satın alma/
// hediye toplamı ve oran YAKLAŞIK.
// Reklam/gelir (HEAVY_VERSION 4): Firestore'da iz bırakan reklamlar = coin için ödüllü reklam ('Reklam izleme'
// işlemi) + Oyun Salonu reklamla ek hak (gamePointsState.plays[*].ads, dayKey günü). Geçiş (interstitial) ve kostüm
// denemesi reklamları Firestore'a YAZILMAZ — onların sayısı/geliri yalnızca Appodeal'da. Fiyatlar Zibo'nun TRY liste
// fiyatları (coin_packages.dart / subscription_products.dart fallbackPrice) — Google payı (%15) DÜŞÜLMEMİŞ brüt tahmin.
const PACKAGE_TRY = { 100: 16.99, 250: 37.99, 500: 69.99, 1000: 129.99, 5000: 599.99, 10000: 1099.99 };
const MONTHLY_TRY = { pro: 59.9, proplus: 99.9 };
const ACTIVITY_DAYS = 8;
const BIG_ORGANIC_EARN = 1000;
const FAST_EARN_PER_DAY = 1000;
const TOP_BALANCES = 25;
const MAX_SUSPECTS = 40;

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

async function excludedUids() {
  const uids = new Set(EXCLUDED_UIDS);
  for (const email of EXCLUDED_EMAILS) {
    try {
      uids.add((await auth.getUserByEmail(email)).uid);
    } catch (error) {
      console.warn(`Hariç tutulacak hesap bulunamadı (${error.code || error.message})`);
    }
  }
  return uids;
}

function emptyDay() {
  return { coinAds: 0, coinAdUsers: new Set(), gameAds: 0, gameAdUsers: new Set(), purchases: 0, purchaseZc: 0, purchaseTry: 0 };
}

/** Son işlemleri gün kovalarına dağıtır. İşlem zamanı cihazın yerel ISO metni → ilk 10 karakter = yerel gün. */
function addCoinActivity(activity, uid, data, dayKeys) {
  for (const t of Array.isArray(data.transactions) ? data.transactions : []) {
    if (!t || t.type !== 'earn') continue;
    const day = String(t.timestamp || '').slice(0, 10);
    if (!dayKeys.has(day)) continue;
    const bucket = activity[day];
    const reason = String(t.reason || '');
    if (reason === 'Reklam izleme') {
      bucket.coinAds += 1;
      bucket.coinAdUsers.add(uid);
    } else if (reason.includes('Satın alma')) {
      const m = /Satın alma: (\d+) ZC/.exec(reason);
      bucket.purchases += 1;
      bucket.purchaseZc += Number(t.amount) || 0;
      if (m && PACKAGE_TRY[m[1]]) bucket.purchaseTry += PACKAGE_TRY[m[1]];
    }
  }
}

function addGameActivity(activity, uid, data, dayKeys) {
  if (!dayKeys.has(data.dayKey) || !data.plays || typeof data.plays !== 'object') return;
  const ads = Object.values(data.plays).reduce((sum, p) => sum + (Number(p && p.ads) || 0), 0);
  if (ads <= 0) return;
  activity[data.dayKey].gameAds += ads;
  activity[data.dayKey].gameAdUsers.add(uid);
}

/** coinState'in son işlemlerinden şüphe işaretleri. */
function coinSignals(uid, data) {
  const balance = Number(data.balance) || 0;
  const earned = Number(data.totalEarned) || 0;
  const spent = Number(data.totalSpent) || 0;
  let purchased = 0;
  let gifted = 0;
  let maxOrganic = 0;
  let maxOrganicReason = null;
  for (const t of Array.isArray(data.transactions) ? data.transactions : []) {
    if (!t || t.type !== 'earn') continue;
    const amount = Number(t.amount) || 0;
    const reason = String(t.reason || '');
    if (reason.includes('Satın alma')) purchased += amount;
    else if (reason === 'Hediye') gifted += amount;
    else if (amount > maxOrganic) {
      maxOrganic = amount;
      maxOrganicReason = reason.slice(0, 60);
    }
  }
  return { uid, balance, earned, spent, purchased, gifted, maxOrganic, maxOrganicReason };
}

async function heavyCounts(now) {
  const userRefs = (await db.collection('users').select().get()).docs.map((d) => d.ref);
  const excluded = await excludedUids();
  const coin = { balance: 0, earned: 0, spent: 0, holders: 0 };
  const subs = { pro: 0, proplus: 0 };
  const excludedTotals = { accounts: 0, balance: 0 };
  const signals = [];
  const dayKeys = new Set();
  const activity = {};
  for (let d = 0; d < ACTIVITY_DAYS; d++) {
    const key = userDateKey({ timeZone: 'Europe/Istanbul' }, new Date(now.getTime() - d * DAY_MS));
    dayKeys.add(key);
    activity[key] = emptyDay();
  }
  let giftedForever = 0;
  for (let i = 0; i < userRefs.length; i += CHUNK) {
    const chunk = userRefs.slice(i, i + CHUNK);
    const refs = chunk.flatMap((u) => [
      u.collection('state').doc('coinState'),
      u.collection('state').doc('subscriptionState'),
      u.collection('state').doc('gamePointsState'),
    ]);
    const snaps = await db.getAll(...refs);
    for (const snap of snaps) {
      if (!snap.exists) continue;
      const data = snap.data();
      const uid = snap.ref.parent.parent.id;
      // Sahibin hesapları ne coin ne üyelik sayısına girer (hediye Pro+'lar Pro+ sayısını şişirmesin).
      if (excluded.has(uid)) {
        if (snap.id === 'coinState') {
          excludedTotals.accounts += 1;
          excludedTotals.balance += Number(data.balance) || 0;
        }
        continue;
      }
      if (snap.id === 'gamePointsState') {
        addGameActivity(activity, uid, data, dayKeys);
        continue;
      }
      if (snap.id === 'coinState') {
        signals.push(coinSignals(uid, data));
        addCoinActivity(activity, uid, data, dayKeys);
        coin.balance += Number(data.balance) || 0;
        coin.earned += Number(data.totalEarned) || 0;
        coin.spent += Number(data.totalSpent) || 0;
        coin.holders += 1;
      } else if (['pro', 'proplus'].includes(data.subscriptionTier)) {
        // Zibo'nun `SubscriptionProvider.tier` mantığı: süresi geçmişse free.
        const expiry = Date.parse(data.subscriptionExpiryDate || '');
        if (Number.isFinite(expiry) && expiry > now.getTime()) {
          // 2099 = süresiz hediye (panel/grantGift) — gelir tahmininden ayrı say.
          if (new Date(expiry).getUTCFullYear() >= 2090) giftedForever += 1;
          else subs[data.subscriptionTier] += 1;
        }
      }
    }
  }
  const suspects = await buildSuspects(signals, now);
  const activityOut = {};
  for (const [day, b] of Object.entries(activity)) {
    activityOut[day] = {
      coinAds: b.coinAds,
      coinAdUsers: b.coinAdUsers.size,
      gameAds: b.gameAds,
      gameAdUsers: b.gameAdUsers.size,
      adUsers: new Set([...b.coinAdUsers, ...b.gameAdUsers]).size,
      purchases: b.purchases,
      purchaseZc: b.purchaseZc,
      purchaseTry: Math.round(b.purchaseTry * 100) / 100,
    };
  }
  subs.giftedForever = giftedForever;
  const revenue = {
    // Aylık/yıllık plan ayrımı subscriptionState'te yok → hepsi aylık fiyatla (üst sınır tahmini).
    subsMonthlyTry: Math.round((subs.pro * MONTHLY_TRY.pro + subs.proplus * MONTHLY_TRY.proplus) * 100) / 100,
    purchaseTry7d:
      Math.round(Object.values(activityOut).slice(0, 7).reduce((sum, d) => sum + d.purchaseTry, 0) * 100) / 100,
  };
  return {
    coin,
    subs,
    revenue,
    activity: activityOut,
    scannedUsers: userRefs.length,
    excluded: excludedTotals,
    suspects,
    heavyVersion: HEAVY_VERSION,
  };
}

/** En yüksek bakiyeler + işaretli hesaplar; Auth (e-posta, oluşturulma) ve profil adıyla zenginleştirilir. */
async function buildSuspects(signals, now) {
  const byBalance = [...signals].sort((a, b) => b.balance - a.balance);
  const top = new Set(byBalance.slice(0, TOP_BALANCES).map((s) => s.uid));
  const pick = signals.filter(
    (s) => top.has(s.uid) || s.balance !== s.earned - s.spent || s.maxOrganic > BIG_ORGANIC_EARN,
  );
  const users = new Map();
  for (let i = 0; i < pick.length; i += 100) {
    const result = await auth.getUsers(pick.slice(i, i + 100).map((s) => ({ uid: s.uid })));
    for (const u of result.users) users.set(u.uid, u);
  }
  const profiles = pick.length
    ? await db.getAll(...pick.map((s) => db.collection('users').doc(s.uid).collection('state').doc('profileState')))
    : [];
  const names = new Map(profiles.filter((p) => p.exists).map((p) => [p.ref.parent.parent.id, p.data().name]));

  const out = pick.map((s) => {
    const user = users.get(s.uid);
    const created = user ? Date.parse(user.metadata.creationTime) : NaN;
    const ageDays = Number.isFinite(created) ? Math.max(1, Math.round((now.getTime() - created) / DAY_MS)) : null;
    const organic = Math.max(0, s.earned - s.purchased - s.gifted);
    const earnPerDay = ageDays ? Math.round(organic / ageDays) : null;
    const flags = [];
    if (s.balance !== s.earned - s.spent) flags.push('mismatch');
    if (s.maxOrganic > BIG_ORGANIC_EARN) flags.push('bigEarn');
    if (earnPerDay !== null && earnPerDay > FAST_EARN_PER_DAY) flags.push('fastEarn');
    return {
      ...s,
      email: (user && user.email) || null,
      name: names.get(s.uid) || null,
      providers: user ? user.providerData.map((p) => p.providerId) : [],
      ageDays,
      earnPerDay,
      flags,
    };
  });
  // Önce işaretliler (işaret sayısına göre), sonra bakiye.
  out.sort((a, b) => b.flags.length - a.flags.length || b.balance - a.balance);
  return out.slice(0, MAX_SUSPECTS);
}

// --- Appodeal reklam geliri (Reporting API) -------------------------------------------------
// Belge: https://docs.appodeal.com/reporting/reporting-api — EŞZAMANSIZ: stats_api → task_id →
// check_status (yokla) → output_result (`{code:0, data:[{date, app_key, app_name, impressions, revenue, ecpm, ...}]}`,
// büyükse `{code:0, url}` → indir). Belge yanıt şekillerini tam vermiyor → alan adları savunmacı okunur.
// Anahtar/ID GitHub Secret (APPODEAL_API_KEY, APPODEAL_USER_ID; Appodeal > Profil > API Credentials). Yoksa ADIM ATLANIR.
// Ağ gelirleri 4–6 saatte bir güncellenir ve son 3 gün değişebilir → 6 saatte bir son 8 gün yeniden çekilir.
// Anahtar ASLA log'a yazılmaz (yalnızca HTTP durumu/mesajı).
const APPODEAL_BASE = 'https://api-services.appodeal.com/api/v2';
const APPODEAL_EVERY_MS = 6 * 60 * 60 * 1000;
const APPODEAL_DAYS = 8;

async function appodealGet(path, params) {
  const url = new URL(`${APPODEAL_BASE}/${path}`);
  url.searchParams.set('api_key', process.env.APPODEAL_API_KEY);
  url.searchParams.set('user_id', process.env.APPODEAL_USER_ID);
  for (const [k, v] of params) url.searchParams.append(k, v);
  const res = await fetch(url, { signal: AbortSignal.timeout(30000) });
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch (_) {
    throw new Error(`Appodeal ${path}: HTTP ${res.status}, JSON değil`);
  }
  if (!res.ok || (body.code !== undefined && Number(body.code) !== 0)) {
    throw new Error(`Appodeal ${path}: HTTP ${res.status} code=${body.code} ${String(body.message || '').slice(0, 120)}`);
  }
  return body;
}

const pick = (obj, ...keys) => keys.map((k) => obj && obj[k]).find((v) => v !== undefined && v !== null);

async function fetchAppodealRevenue(now) {
  const dateTo = userDateKey({ timeZone: 'Europe/Istanbul' }, now);
  const dateFrom = userDateKey({ timeZone: 'Europe/Istanbul' }, new Date(now.getTime() - (APPODEAL_DAYS - 1) * DAY_MS));
  const start = await appodealGet('stats_api', [
    ['date_from', dateFrom],
    ['date_to', dateTo],
    ['detalisation[]', 'date'],
    ['detalisation[]', 'app'],
  ]);
  const taskId = pick(start, 'task_id') || pick(start.data, 'task_id');
  if (!taskId) throw new Error('Appodeal stats_api: task_id gelmedi');

  // Durum alanı belgede yok — "bitti" sinyali gelene ya da 90 sn dolana kadar yokla; sonra output_result dene.
  for (let i = 0; i < 18; i++) {
    await new Promise((r) => setTimeout(r, 5000));
    const st = await appodealGet('check_status', [['task_id', taskId]]).catch(() => null);
    const status = String(pick(st, 'task_status', 'status') || pick(st && st.data, 'task_status', 'status') || '');
    if (/^(1|true|done|finished|ready|success|completed)$/i.test(status)) break;
  }
  let out = await appodealGet('output_result', [['task_id', taskId]]);
  if (!Array.isArray(out.data) && out.url) {
    const res = await fetch(out.url, { signal: AbortSignal.timeout(30000) });
    out = JSON.parse(await res.text());
  }
  const rows = Array.isArray(out.data) ? out.data : [];
  const days = {};
  for (const row of rows) {
    const date = String(pick(row, 'date') || '').slice(0, 10);
    if (!date) continue;
    const app = String(pick(row, 'app_name', 'app_key') || 'app');
    const day = (days[date] = days[date] || { revenue: 0, impressions: 0, apps: {} });
    const revenue = Number(row.revenue) || 0;
    const impressions = Number(row.impressions) || 0;
    day.revenue += revenue;
    day.impressions += impressions;
    const a = (day.apps[app] = day.apps[app] || { revenue: 0, impressions: 0 });
    a.revenue += revenue;
    a.impressions += impressions;
  }
  for (const d of Object.values(days)) {
    d.revenue = Math.round(d.revenue * 10000) / 10000;
    d.ecpm = d.impressions ? Math.round((d.revenue / d.impressions) * 1000 * 100) / 100 : 0;
  }
  return { days, rows: rows.length, from: dateFrom, to: dateTo };
}

async function main() {
  const now = new Date();
  const dateKey = userDateKey({ timeZone: 'Europe/Istanbul' }, now);
  const ref = db.collection('stats').doc(dateKey);
  const cheap = await cheapCounts(now);
  const update = { ...cheap, date: dateKey, updatedAt: admin.firestore.FieldValue.serverTimestamp() };

  const existing = await ref.get();
  if (!existing.exists || existing.data().heavyVersion !== HEAVY_VERSION) {
    const heavy = await heavyCounts(now);
    Object.assign(update, heavy, { heavyAt: admin.firestore.FieldValue.serverTimestamp() });
    console.log(
      `Günlük ağır sayım: kullanıcı=${heavy.scannedUsers} ZC dolaşımda=${heavy.coin.balance} ` +
        `Pro=${heavy.subs.pro} Pro+=${heavy.subs.proplus} | hariç=${heavy.excluded.accounts} hesap ` +
        `(${heavy.excluded.balance} ZC) | şüpheli listesi=${heavy.suspects.length} ` +
        `(işaretli ${heavy.suspects.filter((x) => x.flags.length).length}) | ` +
        `reklam (gün: coin/oyun izleyen) ${Object.entries(heavy.activity)
          .map(([d, a]) => `${d.slice(5)}=${a.coinAdUsers}/${a.gameAdUsers}`)
          .join(' ')} | abonelik ~${heavy.revenue.subsMonthlyTry} TL/ay, coin satışı 7g ~${heavy.revenue.purchaseTry7d} TL`,
    );
  }
  if (!process.env.APPODEAL_API_KEY || !process.env.APPODEAL_USER_ID) {
    console.log('Appodeal: APPODEAL_API_KEY / APPODEAL_USER_ID secret yok — reklam geliri atlandı.');
  } else {
    const last = existing.exists && existing.data().appodealAt ? existing.data().appodealAt.toMillis() : 0;
    if (now.getTime() - last >= APPODEAL_EVERY_MS) {
      try {
        const appodeal = await fetchAppodealRevenue(now);
        update.appodeal = appodeal;
        update.appodealAt = admin.firestore.FieldValue.serverTimestamp();
        update.appodealError = admin.firestore.FieldValue.delete();
        const total = Object.values(appodeal.days).reduce((sum, d) => sum + d.revenue, 0);
        console.log(`Appodeal: ${appodeal.rows} satır, ${appodeal.from}→${appodeal.to} toplam gelir $${total.toFixed(4)}`);
      } catch (error) {
        update.appodealError = String(error.message || error).slice(0, 200);
        console.warn('Appodeal okunamadı:', update.appodealError);
      }
    }
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
