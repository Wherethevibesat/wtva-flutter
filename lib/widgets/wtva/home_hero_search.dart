import 'package:flutter/material.dart';
import '../../screens/wtva/events_filters_sheet.dart';
import '../../screens/wtva/search_screen.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';
import 'wtva_pill_search_bar.dart';

/// Web-parity home hero search: query + filters + popular chips.
class HomeHeroSearch extends StatefulWidget {
  const HomeHeroSearch({super.key, this.onDark = true});

  /// When true, popular-search label uses light-on-dark hero styling.
  final bool onDark;

  static const popular = [
    'Rooftop',
    'Happy Hour',
    'Afrobeats',
    'R&B',
    'Brunch',
    'After Hours',
  ];

  @override
  State<HomeHeroSearch> createState() => _HomeHeroSearchState();
}

class _HomeHeroSearchState extends State<HomeHeroSearch> {
  final _controller = TextEditingController();
  EventsFilters _filters = const EventsFilters();
  List<NeighborhoodRecord> _neighborhoods = const [];
  bool _loadingNeighborhoods = true;

  @override
  void initState() {
    super.initState();
    _loadNeighborhoods();
  }

  Future<void> _loadNeighborhoods() async {
    final list = await NeighborhoodsRepository.instance.list();
    if (!mounted) return;
    setState(() {
      _neighborhoods = list;
      _loadingNeighborhoods = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSearch({String? query, EventsFilters? filters}) {
    final q = (query ?? _controller.text).trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialQuery: q.isEmpty ? null : q,
          initialFilters: filters ?? (_filters.hasSelection ? _filters : null),
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    if (_loadingNeighborhoods) return;
    final result = await EventsFiltersSheet.show(
      context,
      initial: _filters,
      neighborhoods: _neighborhoods,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    // Match web: applying filters navigates to search results.
    _openSearch(filters: result);
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _filters.activeCount;
    final labelColor = widget.onDark
        ? Colors.white.withValues(alpha: 0.78)
        : WtvaColors.neutral300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WtvaPillSearchBar(
          controller: _controller,
          hintText: 'Search events, DJs, venues…',
          filterCount: filterCount,
          onFilters: _openFilters,
          onSubmitted: (_) => _openSearch(),
        ),
        const SizedBox(height: 12),
        Text(
          'POPULAR SEARCHES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: HomeHeroSearch.popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final term = HomeHeroSearch.popular[i];
              return ActionChip(
                label: Text(
                  term,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: WtvaColors.neutral50,
                  ),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => _openSearch(query: term),
              );
            },
          ),
        ),
      ],
    );
  }
}
