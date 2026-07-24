import 'package:flutter/material.dart';
import '../../services/events_repository.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/inline_event_date_picker.dart';
import '../../widgets/wtva/wtva_pill_search_bar.dart';
import 'event_detail_screen.dart';
import 'events_filters_sheet.dart';

class EventsBrowseScreen extends StatefulWidget {
  const EventsBrowseScreen({
    super.key,
    this.initialEventType,
    this.initialQuery,
    this.initialNeighborhood,
    this.initialDate,
    this.initialFilters,
    this.embedded = false,
  });

  final String? initialEventType;
  final String? initialQuery;
  final String? initialNeighborhood;
  final String? initialDate;
  final EventsFilters? initialFilters;

  /// When true (bottom-nav tab), hide the back button.
  final bool embedded;

  @override
  State<EventsBrowseScreen> createState() => _EventsBrowseScreenState();
}

class _EventsBrowseScreenState extends State<EventsBrowseScreen> {
  static const _categories = <({String label, String? eventType, IconData icon})>[
    (label: 'All Events', eventType: null, icon: Icons.auto_awesome),
    (label: 'Nightlife', eventType: 'Night Party', icon: Icons.nightlife),
    (label: 'Day Party', eventType: 'Day Party', icon: Icons.wb_sunny_outlined),
    (label: 'Brunch', eventType: 'Brunch / Daytime', icon: Icons.local_cafe_outlined),
    (label: 'Live Music', eventType: 'Live Music / DJ', icon: Icons.mic_none_rounded),
    (label: 'After Hours', eventType: 'After Hours', icon: Icons.nights_stay_outlined),
  ];

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
    final q = widget.initialQuery?.trim();
    if (q != null && q.isNotEmpty) {
      _searchController.text = q;
    }
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

  void _selectCategory(String? eventType) {
    setState(() {
      _eventType = eventType;
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
    final topPad = widget.embedded ? MediaQuery.paddingOf(context).top : 0.0;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Column(
        children: [
          SizedBox(height: topPad),
          if (!widget.embedded)
            AppBar(
              backgroundColor: WtvaColors.dark500,
              foregroundColor: WtvaColors.neutral50,
              elevation: 0,
              title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          Expanded(
            child: FutureBuilder<List<NeighborhoodRecord>>(
              future: _neighborhoodsFuture,
              builder: (context, hoodSnap) {
                final neighborhoods = hoodSnap.data ?? const [];
                return FutureBuilder<List<WtvaEventRecord>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    final loading = snapshot.connectionState == ConnectionState.waiting;
                    final events = _applyClientFilters(snapshot.data ?? const []);

                    return RefreshIndicator(
                      color: WtvaColors.accentPurple,
                      onRefresh: () async {
                        setState(_reloadEvents);
                        await _eventsFuture;
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _EventsHeader(
                              searchController: _searchController,
                              onSearchChanged: () => setState(() {}),
                              date: _date,
                              onDateChanged: _setDate,
                              filterCount: _filters.activeCount,
                              onOpenFilters: () => _openFilters(neighborhoods),
                              categories: _categories,
                              selectedType: _eventType,
                              onSelectCategory: _selectCategory,
                            ),
                          ),
                          if (loading)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(color: WtvaColors.accentPurple),
                              ),
                            )
                          else if (events.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    _hasAnyFilter
                                        ? 'No upcoming events match these filters.'
                                        : 'No upcoming events right now.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: WtvaColors.neutral300, height: 1.4),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 16, color: WtvaColors.accentPurple),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'Upcoming Events',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: WtvaColors.accentPurple,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${events.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: WtvaColors.neutral300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                              sliver: SliverList.separated(
                                itemCount: events.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) => _EventBrowseCard(event: events[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.date,
    required this.onDateChanged,
    required this.filterCount,
    required this.onOpenFilters,
    required this.categories,
    required this.selectedType,
    required this.onSelectCategory,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String? date;
  final ValueChanged<String?> onDateChanged;
  final int filterCount;
  final VoidCallback onOpenFilters;
  final List<({String label, String? eventType, IconData icon})> categories;
  final String? selectedType;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: WtvaColors.dark400,
                  shape: BoxShape.circle,
                  border: Border.all(color: WtvaColors.night200),
                  boxShadow: WtvaColors.cardShadow,
                ),
                child: const Icon(Icons.calendar_month_rounded, color: WtvaColors.accentPurple),
              ),
            ],
          ),
          const SizedBox(height: 18),
          WtvaPillSearchBar(
            controller: searchController,
            hintText: 'Search events, venues…',
            filterCount: filterCount,
            onFilters: onOpenFilters,
            onChanged: (_) => onSearchChanged(),
            onSubmitted: (_) => onSearchChanged(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                final selected = selectedType == c.eventType;
                return _CategoryChip(
                  label: c.label,
                  icon: c.icon,
                  selected: selected,
                  onTap: () => onSelectCategory(c.eventType),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: InlineEventDatePicker(date: date, onChanged: onDateChanged),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected ? WtvaColors.buttonGradient : null,
            color: selected ? null : WtvaColors.dark400,
            border: Border.all(
              color: selected ? Colors.transparent : WtvaColors.night200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? WtvaColors.onPrimary : WtvaColors.neutral50,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? WtvaColors.onPrimary : WtvaColors.neutral50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventBrowseCard extends StatelessWidget {
  const _EventBrowseCard({required this.event});

  final WtvaEventRecord event;

  bool get _isTonight {
    final now = DateTime.now();
    final local = event.startsAt.toLocal();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final local = event.startsAt.toLocal();
    final dateLabel = _isTonight
        ? 'TONIGHT'
        : MaterialLocalizations.of(context)
            .formatShortMonthDay(local)
            .toUpperCase();
    final timeLabel = TimeOfDay.fromDateTime(local).format(context);
    final place = [
      if (event.venueName != null && event.venueName!.isNotEmpty) event.venueName!,
      if (event.neighborhood != null && event.neighborhood!.isNotEmpty) event.neighborhood!,
    ].join(' · ');

    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WtvaColors.night200),
            boxShadow: WtvaColors.cardShadow,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 108,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      event.imageUrl != null && event.imageUrl!.isNotEmpty
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
                            )
                          : Container(
                              color: WtvaColors.dark300,
                              child: const Icon(Icons.event, color: WtvaColors.accentPurple),
                            ),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: _isTonight
                                ? WtvaColors.buttonGradient
                                : const LinearGradient(
                                    colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
                                  ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.eventType,
                      style: const TextStyle(
                        color: WtvaColors.accentPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: WtvaColors.neutral300),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WtvaColors.neutral300,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: WtvaColors.neutral300),
                        const SizedBox(width: 4),
                        Text(
                          '${MaterialLocalizations.of(context).formatMediumDate(local)} · $timeLabel',
                          style: const TextStyle(
                            color: WtvaColors.neutral300,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.chevron_right, color: WtvaColors.neutral300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
