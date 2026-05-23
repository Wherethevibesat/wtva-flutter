import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../services/events_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/event_type_chips.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import 'events_browse_screen.dart';
import 'venue_detail_screen.dart';

/// Venues and events filtered by admin-defined neighborhood name.
class NeighborhoodVenuesScreen extends StatefulWidget {
  final String neighborhoodName;

  const NeighborhoodVenuesScreen({
    super.key,
    required this.neighborhoodName,
  });

  @override
  State<NeighborhoodVenuesScreen> createState() => _NeighborhoodVenuesScreenState();
}

class _NeighborhoodVenuesScreenState extends State<NeighborhoodVenuesScreen> {
  String? _eventType;
  late Future<List<WtvaEventRecord>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _reloadEvents();
  }

  void _reloadEvents() {
    _eventsFuture = EventsRepository.instance.listPublished(
      neighborhood: widget.neighborhoodName,
      eventType: _eventType,
      limit: 24,
    );
  }

  List<VenueDetail> get _venues {
    final target = widget.neighborhoodName.toLowerCase();
    return MockVenueStore.all
        .where((d) => (d.neighborhood ?? '').toLowerCase() == target)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final venues = _venues;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: Text(widget.neighborhoodName, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EventTypeChips(
            selected: _eventType,
            onSelected: (type) {
              setState(() {
                _eventType = type;
                _reloadEvents();
              });
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<WtvaEventRecord>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              final events = snapshot.data ?? const [];
              if (events.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...events.map(
                    (e) => Card(
                      color: WtvaColors.dark400,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${e.eventType} · ${MaterialLocalizations.of(context).formatMediumDate(e.startsAt)}',
                          style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventsBrowseScreen(
                          initialNeighborhood: widget.neighborhoodName,
                          initialEventType: _eventType,
                        ),
                      ),
                    ),
                    child: Text('View all events in ${widget.neighborhoodName}'),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          Text(
            'Venues',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (venues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No venues in ${widget.neighborhoodName} yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: WtvaColors.neutral300),
              ),
            )
          else
            ...venues.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WtvaVenueCard(
                  venue: detail.venue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailScreen(venueId: detail.venue.id),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
