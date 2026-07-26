import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../services/favorites_service.dart';
import '../../services/neighborhoods_repository.dart';
import '../../services/venue_repository.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_pill_search_bar.dart';
import 'map_search_screen.dart';
import 'venue_detail_screen.dart';
import 'venues_filters_sheet.dart';

/// List-first venues browse aligned with the customer web `/venues` page.
class VenuesBrowseScreen extends StatefulWidget {
  const VenuesBrowseScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VenuesBrowseScreen> createState() => _VenuesBrowseScreenState();
}

class _VenuesBrowseScreenState extends State<VenuesBrowseScreen> {
  static const _categories = <({String label, String? match, IconData icon})>[
    (label: 'All Venues', match: null, icon: Icons.storefront_outlined),
    (label: 'Clubs', match: 'club', icon: Icons.nightlife),
    (label: 'Lounges', match: 'lounge', icon: Icons.weekend_outlined),
    (label: 'Hookah', match: 'hookah', icon: Icons.smoking_rooms_outlined),
    (label: 'Rooftop', match: 'rooftop', icon: Icons.apartment_outlined),
  ];

  final _searchController = TextEditingController();
  VenuesFilters _filters = const VenuesFilters();
  List<NeighborhoodRecord> _neighborhoods = const [];
  String? _categoryMatch;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      VenueRepository.instance.hydrate(),
      FavoritesService.instance.load(),
    ]);
    final hoods = await NeighborhoodsRepository.instance.list();
    if (!mounted) return;
    setState(() {
      _neighborhoods = hoods;
      _loading = false;
    });
  }

  List<VenueDetail> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    final selected = _filters.neighborhoods.map((n) => n.toLowerCase()).toSet();
    final cat = _categoryMatch;
    return MockVenueStore.all.where((d) {
      if (selected.isNotEmpty) {
        final hood = (d.neighborhood ?? '').toLowerCase();
        if (!selected.contains(hood)) return false;
      }
      if (cat != null) {
        final hay = '${d.category} ${d.venue.name}'.toLowerCase();
        if (!hay.contains(cat)) return false;
      }
      if (q.isEmpty) return true;
      final hay = [
        d.venue.name,
        d.category,
        d.neighborhood ?? '',
        d.address,
        ...d.services,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.featured != b.featured) return a.featured ? -1 : 1;
        return a.venue.distanceMiles.compareTo(b.venue.distanceMiles);
      });
  }

  Future<void> _openFilters() async {
    final next = await VenuesFiltersSheet.show(
      context,
      initial: _filters,
      neighborhoods: _neighborhoods,
    );
    if (next == null || !mounted) return;
    setState(() => _filters = next);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = widget.embedded ? MediaQuery.paddingOf(context).top : 0.0;
    final venues = _filtered;
    final popular = venues.where((v) => v.featured).toList();
    final gridVenues = popular.isNotEmpty ? popular : venues;
    final sectionTitle = popular.isNotEmpty ? 'Popular in Houston' : 'All Venues';

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
              title: const Text('Venues', style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                IconButton(
                  tooltip: 'Map',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapSearchScreen()),
                  ),
                  icon: const Icon(Icons.map_outlined),
                ),
              ],
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: WtvaColors.accentPurple),
                  )
                : RefreshIndicator(
                    color: WtvaColors.accentPurple,
                    onRefresh: () async {
                      await VenueRepository.instance.hydrate(force: true);
                      final hoods =
                          await NeighborhoodsRepository.instance.list(forceRefresh: true);
                      if (!mounted) return;
                      setState(() => _neighborhoods = hoods);
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _VenuesHeader(
                            searchController: _searchController,
                            onSearchChanged: () => setState(() {}),
                            filterCount: _filters.activeCount,
                            onOpenFilters: _openFilters,
                            onOpenMap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MapSearchScreen()),
                            ),
                            showMapButton: widget.embedded,
                            categories: _categories,
                            selectedMatch: _categoryMatch,
                            onSelectCategory: (match) => setState(() => _categoryMatch = match),
                            activeNeighborhoods: _filters.neighborhoods,
                            onRemoveNeighborhood: (n) => setState(() {
                              _filters = VenuesFilters(
                                neighborhoods:
                                    _filters.neighborhoods.where((x) => x != n).toList(),
                              );
                            }),
                            onClearFilters: () => setState(() => _filters = const VenuesFilters()),
                            matchCount: venues.length,
                          ),
                        ),
                        if (venues.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No venues found. Clear filters and try again.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: WtvaColors.neutral300, height: 1.4),
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
                                  const Icon(Icons.auto_awesome,
                                      size: 16, color: WtvaColors.accentPurple),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      sectionTitle,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: WtvaColors.accentPurple,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${venues.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: WtvaColors.neutral300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _VenueList(
                            venues: gridVenues,
                            onFavoriteChanged: () => setState(() {}),
                          ),
                          if (popular.isNotEmpty && venues.length > popular.length) ...[
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
                                child: Text(
                                  'All Venues',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: WtvaColors.accentPurple,
                                  ),
                                ),
                              ),
                            ),
                            _VenueList(
                              venues: venues.where((v) => !v.featured).toList(),
                              onFavoriteChanged: () => setState(() {}),
                            ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VenuesHeader extends StatelessWidget {
  const _VenuesHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.filterCount,
    required this.onOpenFilters,
    required this.onOpenMap,
    required this.showMapButton,
    required this.categories,
    required this.selectedMatch,
    required this.onSelectCategory,
    required this.activeNeighborhoods,
    required this.onRemoveNeighborhood,
    required this.onClearFilters,
    required this.matchCount,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final int filterCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenMap;
  final bool showMapButton;
  final List<({String label, String? match, IconData icon})> categories;
  final String? selectedMatch;
  final ValueChanged<String?> onSelectCategory;
  final List<String> activeNeighborhoods;
  final ValueChanged<String> onRemoveNeighborhood;
  final VoidCallback onClearFilters;
  final int matchCount;

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
                  'Venues',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
              if (showMapButton) ...[
                const SizedBox(width: 12),
                Material(
                  color: WtvaColors.dark400,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    onTap: onOpenMap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: WtvaColors.night200),
                        boxShadow: WtvaColors.cardShadow,
                      ),
                      child: const Icon(Icons.map_outlined, color: WtvaColors.accentPurple),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          WtvaPillSearchBar(
            controller: searchController,
            hintText: 'Search venues…',
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
                final selected = selectedMatch == c.match;
                return _VenueCategoryChip(
                  label: c.label,
                  icon: c.icon,
                  selected: selected,
                  onTap: () => onSelectCategory(c.match),
                );
              },
            ),
          ),
          if (activeNeighborhoods.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final n in activeNeighborhoods)
                  InputChip(
                    label: Text(n),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onRemoveNeighborhood(n),
                    backgroundColor: WtvaColors.dark300,
                    side: const BorderSide(color: WtvaColors.night200),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$matchCount venue${matchCount == 1 ? '' : 's'} match',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: WtvaColors.neutral300,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _VenueCategoryChip extends StatelessWidget {
  const _VenueCategoryChip({
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

class _VenueList extends StatelessWidget {
  const _VenueList({
    required this.venues,
    required this.onFavoriteChanged,
  });

  final List<VenueDetail> venues;
  final VoidCallback onFavoriteChanged;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: venues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final d = venues[i];
          return _VenueBrowseCard(
            detail: d,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VenueDetailScreen(venueId: d.venue.id),
              ),
            ),
            onFavoriteChanged: onFavoriteChanged,
          );
        },
      ),
    );
  }
}

class _VenueBrowseCard extends StatelessWidget {
  const _VenueBrowseCard({
    required this.detail,
    required this.onTap,
    required this.onFavoriteChanged,
  });

  final VenueDetail detail;
  final VoidCallback onTap;
  final VoidCallback onFavoriteChanged;

  String get _badgeLabel {
    if (detail.featured) return 'FEATURED';
    final cat = detail.category.trim();
    if (cat.isEmpty) return 'VENUE';
    final lower = cat.toLowerCase();
    if (lower.contains('rooftop')) return 'ROOFTOP';
    if (lower.contains('hookah')) return 'HOOKAH';
    if (lower.contains('lounge')) return 'LOUNGE';
    if (lower.contains('club')) return 'CLUB';
    return cat.split(RegExp(r'[\s/·|-]+')).first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final v = detail.venue;
    final favorited = FavoritesService.instance.isFavorite(v.id);
    final hours = detail.hoursLabel.trim();
    final openLabel = hours.isNotEmpty
        ? (detail.isOpen
            ? (hours.toLowerCase().startsWith('open') ? hours : 'Open · $hours')
            : hours)
        : (detail.isOpen ? 'Open now' : 'Closed');
    final place = [
      if (detail.category.trim().isNotEmpty) detail.category.trim(),
      if (detail.neighborhood != null && detail.neighborhood!.isNotEmpty)
        detail.neighborhood!,
    ].join(' · ');

    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      v.imageUrl.isNotEmpty
                          ? Image.network(
                              v.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: WtvaColors.dark300),
                            )
                          : Container(
                              color: WtvaColors.dark300,
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: WtvaColors.accentPurple,
                              ),
                            ),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: detail.featured
                                ? WtvaColors.buttonGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFDB2777),
                                      Color(0xFFF472B6),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _badgeLabel,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            v.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () async {
                              await FavoritesService.instance.toggle(v.id);
                              onFavoriteChanged();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                favorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: favorited
                                    ? const Color(0xFFF472B6)
                                    : WtvaColors.neutral300,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WtvaColors.accentPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: WtvaColors.neutral300,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${v.distanceMiles.toStringAsFixed(1)} mi away',
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: detail.isOpen
                              ? WtvaColors.accentGreen
                              : WtvaColors.neutral300,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            openLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: detail.isOpen
                                  ? WtvaColors.accentGreen
                                  : WtvaColors.neutral300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (v.rating > 0) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            v.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
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
