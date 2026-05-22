import 'package:flutter/material.dart';

import '../models/points_reason.dart';
import '../models/rank_tier.dart';
import '../theme/figma_theme.dart';

/// Point values and rank thresholds — single source of truth.
abstract final class RankingRules {
  static const int checkInPoints = 25;
  static const int checkInPostPoints = 25;
  static const int hourlyStayPoints = 10;
  static const int businessInvitePoints = 50;

  static int pointsFor(PointsReason reason) => switch (reason) {
        PointsReason.checkIn => checkInPoints,
        PointsReason.checkInPost => checkInPostPoints,
        PointsReason.hourlyStay => hourlyStayPoints,
        PointsReason.businessInvite => businessInvitePoints,
      };

  static const tiers = <RankTier>[
    RankTier(
      name: 'Vibee',
      pointsRequired: 500,
      description:
          'Businesses cannot contact you yet. Collect points and you will increase your rank.',
      icon: Icons.trending_up,
    ),
    RankTier(
      name: 'Vibe Master',
      pointsRequired: 10000,
      description:
          'Businesses can start inviting you to check in at their location and pay you.',
      payRate: r'$50/hour',
      iconGradient: WtvaColors.rankBlueGradient,
      cardGradient: WtvaColors.rankBlueGradient,
      icon: Icons.military_tech,
    ),
    RankTier(
      name: 'Vibe Champion',
      pointsRequired: 25000,
      description:
          'Businesses can start inviting you to check in at their location and pay you.',
      payRate: r'$100/hour',
      iconGradient: WtvaColors.rankPinkGradient,
      icon: Icons.emoji_events,
    ),
    RankTier(
      name: 'Vibesetters',
      pointsRequired: 50000,
      description:
          'Businesses can start inviting you to check in at their location and pay you.',
      payRate: r'$200/hour',
      iconGradient: WtvaColors.rankPurpleGradient,
      icon: Icons.workspace_premium,
    ),
    RankTier(
      name: 'Influencers',
      pointsRequired: 100000,
      description:
          'Businesses can start inviting you to check in at their location and pay you.',
      payRate: r'$500/hour',
      iconGradient: WtvaColors.rankOrangeGradient,
      icon: Icons.diamond,
    ),
  ];

  static RankTier tierForPoints(int points) {
    RankTier current = tiers.first;
    for (final t in tiers) {
      if (points >= t.pointsRequired) current = t;
    }
    return current;
  }

  static RankTier? nextTierAfter(int points) {
    for (final t in tiers) {
      if (points < t.pointsRequired) return t;
    }
    return null;
  }

  static int pointsToNextTier(int points) {
    final next = nextTierAfter(points);
    if (next == null) return 0;
    return next.pointsRequired - points;
  }

  /// Five milestones from current tier floor to next tier ceiling.
  static List<int> progressMilestones(int points) {
    final next = nextTierAfter(points);
    final current = tierForPoints(points);
    final low = current.pointsRequired;
    if (next == null) {
      return [low, low + 2500, low + 5000, low + 7500, low + 10000];
    }
    final high = next.pointsRequired;
    final span = high - low;
    return List.generate(5, (i) => low + ((span * i) / 4).round());
  }

  static List<(String label, String value)> infoSheetItems() => [
        (PointsReason.checkIn.label, '+$checkInPoints'),
        (PointsReason.checkInPost.label, '+$checkInPostPoints'),
        (PointsReason.hourlyStay.label, '+$hourlyStayPoints'),
        (PointsReason.businessInvite.label, '+$businessInvitePoints'),
        ('${tierForPoints(10000).name} rank unlock', 'Unlock paid invites'),
      ];
}
