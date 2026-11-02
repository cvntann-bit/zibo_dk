import 'home_item.dart';

/// Zibo'nun dört ihtiyacı. Her ihtiyaç bir odada giderilir
/// (docs/zibo_world.md). Değerler 0–100; zamanla düşer ama
/// [HomeConfig.minLevel]'in altına inmez — çocuklar kullanıyor, ceza yok.
enum HomeNeed {
  hunger('hunger', HomeRoom.kitchen),
  hygiene('hygiene', HomeRoom.bath),
  energy('energy', HomeRoom.bedroom),
  fun('fun', HomeRoom.living);

  const HomeNeed(this.id, this.room);

  /// Kalıcı kimlik (Firestore `homeNeedsState.levels` anahtarı).
  final String id;
  final HomeRoom room;

  static HomeNeed? fromId(String id) {
    for (final need in values) {
      if (need.id == id) return need;
    }
    return null;
  }
}
