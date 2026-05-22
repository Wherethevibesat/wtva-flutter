/// Why points were awarded (drives copy and amounts in [RankingRules]).
enum PointsReason {
  checkIn,
  checkInPost,
  hourlyStay,
  businessInvite,
}

extension PointsReasonX on PointsReason {
  String get label => switch (this) {
        PointsReason.checkIn => 'Check-in at a venue',
        PointsReason.checkInPost => 'Post photos with check-in',
        PointsReason.hourlyStay => 'Stay checked in (per hour)',
        PointsReason.businessInvite => 'Business invite check-in',
      };
}
