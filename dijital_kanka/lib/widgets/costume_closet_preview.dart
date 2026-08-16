import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../providers/costume_provider.dart';
import '../screens/store_screen.dart';

/// Profil > "Zibo ile Bağın" bölümündeki Kostüm Dolabı satırı — diğer
/// satırların aksine yeni bir sayfa AÇMAZ, doğrudan sahip olunan kostümlerin
/// küçük görsellerini yatay bir şeritte gösterir; şeride (veya boş durum
/// mesajına) dokununca Mağaza'nın "Kostümler" segmentine gider (kullanıcının
/// açıkça belirttiği istisna davranış).
class CostumeClosetPreview extends StatelessWidget {
  const CostumeClosetPreview({super.key});

  void _openStore(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(l10n.storeTitle)),
          body: const StoreScreen(initialSection: StoreSection.costumes),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final ownedIds = context.watch<CostumeProvider>().ownedIds;
    final owned = ownedIds
        .map(findCostumeById)
        .whereType<Costume>()
        .toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openStore(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.checkroom_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.profileCostumeClosetRowTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              if (owned.isEmpty)
                Text(
                  l10n.profileCostumeClosetEmpty,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                )
              else
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: owned.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final costume = owned[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: colorScheme.surfaceContainerHigh,
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            costume.imageAsset,
                            semanticLabel: costume.localizedName(l10n),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
