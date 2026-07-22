import '../config/app_config.dart';
import '../data/mock_discover_data.dart';
import '../data/mock_venue_store.dart';
import '../models/venue.dart';
import '../models/venue_detail.dart';
import 'supabase_bootstrap.dart';

/// Loads venue catalog from Supabase into [MockVenueStore] (replace, not merge).
class VenueRepository {
  VenueRepository._();
  static final VenueRepository instance = VenueRepository._();

  bool _hydrated = false;
  bool get isHydrated => _hydrated;

  Future<void> hydrate({bool force = false}) async {
    if (_hydrated && !force) return;

    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      MockVenueStore.clear();
      MockDiscoverData.clear();
      _hydrated = true;
      return;
    }

    final client = SupabaseBootstrap.client;
    if (client == null) {
      MockVenueStore.clear();
      MockDiscoverData.clear();
      _hydrated = true;
      return;
    }

    try {
      // Match web: published venues only; fall back if column/filter fails.
      List<dynamic> rows;
      try {
        rows = await client
            .from('venues')
            .select()
            .eq('published', true)
            .order('name');
      } catch (_) {
        rows = await client.from('venues').select().order('name');
      }

      final details = <VenueDetail>[];
      for (final row in rows) {
        details.add(_detailFromRow(row as Map<String, dynamic>));
      }

      MockVenueStore.replaceAll(details);
      MockDiscoverData.setVenues(details.map((d) => d.venue).toList());

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
      MockVenueStore.clear();
      MockDiscoverData.clear();
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
              avatarUrl: user?['profile_image_url'] as String? ?? '',
              imageUrl: row['image_url'] as String? ?? '',
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
          checkInCount: existing.checkInCount > 0
              ? existing.checkInCount
              : entry.value.length,
          isOpen: existing.isOpen,
          hoursLabel: existing.hoursLabel,
          neighborhood: existing.neighborhood,
          phone: existing.phone,
          services: existing.services,
          recentCheckIns: entry.value.take(10).toList(),
          featured: existing.featured,
        ),
      );
    }
  }

  VenueDetail _detailFromRow(Map<String, dynamic> row) {
    final rating = (row['rating'] as num?)?.toDouble() ?? 0;
    final fullStars = row['full_stars'] as int? ??
        (rating > 0 ? rating.floor().clamp(0, 5) : 0);
    final halfStar = row['half_star'] as bool? ??
        (rating > 0 && rating - fullStars >= 0.25);

    final venue = Venue(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'Venue',
      imageUrl: row['image_url'] as String? ?? '',
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
        : const <String>[];
    final phoneRaw = (row['phone'] as String?)?.trim();

    return VenueDetail(
      venue: venue,
      category: row['venue_type'] as String? ?? 'Venue',
      address: row['address'] as String? ?? '',
      description: row['description'] as String? ?? '',
      checkInCount: row['check_in_count'] as int? ?? 0,
      isOpen: row['is_open'] as bool? ?? true,
      hoursLabel: row['hours_label'] as String? ?? '',
      neighborhood: row['neighborhood'] as String?,
      phone: (phoneRaw == null || phoneRaw.isEmpty) ? null : phoneRaw,
      services: services,
      featured: row['featured'] as bool? ?? false,
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
