// 1. GÜNLÜK MOTİVASYON — SAATTE BİR (bkz. .github/workflows/daily-motivation.yml)
// çalışan TEK bir GitHub Actions çalıştırması, her kullanıcının KENDİ yerel
// saatine göre günde DÖRT kez (09/12/16/20 — bkz. TARGET_LOCAL_HOURS)
// gönderim yapar. Bir kullanıcının yerel saati bu dört değerden birine denk
// geldiğinde o çalıştırmada bir bildirim gönderilir; farklı diliminde olan
// kullanıcılar o saatte pas geçilip KENDİ saatleri geldiğinde yakalanır.
//
// 2026 GÜNCELLEMESİ — kullanıcı raporu: Kolombiya'daki bir test kullanıcısı
// sabah 4'te bildirim aldığını bildirdi — kök neden, TÜM kullanıcılara sabit
// Europe/Istanbul saatine göre (kullanıcının GERÇEK konumu/saat dilimi hiç
// dikkate alınmadan) gönderim yapılmasıydı. Artık her kullanıcının
// `timeZone` alanına (bkz. PushNotificationService.touchLastActive) göre
// KENDİ yerel saati hesaplanıp (bkz. common.js'teki `userLocalHour` —
// IANA saat dilimi kullanıldığı için yaz/kış saati otomatik doğru) yalnızca
// hedef saatlerden birine denk gelenlere gönderim yapılıyor.
//
// **Önceki tasarım (dört AYRI, sabit-Istanbul-saatli cron tetikleyicisi,
// `SAFETY_MIN_MINUTE`/`SAFETY_MAX_MINUTE` güvenlik penceresiyle) TAMAMEN
// YERİNE bu SAATLİK + kullanıcı-bazlı filtreleme mantığı geçti** — eski
// "GitHub'ın çalıştırmayı çok geç tetiklemesine karşı geniş bir Istanbul
// penceresi" güvenlik ağına artık gerek yok, çünkü YENİ tasarım zaten
// yalnızca kullanıcının KENDİ hesaplanan yerel saati hedefe denk geldiğinde
// gönderim yapıyor — "yanlış saatte gönderim" riski tasarım gereği yok.
//
// 2026 ÜÇÜNCÜ GÜNCELLEME — kullanıcı raporu: bu değişiklikten sonra
// bildirimler TAMAMEN durdu (manuel tetiklemede bile "0 kullanıcı hedef
// saatte"). Kök neden: "TAM o saat mi?" kontrolü GitHub Actions'ın saatlik
// cron'u sık sık GECİKTİRDİĞİ/hiç ateşlemediği (bkz. CLAUDE.md "Push
// Bildirimleri" bölümü) gerçek dünyada çok kırılgan çıktı — bir tetikleme
// dakikasında ateşlenmezse o dilim o gün BİR DAHA hiç yakalanamıyordu.
// Artık `pendingNotifyHours` (bkz. common.js) ile "hedef saat GEÇTİ mi VE
// bugün için henüz işlenmedi mi?" soruluyor — gecikmiş bir tetikleme günün
// SONRAKİ herhangi bir çalıştırmasında hâlâ doğru şekilde yakalanıyor.

const {
  db,
  fetchAllUsers,
  sendToUser,
  getLanguageCode,
  userDateKey,
  pendingNotifyHours,
  markNotifyHoursSent,
} = require('./common');
const { daily_motivation: MOTIVATION_QUOTES } = require('./content');

// 2026 İKİNCİ GÜNCELLEMESİ — kullanıcı raporu: bildirimler kullanıcının arayüz dilinden
// BAĞIMSIZ, her zaman Türkçe gidiyordu. Artık HER kullanıcı için ayrı ayrı `getLanguageCode`
// ile dil çözülüp o dildeki söz havuzundan rastgele bir söz seçiliyor — "tüm kullanıcılara
// aynı çalıştırmada aynı söz" tasarımı artık yalnızca "aynı çalıştırma" kısmında geçerli,
// söz her kullanıcının kendi dilinde.
//
// 2026 ÜÇÜNCÜ GÜNCELLEME — kullanıcı raporu: "bildirimlerde hep aynı motivasyon cümleleri
// tekrar ediyor". Kök neden: `content.js`'in `daily_motivation` havuzu YALNIZCA 8 söz/dil
// içeriyordu (Ana Sayfa'nın KENDİSİNİN kullandığı `lib/data/zibo_messages.dart`'taki tam
// 279'luk havuzdan bilerek küçültülmüş, "temsili" bir alt küme) — 8 sözlük bir havuzdan
// günde 4 kez rastgele seçim yapınca birkaç gün içinde kaçınılmaz olarak aynı sözler
// tekrarlanıyordu. **İKİ AYRI düzeltme birlikte uygulandı:** (1) `content.js` artık TAM
// 279'luk havuzla senkron (bkz. o dosyanın kendi yorumu, `tool/generate_content_js_daily_
// motivation.dart` ile üretildi); (2) kullanıcının AÇIKÇA istediği "en azından son birkaç
// günde kullanılmamış" garantisi için `users/{uid}.notifyState.daily_motivation.
// recentQuoteIndices` (kalıcı, en fazla [RECENT_QUOTE_MEMORY] elemanlı bir dizi) son
// gönderilen söz INDEX'lerini tutuyor — [pickQuoteAvoidingRecent] bu indexleri HARİÇ TUTARAK
// seçim yapıyor (279'luk havuzda hepsi hariç tutulacak kadar dolması pratik olarak imkansız,
// ama yine de bir güvenlik ağı olarak havuz tükenirse TÜM havuza geri düşülüyor). Bu, dilden
// BAĞIMSIZ tek bir index dizisi — kullanıcı dil değiştirse bile (üç dilin havuzları AYNI
// sırada/anlamda hizalı, bkz. content.js) AYNI kavramsal söz kısa sürede tekrar gelmiyor.
const RECENT_QUOTE_MEMORY = 20; // günde 4 gönderimle ~5 günlük tekrarsızlık penceresi

function pickQuoteAvoidingRecent(quotes, recentIndices) {
  const avoid = new Set(recentIndices);
  const candidates = [];
  for (let i = 0; i < quotes.length; i++) {
    if (!avoid.has(i)) candidates.push(i);
  }
  const pool = candidates.length > 0 ? candidates : quotes.map((_, i) => i);
  return pool[Math.floor(Math.random() * pool.length)];
}

async function recordQuoteIndex(uid, recentIndices, newIndex) {
  const updated = [...recentIndices, newIndex].slice(-RECENT_QUOTE_MEMORY);
  try {
    await db
      .collection('users')
      .doc(uid)
      .set({ notifyState: { daily_motivation: { recentQuoteIndices: updated } } }, { merge: true });
  } catch (error) {
    console.warn(`recordQuoteIndex başarısız: uid=${uid}`, error.message || error);
  }
}

// Eski sabit Istanbul saatleriyle (09:07/12:22/16:37/20:52) AYNI ruhu
// koruyan dört hedef yerel saat — yalnızca artık HERKES için Istanbul değil,
// HERKESİN KENDİ yerel saatinde.
const TARGET_LOCAL_HOURS = [9, 12, 16, 20];

async function main() {
  const now = new Date();
  const users = await fetchAllUsers();
  const eligible = users
    .map((user) => ({
      user,
      pending: pendingNotifyHours(user, 'daily_motivation', TARGET_LOCAL_HOURS, now),
    }))
    .filter((e) => e.pending.length > 0);
  console.log(
    `${users.length} kullanıcıdan ${eligible.length}'i şu an hedef yerel saatte ` +
      `(veya kaçırılmış bir dilimi yakalıyor) — günlük motivasyon gönderiliyor.`,
  );

  await Promise.all(
    eligible.map(async ({ user, pending }) => {
      const lang = await getLanguageCode(user.uid);
      const quotes = MOTIVATION_QUOTES[lang] || MOTIVATION_QUOTES.tr;
      const motivationState = (user.notifyState && user.notifyState.daily_motivation) || {};
      const recentIndices = Array.isArray(motivationState.recentQuoteIndices)
        ? motivationState.recentQuoteIndices
        : [];
      const index = pickQuoteAvoidingRecent(quotes, recentIndices);
      const quote = quotes[index];
      await sendToUser(user, 'daily_motivation', 'Zibo', quote);
      await markNotifyHoursSent(user, 'daily_motivation', userDateKey(user, now), pending);
      await recordQuoteIndex(user.uid, recentIndices, index);
    }),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
