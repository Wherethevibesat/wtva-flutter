import '../models/venue.dart';
import '../services/favorites_service.dart';

class MockFavoritesData {
  static List<Venue> get venues => FavoritesService.instance.venues;
}
