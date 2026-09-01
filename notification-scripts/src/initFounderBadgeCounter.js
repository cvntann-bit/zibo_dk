// BİR KERELİK kurulum betiği (bkz. CLAUDE.md "Kurucu Üye Rozeti" bölümü) —
// artık istemci tarafında (Firestore transaction ile) canlı çalışan Kurucu
// Üye sayacının (`founderBadgeStatus/status`, bkz.
// lib/providers/founder_badge_provider.dart) BAŞLANGIÇ değerini oluşturur.
//
// **Bu betik, KALDIRILAN `grantFounderBadges.js`'in YERİNE geçti** — o eski
// betik "ilk 500 KAYIT OLAN kullanıcıya" rozet veriyordu (Firebase Auth
// `creationTime`'a göre); kullanıcının yeni isteğiyle rozet artık "Google
// hesabına BAĞLANAN ilk 500 kullanıcı"ya, uygulama içi canlı bir sayaçla
// veriliyor. Bu betiğin TEK işi: eğer eski betik DAHA ÖNCE gerçekten
// çalıştırılıp bazı kullanıcılara rozet vermişse, yeni sayacı SIFIRDAN
// değil o gerçek sayıdan başlatmak — TÜM kullanıcıları tarayıp
// `costumeState.ownedIds` içinde `founder_badge` arayarak kendi hesaplar
// (elle Firebase Console'da saymaya GEREK KALMADAN).
//
// GÜVENLİK — `cleanupStaleAnonymousUsers.js`/eski `grantFounderBadges.js`
// ile AYNI dry-run-varsayılan desen: `DRY_RUN=false` verilmedikçe HİÇBİR
// ŞEY YAZMAZ, yalnızca sayıp loglar. `founderBadgeStatus/status` dokümanı
// ZATEN VARSA (bu betik daha önce çalıştırılmış VEYA özellik canlıya
// alınıp sayaç artık GERÇEK kullanıcı bağlamalarıyla ilerliyor olabilir)
// `FORCE=true` AÇIKÇA verilmedikçe ÜZERİNE YAZILMAZ — canlı bir sayacı
// yanlışlıkla sıfırlamamak için.

const { db, auth } = require('./common');

const DRY_RUN = process.env.DRY_RUN !== 'false';
const FORCE = process.env.FORCE === 'true';
const FOUNDER_BADGE_ID = 'founder_badge';
const STATUS_COLLECTION = 'founderBadgeStatus';
const STATUS_DOC_ID = 'status';

async function listAllAuthUids() {
  const uids = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    uids.push(...result.users.map((u) => u.uid));
    pageToken = result.pageToken;
  } while (pageToken);
  return uids;
}

/** TÜM kullanıcıları tarayıp `costumeState.ownedIds` içinde ZATEN
 * `founder_badge` id'sine sahip olanları sayar. */
async function countExistingFounderBadges() {
  const uids = await listAllAuthUids();
  console.log(`Toplam ${uids.length} Firebase Auth kullanıcısı taranıyor...`);
  let count = 0;
  for (const uid of uids) {
    const snap = await db
      .collection('users')
      .doc(uid)
      .collection('state')
      .doc('costumeState')
      .get();
    const ownedIds =
      snap.exists && Array.isArray(snap.data().ownedIds) ? snap.data().ownedIds : [];
    if (ownedIds.includes(FOUNDER_BADGE_ID)) {
      count++;
      console.log(`  Kurucu Üye rozeti zaten var: uid=${uid}`);
    }
  }
  return count;
}

async function main() {
  console.log(`Başlıyor — DRY_RUN=${DRY_RUN}, FORCE=${FORCE}`);
  const existingCount = await countExistingFounderBadges();
  console.log(`Toplam ${existingCount} kullanıcıda ZATEN "Kurucu Üye" rozeti var.`);

  const statusRef = db.collection(STATUS_COLLECTION).doc(STATUS_DOC_ID);
  const statusSnap = await statusRef.get();

  if (statusSnap.exists && !FORCE) {
    console.log(
      `founderBadgeStatus/status ZATEN VAR (count=${statusSnap.data().count}) — canlı bir ` +
        `sayacı yanlışlıkla sıfırlamamak için ÜZERİNE YAZILMADI. Kasıtlı olarak sıfırlamak ` +
        `istiyorsanız FORCE=true verin.`,
    );
    return;
  }

  if (DRY_RUN) {
    console.log(
      `[DRY RUN] founderBadgeStatus/status, count=${existingCount} ile ` +
        `${statusSnap.exists ? 'ÜZERİNE YAZILACAKTI (FORCE)' : 'OLUŞTURULACAKTI'} ` +
        `(GERÇEKTE yazılmadı).`,
    );
    return;
  }

  await statusRef.set({ count: existingCount });
  console.log(`founderBadgeStatus/status oluşturuldu/güncellendi: count=${existingCount}.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
