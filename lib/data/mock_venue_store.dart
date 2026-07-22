import '../models/venue.dart';
import '../models/venue_detail.dart';
import 'mock_check_in_data.dart';

/// In-memory venue catalog for customer screens.
/// Populated only from [VenueRepository.hydrate] (Supabase) — no seed fixtures.
class MockVenueStore {
  MockVenueStore._();

  static final Map<String, VenueDetail> _details = {};

  static void clear() => _details.clear();

  static void replaceAll(Iterable<VenueDetail> details) {
    _details
      ..clear()
      ..addEntries(details.map((d) => MapEntry(d.venue.id, d)));
  }

  static void putDetail(VenueDetail detail) {
    _details[detail.venue.id] = detail;
  }

  static VenueDetail? byId(String id) => _details[id];

  static VenueDetail byIdOrThrow(String id) {
    final detail = _details[id];
    if (detail == null) {
      throw StateError('Venue not found: $id');
    }
    return detail;
  }

  static List<VenueDetail> get all => _details.values.toList();

  static Venue? venueById(String id) => byId(id)?.venue;

  /// Resolve check-in sheet row to full detail (creates a thin entry if needed).
  static VenueDetail fromCheckIn(NearbyVenueCheckIn nearby) {
    final existing = byId(nearby.id);
    if (existing != null) return existing;

    final venue = Venue(
      id: nearby.id,
      name: nearby.name,
      imageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
      distanceMiles: nearby.distanceMiles,
      rating: 0,
      fullStars: 0,
    );
    final detail = VenueDetail(
      venue: venue,
      category: 'Venue',
      address: 'Houston, TX',
      description: '',
      checkInCount: 0,
      isOpen: true,
      hoursLabel: '',
      neighborhood: null,
      services: const [],
      recentCheckIns: const [],
      featured: false,
    );
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
