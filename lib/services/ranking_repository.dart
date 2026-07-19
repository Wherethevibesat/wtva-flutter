import '../data/ranking_rules.dart';
import '../models/leaderboard_entry.dart';
import '../services/supabase_data.dart';
import '../services/supabase_bootstrap.dart';
import 'user_service.dart';

/// Syncs lifetime points and leaderboards with Supabase `user_rankings`.
class RankingRepository {
  RankingRepository._();
  static final RankingRepository instance = RankingRepository._();

  Future<int?> fetchPoints(String userId) async {
    if (!SupabaseData.syncAuth) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('user_rankings')
          .select('total_points')
          .eq('user_id', userId)
          .maybeSingle();
      return row?['total_points'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertPoints(String userId, int totalPoints) async {
    if (!SupabaseData.syncAuth) return;
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('user_rankings').upsert({
        'user_id': userId,
        'total_points': totalPoints,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // local cache remains source until next load
    }
  }

  /// Weekly (or any window) leaderboard from the points ledger via RPC.
  Future<List<LeaderboardEntry>> fetchLeaderboardWindow({int days = 7, int limit = 50}) async {
    if (!SupabaseData.syncAuth) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final data = await client.rpc('leaderboard_window', params: {
        'p_days': days,
        'p_limit': limit,
      });
      final rows = (data as List?) ?? [];
      final userId = UserService().currentUser?.id;
      final list = <LeaderboardEntry>[];
      var rank = 1;
      for (final raw in rows) {
        final row = (raw as Map).cast<String, dynamic>();
        final id = '${row['user_id'] ?? ''}';
        if (id.isEmpty) continue;
        final points = (row['points'] as num?)?.toInt() ?? 0;
        list.add(
          LeaderboardEntry(
            rank: rank++,
            id: id,
            name: row['name'] as String? ?? 'User',
            avatarUrl: row['profile_image_url'] as String? ??
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80',
            points: points,
            tierName: RankingRules.tierForPoints(points).name,
            isCurrentUser: id == userId,
          ),
        );
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaderboardEntry>> fetchGlobalLeaderboard() async {
    if (!SupabaseData.syncAuth) return [];
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('user_rankings')
          .select('total_points, users(id, name, profile_image_url, role)')
          .order('total_points', ascending: false)
          .limit(50);

      final userId = UserService().currentUser?.id;
      final list = <LeaderboardEntry>[];
      var rank = 1;
      for (final raw in rows) {
        final row = raw;
        final user = row['users'] as Map<String, dynamic>?;
        if (user == null) continue;
        if ((user['role'] as String?) != 'customer') continue;
        final id = user['id'] as String;
        final points = row['total_points'] as int? ?? 0;
        list.add(
          LeaderboardEntry(
            rank: rank++,
            id: id,
            name: user['name'] as String? ?? 'User',
            avatarUrl: user['profile_image_url'] as String? ??
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80',
            points: points,
            tierName: RankingRules.tierForPoints(points).name,
            isCurrentUser: id == userId,
          ),
        );
      }
      return list;
    } catch (_) {
      return [];
    }
  }
}
