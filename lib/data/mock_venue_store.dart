import '../models/venue.dart';
import '../models/venue_detail.dart';
import 'mock_check_in_data.dart';
import 'mock_discover_data.dart';

/// Central mock venue lookup for discover, map, and detail screens.
class MockVenueStore {
  MockVenueStore._();

  static final Map<String, VenueDetail> _details = {
    for (final v in MockDiscoverData.venues) v.id: _detailFor(v),
    '4': _detailFor(
      const Venue(
        id: '4',
        name: 'Dream Land',
        imageUrl: 'https://images.unsplash.com/photo-1566417713940-7c8aeb8c8a3a?w=800&q=80',
        distanceMiles: 0.3,
        rating: 4.2,
        fullStars: 4,
        halfStar: true,
        latitude: 29.7581,
        longitude: -95.3546,
      ),
      category: 'Night clubs',
    ),
  };

  static void putDetail(VenueDetail detail) {
    _details[detail.venue.id] = detail;
  }

  static VenueDetail? byId(String id) => _details[id];

  static VenueDetail byIdOrThrow(String id) {
    return _details[id] ?? _details['1']!;
  }

  static List<VenueDetail> get all => _details.values.toList();

  static Venue? venueById(String id) => byId(id)?.venue;

  static VenueDetail _detailFor(Venue v, {String category = 'Restaurant'}) {
    final posts = [
      VenueCheckInPost(
        userName: 'Alex Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
        imageUrl: v.imageUrl,
        caption: 'Vibes are insane tonight 🔥',
        timeAgo: '2h ago',
        likes: 42,
      ),
      VenueCheckInPost(
        userName: 'Jordan Lee',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
        imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
        caption: 'Live DJ set just started',
        timeAgo: '5h ago',
        likes: 18,
      ),
    ];

    return VenueDetail(
      venue: v,
      category: category,
      address: '123 Main St, Houston, TX',
      description:
          'Popular spot for ${v.name} — great music, strong drinks, and a crowd that shows up on weekends.',
      checkInCount: 1289,
      isOpen: true,
      hoursLabel: 'Open until 2:00 AM',
      services: const ['Dine-in', 'Takeaway', 'Delivery'],
      recentCheckIns: posts,
    );
  }

  /// Resolve check-in sheet row to full detail (creates entry if needed).
  static VenueDetail fromCheckIn(NearbyVenueCheckIn nearby) {
    final existing = byId(nearby.id);
    if (existing != null) return existing;

    final venue = Venue(
      id: nearby.id,
      name: nearby.name,
      imageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
      distanceMiles: nearby.distanceMiles,
      rating: 4.5,
      fullStars: 4,
      halfStar: true,
    );
    final detail = _detailFor(venue, category: 'Night clubs');
    _details[nearby.id] = detail;
    return detail;
  }

  static VenueDetail? byName(String name) {
    try {
      return _details.values.firstWhere((d) => d.venue.name == name);
    } catch (_) {
      return null;
    }
  }
}
