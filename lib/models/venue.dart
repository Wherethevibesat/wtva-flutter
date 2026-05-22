class Venue {
  final String id;
  final String name;
  final String imageUrl;
  final String? logoUrl;
  final double distanceMiles;
  final double rating;
  final int fullStars;
  final bool halfStar;
  final double? latitude;
  final double? longitude;

  const Venue({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.logoUrl,
    required this.distanceMiles,
    required this.rating,
    this.fullStars = 5,
    this.halfStar = false,
    this.latitude,
    this.longitude,
  });
}

class PromotedOffer {
  final String title;
  final String venueName;
  final String imageUrl;
  final String description;

  const PromotedOffer({
    required this.title,
    required this.venueName,
    required this.imageUrl,
    required this.description,
  });
}

class LiveStory {
  final String userName;
  final String imageUrl;
  final String avatarUrl;

  const LiveStory({
    required this.userName,
    required this.imageUrl,
    required this.avatarUrl,
  });
}
