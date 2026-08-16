import '../l10n/app_localizations.dart';

/// Kullanıcının Zibo'yu kullanmaya başladığı günden bu yana geçen süreye
/// bağlı kademeler — `ProfileProvider.firstUsedAt` üzerinden hesaplanır
/// (bkz. `bondLevelForDays`). Eşikler kullanıcı isteğiyle "mantıklı gün
/// aralıkları" olarak serbestçe belirlendi: bir hafta, bir ay, üç ay, bir
/// yıl — günlük alışkanlık uygulamalarında sık kullanılan, kolay anlaşılır
/// dönüm noktaları.
enum BondLevel { newBuddy, gettingClose, oldFriend, soulBuddy, lifetimeBuddy }

/// [days] (bkz. `ProfileProvider.daysSinceFirstUsed`) kaç gün önce
/// başladığına göre kademeyi belirler.
BondLevel bondLevelForDays(int days) {
  if (days < 7) return BondLevel.newBuddy;
  if (days < 30) return BondLevel.gettingClose;
  if (days < 90) return BondLevel.oldFriend;
  if (days < 365) return BondLevel.soulBuddy;
  return BondLevel.lifetimeBuddy;
}

/// Bir sonraki kademeye geçmek için gereken gün eşiği — mevcut kademenin
/// en üst sınırı. Zaten en üst kademedeyse (`lifetimeBuddy`) `null` döner
/// (bir sonraki kademe yok).
int? nextBondLevelThreshold(BondLevel level) {
  switch (level) {
    case BondLevel.newBuddy:
      return 7;
    case BondLevel.gettingClose:
      return 30;
    case BondLevel.oldFriend:
      return 90;
    case BondLevel.soulBuddy:
      return 365;
    case BondLevel.lifetimeBuddy:
      return null;
  }
}

extension BondLevelL10n on BondLevel {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case BondLevel.newBuddy:
        return l10n.bondLevelNewBuddy;
      case BondLevel.gettingClose:
        return l10n.bondLevelGettingClose;
      case BondLevel.oldFriend:
        return l10n.bondLevelOldFriend;
      case BondLevel.soulBuddy:
        return l10n.bondLevelSoulBuddy;
      case BondLevel.lifetimeBuddy:
        return l10n.bondLevelLifetimeBuddy;
    }
  }
}
