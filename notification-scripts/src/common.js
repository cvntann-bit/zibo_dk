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

/** 2026 GÜNCELLEMESİ — "hâlâ 2 kez geliyor" (özellikle Günlük Motivasyon,
 * günde 4 hedef saatiyle en sık tetiklenen tür olduğu için istatistiksel
 * olarak İLK bu türde fark edildi) kullanıcı raporu üzerine bulunan gerçek
 * kök neden: `users/{uid}.fcmToken` yalnızca YAZILIYOR
 * (`PushNotificationService._saveToken`), hesap değişimlerinde (Ayarlar >
 * "Çıkış Yap"/"Hesap Değiştir", bkz. `GoogleAuthService.signOut`/`signIn`)
 * ESKİ uid'in belgesinden HİÇ SİLİNMİYORDU. FCM token'ı Firebase Auth
 * kullanıcısından BAĞIMSIZ, cihazın/uygulama kurulumunun kendisine ait
 * olduğu için, bir kullanıcı AYNI fiziksel cihazda birden fazla Firebase
 * uid'i arasında geçiş yaparsa (anonim → Google'a bağlı → çıkış → yeni
 * anonim → farklı bir hesaba geçiş, vb. — bu proje boyunca test cihazında
 * SIK yaşanan bir senaryo), o cihazın `fcmToken`'ı BİRDEN FAZLA `users/{uid}`
 * belgesinde AYNI ANDA canlı kalabiliyordu — her iki uid de bağımsız olarak
 * "eligible" olduğunda AYNI fiziksel cihaza İKİ AYRI FCM mesajı gidiyordu
 * (istemci tarafındaki `messageId` dedup'ı bunu YAKALAYAMAZ, çünkü bunlar
 * GERÇEKTEN iki farklı mesaj/messageId — bkz. `push_notification_service.
 * dart`).
 *
 * Asıl/kök düzeltme istemci tarafında (`GoogleAuthService.signOut`/`signIn`
 * artık uid değişmeden HEMEN ÖNCE eski uid'in `fcmToken`'ını temizliyor) —
 * ama bu, YENİ hesap geçişleri için geçerli; bu değişiklikten ÖNCE zaten
 * oluşmuş ESKİ duplicate token'lar Firestore'da hâlâ duruyor olabilir. Bu
 * yüzden BURADA, sunucu tarafında da bir GÜVENLİK AĞI: `fetchAllUsers()`'ın
 * döndürdüğü listede AYNI `fcmToken` değerine sahip birden fazla kullanıcı
 * varsa yalnızca `fcmTokenUpdatedAt`'i EN YENİ olan (o token'ın o anki
 * GERÇEK/aktif sahibi — eski/terk edilmiş uid'ler token'ı bir daha hiç
 * YENİLEMEDİĞİ için zaman damgaları DONMUŞ kalır, bkz. `_saveToken`'ın her
 * `initialize()`'da çağrıldığı notu) TUTULUYOR, diğerleri elenip AYNI
 * fiziksel cihaza tekrar gönderim yapılması ENGELLENİYOR. Token'ı OLMAYAN
 * kullanıcılar (henüz izin vermemiş/hiç açmamış) bu filtrelemeden hiç
 * ETKİLENMİYOR. */
function dedupeByFcmToken(users) {
  const withoutToken = [];
  const byToken = new Map();
  for (const user of users) {
    if (!user.fcmToken) {
      withoutToken.push(user);
      continue;
    }
    const existing = byToken.get(user.fcmToken);
    if (!existing) {
      byToken.set(user.fcmToken, user);
      continue;
    }
    const existingTime = existing.fcmTokenUpdatedAt
      ? existing.fcmTokenUpdatedAt.toMillis()
      : 0;
    const candidateTime = user.fcmTokenUpdatedAt ? user.fcmTokenUpdatedAt.toMillis() : 0;
    if (candidateTime > existingTime) {
      console.warn(
        `dedupeByFcmToken: AYNI cihaz için birden fazla uid bulundu (${existing.uid} yerine ` +
          `${user.uid} tutuluyor, daha yeni fcmTokenUpdatedAt) — eski uid ATLANACAK.`,
      );
      byToken.set(user.fcmToken, user);
    } else {
      console.warn(
        `dedupeByFcmToken: AYNI cihaz için birden fazla uid bulundu (${user.uid} ATLANIYOR, ` +
          `${existing.uid} daha yeni fcmTokenUpdatedAt taşıyor).`,
      );
    }
  }
  return [...withoutToken, ...byToken.values()];
}

async function fetchAllUsers() {
  const snap = await db.collection('users').get();
  const users = snap.docs.map((doc) => ({ uid: doc.id, ...doc.data() }));
  return dedupeByFcmToken(users);
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

/** Faz 5 (E2) — Zibo Pro+'a özel bildirim sesleri. Android bir kanalın
 * sesini OLUŞTURULDUKTAN SONRA değiştiremediği için (bkz.
 * lib/services/notification_service.dart'taki AYNI gerekçe), 5 seçenek 5
 * AYRI, istemcide önceden oluşturulmuş kanala karşılık geliyor —
 * `user.proPlusSoundChoice` (`users/{uid}` kök alanı, istemci PushNotification
 * Provider.setProPlusSoundChoice tarafından yazılıyor) burada TEK bir yerde
 * çözülüyor, 5 betiğin HİÇBİRİNİN kendi başına bilmesi gerekmiyor. Sunucu
 * tarafında abonelik durumu TEKRAR doğrulanmıyor — istemci zaten seçim
 * arayüzünü yalnızca Pro+ kullanıcıya gösteriyor (bu projenin coin ekonomisiyle
 * AYNI istemci-yetkili mimarisi, bkz. docs/decisions/002/005). */
const PROPLUS_SOUND_CHANNELS = {
  '1': 'push_notifications_proplus_1',
  '2': 'push_notifications_proplus_2',
  '3': 'push_notifications_proplus_3',
  '4': 'push_notifications_proplus_4',
  '5': 'push_notifications_proplus_5',
};

async function sendToUser(user, type, title, body) {
  if (!user.fcmToken) return;
  const info = TYPE_INFO[type];
  if (!(await isTypeEnabled(user.uid, info.field))) return;
  const channelId = PROPLUS_SOUND_CHANNELS[user.proPlusSoundChoice] || 'push_notifications';
  try {
    await messaging.send({
      token: user.fcmToken,
      notification: { title, body },
      data: { type },
      android: {
        priority: 'high',
        notification: {
          // Uygulama içindeki kanallardan (bkz.
          // lib/services/notification_service.dart) BİREBİR aynı id —
          // Android O+'ta bildirim, kanal ADI/ID'sine göre o kanalın kayıtlı
          // özel sesini (varsayılan: zibo_notification.wav, Pro+ seçtiyse
          // proplus_sound_N.mp3, res/raw/) kullanır. Kanal önceden (uygulama
          // ilk açıldığında) oluşturulmamışsa bildirim SESSİZCE düşer — bkz.
          // PushNotificationService.initialize().
          channelId,
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
