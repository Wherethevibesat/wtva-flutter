import '../models/reward.dart';
import 'supabase_bootstrap.dart';
import 'supabase_data.dart';

/// Redemption result returned by the `redeem_reward` RPC.
class RedeemResult {
  final String code;
  final String rewardTitle;
  final int costPoints;
  final int totalPoints;

  const RedeemResult({
    required this.code,
    required this.rewardTitle,
    required this.costPoints,
    required this.totalPoints,
  });
}

/// Reads the rewards catalog and redemptions, and spends points via RPC.
class RewardsRepository {
  RewardsRepository._();
  static final RewardsRepository instance = RewardsRepository._();

  Future<List<Reward>> listRewards() async {
    if (!SupabaseData.syncAuth) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('rewards')
          .select('*, venues(name)')
          .eq('active', true)
          .order('cost_points', ascending: true);
      return (rows as List)
          .map((r) => Reward.fromMap((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Redemption>> listMyRedemptions() async {
    if (!SupabaseData.syncAuth) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('reward_redemptions')
          .select('*, rewards(title)')
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List)
          .map((r) => Redemption.fromMap((r as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Spends points on a reward. Throws with a user-facing message on failure.
  Future<RedeemResult> redeem(String rewardId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || !SupabaseData.syncAuth) {
      throw Exception('Sign in required to redeem rewards');
    }
    final data = await client.rpc('redeem_reward', params: {'p_reward_id': rewardId});
    final map = (data as Map).cast<String, dynamic>();
    return RedeemResult(
      code: '${map['code'] ?? ''}',
      rewardTitle: '${map['reward_title'] ?? 'Reward'}',
      costPoints: (map['cost_points'] as num?)?.toInt() ?? 0,
      totalPoints: (map['total_points'] as num?)?.toInt() ?? 0,
    );
  }
}
