import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_discover_data.dart';
import '../models/venue.dart';
import 'supabase_bootstrap.dart';
import 'supabase_data.dart';
import 'user_service.dart';

/// Favorites — local cache with Supabase `user_favorites` sync.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'wtva_favorite_venue_ids';
  final Set<String> _ids = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    if (SupabaseData.syncAuth && !UserService().isGuest) {
      final userId = UserService().currentUser?.id;
      final client = SupabaseBootstrap.client;
      if (userId != null && userId != 'guest' && client != null) {
        try {
          final rows = await client
              .from('user_favorites')
              .select('venue_id')
              .eq('user_id', userId);
          _ids
            ..clear()
            ..addAll(rows.map((r) => (r as Map)['venue_id'] as String));
          _loaded = true;
          return;
        } catch (_) {}
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _ids
      ..clear()
      ..addAll(prefs.getStringList(_key) ?? ['2', '1', '3']);
    _loaded = true;
  }

  Future<void> onUserChanged() async {
    _loaded = false;
    await load();
  }

  bool isFavorite(String venueId) => _ids.contains(venueId);

  List<Venue> get venues {
    return MockDiscoverData.venues.where((v) => _ids.contains(v.id)).toList();
  }

  Future<bool> toggle(String venueId) async {
    await load();
    final adding = !_ids.contains(venueId);
    if (adding) {
      _ids.add(venueId);
    } else {
      _ids.remove(venueId);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _ids.toList());

    if (SupabaseData.syncAuth && !UserService().isGuest) {
      final userId = UserService().currentUser?.id;
      final client = SupabaseBootstrap.client;
      if (userId != null && userId != 'guest' && client != null) {
        try {
          if (adding) {
            await client.from('user_favorites').insert({
              'user_id': userId,
              'venue_id': venueId,
            });
          } else {
            await client
                .from('user_favorites')
                .delete()
                .eq('user_id', userId)
                .eq('venue_id', venueId);
          }
        } catch (_) {}
      }
    }

    return _ids.contains(venueId);
  }
}
