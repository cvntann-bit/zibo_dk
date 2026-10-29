import 'package:cloud_firestore/cloud_firestore.dart';

/// Yönetici panelinden (`zibo_admin/`, Duyuru > Uygulama içi) yayınlanan mesaj kartı —
/// Firestore `inAppMessages/{id}`. Belge şekli panelin `in_app_message_screen.dart`'ıyla AYNI.
/// Bkz. `docs/admin_panel.md`.
class InAppMessage {
  const InAppMessage({
    required this.id,
    required this.emoji,
    required this.audience,
    required this.startAt,
    required this.endAt,
    required this.texts,
    this.onlyUid,
  });

  final String id;
  final String emoji;

  /// 'all' | 'free' | 'pro' (Pro + Pro+). Tanınmayan değer → kimseye gösterilmez.
  final String audience;
  final DateTime startAt;
  final DateTime endAt;

  /// Dil kodu → (başlık, metin). Kullanıcının dili yoksa kart ona GÖSTERİLMEZ.
  final Map<String, ({String title, String body})> texts;

  /// Doluysa yalnızca bu uid görür (yöneticinin kendinde denemesi için).
  final String? onlyUid;

  /// Bozuk/eksik belge → `null` (sessizce atlanır).
  static InAppMessage? fromFirestore(String id, Map<String, dynamic> data) {
    final start = data['startAt'];
    final end = data['endAt'];
    final rawTexts = data['texts'];
    if (start is! Timestamp || end is! Timestamp || rawTexts is! Map) return null;
    final texts = <String, ({String title, String body})>{};
    rawTexts.forEach((lang, value) {
      if (lang is! String || value is! Map) return;
      final title = value['title'], body = value['body'];
      if (title is String && body is String && title.trim().isNotEmpty && body.trim().isNotEmpty) {
        texts[lang] = (title: title.trim(), body: body.trim());
      }
    });
    if (texts.isEmpty) return null;
    final emoji = data['emoji'];
    final onlyUid = data['onlyUid'];
    return InAppMessage(
      id: id,
      emoji: emoji is String && emoji.isNotEmpty ? emoji : '📣',
      audience: data['audience'] as String? ?? 'all',
      startAt: start.toDate(),
      endAt: end.toDate(),
      texts: texts,
      onlyUid: onlyUid is String && onlyUid.isNotEmpty ? onlyUid : null,
    );
  }

  bool isVisibleTo({required DateTime now, required String? uid, required bool isPro, required String languageCode}) {
    if (now.isBefore(startAt) || !now.isBefore(endAt)) return false;
    if (!texts.containsKey(languageCode)) return false;
    if (onlyUid != null) return onlyUid == uid;
    return switch (audience) {
      'all' => true,
      'free' => !isPro,
      'pro' => isPro,
      _ => false,
    };
  }
}

/// Bu kullanıcıya şimdi gösterilecek mesaj — görülmemişler arasından en YENİ başlayan; yoksa `null`.
InAppMessage? pickInAppMessage(
  Iterable<InAppMessage> messages, {
  required DateTime now,
  required String? uid,
  required bool isPro,
  required String languageCode,
  required Set<String> seenIds,
}) {
  InAppMessage? best;
  for (final m in messages) {
    if (seenIds.contains(m.id)) continue;
    if (!m.isVisibleTo(now: now, uid: uid, isPro: isPro, languageCode: languageCode)) continue;
    if (best == null || m.startAt.isAfter(best.startAt)) best = m;
  }
  return best;
}
