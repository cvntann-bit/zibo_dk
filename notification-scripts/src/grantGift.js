// BİR KERELİK yönetim betiği — uygulama sahibinin belirli bir kullanıcıya (ör. yakınına)
// HEDİYE vermesi: ZC ekleme, Zibo Pro/Pro+ üyelik, sınırsız oyun hakkı.
// **Herhangi bir cron'a/otomatik tekrara BAĞLI DEĞİL** — yalnızca elle
// (`workflow_dispatch`, bkz. `.github/workflows/grant-gift.yml`) tetiklenir.
//
// **GÜVENLİK — varsayılan DRY RUN.** `DRY_RUN=false` verilmedikçe HİÇBİR ŞEY yazmaz;
// yalnızca hedef hesabı bulur (Auth kaydı: uid, görünen ad, giriş sağlayıcıları) ve
// mevcut durumu + NE YAPILACAĞINI loglar. Önce dry-run ile doğru hesap olduğunu
// doğrula, sonra `dry_run: false` ile tekrar çalıştır.
//
// Girdiler (ortam değişkeni):
//   TARGET_EMAIL     Hedef kullanıcının Google e-postası (Auth'ta kayıtlı olmalı)
//   COINS            Eklenecek ZC (tamsayı, varsayılan 0)
//   TIER             'none' (dokunma) | 'pro' | 'proplus'  (varsayılan 'none')
//   UNLIMITED_PLAYS  'true' → Oyun Salonu günlük hak sınırı kalkar (uygulama 1.14.1+ okur)
//   GRANT_ID         ZC için tekrar-koruması anahtarı (COINS > 0 ise ZORUNLU) — aynı
//                    GRANT_ID ile ikinci çalıştırma ZC'yi TEKRAR eklemez.
//   DRY_RUN          varsayılan 'true'
//
// Neden doğrudan Firestore'a yazılıyor: `coinState`/`subscriptionState` için
// `firestore.rules` istemci yazımını kısıtlıyor (tek yazımda ≤ 10500 ZC kazanç vb.);
// Admin SDK kuralları aşar (bkz. `processReferralRewards.js`'teki AYNI desen).
// Bu bir bakım/hediye yolu — oyun içi ekonomiyi yeniden tasarlamıyor.
//
// Uygulama tarafı notu: hesap sahibi uygulamayı TAMAMEN kapatıp açmalı. Açıkken
// yazılan eski yerel durum, buluttaki daha büyük toplamları kural gereği
// reddedilir (kayıp yok), ama ekran yeniden açılana kadar eski bakiyeyi gösterir.

const admin = require('firebase-admin');
const { db, auth } = require('./common');

const MAX_STORED_TRANSACTIONS = 50; // CoinProvider._maxStoredTransactions ile AYNI
const FAR_FUTURE_EXPIRY = '2099-12-31T00:00:00.000Z'; // SubscriptionProvider: ISO string, ≤ 40 karakter
const PRODUCT_BY_TIER = { pro: 'zibo_pro', proplus: 'zibo_proplus' };

const DRY_RUN = process.env.DRY_RUN !== 'false';
const EMAIL = (process.env.TARGET_EMAIL || '').trim().toLowerCase();
const COINS = Number(process.env.COINS || '0');
const TIER = (process.env.TIER || 'none').trim().toLowerCase();
const UNLIMITED_PLAYS = process.env.UNLIMITED_PLAYS === 'true';
const GRANT_ID = (process.env.GRANT_ID || '').trim();

function fail(message) {
  console.error(`HATA: ${message}`);
  process.exit(1);
}

function validateInputs() {
  if (!EMAIL || !EMAIL.includes('@')) fail('TARGET_EMAIL geçerli bir e-posta olmalı.');
  if (!Number.isInteger(COINS) || COINS < 0 || COINS > 1000000) {
    fail('COINS 0 ile 1.000.000 arasında bir tamsayı olmalı.');
  }
  if (!['none', 'pro', 'proplus'].includes(TIER)) fail("TIER 'none', 'pro' veya 'proplus' olmalı.");
  if (COINS > 0 && !/^[A-Za-z0-9_-]{3,60}$/.test(GRANT_ID)) {
    fail('COINS > 0 iken GRANT_ID (3-60 karakter: harf, rakam, _ veya -) ZORUNLU — çift ekleme koruması.');
  }
}

function stateRef(uid, name) {
  return db.collection('users').doc(uid).collection('state').doc(name);
}

async function main() {
  validateInputs();
  console.log(`Mod: ${DRY_RUN ? 'DRY RUN (hiçbir şey yazılmaz)' : 'GERÇEK YAZIM'}`);
  console.log(`Hedef: ${EMAIL} | ZC: +${COINS} | Üyelik: ${TIER} | Sınırsız oyun hakkı: ${UNLIMITED_PLAYS}`);

  let user;
  try {
    user = await auth.getUserByEmail(EMAIL);
  } catch (error) {
    fail(`Bu e-postayla Auth kaydı bulunamadı (${error.code || error.message}). Kullanıcı uygulamada Google ile giriş yaptı mı?`);
  }
  console.log(
    `Hesap bulundu: uid=${user.uid}, ad=${user.displayName || '-'}, ` +
      `sağlayıcılar=${user.providerData.map((p) => p.providerId).join(',') || '(anonim)'}, ` +
      `oluşturulma=${user.metadata.creationTime}, son giriş=${user.metadata.lastSignInTime}`,
  );

  const [coinSnap, subSnap, gameSnap] = await Promise.all([
    stateRef(user.uid, 'coinState').get(),
    stateRef(user.uid, 'subscriptionState').get(),
    stateRef(user.uid, 'gamePointsState').get(),
  ]);
  const coin = coinSnap.exists ? coinSnap.data() : null;
  console.log(
    `Şu an: bakiye=${coin ? coin.balance : '(coinState yok)'}, ` +
      `üyelik=${subSnap.exists ? subSnap.data().subscriptionTier : '(yok → free)'}, ` +
      `oyun durumu=${gameSnap.exists ? 'var' : 'yok'}`,
  );

  const grantRef = db.collection('users').doc(user.uid).collection('giftGrants').doc(GRANT_ID || '_none');
  const alreadyGranted = COINS > 0 && (await grantRef.get()).exists;
  if (alreadyGranted) console.log(`UYARI: GRANT_ID=${GRANT_ID} bu hesaba ZATEN uygulanmış — ZC TEKRAR eklenmeyecek.`);

  const plan = [];
  if (COINS > 0 && !alreadyGranted) plan.push(`ZC: ${coin ? coin.balance : 0} → ${(coin ? coin.balance : 0) + COINS}`);
  if (TIER !== 'none') plan.push(`Üyelik: ${TIER} (bitiş ${FAR_FUTURE_EXPIRY})`);
  if (UNLIMITED_PLAYS) plan.push('gamePointsState.unlimitedPlays = true');
  console.log(plan.length ? `Plan: ${plan.join(' | ')}` : 'Plan: yapılacak bir şey yok.');
  if (DRY_RUN || plan.length === 0) {
    console.log(DRY_RUN ? 'DRY RUN — hiçbir şey yazılmadı.' : 'Bitti.');
    return;
  }

  if (COINS > 0 && !alreadyGranted) {
    const ref = stateRef(user.uid, 'coinState');
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const data = snap.exists ? snap.data() : {};
      const transactions = [
        { type: 'earn', amount: COINS, reason: 'Hediye', timestamp: new Date().toISOString() },
        ...(data.transactions || []),
      ].slice(0, MAX_STORED_TRANSACTIONS);
      tx.set(
        ref,
        {
          ...data,
          balance: (data.balance || 0) + COINS,
          totalEarned: (data.totalEarned || 0) + COINS,
          totalSpent: data.totalSpent || 0,
          transactions,
        },
        { merge: true },
      );
      tx.set(grantRef, { coins: COINS, grantedAt: admin.firestore.FieldValue.serverTimestamp() });
    });
    console.log(`ZC eklendi: +${COINS}`);
  }

  if (TIER !== 'none') {
    await stateRef(user.uid, 'subscriptionState').set(
      {
        subscriptionTier: TIER, // 'pro' | 'proplus' (SubscriptionTierJson)
        subscriptionExpiryDate: FAR_FUTURE_EXPIRY,
        subscriptionProductId: PRODUCT_BY_TIER[TIER],
      },
      { merge: true },
    );
    console.log(`Üyelik ayarlandı: ${TIER}`);
  }

  if (UNLIMITED_PLAYS) {
    await stateRef(user.uid, 'gamePointsState').set({ unlimitedPlays: true }, { merge: true });
    console.log('Sınırsız oyun hakkı işaretlendi (uygulama 1.14.1+ okur).');
  }
  console.log('Bitti.');
}

main().catch((error) => {
  console.error('Beklenmeyen hata:', error);
  process.exit(1);
});
