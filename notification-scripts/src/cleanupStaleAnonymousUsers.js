// BİR KERELİK bakım betiği (bkz. CLAUDE.md "Firebase Anonymous Auth
// temizliği" bölümü) — kullanıcı isteği: geçmiş test/geliştirme
// oturumlarında (her yeniden kurulum/uygulama verisi temizleme yeni bir
// anonim kimlik oluşturuyor, bkz. main.dart Anonymous Auth notu) Firebase'e
// "boşuna" kaydedilmiş, uzun süredir hiç açılmamış anonim kullanıcıları hem
// Firebase Authentication'dan HEM Firestore'dan (`users/{uid}` + `state/*`
// alt koleksiyonu) SİLER. **Herhangi bir cron'a/otomatik tekrara BAĞLI
// DEĞİL** — yalnızca elle (`workflow_dispatch`) tetiklenir; kullanıcı
// açıkça periyodik bir mekanizma İSTEMEDİ, yalnızca şu an birikmiş test
// artıklarının bir kerelik temizliğini istedi.
//
// **GÜVENLİK — varsayılan DRY RUN.** Bu betik VARSAYILAN olarak hiçbir şey
// SİLMEZ, yalnızca neyin silineceğini konsola loglar
// (`DRY_RUN=false` verilmedikçe). Gerçekten silmek isteyen kullanıcı
// `.github/workflows/cleanup-stale-anonymous-users.yml`'i ÖNCE
// `dry_run: true` (varsayılan) ile çalıştırıp listeyi gözden geçirmeli,
// sonra `dry_run: false` ile TEKRAR tetiklemeli. Bu, tersine çevrilemez bir
// silme işleminin (gerçek kullanıcı verisi + Auth kaydı) kör bir şekilde
// tek seferde çalıştırılmasını önlüyor.
//
// **"Terkedilmiş" tanımı — `MIN_INACTIVE_DAYS` (varsayılan 30) gündür
// hiçbir aktivite izi TAŞIMAYAN kullanıcı.** Aktivite İKİ kaynaktan
// belirleniyor, HANGİSİ daha YENİYSE O kullanılıyor (aktif bir kurulumu
// yanlışlıkla silmemek için elden geldiğince TEMKİNLİ bir seçim):
//   1. Firestore `users/{uid}.lastActiveAt` (bkz.
//      `PushNotificationService.touchLastActive` — `RootScreen`'in her öne
//      gelişinde tazelenir) — yalnızca push bildirimi özelliği
//      eklendikten SONRA en az bir kez açılmış kurulumlar için mevcut.
//   2. Firebase Auth'un KENDİ `metadata.lastRefreshTime` (yoksa
//      `lastSignInTime`, o da yoksa `creationTime`) — Firebase'in HER
//      kullanıcı için OTOMATİK tuttuğu, bizim kodumuza bağımlı OLMAYAN bir
//      sinyal; push bildirimi eklenmeden ÖNCEki eski test kullanıcıları
//      için TEK kaynak bu.
// İkisinden HİÇBİRİ yoksa (teorik olarak imkansız — Auth her zaman
// `creationTime` taşır) güvenlik gereği o kullanıcıya DOKUNULMUYOR.

const { db, auth } = require('./common');

const DRY_RUN = process.env.DRY_RUN !== 'false';
const MIN_INACTIVE_DAYS = Number(process.env.MIN_INACTIVE_DAYS || '30');
const THRESHOLD_MS = Date.now() - MIN_INACTIVE_DAYS * 24 * 60 * 60 * 1000;

async function lastActiveMsFromFirestore(uid) {
  try {
    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    const lastActiveAt = doc.data().lastActiveAt;
    if (!lastActiveAt) return null;
    return lastActiveAt.toMillis
      ? lastActiveAt.toMillis()
      : new Date(lastActiveAt).getTime();
  } catch (error) {
    console.warn(`Firestore lastActiveAt okunamadı: uid=${uid}`, error.message || error);
    return null;
  }
}

function lastActiveMsFromAuthMetadata(userRecord) {
  const { lastRefreshTime, lastSignInTime, creationTime } = userRecord.metadata;
  const candidate = lastRefreshTime || lastSignInTime || creationTime;
  return candidate ? new Date(candidate).getTime() : null;
}

/** `users/{uid}` dokümanı + TÜM `state/*` alt koleksiyonu — tek bir batch'te
 * silinir (`WriteBatch`'in 500 yazma sınırı bu proje ölçeğinde asla
 * aşılmaz, tek bir kullanıcının `state` alt koleksiyonu ~20 doküman). */
async function deleteFirestoreUserData(uid) {
  const userRef = db.collection('users').doc(uid);
  const stateDocs = await userRef.collection('state').listDocuments();
  const batch = db.batch();
  for (const docRef of stateDocs) batch.delete(docRef);
  batch.delete(userRef);
  await batch.commit();
}

async function listAllAuthUsers() {
  const users = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    users.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);
  return users;
}

async function main() {
  console.log(
    `Başlıyor — DRY_RUN=${DRY_RUN}, eşik=${MIN_INACTIVE_DAYS} gün ` +
      `(${new Date(THRESHOLD_MS).toISOString()}'ten eski aktivite → silinir)`,
  );
  const users = await listAllAuthUsers();
  console.log(`Toplam ${users.length} Firebase Auth kullanıcısı bulundu.`);

  let deletedCount = 0;
  let keptCount = 0;
  let skippedNoSignalCount = 0;

  for (const user of users) {
    const firestoreMs = await lastActiveMsFromFirestore(user.uid);
    const authMs = lastActiveMsFromAuthMetadata(user);
    const candidates = [firestoreMs, authMs].filter((ms) => ms !== null);
    const lastActiveMs = candidates.length > 0 ? Math.max(...candidates) : null;

    if (lastActiveMs === null) {
      console.log(`ATLA (hiç aktivite sinyali yok, güvenlik gereği dokunulmadı): uid=${user.uid}`);
      skippedNoSignalCount++;
      continue;
    }

    if (lastActiveMs >= THRESHOLD_MS) {
      keptCount++;
      continue;
    }

    const daysInactive = Math.floor(
      (Date.now() - lastActiveMs) / (24 * 60 * 60 * 1000),
    );
    console.log(
      `${DRY_RUN ? '[DRY RUN] SİLİNECEK' : 'SİLİNİYOR'}: uid=${user.uid} ` +
        `(${daysInactive} gündür etkin değil, son aktivite: ${new Date(lastActiveMs).toISOString()})`,
    );

    if (!DRY_RUN) {
      await deleteFirestoreUserData(user.uid);
      await auth.deleteUser(user.uid);
    }
    deletedCount++;
  }

  console.log(
    `Bitti — ${deletedCount} kullanıcı ${
      DRY_RUN ? 'silinecekti (DRY RUN, GERÇEKTE silinmedi)' : 'silindi'
    }, ${keptCount} kullanıcı aktif olduğu için korundu, ${skippedNoSignalCount} kullanıcı sinyal yokluğu nedeniyle atlandı.`,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
