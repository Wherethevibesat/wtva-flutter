import 'package:flutter/material.dart';
import '../../screens/wtva/events_filters_sheet.dart';
import '../../screens/wtva/search_screen.dart';
import '../../services/neighborhoods_repository.dart';
import 'wtva_pill_search_bar.dart';

/// Web-parity home hero search: query + filters.
class HomeHeroSearch extends StatefulWidget {
  const HomeHeroSearch({super.key, this.onDark = true});

  /// Kept for call-site compatibility; hero search bar is the same either way.
  final bool onDark;

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
    return WtvaPillSearchBar(
      controller: _controller,
      hintText: 'Search events, DJs, venues…',
      filterCount: _filters.activeCount,
      onFilters: _openFilters,
      onSubmitted: (_) => _openSearch(),
    );
  }
}
