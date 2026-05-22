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
  static const entries = [
    CheckInHistoryEntry(
      id: 'h1',
      venueId: '2',
      venueName: "Joe's Strip Bar",
      imageUrl:
          'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=400&q=80',
      dateLabel: 'Tonight · 9:42 PM',
      pointsEarned: 25,
      hasPost: true,
    ),
    CheckInHistoryEntry(
      id: 'h2',
      venueId: '1',
      venueName: 'Barbarella Pizza',
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&q=80',
      dateLabel: 'Sat, May 18',
      pointsEarned: 35,
      hasPost: true,
    ),
    CheckInHistoryEntry(
      id: 'h3',
      venueId: '3',
      venueName: 'The Dream Club',
      imageUrl:
          'https://images.unsplash.com/photo-1571330735065-0aa5a2c2ce9c?w=400&q=80',
      dateLabel: 'Fri, May 10',
      pointsEarned: 25,
    ),
    CheckInHistoryEntry(
      id: 'h4',
      venueId: '4',
      venueName: 'Dream Land',
      imageUrl:
          'https://images.unsplash.com/photo-1566417713940-7c8aeb8c8a3a?w=400&q=80',
      dateLabel: 'Sun, May 5',
      pointsEarned: 50,
      hasPost: true,
    ),
  ];
}
