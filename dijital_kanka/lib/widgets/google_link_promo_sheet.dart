import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/google_link_action.dart';

/// Mağaza'da kullanıcı İLK GERÇEK Zibo Coin satın alma DENEMESİNDE (hesabı
/// henüz Google'a bağlı değilse) gösterilen teşvik sheet'i — bkz.
/// `StoreScreen._PackageCardState._buy` (`AuthLinkProvider.hasSeenLinkPrompt`
/// kontrolü). `showModulesMenuSheet` ile AYNI `showModalBottomSheet`
/// deseni. Kullanıcı isteği: "zorunlu tutma, güçlü şekilde teşvik et" —
/// bu yüzden "Şimdilik Atla" her zaman kullanılabilir, sheet dokunarak
/// dışarı çıkma/sürükleme tutamacıyla da kapanabilir; HANGİ yol seçilirse
/// seçilsin, sheet kapandıktan SONRA orijinal satın alma işlemi normal
/// şekilde devam eder (bkz. çağıran taraf).
Future<void> showGoogleLinkPromoSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Theme.of(sheetContext).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.googleLinkPromoTitle,
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.googleLinkPromoBody,
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('googleLinkPromoLinkButton'),
                  onPressed: () async {
                    // `handleGoogleLinkTap` kendi SnackBar/diyalog geri
                    // bildirimini yönetiyor — burada yalnızca sheet'i
                    // kapatıp asıl satın alma akışının devam etmesine
                    // izin veriyoruz (bağlanma başarılı/başarısız/iptal
                    // olması SATIN ALMAYI etkilemez, bkz. dosya
                    // dokümantasyonu).
                    Navigator.of(sheetContext).pop();
                    await handleGoogleLinkTap(context);
                  },
                  child: Text(l10n.googleLinkRowTitleUnlinked),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('googleLinkPromoSkipButton'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.googleLinkPromoSkipButton),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
