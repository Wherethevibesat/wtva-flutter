import '../config/app_config.dart';
import '../data/event_types.dart';
import 'supabase_bootstrap.dart';

class WtvaEventRecord {
  const WtvaEventRecord({
    required this.id,
    required this.title,
    required this.eventType,
    required this.neighborhood,
    required this.startsAt,
    this.imageUrl,
    this.venueName,
  });

  final String id;
  final String title;
  final String eventType;
  final String? neighborhood;
  final DateTime startsAt;
  final String? imageUrl;
  final String? venueName;
}

/// Loads published events from Supabase for browse/filter screens.
class EventsRepository {
  EventsRepository._();
  static final EventsRepository instance = EventsRepository._();

  Future<List<WtvaEventRecord>> listPublished({
    String? eventType,
    String? neighborhood,
    List<String>? neighborhoods,
    int limit = 60,
  }) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) {
      return const [];
    }
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    final neighborhoodFilters = neighborhoods ??
        (neighborhood != null && neighborhood.isNotEmpty ? [neighborhood] : null);

    try {
      var query = client
          .from('events')
          .select('id, title, event_type, neighborhood, starts_at, image_url, venue:venues(name)')
          .eq('status', 'published')
          .gte('starts_at', DateTime.now().toUtc().toIso8601String());

      if (eventType != null && eventType.isNotEmpty) {
        query = query.eq('event_type', eventType);
      }
      if (neighborhoodFilters != null && neighborhoodFilters.isNotEmpty) {
        if (neighborhoodFilters.length == 1) {
          query = query.eq('neighborhood', neighborhoodFilters.first);
        } else {
          query = query.inFilter('neighborhood', neighborhoodFilters);
        }
      }

      final rows = await query.order('starts_at').limit(limit);
      return rows.map<WtvaEventRecord>(_fromRow).toList();
    } catch (_) {
      return const [];
    }
  }

  WtvaEventRecord _fromRow(dynamic row) {
    final map = row as Map<String, dynamic>;
    final venue = map['venue'];
    String? venueName;
    if (venue is Map) {
      venueName = venue['name'] as String?;
    } else if (venue is List && venue.isNotEmpty) {
      venueName = (venue.first as Map)['name'] as String?;
    }

    return WtvaEventRecord(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Event',
      eventType: map['event_type'] as String? ?? WtvaEventTypes.defaultType,
      neighborhood: map['neighborhood'] as String?,
      startsAt: DateTime.parse(map['starts_at'] as String),
      imageUrl: map['image_url'] as String?,
      venueName: venueName,
    );
  }
}
