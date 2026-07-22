import 'package:flutter/material.dart';
import '../../screens/wtva/events_filters_sheet.dart';
import '../../screens/wtva/search_screen.dart';
import '../../services/neighborhoods_repository.dart';
import '../../theme/figma_theme.dart';

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
        Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: WtvaColors.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _openSearch(),
                  style: const TextStyle(
                    color: WtvaColors.neutral50,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search events, DJs, venues…',
                    hintStyle: TextStyle(
                      color: WtvaColors.neutral300,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: WtvaColors.neutral300,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _FilterButton(
                count: filterCount,
                onPressed: _openFilters,
              ),
              const SizedBox(width: 6),
              _SearchButton(onPressed: () => _openSearch()),
            ],
          ),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral50,
            side: const BorderSide(color: WtvaColors.night200),
            backgroundColor: WtvaColors.dark400,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: const Icon(Icons.tune_rounded, size: 18),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
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
                '$count',
                style: const TextStyle(
                  color: WtvaColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: WtvaColors.buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: WtvaColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 18, color: WtvaColors.onPrimary),
                SizedBox(width: 4),
                Text(
                  'Search',
                  style: TextStyle(
                    color: WtvaColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
