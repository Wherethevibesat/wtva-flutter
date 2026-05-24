import 'package:flutter/material.dart';
import '../../services/events_repository.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/inline_event_date_picker.dart';
import 'event_detail_screen.dart';
import 'events_filters_sheet.dart';

class EventsBrowseScreen extends StatefulWidget {
  const EventsBrowseScreen({
    super.key,
    this.initialEventType,
    this.initialNeighborhood,
    this.initialDate,
    this.initialFilters,
  });

  final String? initialEventType;
  final String? initialNeighborhood;
  final String? initialDate;
  final EventsFilters? initialFilters;

  @override
  State<EventsBrowseScreen> createState() => _EventsBrowseScreenState();
}

class _EventsBrowseScreenState extends State<EventsBrowseScreen> {
  final _searchController = TextEditingController();
  String? _eventType;
  List<String> _neighborhoods = const [];
  List<int> _daysOfWeek = const [];
  String? _date;
  late Future<List<WtvaEventRecord>> _eventsFuture;
  late Future<List<NeighborhoodRecord>> _neighborhoodsFuture;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    if (initial != null) {
      _eventType = initial.eventType;
      _neighborhoods = List<String>.from(initial.neighborhoods);
      _daysOfWeek = List<int>.from(initial.daysOfWeek);
    } else {
      _eventType = widget.initialEventType;
      if (widget.initialNeighborhood != null && widget.initialNeighborhood!.isNotEmpty) {
        _neighborhoods = [widget.initialNeighborhood!];
      }
    }
    _date = widget.initialDate;
    _neighborhoodsFuture = NeighborhoodsRepository.instance.list();
    _reloadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  EventsFilters get _filters => EventsFilters(
        eventType: _eventType,
        neighborhoods: _neighborhoods,
        daysOfWeek: _daysOfWeek,
      );

  bool get _hasAnyFilter =>
      _filters.hasSelection || _date != null || _searchController.text.trim().isNotEmpty;

  void _reloadEvents() {
    _eventsFuture = EventsRepository.instance.listPublished(
      eventType: _eventType,
      neighborhoods: _neighborhoods,
      date: _date,
    );
  }

  Future<void> _openFilters(List<NeighborhoodRecord> neighborhoods) async {
    final result = await EventsFiltersSheet.show(
      context,
      initial: _filters,
      neighborhoods: neighborhoods,
    );
    if (result == null || !mounted) return;
    setState(() {
      _eventType = result.eventType;
      _neighborhoods = result.neighborhoods;
      _daysOfWeek = result.daysOfWeek;
      _reloadEvents();
    });
  }

  void _setDate(String? date) {
    setState(() {
      _date = date;
      _reloadEvents();
    });
  }

  List<WtvaEventRecord> _applyClientFilters(List<WtvaEventRecord> events) {
    var list = events;
    if (_daysOfWeek.isNotEmpty) {
      final selected = _daysOfWeek.toSet();
      list = list.where((e) => selected.contains(e.startsAt.toLocal().weekday)).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((e) {
      final haystack = [
        e.title,
        e.eventType,
        e.venueName,
        e.neighborhood,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: WtvaColors.neutral50),
                  decoration: InputDecoration(
                    hintText: 'Search events, venues...',
                    hintStyle: const TextStyle(color: WtvaColors.neutral300),
                    prefixIcon: const Icon(Icons.search, color: WtvaColors.neutral300),
                    filled: true,
                    fillColor: WtvaColors.dark400,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.85)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: WtvaColors.night200.withValues(alpha: 0.85)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: WtvaColors.accentPurple),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<NeighborhoodRecord>>(
                  future: _neighborhoodsFuture,
                  builder: (context, snapshot) {
                    final neighborhoods = snapshot.data ?? const [];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        InlineEventDatePicker(
                          date: _date,
                          onChanged: _setDate,
                        ),
                        OutlinedButton.icon(
                          onPressed: snapshot.connectionState == ConnectionState.waiting
                              ? null
                              : () => _openFilters(neighborhoods),
                          icon: const Icon(Icons.tune, size: 18),
                          label: Text(
                            _filters.hasSelection
                                ? 'Filters (${_filters.activeCount})'
                                : 'Filters',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WtvaColors.neutral100,
                            side: BorderSide(
                              color: _filters.hasSelection
                                  ? WtvaColors.accentPurple
                                  : WtvaColors.night200.withValues(alpha: 0.85),
                            ),
                            backgroundColor: WtvaColors.dark400,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<WtvaEventRecord>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = _applyClientFilters(snapshot.data ?? const []);
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _hasAnyFilter
                            ? 'No upcoming events match these filters.'
                            : 'No upcoming events right now.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: WtvaColors.neutral300),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _EventTile(event: events[i]),
                );
              },
            ),
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
      child: ListTile(
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${event.eventType} · $date${event.venueName != null ? ' · ${event.venueName}' : ''}${event.neighborhood != null ? ' · ${event.neighborhood}' : ''}',
          style: const TextStyle(color: WtvaColors.neutral300, fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
          );
        },
      ),
    );
  }
}
