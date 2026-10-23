// Saatlik bildirim işlerinin TEK süreçte çalıştırılması — maliyet optimizasyonu (2026-10-23).
//
// Eskiden `hourly-jobs.yml` beş bildirim betiğini ayrı `node` süreçleri olarak çalıştırıyordu ve her biri
// `fetchAllUsers()` ile TÜM `users` koleksiyonunu baştan okuyordu (kullanıcı × 120 okuma/gün). Burada hepsi
// aynı süreçte art arda çalışır; `fetchAllUsers()` sonucu süreç içinde paylaşıldığı için tarama BİR kez
// yapılır (bkz. common.js). Her iş kendi try/catch'inde — biri patlarsa diğerleri yine çalışır (eski
// `if: ${{ !cancelled() }}` davranışıyla AYNI). Betikler hâlâ tek başına (`npm run daily-motivation` vb.) çalışır.

const JOBS = [
  ['daily-motivation', './dailyMotivation'],
  ['streak-reminder', './streakReminder'],
  ['daily-reward-reminder', './dailyRewardReminder'],
  ['water-reminder', './waterReminder'],
  ['re-engagement', './reEngagement'],
];

async function run() {
  let failed = 0;
  for (const [name, modulePath] of JOBS) {
    console.log(`::group::${name}`);
    try {
      await require(modulePath).main();
    } catch (error) {
      failed += 1;
      console.error(`${name} BAŞARISIZ:`, error);
    }
    console.log('::endgroup::');
  }
  return failed;
}

run()
  .then((failed) => process.exit(failed > 0 ? 1 : 0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
