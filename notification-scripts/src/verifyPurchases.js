// Satın alma doğrulaması — `hourlyAll.js` işi (docs/purchase_verification.md).
//
// Uygulama her satın almanın makbuzunu `purchaseRecords/{sha256(token)}`'a `pending` yazar
// (PurchaseRecorder). Bu iş Google Play Developer API'ye sorar ve belgeyi etiketler:
//   verified  Google onayladı (abonelikte `expiryTime` ile; `nextCheckAt` geldikçe tazelenir)
//   invalid   Google tanımıyor (`reason` nedenini yazar) — sahte makbuz adayı
//   canceled  Google iptal edilmiş diyor
//   voided    para iadesi / geri ödeme (günde bir `voidedpurchases` listesinden)
//   expired   token artık Google'da yok (eski abonelik, HTTP 410)
//
// **YALNIZCA ETİKETLER:** coin/üyelik geri ALINMAZ, sonuç panelde görünür. Yaptırım, gerçek veride
// yanlış alarm olmadığı görüldükten sonra ayrıca açılacak.
//
// Yetki: `FIREBASE_SERVICE_ACCOUNT_JSON`'daki servis hesabı Play Console'a kullanıcı olarak
// eklenmeli ve Google Play Android Developer API açık olmalı. Yetki yoksa (401/403) belgelere
// dokunulmaz, hata `stats/purchases.lastError`'a yazılır ve bir sonraki saat yeniden denenir.

const crypto = require('crypto');
const admin = require('firebase-admin');
const { JWT } = require('google-auth-library');
const { db } = require('./common');

const PACKAGE_NAME = 'com.dijitalkanka.dijital_kanka';
const API = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}`;
const SUBSCRIPTION_PRODUCTS = new Set(['zibo_pro', 'zibo_proplus']);
const MAX_PER_RUN = 200;
const RECHECK_MS = 24 * 60 * 60 * 1000;
const VOIDED_UTC_HOUR = 3; // Günde bir — liste Google'dan son 30 gün gelir, kaçan saat sorun değil.
const PROBLEM_STATUSES = ['invalid', 'canceled', 'voided'];
const COUNTED_STATUSES = ['pending', 'verified', 'expired', ...PROBLEM_STATUSES];

/** Geçici ya da yetki sorunu — hiçbir belge etiketlenmeden çalışma durur. */
class PlayApiError extends Error {}

const sha256 = (text) => crypto.createHash('sha256').update(text).digest('hex');

async function getAccessToken() {
  const account = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  const client = new JWT({
    email: account.client_email,
    key: account.private_key,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return (await client.getAccessToken()).token;
}

async function playGet(path, accessToken) {
  const response = await fetch(`${API}${path}`, { headers: { Authorization: `Bearer ${accessToken}` } });
  const body = await response.json().catch(() => ({}));
  const message = body.error ? String(body.error.message).slice(0, 200) : '';
  if (response.status === 401 || response.status === 403 || response.status === 429 || response.status >= 500) {
    throw new PlayApiError(`HTTP ${response.status}: ${message}`);
  }
  return { status: response.status, body, message };
}

/** Tek seferlik ürün (coin paketi, reklamsız). `purchaseState`: 0 alındı, 1 iptal, 2 bekliyor. */
function resultFromProduct(body) {
  const common = {
    googleOrderId: body.orderId || null,
    purchaseTimeMillis: body.purchaseTimeMillis || null,
    regionCode: body.regionCode || null,
    testPurchase: body.purchaseType === 0,
  };
  if (body.purchaseState === 0) return { status: 'verified', ...common };
  if (body.purchaseState === 1) return { status: 'canceled', ...common };
  return null; // Ödeme henüz tamamlanmadı — `pending` kalır.
}

function resultFromSubscription(productId, body) {
  const state = body.subscriptionState;
  if (state === 'SUBSCRIPTION_STATE_PENDING') return null;
  const item = (body.lineItems || []).find((line) => line.productId === productId);
  if (!item) return { status: 'invalid', reason: 'product_mismatch' };
  const common = {
    subscriptionState: state || null,
    expiryTime: item.expiryTime || null,
    googleOrderId: body.latestOrderId || null,
    regionCode: body.regionCode || null,
    testPurchase: Boolean(body.testPurchase),
  };
  if (state === 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED') return { status: 'canceled', ...common };
  return { status: 'verified', ...common };
}

async function checkRecord(docId, data, accessToken) {
  if (typeof data.purchaseToken !== 'string' || sha256(data.purchaseToken) !== docId) {
    return { status: 'invalid', reason: 'hash_mismatch' };
  }
  const token = encodeURIComponent(data.purchaseToken);
  const isSubscription = SUBSCRIPTION_PRODUCTS.has(data.productId);
  const path = isSubscription
    ? `/purchases/subscriptionsv2/tokens/${token}`
    : `/purchases/products/${encodeURIComponent(data.productId)}/tokens/${token}`;
  const { status, body, message } = await playGet(path, accessToken);
  if (status === 410) return { status: 'expired' };
  if (status !== 200) return { status: 'invalid', reason: `http_${status}: ${message}` };
  return isSubscription ? resultFromSubscription(data.productId, body) : resultFromProduct(body);
}

async function applyResult(doc, result, now) {
  const stillActive =
    result.status === 'verified' &&
    SUBSCRIPTION_PRODUCTS.has(doc.data().productId) &&
    result.subscriptionState !== 'SUBSCRIPTION_STATE_EXPIRED';
  await doc.ref.update({
    ...result,
    checkedAt: admin.firestore.Timestamp.fromDate(now),
    nextCheckAt: stillActive
      ? admin.firestore.Timestamp.fromMillis(now.getTime() + RECHECK_MS)
      : admin.firestore.FieldValue.delete(),
  });
}

/** Son 30 günün iade/geri ödemeleri. Kaydı olmayan (eski sürümden) satın almalar yalnızca sayılır. */
async function checkVoided(accessToken) {
  let pageToken = null;
  let total = 0;
  let matched = 0;
  do {
    const query = `?type=1&maxResults=1000${pageToken ? `&token=${encodeURIComponent(pageToken)}` : ''}`;
    const { status, body, message } = await playGet(`/purchases/voidedpurchases${query}`, accessToken);
    if (status !== 200) throw new PlayApiError(`voidedpurchases HTTP ${status}: ${message}`);
    for (const voided of body.voidedPurchases || []) {
      total += 1;
      const ref = db.collection('purchaseRecords').doc(sha256(voided.purchaseToken));
      const snap = await ref.get();
      if (!snap.exists || snap.data().status === 'voided') continue;
      await ref.update({
        status: 'voided',
        voidedTimeMillis: voided.voidedTimeMillis || null,
        voidedReason: voided.voidedReason ?? null,
        nextCheckAt: admin.firestore.FieldValue.delete(),
      });
      matched += 1;
    }
    pageToken = body.tokenPagination ? body.tokenPagination.nextPageToken : null;
  } while (pageToken);
  console.log(`İade listesi: ${total} kayıt, ${matched} yeni eşleşme`);
}

async function writeSummary(now, lastError) {
  const records = db.collection('purchaseRecords');
  const counts = {};
  for (const status of COUNTED_STATUSES) {
    counts[status] = (await records.where('status', '==', status).count().get()).data().count;
  }
  const problems = await records.where('status', 'in', PROBLEM_STATUSES).limit(50).get();
  const problemList = problems.docs
    .map((doc) => {
      const d = doc.data();
      return {
        uid: d.uid || null,
        productId: d.productId || null,
        status: d.status,
        reason: d.reason || null,
        orderId: d.googleOrderId || d.orderId || null,
        testPurchase: Boolean(d.testPurchase),
        createdAt: d.createdAt ? d.createdAt.toDate().toISOString() : null,
      };
    })
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)))
    .slice(0, 20);
  await db.collection('stats').doc('purchases').set({
    counts,
    problems: problemList,
    lastError,
    updatedAt: admin.firestore.Timestamp.fromDate(now),
  });
  console.log('Satın alma kayıtları:', JSON.stringify(counts));
}

async function main() {
  const now = new Date();
  const records = db.collection('purchaseRecords');
  const pending = await records.where('status', '==', 'pending').limit(MAX_PER_RUN).get();
  const due = await records
    .where('nextCheckAt', '<=', admin.firestore.Timestamp.fromDate(now))
    .limit(MAX_PER_RUN)
    .get();
  const docs = [...pending.docs, ...due.docs];
  const voidedDue = now.getUTCHours() === VOIDED_UTC_HOUR;
  console.log(`Bekleyen makbuz: ${pending.size}, yeniden kontrol: ${due.size}, iade taraması: ${voidedDue}`);

  let lastError = null;
  if (docs.length > 0 || voidedDue) {
    try {
      const accessToken = await getAccessToken();
      for (const doc of docs) {
        const result = await checkRecord(doc.id, doc.data(), accessToken);
        if (result) await applyResult(doc, result, now);
      }
      if (voidedDue) await checkVoided(accessToken);
    } catch (error) {
      if (!(error instanceof PlayApiError)) throw error;
      // Yetki/kota/Google arızası — kırmızı workflow yerine panelde görünür, sonraki saat yeniden dener.
      lastError = String(error.message);
      console.error('Play API kullanılamadı:', lastError);
    }
  }
  await writeSummary(now, lastError);
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
