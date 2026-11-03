import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/localized_calendar_names.dart';
import '../l10n/app_localizations.dart';
import '../models/home_item.dart';
import '../models/zibo_event.dart';
import '../providers/coin_provider.dart';
import '../providers/events_provider.dart';
import '../providers/home_decor_provider.dart';
import '../utils/adaptive.dart';
import '../widgets/home_art/item_thumb.dart';
import '../widgets/sticker_style.dart';

/// Zibo Dünyası → Etkinlikler (docs/zibo_world_roadmap.md Faz 6). Süren
/// takvim etkinlikleri gün kutularıyla, yaklaşanlar liste olarak.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final events = context.watch<EventsProvider>();
    final active = events.active;
    final upcoming = events.upcoming;
    final hPad = Adaptive.horizontalPadding(context, maxWidth: 640, minPadding: 16);
    return Scaffold(
      appBar: plainStickerAppBar(context, title: l10n.eventsTitle),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
        children: [
          if (active.isEmpty && upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Image.asset('assets/images/home/zibo_idle.webp', height: 140),
                  const SizedBox(height: 12),
                  Text(
                    l10n.eventsEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          for (final e in active) ...[_CalendarCard(event: e), const SizedBox(height: 16)],
          if (upcoming.isNotEmpty) ...[
            Text(
              l10n.eventsUpcomingTitle,
              style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final e in upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StickerCard(
                  child: Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.titleFor(Localizations.localeOf(context)), style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              l10n.eventsStartsOn(eventDateLabel(Localizations.localeOf(context), e.start)),
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "1 Aralık" / "December 1" / "1 de diciembre".
String eventDateLabel(Locale locale, DateTime d) {
  final month = monthNamesForLocale(locale)[d.month - 1];
  return switch (locale.languageCode) {
    'en' => '$month ${d.day}',
    'es' => '${d.day} de ${month.toLowerCase()}',
    _ => '${d.day} $month',
  };
}

/// Bir etkinlik kutusunu açar, ödülü uygular ve gösterir. Giriş ekranındaki
/// kart da bunu kullanır.
Future<void> openEventBox(BuildContext context, ZiboEvent event, int day) async {
  final l10n = AppLocalizations.of(context)!;
  final reward = context.read<EventsProvider>().open(event, day);
  if (reward == null) return;
  final coins = context.read<CoinProvider>();
  final decor = context.read<HomeDecorProvider>();
  if (reward.zc > 0) coins.earnEventReward(amount: reward.zc, eventId: event.id, day: day);
  final item = _rewardItem(reward);
  if (item != null) decor.markOwned(item.$1, item.$2.id, item.$3.id);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.eventsBoxOpened, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item != null)
            HomeItemThumb(kind: item.$2.kind, item: item.$3, size: 96)
          else
            const Text('🎁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 10),
          if (reward.zc > 0) Text(l10n.eventsRewardZc(reward.zc), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (item != null) Text(l10n.eventsRewardItem(item.$3.nameTr), textAlign: TextAlign.center),
          if (reward.zc <= 0 && item == null) Text(l10n.eventsRewardEmpty, textAlign: TextAlign.center),
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.eventsOk))],
    ),
  );
}

/// `oda:kategori:eşya` katalogda varsa (oda, kategori, eşya).
(HomeRoom, HomeCategory, HomeItem)? _rewardItem(EventReward reward) {
  final key = reward.itemKey;
  if (key == null) return null;
  final [roomId, categoryId, itemId] = key.split(':');
  final room = HomeRoom.fromId(roomId);
  if (room == null) return null;
  final category = HomeDecorProvider.roomDef(room).category(categoryId);
  final item = category?.item(itemId);
  if (category == null || item == null) return null;
  return (room, category, item);
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.event});

  final ZiboEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final events = context.watch<EventsProvider>();
    final today = events.todayIndex(event);
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.titleFor(locale),
            style: const TextStyle(fontFamily: 'Baloo2', fontVariations: [FontVariation('wght', 800)], fontSize: 20, height: 1.1),
          ),
          if (event.descriptionFor(locale).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(event.descriptionFor(locale), style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.eventsEndsOn(eventDateLabel(locale, event.end)),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 0; d < event.days.length; d++)
                _DayBox(
                  day: d,
                  reward: event.days[d],
                  opened: events.isOpened(event, d),
                  openable: events.canOpen(event, d),
                  isToday: d == today,
                  onOpen: () => openEventBox(context, event, d),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBox extends StatelessWidget {
  const _DayBox({
    required this.day,
    required this.reward,
    required this.opened,
    required this.openable,
    required this.isToday,
    required this.onOpen,
  });

  final int day;
  final EventReward reward;
  final bool opened;
  final bool openable;
  final bool isToday;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final label = l10n.eventsDay(day + 1);
    final Widget face;
    if (opened) {
      face = Text(
        reward.zc > 0 ? '+${reward.zc}' : (reward.itemKey != null ? '🎄' : '·'),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      );
    } else if (openable) {
      face = const Text('🎁', style: TextStyle(fontSize: 24));
    } else {
      face = Icon(Icons.lock_rounded, size: 18, color: colorScheme.onSurfaceVariant);
    }
    return Semantics(
      button: openable,
      label: label,
      excludeSemantics: true,
      // Kartın (StickerCard) opak zemini Ink süslemesini örtmesin diye kendi yüzeyi.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: openable ? onOpen : null,
          child: Ink(
            width: 58,
            height: 64,
            decoration: BoxDecoration(
              color: opened
                  ? colorScheme.surfaceContainerHighest
                  : openable
                  ? const Color(0xFFFFE07A)
                  : colorScheme.surfaceContainerLowest,
              border: Border.all(color: isToday ? const Color(0xFFF2564B) : kStickerOutline, width: isToday ? 3 : 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${day + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 2),
                face,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
