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

const SUPPORTED_LANGUAGE_CODES = ['tr', 'en', 'es'];

/** `users/{uid}/state/languageCode` — bkz. lib/providers/locale_provider.dart. Doküman/alan
 * yoksa veya değer tanınmıyorsa varsayılan `'tr'` (istemcideki varsayılanla AYNI). Bildirim
 * içeriğini kullanıcının seçtiği arayüz diline göre göndermek için kullanılıyor (bkz.
 * content.js) — daha önce TÜM bildirimler dilden bağımsız hep Türkçe gidiyordu, kullanıcı
 * raporuyla düzeltildi. */
async function getLanguageCode(uid) {
  try {
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('state')
      .doc('languageCode')
      .get();
    if (!doc.exists) return 'tr';
    const value = doc.data().value;
    return SUPPORTED_LANGUAGE_CODES.includes(value) ? value : 'tr';
  } catch (error) {
    console.warn(`getLanguageCode başarısız: uid=${uid}`, error.message || error);
    return 'tr';
  }
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
      android: {
        priority: 'high',
        notification: {
          // Uygulama içindeki `push_notifications` kanalıyla (bkz.
          // lib/services/notification_service.dart) BİREBİR aynı id —
          // Android O+'ta bildirim, kanal ADI/ID'sine göre o kanalın kayıtlı
          // özel sesini (zibo_notification.wav, res/raw/) kullanır. Kanal
          // önceden (uygulama ilk açıldığında) oluşturulmamışsa bildirim
          // SESSİZCE düşer — bkz. PushNotificationService.initialize().
          channelId: 'push_notifications',
          // Yalnızca ÇOK eski (Android 7 ve altı, kanal kavramı olmayan)
          // cihazlar için geri düşüş — kanal varsa bu alan yok sayılır.
          sound: 'zibo_notification',
        },
      },
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
  istanbulDateKey,
  istanbulMinutesOfDay,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
};
