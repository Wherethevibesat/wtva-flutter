import 'package:flutter/material.dart';

import '../services/ranking_service.dart';
import 'wtva_feedback.dart';

void showPointsAwards(BuildContext context, List<PointsAward> awards) {
  if (awards.isEmpty) return;
  final total = awards.fold<int>(0, (s, a) => s + a.amount);
  final rankUp = awards.map((a) => a.rankUpTo).whereType<String>().lastOrNull;
  final label = awards.length == 1
      ? '+$total points'
      : '+$total points (${awards.length} bonuses)';
  showWtvaSnack(
    context,
    rankUp != null ? '$label · Rank up: $rankUp!' : label,
    icon: Icons.stars_outlined,
  );
}

void showPointsAward(BuildContext context, PointsAward award) {
  showPointsAwards(context, [award]);
}
