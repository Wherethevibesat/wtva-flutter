import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/mock_discover_data.dart';
import '../../data/mock_venue_store.dart';
import '../../data/weekdays.dart';
import '../../models/venue.dart';
import '../../services/events_repository.dart';
import '../../services/neighborhoods_repository.dart';
import '../../services/venue_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import 'event_detail_screen.dart';
import 'events_filters_sheet.dart';
import 'venue_detail_screen.dart';

/// Matches web `/discover/search` + hero popular searches + filters.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery, this.initialFilters});

  final String? initialQuery;
  final EventsFilters? initialFilters;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _popular = [
    'Rooftop',
    'Happy Hour',
    'Afrobeats',
    'R&B',
    'Brunch',
    'After Hours',
  ];

  static const _shortcuts = [
    (label: 'Happy Hour', query: 'Happy Hour', icon: Icons.local_bar_rounded),
    (label: 'Afrobeats', query: 'Afrobeats', icon: Icons.album_rounded),
    (label: 'After Hours', query: 'After Hours', icon: Icons.nights_stay_rounded),
    (label: 'Rooftops', query: 'Rooftop', icon: Icons.apartment_rounded),
    (label: 'Brunch', query: 'Brunch', icon: Icons.brunch_dining_rounded),
    (label: 'Live Music', query: 'Live Music', icon: Icons.music_note_rounded),
  ];

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List<Venue> _venues = const [];
  List<WtvaEventRecord> _events = const [];
  List<WtvaEventRecord> _allEvents = const [];
  List<NeighborhoodRecord> _neighborhoods = const [];
  EventsFilters _filters = const EventsFilters();
  bool _ready = false;
  String _query = '';

  bool get _hasActiveSearch =>
      _query.trim().isNotEmpty || _filters.hasSelection;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _query = initial;
    }
    if (widget.initialFilters != null) {
      _filters = widget.initialFilters!;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await VenueRepository.instance.hydrate();
    final results = await Future.wait([
      EventsRepository.instance.listPublished(limit: 80),
      NeighborhoodsRepository.instance.list(),
    ]);
    if (!mounted) return;
    setState(() {
      _allEvents = results[0] as List<WtvaEventRecord>;
      _neighborhoods = results[1] as List<NeighborhoodRecord>;
      _ready = true;
    });
    if (_hasActiveSearch) _applyResults();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() => _query = value.trim());
      _applyResults();
    });
  }

  void _runSearch(String raw) {
    setState(() => _query = raw.trim());
    _applyResults();
  }

  Future<void> _openFilters() async {
    final result = await EventsFiltersSheet.show(
      context,
      initial: _filters,
      neighborhoods: _neighborhoods,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _applyResults();
  }

  void _clearFilters() {
    setState(() => _filters = const EventsFilters());
    _applyResults();
  }

  void _applyResults() {
    final q = _query.trim();
    final needle = q.toLowerCase();
    final hasQuery = needle.isNotEmpty;
    final hasFilters = _filters.hasSelection;

    if (!hasQuery && !hasFilters) {
      setState(() {
        _venues = const [];
        _events = const [];
      });
      return;
    }

    var events = _allEvents.where((e) {
      if (_filters.eventType != null &&
          e.eventType.toLowerCase() != _filters.eventType!.toLowerCase()) {
        return false;
      }
      if (_filters.neighborhoods.isNotEmpty) {
        final n = e.neighborhood?.trim() ?? '';
        if (!_filters.neighborhoods.any((f) => f.toLowerCase() == n.toLowerCase())) {
          return false;
        }
      }
      if (_filters.daysOfWeek.isNotEmpty) {
        final day = e.startsAt.toLocal().weekday;
        if (!_filters.daysOfWeek.contains(day)) return false;
      }
      if (!hasQuery) return true;
      final haystack = [
        e.title,
        e.eventType,
        e.venueName,
        e.neighborhood,
        e.description,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();

    // Venues: keyword + neighborhood only (type/day are event filters).
    final venues = (!hasQuery && _filters.eventType == null && _filters.daysOfWeek.isEmpty)
        ? MockDiscoverData.venues.where((v) {
            if (_filters.neighborhoods.isEmpty) return true;
            final detail = MockVenueStore.byId(v.id);
            final n = detail?.neighborhood?.trim() ?? '';
            return _filters.neighborhoods
                .any((f) => f.toLowerCase() == n.toLowerCase());
          }).toList()
        : MockDiscoverData.venues.where((v) {
            final detail = MockVenueStore.byId(v.id);
            if (_filters.neighborhoods.isNotEmpty) {
              final n = detail?.neighborhood?.trim() ?? '';
              if (!_filters.neighborhoods
                  .any((f) => f.toLowerCase() == n.toLowerCase())) {
                return false;
              }
            }
            // Event-type / day filters mean this is an event browse — skip venues
            // unless there's also a text query matching the venue.
            if ((_filters.eventType != null || _filters.daysOfWeek.isNotEmpty) &&
                !hasQuery) {
              return false;
            }
            if (!hasQuery) return _filters.neighborhoods.isNotEmpty;
            final haystack = [
              v.name,
              detail?.category,
              detail?.neighborhood,
              detail?.address,
              detail?.description,
            ].whereType<String>().join(' ').toLowerCase();
            return haystack.contains(needle);
          }).toList();

    setState(() {
      _events = events;
      _venues = venues;
    });
  }

  void _applyChip(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _runSearch(term);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _filters.activeCount;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.initialQuery == null,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: WtvaColors.neutral50, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search events, DJs, venues…',
              hintStyle: const TextStyle(color: WtvaColors.neutral300, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: WtvaColors.neutral300, size: 20),
              filled: true,
              fillColor: WtvaColors.dark400,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: WtvaColors.night200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: WtvaColors.night200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: WtvaColors.accentPurple, width: 1.5),
              ),
              isDense: true,
            ),
            onChanged: _onQueryChanged,
            onSubmitted: _runSearch,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Filters',
                  onPressed: _ready ? _openFilters : null,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: filterCount > 0
                        ? WtvaColors.accentPurple
                        : WtvaColors.neutral50,
                  ),
                ),
                if (filterCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: WtvaColors.accentPurple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: WtvaColors.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: WtvaColors.accentPurple))
          : Column(
              children: [
                if (_filters.hasSelection)
                  _ActiveFiltersBar(
                    filters: _filters,
                    onClear: _clearFilters,
                    onOpen: _openFilters,
                  ),
                Expanded(
                  child: _hasActiveSearch
                      ? _ResultsBody(
                          query: _query,
                          filters: _filters,
                          events: _events,
                          venues: _venues,
                        )
                      : _IdleBody(
                          popular: _popular,
                          shortcuts: _shortcuts,
                          onChip: _applyChip,
                          onShortcut: _applyChip,
                          onOpenFilters: _openFilters,
                        ),
                ),
              ],
            ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.filters,
    required this.onClear,
    required this.onOpen,
  });

  final EventsFilters filters;
  final VoidCallback onClear;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (filters.eventType != null) filters.eventType!,
      ...filters.neighborhoods,
      ...filters.daysOfWeek.map(WtvaWeekdays.shortLabelFor),
    ];

    return Material(
      color: WtvaColors.dark500,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final label in chips) ...[
                      ActionChip(
                        onPressed: onOpen,
                        label: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: WtvaColors.neutral50,
                          ),
                        ),
                        backgroundColor: WtvaColors.dark400,
                        side: const BorderSide(color: WtvaColors.accentPurple),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: WtvaColors.accentPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({
    required this.popular,
    required this.shortcuts,
    required this.onChip,
    required this.onShortcut,
    required this.onOpenFilters,
  });

  final List<String> popular;
  final List<({String label, String query, IconData icon})> shortcuts;
  final ValueChanged<String> onChip;
  final ValueChanged<String> onShortcut;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        OutlinedButton.icon(
          onPressed: onOpenFilters,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('Filters · type, day, neighborhood'),
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral50,
            side: const BorderSide(color: WtvaColors.night200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Popular searches',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: WtvaColors.neutral300,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in popular)
              ActionChip(
                label: Text(
                  term,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: WtvaColors.neutral50,
                  ),
                ),
                backgroundColor: WtvaColors.dark400,
                side: const BorderSide(color: WtvaColors.night200),
                onPressed: () => onChip(term),
              ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Browse by vibe',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: WtvaColors.neutral300,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in shortcuts)
              InkWell(
                onTap: () => onShortcut(s.query),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: (MediaQuery.sizeOf(context).width - 50) / 2,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark400,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: WtvaColors.night200),
                    boxShadow: WtvaColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, size: 18, color: WtvaColors.onPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WtvaColors.night200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What can I search?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              SizedBox(height: 6),
              Text(
                'Try event names, venues, neighborhoods, music styles, or vibes like rooftop and happy hour — same as the website. Use Filters for event type, day of week, and neighborhood.',
                style: TextStyle(
                  color: WtvaColors.neutral200,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.query,
    required this.filters,
    required this.events,
    required this.venues,
  });

  final String query;
  final EventsFilters filters;
  final List<WtvaEventRecord> events;
  final List<Venue> venues;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && venues.isEmpty) {
      final title = query.isNotEmpty
          ? 'No results for “$query”'
          : 'No results for these filters';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: WtvaColors.neutral300),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try another vibe, neighborhood, day, or event type.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WtvaColors.neutral300, height: 1.35),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text(
          '${events.length + venues.length} result${events.length + venues.length == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WtvaColors.neutral300,
          ),
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final e in events.take(20)) ...[
            _EventResultTile(event: e),
            const SizedBox(height: 8),
          ],
        ],
        if (venues.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Venues',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final v in venues.take(20)) ...[
            WtvaVenueCard(
              venue: v,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: v.id)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _EventResultTile extends StatelessWidget {
  const _EventResultTile({required this.event});

  final WtvaEventRecord event;

  @override
  Widget build(BuildContext context) {
    final when = MaterialLocalizations.of(context).formatMediumDate(event.startsAt.toLocal());
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: event.imageUrl != null && event.imageUrl!.isNotEmpty
              ? Image.network(
                  event.imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            event.eventType,
            when,
            if (event.venueName != null && event.venueName!.isNotEmpty) event.venueName!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
        ),
        trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: WtvaColors.dark300,
      child: const Icon(Icons.event, color: WtvaColors.accentPurple),
    );
  }
}
