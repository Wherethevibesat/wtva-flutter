import '../data/event_types.dart';
import '../data/event_occurrences.dart';
import '../data/ticket_tier.dart';
import '../services/business_repository.dart';
import '../services/supabase_bootstrap.dart';
import '../services/supabase_data.dart';
import '../services/user_service.dart';

class BusinessEventRecord {
  const BusinessEventRecord({
    required this.id,
    required this.title,
    required this.eventType,
    required this.neighborhood,
    required this.startsAt,
    required this.status,
    this.endsAt,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String eventType;
  final String? neighborhood;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? description;
  final String? imageUrl;
  final String status;
}

class BusinessEventDraft {
  const BusinessEventDraft({
    this.id,
    required this.title,
    required this.eventType,
    required this.neighborhood,
    required this.startsAt,
    this.endsAt,
    this.description = '',
    this.imageUrl = '',
    this.additionalDates = const [],
    this.recurrence,
    this.ticketTiers = const [TicketTierInput(name: freeRsvpTierName, priceCents: 0)],
  });

  final String? id;
  final String title;
  final String eventType;
  final String neighborhood;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String description;
  final String imageUrl;
  final List<DateTime> additionalDates;
  final EventRecurrenceInput? recurrence;
  final List<TicketTierInput> ticketTiers;
}

class BusinessEventsRepository {
  BusinessEventsRepository._();
  static final BusinessEventsRepository instance = BusinessEventsRepository._();

  String? get _ownerId => UserService().currentUser?.id;

  Future<List<BusinessEventRecord>> listOwnerEvents() async {
    if (!SupabaseData.syncAuth) return const [];
    final venueId = await BusinessRepository.instance.primaryVenueId();
    if (venueId == null) return const [];
    final client = SupabaseBootstrap.client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('events')
          .select('id, title, event_type, neighborhood, starts_at, ends_at, image_url, description, status')
          .eq('venue_id', venueId)
          .order('starts_at', ascending: false);
      return rows.map<BusinessEventRecord>(_fromRow).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> submitEvent(BusinessEventDraft draft) async {
    if (!SupabaseData.syncAuth) return const [];
    final ownerId = _ownerId;
    final venueId = await BusinessRepository.instance.primaryVenueId();
    final client = SupabaseBootstrap.client;
    if (ownerId == null || venueId == null || client == null) {
      throw StateError('Sign in and link a venue before submitting events.');
    }

    final occurrences = _buildOccurrences(draft);
    final now = DateTime.now().toUtc().toIso8601String();

    if (draft.id != null) {
      if (occurrences.length != 1) {
        throw StateError('When editing, use a single date.');
      }
      final occ = occurrences.first;
      await client.from('events').update({
        'title': draft.title.trim(),
        'description': draft.description.trim(),
        'event_type': draft.eventType,
        'neighborhood': draft.neighborhood.isEmpty ? null : draft.neighborhood,
        'starts_at': occ.startsAt.toUtc().toIso8601String(),
        'ends_at': occ.endsAt?.toUtc().toIso8601String(),
        'image_url': draft.imageUrl.trim().isEmpty ? null : draft.imageUrl.trim(),
        'status': 'pending_review',
        'updated_at': now,
      }).eq('id', draft.id!).eq('venue_id', venueId);
      return [draft.id!];
    }

    final rows = occurrences
        .map(
          (occ) => {
            'venue_id': venueId,
            'title': draft.title.trim(),
            'description': draft.description.trim(),
            'event_type': draft.eventType,
            'neighborhood': draft.neighborhood.isEmpty ? null : draft.neighborhood,
            'starts_at': occ.startsAt.toUtc().toIso8601String(),
            'ends_at': occ.endsAt?.toUtc().toIso8601String(),
            'image_url': draft.imageUrl.trim().isEmpty ? null : draft.imageUrl.trim(),
            'status': 'pending_review',
            'featured': false,
            'submitted_by': ownerId,
            'updated_at': now,
          },
        )
        .toList();

    final inserted = await client.from('events').insert(rows).select('id');
    return inserted.map((row) => row['id'] as String).toList();
  }

  List<_Occurrence> _buildOccurrences(BusinessEventDraft draft) {
    final duration = draft.endsAt != null ? draft.endsAt!.difference(draft.startsAt) : null;
    final primaryDay = DateTime(draft.startsAt.year, draft.startsAt.month, draft.startsAt.day);
    final extraDays = draft.additionalDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => d != primaryDay)
        .toSet()
        .toList()
      ..sort();

    final days = [primaryDay, ...extraDays];
    return days.map((day) {
      final starts = DateTime(
        day.year,
        day.month,
        day.day,
        draft.startsAt.hour,
        draft.startsAt.minute,
      );
      final ends = duration != null ? starts.add(duration) : null;
      return _Occurrence(startsAt: starts, endsAt: ends);
    }).toList();
  }

  BusinessEventRecord _fromRow(dynamic row) {
    final map = row as Map<String, dynamic>;
    return BusinessEventRecord(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Event',
      eventType: map['event_type'] as String? ?? WtvaEventTypes.defaultType,
      neighborhood: map['neighborhood'] as String?,
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: map['ends_at'] != null ? DateTime.parse(map['ends_at'] as String) : null,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      status: map['status'] as String? ?? 'pending_review',
    );
  }
}

class _Occurrence {
  const _Occurrence({required this.startsAt, this.endsAt});
  final DateTime startsAt;
  final DateTime? endsAt;
}
