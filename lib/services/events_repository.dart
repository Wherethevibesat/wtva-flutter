import '../config/app_config.dart';
import '../data/event_types.dart';
import '../data/event_dates.dart';
import '../data/ticket_tier.dart';
import 'supabase_bootstrap.dart';

class WtvaEventRecord {
  const WtvaEventRecord({
    required this.id,
    required this.title,
    required this.eventType,
    required this.neighborhood,
    required this.startsAt,
    this.endsAt,
    this.description,
    this.imageUrl,
    this.venueName,
  });

  final String id;
  final String title;
  final String eventType;
  final String? neighborhood;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? description;
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
    String? date,
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
      if (date != null && date.isNotEmpty) {
        final localDay = EventDates.parseIsoDate(date);
        final start = DateTime(localDay.year, localDay.month, localDay.day);
        final end = start.add(const Duration(days: 1));
        query = query
            .gte('starts_at', start.toUtc().toIso8601String())
            .lt('starts_at', end.toUtc().toIso8601String());
      }

      final rows = await query.order('starts_at').limit(limit);
      return rows.map<WtvaEventRecord>(_fromRow).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<WtvaEventRecord?> getPublishedEvent(String id) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('events')
          .select(
            'id, title, description, event_type, neighborhood, starts_at, ends_at, image_url, venue:venues(name)',
          )
          .eq('id', id)
          .eq('status', 'published')
          .maybeSingle();
      if (row == null) return null;
      return _fromRow(row);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserRegistrationTierName(String eventId, String userId) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) return null;
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('event_registrations')
          .select('event_ticket_tiers(name)')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .maybeSingle();
      if (row == null) return null;
      final tier = row['event_ticket_tiers'];
      if (tier is Map) return tier['name'] as String?;
      if (tier is List && tier.isNotEmpty) {
        return (tier.first as Map)['name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<List<EventTicketTierRecord>> listTicketTiers(String eventId) async {
    if (!AppConfig.useSupabaseData || !SupabaseBootstrap.initialized) return const [];
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];
    try {
      final rows = await client
          .from('event_ticket_tiers')
          .select('id, name, price_cents, capacity, description')
          .eq('event_id', eventId)
          .eq('is_active', true)
          .order('sort_order');
      return rows
          .map(
            (row) => EventTicketTierRecord(
              id: row['id'] as String,
              name: row['name'] as String? ?? freeRsvpTierName,
              priceCents: row['price_cents'] as int? ?? 0,
              capacity: row['capacity'] as int?,
              description: row['description'] as String?,
            ),
          )
          .toList();
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
      endsAt: map['ends_at'] != null ? DateTime.parse(map['ends_at'] as String) : null,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      venueName: venueName,
    );
  }
}
