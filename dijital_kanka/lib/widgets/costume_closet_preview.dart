import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/costumes.dart';
import '../l10n/app_localizations.dart';
import '../models/costume.dart';
import '../providers/costume_provider.dart';
import '../screens/store_screen.dart';
import 'sticker_style.dart';

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

    final radius = BorderRadius.circular(20);
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: stickerDecoration(
            fill: colorScheme.surfaceContainerLowest,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: stickerCircleDecoration(
                      fill: colorScheme.primary,
                      borderWidth: 2.5,
                      shadowOffset: Offset.zero,
                    ),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Center(
                        child: Text('👕', style: TextStyle(fontSize: 16, height: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.profileCostumeClosetRowTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: kStickerOutline, width: 2),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '›',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (owned.isEmpty)
                Text(
                  l10n.profileCostumeClosetEmpty,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: owned.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final costume = owned[index];
                      return Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          border: Border.all(color: kStickerOutline, width: 2.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          costume.imageAsset,
                          semanticLabel: costume.localizedName(l10n),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(borderRadius: radius, onTap: () => _openStore(context)),
          ),
        ),
      ],
    );
  }
}
