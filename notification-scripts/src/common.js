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
// `auth` — yalnızca bakım betikleri (bkz. cleanupStaleAnonymousUsers.js)
// için; 4 bildirim betiğinin hiçbiri Auth'a dokunmuyor.
const auth = app.auth();

const DEFAULT_TIME_ZONE = 'Europe/Istanbul';

/** `users/{uid}.timeZone` — bkz. `PushNotificationService.touchLastActive`
 * (Flutter tarafı, cihazın IANA saat dilimini `FlutterTimezone.
 * getLocalTimezone()` ile okuyup yazıyor). Alan yoksa (eski uygulama sürümü,
 * henüz güncellemeyen kullanıcı) VEYA geçersiz bir IANA ismiyse [DEFAULT_TIME_ZONE]'a
 * düşülür — bu, 2026 güncellemesinden ÖNCEki davranışla (herkese İstanbul
 * saatine göre gönderim) TUTARLI bir geri düşüş, hiç kimse "kırılmıyor".
 * `Intl.DateTimeFormat`'ın yerleşik IANA veritabanı desteği kullanıldığı için
 * yaz/kış saati (DST) otomatik doğru hesaplanıyor — ek bir npm paketi
 * GEREKMEDİ. */
function resolveTimeZone(user) {
  return (user && user.timeZone) || DEFAULT_TIME_ZONE;
}

function formatInTimeZone(date, timeZone, options) {
  try {
    return new Intl.DateTimeFormat('en-US', { ...options, timeZone }).format(date);
  } catch (error) {
    // Geçersiz/tanınmayan IANA ismi — varsayılana düş.
    console.warn(
      `formatInTimeZone geçersiz timeZone='${timeZone}', Europe/Istanbul'a düşülüyor`,
      error.message || error,
    );
    return new Intl.DateTimeFormat('en-US', { ...options, timeZone: DEFAULT_TIME_ZONE }).format(
      date,
    );
  }
}

/** [user]'ın KENDİ yerel saatindeki saat değeri (0-23) — bildirim
 * betiklerinin "şu an bu kullanıcı için doğru gönderim saati mi?" kontrolü
 * için TEK veri kaynağı (bkz. her betikteki `TARGET_LOCAL_HOURS`). */
function userLocalHour(user, date) {
  const formatted = formatInTimeZone(date, resolveTimeZone(user), {
    hour: 'numeric',
    hour12: false,
  });
  // Bazı ICU sürümleri gece yarısı için "24" döndürüyor — 0'a normalize et.
  const hour = parseInt(formatted, 10);
  return hour === 24 ? 0 : hour;
}

/** [user]'ın KENDİ yerel takvim gününü `YYYY-MM-DD` olarak döner — "bugün
 * hedefini işaretledi mi?"/"bugünkü su hedefini tamamladı mı?" gibi
 * kontrollerin kullanıcının GERÇEK yerel gününe göre yapılması için (eski
 * tasarımda TÜM kullanıcılar için TEK bir sabit Europe/Istanbul günü
 * varsayılıyordu — `timeZone` alanı olmayan kullanıcılar için hâlâ o
 * varsayılana düşülüyor, bkz. `resolveTimeZone`). */
function userDateKey(user, date) {
  const parts = formatInTimeZone(date, resolveTimeZone(user), {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  });
  // 'en-US' formatı "MM/DD/YYYY" döner — "YYYY-MM-DD"ye çevir.
  const [month, day, year] = parts.split('/');
  return `${year}-${month}-${day}`;
}

async function fetchAllUsers() {
  const snap = await db.collection('users').get();
  return snap.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
}

/** 2026 GÜNCELLEMESİ — "catch-up" penceresi: eskiden her betik
 * `TARGET_LOCAL_HOURS.includes(userLocalHour(u, now))` ile "şu an TAM hedef
 * saat mi?" diye soruyordu — GitHub Actions'ın saatlik cron tetiklemelerini
 * sık sık GECİKTİRDİĞİ/hiç ateşlemediği gerçek dünya kanıtlarıyla
 * doğrulandı (bkz. CLAUDE.md "Push Bildirimleri" bölümündeki GitHub yük
 * dokümantasyonu VE bu güncellemenin kendi bulgusu — 2026-08-25 21:54'teki
 * saat-dilimi dağıtımından SONRA art arda 33+ saat boyunca TÜM betiklerde
 * "0 kullanıcı hedef saatte" görüldü, oysa hemen ÖNCESİNDE gönderimler
 * sorunsuz çalışıyordu) — bir tetikleme TAM o dakikada ateşlenmezse, o
 * kullanıcının o günkü dilimi bir daha HİÇ yakalanamıyordu (ertesi gün
 * `now` ilerleyip hedef saat GERİDE kalana kadar). Artık "hedef saat(ler)
 * GEÇTİ mi VE bugün bu tür için henüz `notifyState`'e işlenmedi mi?"
 * soruluyor — gecikmiş/atlanmış bir tetikleme, GÜN İÇİNDE SONRAKİ (gecikmeli
 * de olsa) herhangi bir çalıştırmada hâlâ doğru şekilde yakalanabiliyor.
 *
 * `user.notifyState[type]` = `{dateKey, sentHours}`, `users/{uid}`
 * dokümanının KENDİSİNDE tutuluyor — `fetchAllUsers()` zaten TÜM dokümanı
 * çektiği için bunu okumak EK bir Firestore sorgusu GEREKTİRMİYOR. `dateKey`
 * bugünkünden FARKLIYSA (yeni bir yerel gün) `sentHours` sıfırlanmış
 * SAYILIR (henüz hiçbir dilim bugün için işlenmedi). */
function pendingNotifyHours(user, type, targetHours, now) {
  const dateKey = userDateKey(user, now);
  const localHour = userLocalHour(user, now);
  const state = (user.notifyState && user.notifyState[type]) || {};
  const sentHours = state.dateKey === dateKey ? state.sentHours || [] : [];
  return targetHours.filter((h) => localHour >= h && !sentHours.includes(h));
}

/** [pendingNotifyHours]'ın döndürdüğü (veya kısmen değerlendirilmiş) saatleri
 * bu kullanıcı için "bugün işlendi" diye kalıcı olarak işaretler. HEM
 * gerçekten bir bildirim GÖNDERİLDİĞİNDE HEM DE altta yatan koşul zaten
 * karşılanmış olduğu için gönderim BİLEREK ATLANDIĞINDA (ör. hedef zaten
 * işaretlenmiş, su hedefi zaten tamamlanmış) çağrılmalı — ikisi de "bu dilim
 * bugün için değerlendirildi" anlamına gelir; aksi halde aynı günün SONRAKİ
 * bir çalıştırmasında (koşul o sırada değişmiş olabileceği için) aynı
 * kullanıcıya birden fazla bildirim gitme riski doğar. Önceki
 * `sentHours`'la (varsa, AYNI `dateKey` için) BİRLEŞTİRİLİR — tek bir
 * çağrının önceki dilimlerin kaydını SİLMEMESİ için (bkz. Günlük Motivasyon'un
 * dört ayrı hedef saati). */
async function markNotifyHoursSent(user, type, dateKey, newHours) {
  const state = (user.notifyState && user.notifyState[type]) || {};
  const priorHours = state.dateKey === dateKey ? state.sentHours || [] : [];
  const sentHours = [...new Set([...priorHours, ...newHours])];
  try {
    await db
      .collection('users')
      .doc(user.uid)
      .set({ notifyState: { [type]: { dateKey, sentHours } } }, { merge: true });
  } catch (error) {
    console.warn(
      `markNotifyHoursSent başarısız: uid=${user.uid} type=${type}`,
      error.message || error,
    );
  }
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
  water_reminder: { field: 'waterReminder' },
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
  auth,
  userLocalHour,
  userDateKey,
  pendingNotifyHours,
  markNotifyHoursSent,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
};
