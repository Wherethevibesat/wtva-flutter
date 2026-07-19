/// A redeemable reward from the catalog (venue-funded or platform-wide).
class Reward {
  final String id;
  final String? venueId;
  final String? venueName;
  final String title;
  final String? description;
  final String rewardType;
  final int costPoints;
  final String? imageUrl;
  final String? terms;
  final int? stock;
  final int redeemedCount;

  const Reward({
    required this.id,
    this.venueId,
    this.venueName,
    required this.title,
    this.description,
    required this.rewardType,
    required this.costPoints,
    this.imageUrl,
    this.terms,
    this.stock,
    required this.redeemedCount,
  });

  bool get soldOut => stock != null && redeemedCount >= stock!;

  factory Reward.fromMap(Map<String, dynamic> map) {
    final venue = map['venues'];
    return Reward(
      id: '${map['id']}',
      venueId: map['venue_id'] as String?,
      venueName: venue is Map ? venue['name'] as String? : null,
      title: map['title'] as String? ?? 'Reward',
      description: map['description'] as String?,
      rewardType: map['reward_type'] as String? ?? 'perk',
      costPoints: (map['cost_points'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url'] as String?,
      terms: map['terms'] as String?,
      stock: (map['stock'] as num?)?.toInt(),
      redeemedCount: (map['redeemed_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A member's redemption of a reward, carrying the one-time code.
class Redemption {
  final String id;
  final String code;
  final String status;
  final int costPoints;
  final String? rewardTitle;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const Redemption({
    required this.id,
    required this.code,
    required this.status,
    required this.costPoints,
    this.rewardTitle,
    this.expiresAt,
    this.createdAt,
  });

  bool get isActive => status == 'issued';

  factory Redemption.fromMap(Map<String, dynamic> map) {
    final reward = map['rewards'];
    DateTime? parse(Object? v) => v == null ? null : DateTime.tryParse('$v');
    return Redemption(
      id: '${map['id']}',
      code: map['code'] as String? ?? '',
      status: map['status'] as String? ?? 'issued',
      costPoints: (map['cost_points'] as num?)?.toInt() ?? 0,
      rewardTitle: reward is Map ? reward['title'] as String? : null,
      expiresAt: parse(map['expires_at']),
      createdAt: parse(map['created_at']),
    );
  }
}
