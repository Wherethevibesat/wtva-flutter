import 'package:flutter/material.dart';
import '../../services/events_repository.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/event_type_chips.dart';

class EventsBrowseScreen extends StatefulWidget {
  const EventsBrowseScreen({
    super.key,
    this.initialEventType,
    this.initialNeighborhood,
  });

  final String? initialEventType;
  final String? initialNeighborhood;

  @override
  State<EventsBrowseScreen> createState() => _EventsBrowseScreenState();
}

class _EventsBrowseScreenState extends State<EventsBrowseScreen> {
  String? _eventType;
  String? _neighborhood;
  late Future<List<WtvaEventRecord>> _eventsFuture;
  late Future<List<NeighborhoodRecord>> _neighborhoodsFuture;

  @override
  void initState() {
    super.initState();
    _eventType = widget.initialEventType;
    _neighborhood = widget.initialNeighborhood;
    _neighborhoodsFuture = NeighborhoodsRepository.instance.list();
    _reloadEvents();
  }

  void _reloadEvents() {
    _eventsFuture = EventsRepository.instance.listPublished(
      eventType: _eventType,
      neighborhood: _neighborhood,
    );
  }

  void _setEventType(String? type) {
    setState(() {
      _eventType = type;
      _reloadEvents();
    });
  }

  void _setNeighborhood(String? name) {
    setState(() {
      _neighborhood = name;
      _reloadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          EventTypeChips(selected: _eventType, onSelected: _setEventType),
          const SizedBox(height: 20),
          FutureBuilder<List<NeighborhoodRecord>>(
            future: _neighborhoodsFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neighborhood',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: WtvaColors.neutral300,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: rows.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return ActionChip(
                            label: const Text('All areas'),
                            backgroundColor:
                                _neighborhood == null ? WtvaColors.accentPurple : WtvaColors.dark300,
                            labelStyle: TextStyle(
                              color: _neighborhood == null ? Colors.white : WtvaColors.neutral100,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onPressed: () => _setNeighborhood(null),
                          );
                        }
                        final n = rows[i - 1];
                        final active = _neighborhood == n.name;
                        return ActionChip(
                          label: Text(n.name),
                          backgroundColor: active ? WtvaColors.accentPurple : WtvaColors.dark300,
                          labelStyle: TextStyle(
                            color: active ? Colors.white : WtvaColors.neutral100,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onPressed: () => _setNeighborhood(n.name),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<WtvaEventRecord>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data ?? const [];
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No upcoming events match these filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WtvaColors.neutral300),
                    ),
                  ),
                );
              }
              return Column(
                children: events.map((e) => _EventTile(event: e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final WtvaEventRecord event;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(event.startsAt);
    return Card(
      color: WtvaColors.dark400,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${event.eventType} · $date${event.venueName != null ? ' · ${event.venueName}' : ''}${event.neighborhood != null ? ' · ${event.neighborhood}' : ''}',
          style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
        ),
      ),
    );
  }
}
