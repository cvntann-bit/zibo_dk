// Level/XP sisteminin saf/test edilebilir matematiği — `wheel_prizes.dart`
// gibi diğer saf yardımcı dosyalarla AYNI felsefe, hiçbir state/provider
// mantığı barındırmaz.
//
// **İlerleme eğrisi:** Level L'den L+1'e geçmek için gereken XP = 50*L —
// yani 1→2: 50, 2→3: 100, 3→4: 150, ... doğrusal ARTAN bir maliyet.
// Kullanıcının istediği "düşük seviyeler hızlı, yüksek seviyeler daha yavaş
// kazanılsın" eğrisini basit/öngörülebilir bir şekilde veriyor. Toplam
// (cumulative) XP formülü bunun aritmetik serisinin kapalı biçimi:
// toplam(L) = 25*L*(L-1) (L=1 için 0).

/// Level [level]'e ULAŞMAK için gereken TOPLAM (kümülatif) XP — Level 1 her
/// zaman 0 XP gerektirir (başlangıç seviyesi).
int cumulativeXpForLevel(int level) {
  if (level <= 1) return 0;
  return 25 * level * (level - 1);
}

/// [level]'den bir SONRAKİ seviyeye geçmek için gereken XP miktarı (ör.
/// level=1 için 50, level=5 için 250).
int xpNeededForNextLevel(int level) => 50 * level;

/// [totalXp] kadar toplam XP'ye sahip bir kullanıcının şu anki seviyesi.
int levelForTotalXp(int totalXp) {
  var level = 1;
  while (cumulativeXpForLevel(level + 1) <= totalXp) {
    level++;
  }
  return level;
}

/// Bir kullanıcının o anki seviyesi + o seviye İÇİNDEKİ ilerlemesi — Profil
/// ekranındaki ilerleme çubuğunun (bkz. `profile_screen.dart`) doğrudan
/// girdisi.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  /// Şu anki seviye (1'den başlar).
  final int level;

  /// Şu anki seviyenin BAŞLANGICINDAN bu yana kazanılan XP (0 ile
  /// [xpForNextLevel] arası).
  final int xpIntoLevel;

  /// Bir sonraki seviyeye geçmek için toplamda gereken XP.
  final int xpForNextLevel;

  /// 0.0-1.0 arası ilerleme oranı — `LinearProgressIndicator.value` için.
  double get fraction =>
      xpForNextLevel == 0 ? 0 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);
}

/// [totalXp]'ye karşılık gelen [LevelProgress]'i hesaplar.
LevelProgress levelProgressForTotalXp(int totalXp) {
  final level = levelForTotalXp(totalXp);
  final base = cumulativeXpForLevel(level);
  return LevelProgress(
    level: level,
    xpIntoLevel: totalXp - base,
    xpForNextLevel: xpNeededForNextLevel(level),
  );
}
