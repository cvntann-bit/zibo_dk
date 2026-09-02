// Davet Et (referral) ödül işleyicisi — bkz. CLAUDE.md "Davet Et" bölümü VE
// lib/providers/referral_provider.dart'ın dokümantasyonu (ORADA "neden
// anlık değil" sorusunun TAM gerekçesi var). İstemciler (bkz.
// ReferralProvider.redeemCode) yalnızca `referralRedemptions` koleksiyonuna
// `status: 'pending'` bir "işlem talebi" bırakabiliyor — Firestore rules bu
// yazmayı KENDİ `refereeUid`'leriyle, kendilerinden FARKLI bir
// `referrerUid`'e, create-only olarak sınırlıyor (bkz. firestore.rules).
// Asıl coin kredisi BURADA, Admin SDK ile (rules'u atlayarak, GÜVENİLİR
// taraf olarak) gerçekleşiyor — davet edilenin cihazı davet edenin
// `coinState`'ine hiçbir zaman DOĞRUDAN yazmıyor.
//
// **Diğer 5 bildirim betiğinden/`cleanupStaleAnonymousUsers.js`'ten FARKLI
// olarak DRY_RUN varsayılanı `false`.** Bu betik EKLEYİCİ/DÜŞÜK RİSKLİ
// (yalnızca coin bakiyesi ARTIRIYOR, hiçbir şey SİLMİYOR/geri alınamaz bir
// işlem yapmıyor) ve gerçek cron otomasyonuyla (bkz. .github/workflows/
// process-referral-rewards.yml) çalışması amaçlanıyor — her saatlik
// çalıştırmada elle onay beklemek otomasyonun amacını bozardı. Yine de ilk
// elle tetiklemede sonucu önce loglayıp görmek isteyenler için
// `DRY_RUN=true` desteği KORUNDU.
//
// **Bilinen/kabul edilen sınırlama:** bu betik AYNI ANDA iki kez
// çalıştırılırsa (ör. örtüşen manuel + zamanlanmış tetikleme) teorik olarak
// aynı `pending` kaydı iki kez kredileyebilir (Firestore transaction/lock
// KULLANILMIYOR) — projenin genelindeki client-authoritative ekonomi risk
// kabulüyle AYNI kategoride, kapsam dışı bırakıldı (bkz. CLAUDE.md "Coin
// Ekonomisi Güvenliği" bölümü).
//
// **2026 güncellemesi — davet EDENİN `referralState` belgesine
// `successfulReferralCount` sayacı eklendi (bkz. `creditReferralReward`).**
// Sosyal/Paylaşım Rozetleri'nin ("Elçi"/"Topluluk Kurucusu", bkz. CLAUDE.md
// "Rozet Sistemi" bölümü) istemci tarafında kaç başarılı davet olduğunu
// öğrenebileceği TEK yol bu — `referralRedemptions` koleksiyonu istemciler
// için tamamen OKUNAMAZ (bkz. firestore.rules).

const admin = require('firebase-admin');
const { db } = require('./common');

// `lib/models/coin_economy.dart`'taki `CoinEconomy.referral` ile AYNI
// değer OLMALI — Node/Dart arasında paylaşılan bir sabit YOK (`content.js`
// TR/EN/ES metinlerini Dart'tan bağımsız tuttuğu AYNI desen), burada elle
// senkron tutuluyor. Dart tarafı değişirse BURASI da güncellenmeli.
const REFERRAL_REWARD_ZC = 100;

// `CoinProvider._maxStoredTransactions` ile AYNI — işlem geçmişi listesi
// sınırsız büyümesin diye yalnızca en yeni N kayıt tutulur.
const MAX_STORED_TRANSACTIONS = 200;

const DRY_RUN = process.env.DRY_RUN === 'true';

/** [uid]'nin `coinState` belgesine [REFERRAL_REWARD_ZC] kadar ekler —
 * `CoinProvider._save()`'in ürettiği JSON şekliyle (bkz. coin_provider.dart)
 * BİREBİR uyumlu bir işlem kaydı (`type: 'earn'`, `reason: 'Arkadaş
 * daveti'` — istemcideki dormant `CoinProvider.earnReferral()`'ın KULLANDIĞI
 * AYNI metin) en başa ekleniyor, ardından liste en yeni 200'e kırpılıyor.
 *
 * [isReferrer] `true` ise AYRICA `referralState` belgesindeki
 * `successfulReferralCount` sayacını +1 artırır — bkz. CLAUDE.md "Rozet
 * Sistemi" bölümü, "Sosyal/Paylaşım Rozetleri" alt bölümü ("Elçi"/"Topluluk
 * Kurucusu"). İstemciler `referralRedemptions` koleksiyonunu OKUYAMADIĞI
 * için (bkz. firestore.rules) bu sayaç, davet EDENİN kaç başarılı daveti
 * olduğunu istemci tarafında öğrenebileceği TEK yol — `merge: true` ile
 * yazılıyor ki istemcinin AYNI belgeye (`redeemCode()` çağrısıyla) yazdığı
 * `redeemed`/`referrerUid` alanları SİLİNMESİN. */
async function creditReferralReward(uid, { isReferrer = false } = {}) {
  const coinRef = db.collection('users').doc(uid).collection('state').doc('coinState');
  const snap = await coinRef.get();
  const data = snap.exists ? snap.data() : {};
  const balance = (data.balance || 0) + REFERRAL_REWARD_ZC;
  const totalEarned = (data.totalEarned || 0) + REFERRAL_REWARD_ZC;
  const transactions = [
    {
      type: 'earn',
      amount: REFERRAL_REWARD_ZC,
      reason: 'Arkadaş daveti',
      timestamp: new Date().toISOString(),
    },
    ...(data.transactions || []),
  ].slice(0, MAX_STORED_TRANSACTIONS);

  await coinRef.set({ ...data, balance, totalEarned, transactions }, { merge: true });

  if (isReferrer) {
    const referralStateRef = db
      .collection('users')
      .doc(uid)
      .collection('state')
      .doc('referralState');
    await referralStateRef.set(
      { successfulReferralCount: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );
  }
}

async function main() {
  console.log(`Başlıyor — DRY_RUN=${DRY_RUN}`);
  const pendingSnap = await db
    .collection('referralRedemptions')
    .where('status', '==', 'pending')
    .get();
  console.log(`${pendingSnap.size} bekleyen davet kaydı bulundu.`);

  let processedCount = 0;
  let rejectedCount = 0;

  for (const doc of pendingSnap.docs) {
    const { referrerUid, refereeUid } = doc.data();

    if (!referrerUid || !refereeUid || referrerUid === refereeUid) {
      console.warn(
        `REDDEDİLDİ (geçersiz kayıt): id=${doc.id} referrerUid=${referrerUid} refereeUid=${refereeUid}`,
      );
      if (!DRY_RUN) await doc.ref.set({ status: 'rejected' }, { merge: true });
      rejectedCount++;
      continue;
    }

    const [referrerExists, refereeExists] = await Promise.all([
      db
        .collection('users')
        .doc(referrerUid)
        .get()
        .then((s) => s.exists),
      db
        .collection('users')
        .doc(refereeUid)
        .get()
        .then((s) => s.exists),
    ]);
    if (!referrerExists || !refereeExists) {
      console.warn(
        `REDDEDİLDİ (kullanıcı bulunamadı): id=${doc.id} referrerUid=${referrerUid} ` +
          `(var=${referrerExists}) refereeUid=${refereeUid} (var=${refereeExists})`,
      );
      if (!DRY_RUN) await doc.ref.set({ status: 'rejected' }, { merge: true });
      rejectedCount++;
      continue;
    }

    console.log(
      `${DRY_RUN ? '[DRY RUN] KREDİLENECEK' : 'KREDİLENİYOR'}: id=${doc.id} ` +
        `referrerUid=${referrerUid} refereeUid=${refereeUid} (+${REFERRAL_REWARD_ZC} ZC her ikisine)`,
    );
    if (!DRY_RUN) {
      await creditReferralReward(referrerUid, { isReferrer: true });
      await creditReferralReward(refereeUid);
      await doc.ref.set(
        { status: 'completed', processedAt: new Date().toISOString() },
        { merge: true },
      );
    }
    processedCount++;
  }

  console.log(
    `Bitti — ${processedCount} davet ${
      DRY_RUN ? 'kredilenecekti (DRY RUN, GERÇEKTE kredilenmedi)' : 'kredilendi'
    }, ${rejectedCount} kayıt geçersiz olduğu için reddedildi.`,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
