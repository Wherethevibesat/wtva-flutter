import '../models/venue.dart';
import 'mock_venue_store.dart';

/// Discover feed helpers. Venue lists come from hydrated [MockVenueStore] only.
class MockDiscoverData {
  static const categories = [
    'Nearest',
    'Bars',
    'Night clubs',
    'Restaurants',
    'Location',
  ];

  static List<Venue> _venues = [];

  static List<Venue> get venues {
    if (_venues.isNotEmpty) return _venues;
    return MockVenueStore.all.map((d) => d.venue).toList();
  }

  static void setVenues(List<Venue> list) {
    _venues = List<Venue>.from(list);
  }

  static void clear() {
    _venues = [];
  }

  /// Filter discover list by category chip (index) using real venue types.
  static List<Venue> venuesForCategory(int categoryIndex) {
    final label = categories[categoryIndex];
    final all = venues;
    switch (label) {
      case 'Bars':
        return all.where((v) {
          final type = (MockVenueStore.byId(v.id)?.category ?? '').toLowerCase();
          return type.contains('bar') || type.contains('lounge');
        }).toList();
      case 'Night clubs':
        return all.where((v) {
          final type = (MockVenueStore.byId(v.id)?.category ?? '').toLowerCase();
          return type.contains('club') || type.contains('night');
        }).toList();
      case 'Restaurants':
        return all.where((v) {
          final type = (MockVenueStore.byId(v.id)?.category ?? '').toLowerCase();
          return type.contains('restaurant') || type.contains('dining');
        }).toList();
      case 'Nearest':
      case 'Location':
      default:
        final sorted = List<Venue>.from(all)
          ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        return sorted;
    }
  }

  /// Hidden until promotions are backed by data.
  static const PromotedOffer? promoted = null;

  /// Hidden until live stories are backed by data.
  static const List<LiveStory> liveStories = [];
}
