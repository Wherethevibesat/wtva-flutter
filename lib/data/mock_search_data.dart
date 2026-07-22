import '../models/venue.dart';
import 'mock_discover_data.dart';
import 'mock_venue_store.dart';

class MockSearchData {
  /// No hardcoded recent queries.
  static const List<String> recentQueries = [];

  static List<Venue> resultsFor(String query) {
    final q = query.toLowerCase().trim();
    final all = MockDiscoverData.venues;
    if (q.isEmpty) return all;
    return all.where((v) {
      final detail = MockVenueStore.byId(v.id);
      final haystack = [
        v.name,
        detail?.category,
        detail?.neighborhood,
        detail?.address,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}
