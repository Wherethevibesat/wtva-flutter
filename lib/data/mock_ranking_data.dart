import '../models/rank_tier.dart';
import 'ranking_rules.dart';

/// Rank tier definitions — points totals come from [RankingService].
class MockRankingData {
  static List<RankTier> get tiers => RankingRules.tiers;
}
