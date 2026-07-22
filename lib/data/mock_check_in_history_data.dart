class CheckInHistoryEntry {
  final String id;
  final String venueId;
  final String venueName;
  final String imageUrl;
  final String dateLabel;
  final int pointsEarned;
  final bool hasPost;

  const CheckInHistoryEntry({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.imageUrl,
    required this.dateLabel,
    required this.pointsEarned,
    this.hasPost = false,
  });
}

class MockCheckInHistoryData {
  /// No seeded history — RankingService loads from Supabase / local prefs.
  static const List<CheckInHistoryEntry> entries = [];
}
