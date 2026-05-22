import 'venue.dart';

class VenueCheckInPost {
  final String userName;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final String timeAgo;
  final int likes;

  const VenueCheckInPost({
    required this.userName,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.timeAgo,
    this.likes = 0,
  });
}

class VenueDetail {
  final Venue venue;
  final String category;
  final String address;
  final String description;
  final int checkInCount;
  final bool isOpen;
  final String hoursLabel;
  final List<String> services;
  final List<VenueCheckInPost> recentCheckIns;

  const VenueDetail({
    required this.venue,
    required this.category,
    required this.address,
    required this.description,
    required this.checkInCount,
    this.isOpen = true,
    this.hoursLabel = 'Open until 2:00 AM',
    this.services = const ['Dine-in', 'Takeaway'],
    this.recentCheckIns = const [],
  });
}
