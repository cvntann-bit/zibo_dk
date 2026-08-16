import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/bond_level.dart';
import '../providers/profile_provider.dart';

/// "Zibo ile Bağ Seviyesi" satırının açtığı sayfa — kaç gündür Zibo'yu
/// kullandığını + hangi kademede olduğunu (bkz. `bond_level.dart`) + bir
/// sonraki kademeye kaç gün kaldığını gösterir.
class BondLevelScreen extends StatelessWidget {
  const BondLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileProvider>();
    final days = profile.daysSinceFirstUsed();
    final level = bondLevelForDays(days);
    final nextThreshold = nextBondLevelThreshold(level);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bondLevelScreenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.favorite_rounded, size: 56, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    level.localizedName(l10n),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Kullanıcının hitap tercihi (bkz. applyAddressTerm)
                    // BİLEREK uygulanmıyor — "kankasın" gibi bir sıfat eki
                    // buraya kullanıcının kendi adı/başka bir terim
                    // koyulduğunda ("... Mehmet Cansın" gibi) anlamsız
                    // oluyordu; bu satır her zaman sabit "kankasın" ifadesini
                    // kullanır.
                    l10n.profileBondLevelRowSubtitle(days),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  nextThreshold == null
                      ? l10n.profileBondMaxLevelHint
                      : l10n.profileBondNextLevelHint(
                          nextThreshold - days,
                          bondLevelForDays(nextThreshold).localizedName(l10n),
                        ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
