/// Result of the `check_in_venue` RPC — the server is the source of truth for
/// points, so the app applies [totalPoints] rather than computing its own.
class CheckInResult {
  final String checkInId;
  final int basePoints;
  final int pointsAwarded;
  final int totalPoints;
  final bool firstVisit;
  final int firstVisitBonus;
  final bool streak;
  final int streakBonus;
  final bool locationVerified;
  final bool qrVerified;

  const CheckInResult({
    required this.checkInId,
    required this.basePoints,
    required this.pointsAwarded,
    required this.totalPoints,
    required this.firstVisit,
    required this.firstVisitBonus,
    required this.streak,
    required this.streakBonus,
    required this.locationVerified,
    required this.qrVerified,
  });

  factory CheckInResult.fromMap(Map<String, dynamic> map) {
    int asInt(Object? v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    bool asBool(Object? v) => v == true;
    return CheckInResult(
      checkInId: '${map['check_in_id'] ?? ''}',
      basePoints: asInt(map['base_points']),
      pointsAwarded: asInt(map['points_awarded']),
      totalPoints: asInt(map['total_points']),
      firstVisit: asBool(map['first_visit']),
      firstVisitBonus: asInt(map['first_visit_bonus']),
      streak: asBool(map['streak']),
      streakBonus: asInt(map['streak_bonus']),
      locationVerified: asBool(map['location_verified']),
      qrVerified: asBool(map['qr_verified']),
    );
  }
}
