import '../config/app_config.dart';
import '../data/mock_discover_data.dart';
import '../data/mock_venue_store.dart';
import '../models/venue.dart';
import '../models/venue_detail.dart';
import 'supabase_bootstrap.dart';

/// Loads venue catalog from Supabase and merges into [MockVenueStore].
class VenueRepository {
  VenueRepository._();
  static final VenueRepository instance = VenueRepository._();

  bool _hydrated = false;
  bool get isHydrated => _hydrated;

  Future<void> hydrate() async {
    if (_hydrated) return;
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      _hydrated = true;
      return;
    }

    final client = SupabaseBootstrap.client;
    if (client == null) {
      _hydrated = true;
      return;
    }

    try {
      final rows = await client.from('venues').select().order('distance_miles');
      if (rows.isEmpty) {
        _hydrated = true;
        return;
      }

      final venues = <Venue>[];
      for (final row in rows) {
        final detail = _detailFromRow(row as Map<String, dynamic>);
        MockVenueStore.putDetail(detail);
        venues.add(detail.venue);
      }

      MockDiscoverData.setVenues(venues);

      try {
        final checkInRows = await client
            .from('check_ins')
            .select('*, users(name, profile_image_url)')
            .order('started_at', ascending: false)
            .limit(40);
        _attachCheckIns(checkInRows);
      } catch (_) {
        // check_ins or join may not exist yet — venues still apply
      }
      _hydrated = true;
    } catch (_) {
      _hydrated = true;
    }
  }

  void _attachCheckIns(List<dynamic> rows) {
    final byVenue = <String, List<VenueCheckInPost>>{};
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      final venueId = row['venue_id'] as String?;
      if (venueId == null) continue;
      final user = row['users'] as Map<String, dynamic>?;
      final started = row['started_at'] as String?;
      byVenue.putIfAbsent(venueId, () => []).add(
            VenueCheckInPost(
              userName: user?['name'] as String? ?? 'Guest',
              avatarUrl: user?['profile_image_url'] as String? ??
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80',
              imageUrl: row['image_url'] as String? ??
                  'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80',
              caption: row['caption'] as String? ?? 'Checked in',
              timeAgo: _timeAgo(started),
              likes: 0,
            ),
          );
    }

    for (final entry in byVenue.entries) {
      final existing = MockVenueStore.byId(entry.key);
      if (existing == null) continue;
      MockVenueStore.putDetail(
        VenueDetail(
          venue: existing.venue,
          category: existing.category,
          address: existing.address,
          description: existing.description,
          checkInCount: existing.checkInCount,
          isOpen: existing.isOpen,
          hoursLabel: existing.hoursLabel,
          services: existing.services,
          recentCheckIns: entry.value.take(10).toList(),
        ),
      );
    }
  }

  VenueDetail _detailFromRow(Map<String, dynamic> row) {
    final rating = (row['rating'] as num?)?.toDouble() ?? 4.5;
    final fullStars = row['full_stars'] as int? ?? rating.floor().clamp(0, 5);
    final halfStar = row['half_star'] as bool? ?? (rating - fullStars >= 0.25);

    final venue = Venue(
      id: row['id'] as String,
      name: row['name'] as String,
      imageUrl: row['image_url'] as String? ??
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
      logoUrl: row['logo_url'] as String?,
      distanceMiles: (row['distance_miles'] as num?)?.toDouble() ?? 0,
      rating: rating,
      fullStars: fullStars,
      halfStar: halfStar,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
    );

    final servicesRaw = row['services'];
    final services = servicesRaw is List
        ? servicesRaw.map((e) => e.toString()).toList()
        : const ['Dine-in', 'Takeaway'];

    return VenueDetail(
      venue: venue,
      category: row['venue_type'] as String? ?? 'Restaurant',
      address: row['address'] as String? ?? 'Houston, TX',
      description: row['description'] as String? ??
          'Popular spot for ${venue.name}.',
      checkInCount: row['check_in_count'] as int? ?? 0,
      isOpen: row['is_open'] as bool? ?? true,
      hoursLabel: row['hours_label'] as String? ?? 'Open until 2:00 AM',
      services: services,
    );
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return 'Just now';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }
}
