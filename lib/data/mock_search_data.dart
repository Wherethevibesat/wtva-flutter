import '../models/venue.dart';
import 'mock_discover_data.dart';

class MockSearchData {
  static const recentQueries = ['Joe\'s Strip Bar', 'rooftop', 'live music', 'Dream Land'];

  static List<Venue> resultsFor(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return MockDiscoverData.venues;
    return MockDiscoverData.venues
        .where((v) => v.name.toLowerCase().contains(q))
        .toList();
  }
}
