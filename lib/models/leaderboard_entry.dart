class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String? avatarUrl;
  final int points;
  final String tierName;
  final bool isCurrentUser;
  final bool followsYou;

  const LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.tierName,
    this.isCurrentUser = false,
    this.followsYou = false,
  });
}
