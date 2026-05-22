import '../models/leaderboard_entry.dart';
import '../services/ranking_service.dart';

class MockLeaderboardData {
  static List<LeaderboardEntry> get global => RankingService.instance.globalLeaderboard();

  static List<LeaderboardEntry> get followers =>
      RankingService.instance.followersLeaderboard();
}
