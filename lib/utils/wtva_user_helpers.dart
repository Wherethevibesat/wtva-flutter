import '../data/mock_messages_data.dart';
import '../data/mock_social_data.dart';
import '../models/leaderboard_entry.dart';
import '../services/ranking_service.dart';
import '../services/user_service.dart';

/// Build the social profile for the signed-in user (not demo John Doe).
SocialUser socialUserFromSession() {
  final userService = UserService();
  final user = userService.currentUser;
  if (user == null || userService.isGuest) {
    return const SocialUser(
      id: 'guest',
      name: 'Guest',
      username: 'guest',
      points: 0,
      rank: 'Guest',
    );
  }

  final ranking = RankingService.instance;
  final emailLocal = user.email.contains('@')
      ? user.email.split('@').first
      : user.email;
  final username = emailLocal
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]'), '')
      .replaceAll(RegExp(r'_+'), '_');

  return SocialUser(
    id: user.id,
    name: user.name,
    username: username.isEmpty ? 'user' : username,
    avatarUrl: user.profileImageUrl,
    points: ranking.currentPoints,
    rank: ranking.currentRank,
  );
}

SocialUser socialUserFromLeaderboard(LeaderboardEntry entry) {
  if (entry.isCurrentUser) {
    return socialUserFromSession();
  }
  for (final u in MockSocialData.users) {
    if (u.name == entry.name) return u;
  }
  return SocialUser(
    id: entry.id,
    name: entry.name,
    username: entry.name.toLowerCase().replaceAll(' ', ''),
    avatarUrl: entry.avatarUrl,
    points: entry.points,
    rank: entry.tierName,
  );
}

ChatThread? chatThreadForUser(String name) {
  for (final t in MockMessagesData.threads) {
    if (t.name == name) return t;
  }
  return MockMessagesData.threads.isNotEmpty ? MockMessagesData.threads.first : null;
}
