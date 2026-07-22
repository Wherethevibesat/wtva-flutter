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
  final String? neighborhood;
  final String? phone;
  final List<String> services;
  final List<VenueCheckInPost> recentCheckIns;
  final bool featured;

  const VenueDetail({
    required this.venue,
    required this.category,
    required this.address,
    required this.description,
    required this.checkInCount,
    this.isOpen = true,
    this.hoursLabel = '',
    this.neighborhood,
    this.phone,
    this.services = const [],
    this.recentCheckIns = const [],
    this.featured = false,
  });
}
