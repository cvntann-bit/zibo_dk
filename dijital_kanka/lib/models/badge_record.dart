/// Kullanıcının kazandığı BİR rozetin kaydı — `BadgeProvider` tarafından
/// tutulur, `CloudStateStore` ile Firestore'a senkronize edilir. [claimed]
/// `false` olduğu sürece rozet "kazanılmış ama ödülü henüz alınmamış"
/// durumda — bkz. `BadgeProvider.markClaimed`.
class BadgeRecord {
  const BadgeRecord({required this.earnedAt, required this.claimed});

  final DateTime earnedAt;
  final bool claimed;

  BadgeRecord copyWith({bool? claimed}) =>
      BadgeRecord(earnedAt: earnedAt, claimed: claimed ?? this.claimed);

  Map<String, dynamic> toJson() => {
    'earnedAt': earnedAt.toIso8601String(),
    'claimed': claimed,
  };

  factory BadgeRecord.fromJson(Map<String, dynamic> json) => BadgeRecord(
    earnedAt: DateTime.parse(json['earnedAt'] as String),
    claimed: json['claimed'] as bool? ?? false,
  );
}
