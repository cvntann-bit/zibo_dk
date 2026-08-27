// BİR KERELİK bakım betiği (bkz. CLAUDE.md "Kurucu Üye" bölümü) —
// kullanıcı isteği: ilk 500 (varsayılan, `FOUNDER_COUNT` ile override
// edilebilir) kayıt olan kullanıcıya özel, SATIN ALINAMAYAN bir "Kurucu
// Üye" rozeti ver. `cleanupStaleAnonymousUsers.js`'in BİREBİR aynı
// dry-run-varsayılan güvenlik deseni — bu betik VARSAYILAN olarak
// kimseye rozet VERMEZ, yalnızca kime verileceğini konsola loglar
// (`DRY_RUN=false` verilmedikçe).
//
// **"İlk N kullanıcı" sırası — Firestore'da `createdAt` alanı YOK, TEK
// güvenilir/manipüle-edilemez sinyal Firebase Auth'un kendi
// `metadata.creationTime`'ı** (bkz. `cleanupStaleAnonymousUsers.js`'teki
// AYNI `auth.listUsers()` sayfalama deseni — o betik bunu "son aktivite"
// için kullanıyor, burada "ilk kayıt sırası" için kullanılıyor).
//
// **Rozet, `CostumeProvider.markOwned('founder_badge')` ile AYNI JSON
// şeklini üretir** (`users/{uid}/state/costumeState.ownedIds` dizisine
// `'founder_badge'` id'sinin eklenmesi) — istemci tarafında HİÇBİR özel
// kod GEREKMEZ, `CostumeProvider.isOwned('founder_badge')` sorunsuz
// çalışır (zaten satın alma-agnostik, bkz. `lib/data/founder_badge.dart`
// dokümantasyonu — bu id BİLEREK `costumes.dart`'taki satılabilir listeye
// EKLENMEDİ).
//
// **Tekrar çalıştırmaya karşı GÜVENLİ (idempotent)** — bir kullanıcı
// zaten `founder_badge`'e sahipse (`ownedIds` dizisinde varsa) atlanır,
// yeniden eklenmez/loglanmaz. Bu, kullanıcının "ilk 500'ü kilitlemek"
// istediği ANI netleşene kadar betiği güvenle birkaç kez (dry-run ile)
// deneyebilmesini sağlıyor.

const { db, auth } = require('./common');

const DRY_RUN = process.env.DRY_RUN !== 'false';
const FOUNDER_COUNT = Number(process.env.FOUNDER_COUNT || '500');
const FOUNDER_BADGE_ID = 'founder_badge';

async function listAllAuthUsersSortedByCreation() {
  const users = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    users.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);
  users.sort(
    (a, b) => new Date(a.metadata.creationTime) - new Date(b.metadata.creationTime),
  );
  return users;
}

/** [uid]'nin `costumeState` belgesine `founder_badge`'i (yoksa) ekler —
 * `CostumeProvider._save()`'in ürettiği `{ownedIds: [...], equippedId:
 * ...}` şekliyle BİREBİR uyumlu. Zaten sahipse `false` (atlandı), yeni
 * eklendiyse `true` döner. */
async function grantFounderBadge(uid) {
  const costumeRef = db.collection('users').doc(uid).collection('state').doc('costumeState');
  const snap = await costumeRef.get();
  const data = snap.exists ? snap.data() : {};
  const ownedIds = Array.isArray(data.ownedIds) ? data.ownedIds : [];
  if (ownedIds.includes(FOUNDER_BADGE_ID)) return false;

  if (!DRY_RUN) {
    await costumeRef.set(
      { ...data, ownedIds: [...ownedIds, FOUNDER_BADGE_ID] },
      { merge: true },
    );
  }
  return true;
}

async function main() {
  console.log(`Başlıyor — DRY_RUN=${DRY_RUN}, FOUNDER_COUNT=${FOUNDER_COUNT}`);
  const users = await listAllAuthUsersSortedByCreation();
  console.log(`Toplam ${users.length} Firebase Auth kullanıcısı bulundu.`);

  const founders = users.slice(0, FOUNDER_COUNT);
  console.log(
    `İlk ${founders.length} kullanıcı (creationTime'a göre sıralı) "Kurucu Üye" adayı.`,
  );

  let grantedCount = 0;
  let alreadyHadCount = 0;

  for (const user of founders) {
    const granted = await grantFounderBadge(user.uid);
    if (granted) {
      console.log(
        `${DRY_RUN ? '[DRY RUN] ROZET VERİLECEK' : 'ROZET VERİLDİ'}: uid=${user.uid} ` +
          `(kayıt: ${user.metadata.creationTime})`,
      );
      grantedCount++;
    } else {
      alreadyHadCount++;
    }
  }

  console.log(
    `Bitti — ${grantedCount} kullanıcı${DRY_RUN ? ' rozet alacaktı (DRY RUN, GERÇEKTE verilmedi)' : 'ya rozet verildi'}, ` +
      `${alreadyHadCount} kullanıcı zaten sahipti (atlandı).`,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
