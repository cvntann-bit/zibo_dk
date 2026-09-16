import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/badge_gift_rewards.dart';
import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/badge_definition.dart';
import '../models/badge_gift_reward.dart';
import '../providers/app_theme_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/costume_provider.dart';
import 'badge_special_reward.dart';

/// Bir rozetin ZC ödülünü (+ varsa kostüm/tema hediyesini) GERÇEKTEN verir
/// — `BadgeCelebrationOverlay`'in kazanma anı popup'ındaki "Ödülü Al" butonu
/// İLE `BadgesGalleryScreen`'in kazanılmış-ama-HENÜZ-alınmamış rozetler için
/// sunduğu YAKALAMA (backfill) claim'i TARAFINDAN PAYLAŞILAN tek kaynak.
///
/// **Neden bir "yakalama" akışı da gerekiyor — gerçek kullanıcı raporu:
/// "7 gün üst üste giriş yap rozetini vermedi".** `BadgeProvider`'ın HER
/// `reconcileX` metodu AYNI reconcile turunda birden fazla rozet YENİ
/// kazanılırsa yalnızca kategorisinin EN SONuncusunu `pendingBadgePopup`'a
/// yazıyor (bkz. o sınıfın dokümantasyonu) — ama bu TEK SLOT sinyal ALTI
/// AYRI `reconcileX` çağrısı arasında da PAYLAŞILIYOR, yani bir kategorinin
/// yazdığı değer bir SONRAKİ kategorinin yazdığı değerle SESSİZCE
/// EZİLEBİLİYOR. Gerçek bir örnek: bir kullanıcı 7 gün ÜST ÜSTE (hiç boşluk
/// vermeden) uygulamayı açarsa, `AppStreakProvider.currentStreak` VE
/// `totalDaysOpened` AYNI ANDA 7'ye ulaşır — bu da `reconcileConsistency
/// Badges`'in "1 Haftalık Seri"yi VE `reconcileLoyaltyBadges`'in "İlk
/// Hafta"yı AYNI `_reconcile()` çağrısında birden kazandırmasına yol açar;
/// Sadakat SONRA çalıştığı için popup'ı EZER, kullanıcı yalnızca "İlk
/// Hafta" kutlamasını görür. "1 Haftalık Seri" `_earned`'de KAYITLIDIR
/// (galeride renkli görünür) ama ödülü hiçbir zaman TALEP EDİLEMEZDİ —
/// `BadgesGalleryScreen`'in eskiden hiçbir "Ödülü Al" affordance'ı YOKTU.
/// Bu fonksiyon + galerideki claim düğmesi bu sınıfın TÜM örneklerini
/// (bu koleksiyon ya da gelecekte başka bir kombinasyon) kalıcı olarak
/// çözüyor — popup'ı KAÇIRAN her rozet artık galeriden HER ZAMAN talep
/// edilebilir.
GrantedBadgeGift? claimBadgeReward(BuildContext context, ZiboBadgeDefinition badge) {
  final l10n = AppLocalizations.of(context)!;
  context.read<BadgeProvider>().markClaimed(badge.id);
  context.read<CoinProvider>().earnBadgeReward(badge.zcReward, badge.id);

  final gift = badgeGiftRewards[badge.id];
  if (gift == null) return null;

  if (gift.type == BadgeGiftType.costume) {
    final costume = findCostumeById(gift.costumeId!);
    if (costume == null) return null;
    unawaited(context.read<CostumeProvider>().markOwned(costume.id));
    return (type: BadgeGiftType.costume, name: costume.localizedName(l10n));
  }

  final themeProvider = context.read<AppThemeProvider>();
  final theme = pickRandomUnownedStandardTheme(themeProvider.ownedIds);
  if (theme == null) return null;
  unawaited(themeProvider.markOwned(theme.id));
  return (type: BadgeGiftType.theme, name: theme.localizedName(l10n));
}
