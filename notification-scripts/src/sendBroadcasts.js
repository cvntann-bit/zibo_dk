// Yönetici duyuruları — yönetici uygulamasının (`zibo_admin/`, Duyuru sekmesi) yazdığı
// `broadcasts/{id}` belgelerini gönderir. `hourlyAll.js`'in İLK işi (saatte bir; "Hemen" = ≤ 1 saat).
// Bkz. dijital_kanka/docs/admin_panel.md (A5).
//
// Belge şekli (panel yazar):
//   status      'pending' → (bu betik) 'sending' → 'sent' | 'failed'   ('canceled': panel iptal etti)
//   sendAfter   Timestamp — bu andan ÖNCE gönderilmez (planlı duyuru)
//   audience    'all' | 'pro' (Pro + Pro+, süresi geçmemiş) | 'inactive7' (7+ gündür açmayan)
//   texts       { tr: {title, body}, en?: {...}, es?: {...} } — kullanıcının dili için metin YOKSA
//               o kullanıcıya GÖNDERİLMEZ (İspanyolca kullanıcıya Türkçe gitmesin diye)
//   testUid     (isteğe bağlı) — yalnızca bu uid'e gönder, kitle/dil filtresi yok (önce kendine dene)
// Sonuç belgeye yazılır: sentCount, skippedCount, failedCount, finishedAt (panel listesinde görünür).
//
// Çift gönderim koruması: belge transaction ile 'pending' → 'sending' yapılmadan gönderime
// başlanmaz; iki çalıştırma çakışırsa yalnızca biri alır.

const admin = require('firebase-admin');
const { db, fetchAllUsers, sendToUser, getLanguageCode } = require('./common');

const TITLE_MAX = 80;
const BODY_MAX = 400;
const CHUNK = 100;
const DAY_MS = 24 * 60 * 60 * 1000;

function cleanText(text) {
  if (!text || typeof text.title !== 'string' || typeof text.body !== 'string') return null;
  const title = text.title.trim().slice(0, TITLE_MAX);
  const body = text.body.trim().slice(0, BODY_MAX);
  return title && body ? { title, body } : null;
}

function toMillis(value) {
  if (!value) return 0;
  return value.toMillis ? value.toMillis() : new Date(value).getTime();
}

/** Zibo'nun `SubscriptionProvider.tier` mantığı: süresi geçmişse free. */
async function isPro(uid, now) {
  try {
    const snap = await db.collection('users').doc(uid).collection('state').doc('subscriptionState').get();
    if (!snap.exists) return false;
    const data = snap.data();
    if (!['pro', 'proplus'].includes(data.subscriptionTier)) return false;
    const expiry = Date.parse(data.subscriptionExpiryDate || '');
    return Number.isFinite(expiry) && expiry > now.getTime();
  } catch (error) {
    console.warn(`isPro okunamadı: uid=${uid}`, error.message || error);
    return false;
  }
}

async function claim(ref) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists || snap.data().status !== 'pending') return false;
    tx.update(ref, { status: 'sending', claimedAt: admin.firestore.FieldValue.serverTimestamp() });
    return true;
  });
}

async function recipientsFor(data) {
  if (data.testUid) {
    const snap = await db.collection('users').doc(String(data.testUid)).get();
    return snap.exists ? [{ uid: snap.id, ...snap.data() }] : [];
  }
  return fetchAllUsers();
}

async function processBroadcast(doc, now) {
  const data = doc.data();
  const texts = {};
  for (const lang of ['tr', 'en', 'es']) {
    const t = cleanText(data.texts && data.texts[lang]);
    if (t) texts[lang] = t;
  }
  if (Object.keys(texts).length === 0) {
    await doc.ref.update({ status: 'failed', error: 'metin yok', finishedAt: admin.firestore.FieldValue.serverTimestamp() });
    return;
  }

  const isTest = Boolean(data.testUid);
  const audience = data.audience || 'all';
  const users = await recipientsFor(data);
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (let i = 0; i < users.length; i += CHUNK) {
    await Promise.all(
      users.slice(i, i + CHUNK).map(async (user) => {
        if (!user.fcmToken) {
          skipped += 1;
          return;
        }
        if (!isTest) {
          if (audience === 'inactive7' && now.getTime() - toMillis(user.lastActiveAt) < 7 * DAY_MS) {
            skipped += 1;
            return;
          }
          if (audience === 'pro' && !(await isPro(user.uid, now))) {
            skipped += 1;
            return;
          }
        }
        const lang = await getLanguageCode(user.uid);
        // Test gönderiminde dil metni yoksa TR'ye düş (yönetici her zaman görsün).
        const text = texts[lang] || (isTest ? texts.tr || Object.values(texts)[0] : null);
        if (!text) {
          skipped += 1;
          return;
        }
        if (await sendToUser(user, 'broadcast', text.title, text.body)) sent += 1;
        else failed += 1;
      }),
    );
  }

  await doc.ref.update({
    status: 'sent',
    sentCount: sent,
    skippedCount: skipped,
    failedCount: failed,
    finishedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`Duyuru ${doc.id}${isTest ? ' (TEST)' : ''}: gönderildi=${sent} atlandı=${skipped} başarısız=${failed}`);
}

async function main() {
  const now = new Date();
  // Tek alanlı eşitlik sorgusu — bileşik indeks gerekmez; zaman filtresi JS'te.
  const snap = await db.collection('broadcasts').where('status', '==', 'pending').get();
  const due = snap.docs.filter((d) => toMillis(d.data().sendAfter) <= now.getTime());
  console.log(`Bekleyen duyuru: ${snap.size}, zamanı gelen: ${due.length}`);
  for (const doc of due) {
    if (!(await claim(doc.ref))) continue;
    try {
      await processBroadcast(doc, now);
    } catch (error) {
      console.error(`Duyuru ${doc.id} BAŞARISIZ:`, error);
      await doc.ref
        .update({ status: 'failed', error: String(error.message || error).slice(0, 300), finishedAt: admin.firestore.FieldValue.serverTimestamp() })
        .catch(() => {});
    }
  }
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
