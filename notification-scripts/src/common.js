// Dört bildirim betiği (dailyMotivation/streakReminder/dailyRewardReminder/
// reEngagement) arasında paylaşılan yardımcılar. GitHub Actions'ta çalışır,
// Firebase CLI/Cloud Functions/Cloud Scheduler'a HİÇ ihtiyaç duymaz —
// yalnızca `firebase-admin` SDK'sı ile doğrudan Firestore'u okuyup FCM'e
// gönderim yapar (Blaze plan GEREKTİRMEZ, bkz. CLAUDE.md "Push Bildirimleri"
// bölümü).

const admin = require('firebase-admin');

function initAdmin() {
  if (admin.apps.length > 0) return admin.app();
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT_JSON ortam değişkeni eksik — GitHub Secrets\'a ' +
        'servis hesabı JSON\'ı eklendi mi? (bkz. CLAUDE.md kurulum adımları)',
    );
  }
  const serviceAccount = JSON.parse(raw);
  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const app = initAdmin();
const db = app.firestore();
const messaging = app.messaging();

/** `uid`+`dateKey` (YYYY-MM-DD, Europe/Istanbul) → 0..slotCount-1 arası
 * deterministik bir dilim. Her kullanıcı her GÜN AYNI (ama kullanıcıdan
 * kullanıcıya FARKLI) dilimi seçer — GitHub Actions cron'u tek bir sabit
 * UTC zamanında çalıştığı için "her kullanıcıya günde 1 kez, rastgele bir
 * saatte" isteği bu hash + "workflow'u pencere boyunca birden çok kez
 * tetikle, yalnızca o anki dilime denk gelenlere gönder" deseniyle
 * karşılanıyor (bkz. daily-motivation.yml'nin cron listesi). */
function pickSlot(uid, dateKey, slotCount) {
  const input = `${uid}:${dateKey}`;
  let hash = 0;
  for (let i = 0; i < input.length; i++) {
    hash = (hash * 31 + input.charCodeAt(i)) >>> 0;
  }
  return hash % slotCount;
}

/** Şu anki UTC zamanını Europe/Istanbul (sabit UTC+3, Türkiye 2016'dan beri
 * yaz/kış saati uygulamıyor) gün anahtarına (`YYYY-MM-DD`) çevirir. */
function istanbulDateKey(date) {
  const istanbul = new Date(date.getTime() + 3 * 60 * 60 * 1000);
  return istanbul.toISOString().slice(0, 10);
}

/** Şu anki UTC zamanının Europe/Istanbul saatindeki dakika-of-day değeri. */
function istanbulMinutesOfDay(date) {
  const istanbul = new Date(date.getTime() + 3 * 60 * 60 * 1000);
  return istanbul.getUTCHours() * 60 + istanbul.getUTCMinutes();
}

async function fetchAllUsers() {
  const snap = await db.collection('users').get();
  return snap.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
}

/** `users/{uid}/state/pushNotificationState` — bkz.
 * lib/providers/push_notification_provider.dart. Doküman/alan yoksa
 * varsayılan `true` (istemcideki varsayılanla AYNI). */
async function isTypeEnabled(uid, field) {
  const doc = await db
    .collection('users')
    .doc(uid)
    .collection('state')
    .doc('pushNotificationState')
    .get();
  if (!doc.exists) return true;
  const data = doc.data() || {};
  return data[field] !== false;
}

/** `type` → `PushNotificationType.wireValue` (bkz.
 * lib/models/push_notification_type.dart) ve tercih dokümanındaki bool alan
 * adının eşlemesi — tek yerde tutulsun diye. */
const TYPE_INFO = {
  daily_motivation: { field: 'dailyMotivation' },
  streak_reminder: { field: 'streakReminder' },
  daily_reward: { field: 'dailyReward' },
  re_engagement: { field: 'reEngagement' },
};

async function sendToUser(user, type, title, body) {
  if (!user.fcmToken) return;
  const info = TYPE_INFO[type];
  if (!(await isTypeEnabled(user.uid, info.field))) return;
  try {
    await messaging.send({
      token: user.fcmToken,
      notification: { title, body },
      data: { type },
      android: { priority: 'high' },
    });
    console.log(`Gönderildi: uid=${user.uid} type=${type}`);
  } catch (error) {
    // Geçersiz/eskimiş token — sessizce atla, tüm çalıştırmayı bozmasın.
    // `fcmToken` bir sonraki uygulama açılışında zaten yenilenip üzerine
    // yazılacak (bkz. PushNotificationService).
    console.warn(`sendToUser başarısız: uid=${user.uid} type=${type}`, error.message || error);
  }
}

module.exports = {
  db,
  messaging,
  pickSlot,
  istanbulDateKey,
  istanbulMinutesOfDay,
  fetchAllUsers,
  sendToUser,
};
