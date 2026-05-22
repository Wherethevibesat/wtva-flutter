import '../models/venue.dart';

/// Mock discover feed aligned with Figma sample content.
class MockDiscoverData {
  static const categories = [
    'Nearest',
    'Bars',
    'Night clubs',
    'Restaurants',
    'Location',
  ];

  static final List<Venue> _defaultVenues = [
    Venue(
      id: '1',
      name: 'Barbarella Pizza',
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      logoUrl:
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200&q=80',
      distanceMiles: 4.9,
      rating: 4.4,
      fullStars: 4,
      halfStar: true,
      latitude: 29.7424,
      longitude: -95.4018,
    ),
    Venue(
      id: '2',
      name: "Joe's Strip Bar",
      imageUrl:
          'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
      distanceMiles: 2.1,
      rating: 4.8,
      fullStars: 5,
      latitude: 29.7604,
      longitude: -95.3698,
    ),
    Venue(
      id: '3',
      name: 'The Dream Club',
      imageUrl:
          'https://images.unsplash.com/photo-1571330735065-0aa5a2c2ce9c?w=800&q=80',
      logoUrl:
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=200&q=80',
      distanceMiles: 4.9,
      rating: 3.0,
      fullStars: 3,
      latitude: 29.7632,
      longitude: -95.3612,
    ),
  ];

  static List<Venue> _venues = List<Venue>.from(_defaultVenues);

  static List<Venue> get venues => _venues;

  static void setVenues(List<Venue> list) {
    _venues = List<Venue>.from(list);
  }

  /// Filter discover list by category chip (index).
  static List<Venue> venuesForCategory(int categoryIndex) {
    final label = categories[categoryIndex];
    switch (label) {
      case 'Bars':
        return _venues.where((v) => v.id == '2').toList();
      case 'Night clubs':
        return _venues.where((v) => v.id == '3' || v.id == '4').toList();
      case 'Restaurants':
        return _venues.where((v) => v.id == '1').toList();
      case 'Nearest':
      default:
        return List<Venue>.from(_venues);
    }
  }

  static const promoted = PromotedOffer(
    title: '50% OFF Entry Fee',
    venueName: "Joe's Strip Bar",
    imageUrl:
        'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
    description:
        'Natoque vel consectetur a vulputate aliquam mi. Eget et faucibus ut felis.',
  );

  static const liveStories = [
    LiveStory(
      userName: 'Charlie Arcand',
      imageUrl:
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400&q=80',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
    ),
    LiveStory(
      userName: 'Alfonso George',
      imageUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
    ),
    LiveStory(
      userName: 'Dulce Bergson',
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&q=80',
      avatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
    ),
    LiveStory(
      userName: 'Kaiya Septimus',
      imageUrl:
          'https://images.unsplash.com/photo-1459747757774-3e4ef7adf0a3?w=400&q=80',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    ),
  ];
}
