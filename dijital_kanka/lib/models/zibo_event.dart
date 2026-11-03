import 'package:flutter/widgets.dart';

/// Zibo Dünyası etkinliği (docs/zibo_world_roadmap.md Faz 6). Firestore
/// `events/{id}` dokümanından okunur; yönetici uygulamasından düzenlenir,
/// uygulama sürümü gerekmez.
///
/// ```
/// events/{id} = {
///   type: 'takvim', enabled: true,
///   title: {tr, en, es}, description: {tr, en, es},
///   start: '2026-12-01', end: '2026-12-25',      // gün olarak, dahil
///   catchUp: true,                                // kaçırılan günler sonra açılabilir
///   days: [{zc: 20}, {item: 'salon:kose:cam'}, …] // sıra = gün
/// }
/// ```
///
/// Uygulama yalnızca içinde kodu olan TÜRLERİ çalıştırır ([supportedTypes]);
/// yeni bir tür ilk kez eklenirken sürüm gerekir.
class ZiboEvent {
  const ZiboEvent({
    required this.id,
    required this.type,
    required this.enabled,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.days,
    this.catchUp = true,
  });

  static const supportedTypes = {'takvim'};

  final String id;
  final String type;
  final bool enabled;
  final Map<String, String> title;
  final Map<String, String> description;

  /// Gün başı (yerel tarih, saat 00:00).
  final DateTime start;
  final DateTime end;
  final List<EventReward> days;
  final bool catchUp;

  bool get isSupported => supportedTypes.contains(type);

  String titleFor(Locale locale) => title[locale.languageCode] ?? title['tr'] ?? '';
  String descriptionFor(Locale locale) => description[locale.languageCode] ?? description['tr'] ?? '';

  /// Bozuk/eksik doküman null döner (uygulama onu yok sayar).
  static ZiboEvent? fromJson(String id, Map<String, dynamic>? json) {
    if (json == null) return null;
    final start = _date(json['start']);
    final end = _date(json['end']);
    if (start == null || end == null || end.isBefore(start)) return null;
    Map<String, String> texts(Object? raw) =>
        raw is Map ? {for (final e in raw.entries) '${e.key}': '${e.value}'} : const {};
    final days = <EventReward>[
      for (final raw in (json['days'] is List ? json['days'] as List : const []))
        EventReward.fromJson(raw is Map ? raw : const {}),
    ];
    return ZiboEvent(
      id: id,
      type: '${json['type'] ?? ''}',
      enabled: json['enabled'] == true,
      title: texts(json['title']),
      description: texts(json['description']),
      start: start,
      end: end,
      days: days,
      catchUp: json['catchUp'] != false,
    );
  }

  static DateTime? _date(Object? raw) {
    final d = DateTime.tryParse('${raw ?? ''}');
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}

/// Bir günün ödülü: ZC ya da eşya (`oda:kategori:eşya`). İkisi de yoksa boş kutu.
class EventReward {
  const EventReward({this.zc = 0, this.itemKey});

  final int zc;
  final String? itemKey;

  bool get isEmpty => zc <= 0 && itemKey == null;

  factory EventReward.fromJson(Map<dynamic, dynamic> json) => EventReward(
    zc: (json['zc'] as num?)?.toInt().clamp(0, EventReward.maxZc) ?? 0,
    itemKey: json['item'] is String && (json['item'] as String).split(':').length == 3 ? json['item'] as String : null,
  );

  /// Tek günde verilebilecek en çok ZC (coinState tek yazım sınırının çok altında).
  static const maxZc = 1000;
}
