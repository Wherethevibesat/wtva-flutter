import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../services/neighborhoods_repository.dart';
import '../../services/venue_repository.dart';
import '../../theme/figma_theme.dart';
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
  final _searchController = TextEditingController();
  VenuesFilters _filters = const VenuesFilters();
  List<NeighborhoodRecord> _neighborhoods = const [];
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
    await VenueRepository.instance.hydrate();
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
    return MockVenueStore.all.where((d) {
      if (selected.isNotEmpty) {
        final hood = (d.neighborhood ?? '').toLowerCase();
        if (!selected.contains(hood)) return false;
      }
      if (q.isEmpty) return true;
      final hay = [
        d.venue.name,
        d.category,
        d.neighborhood ?? '',
        d.address,
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
    final venues = _filtered;
    final featured = venues.where((v) => v.featured).toList();
    final rest = venues.where((v) => !v.featured).toList();

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text('Venues', style: TextStyle(fontWeight: FontWeight.w700)),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: WtvaColors.accentPurple,
              onRefresh: () async {
                await VenueRepository.instance.hydrate(force: true);
                final hoods = await NeighborhoodsRepository.instance.list(forceRefresh: true);
                if (!mounted) return;
                setState(() => _neighborhoods = hoods);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Clubs, lounges, and nightlife spots. Filter by neighborhood or search by name.',
                            style: TextStyle(
                              color: WtvaColors.neutral200,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(color: WtvaColors.neutral50),
                                  decoration: InputDecoration(
                                    hintText: 'Search venues...',
                                    hintStyle: const TextStyle(color: WtvaColors.neutral300),
                                    prefixIcon: const Icon(Icons.search, color: WtvaColors.neutral300),
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.close, size: 18),
                                          ),
                                    filled: true,
                                    fillColor: WtvaColors.dark400,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: WtvaColors.night200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: WtvaColors.night200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: WtvaColors.accentPurple,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: _openFilters,
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: Text(
                                  _filters.hasSelection
                                      ? 'Filters (${_filters.activeCount})'
                                      : 'Filters',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _filters.hasSelection
                                      ? WtvaColors.accentPurple
                                      : WtvaColors.neutral50,
                                  side: BorderSide(
                                    color: _filters.hasSelection
                                        ? WtvaColors.accentPurple
                                        : WtvaColors.night200,
                                  ),
                                  backgroundColor: WtvaColors.dark400,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_filters.hasSelection) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final n in _filters.neighborhoods)
                                  InputChip(
                                    label: Text(n),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () => setState(() {
                                      _filters = VenuesFilters(
                                        neighborhoods: _filters.neighborhoods
                                            .where((x) => x != n)
                                            .toList(),
                                      );
                                    }),
                                    backgroundColor: WtvaColors.dark300,
                                    side: const BorderSide(color: WtvaColors.night200),
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () => setState(() => _filters = const VenuesFilters()),
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${venues.length} venue${venues.length == 1 ? '' : 's'} match',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: WtvaColors.neutral300,
                              ),
                            ),
                          ],
                        ],
                      ),
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
                            style: TextStyle(color: WtvaColors.neutral300),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (featured.isNotEmpty) ...[
                      const _SpacedHeader('Featured'),
                      _VenueGrid(venues: featured),
                    ],
                    if (rest.isNotEmpty || featured.isEmpty) ...[
                      if (featured.isNotEmpty) const _SpacedHeader('All venues'),
                      _VenueGrid(venues: featured.isEmpty ? venues : rest),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SpacedHeader extends StatelessWidget {
  const _SpacedHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: WtvaColors.neutral300,
          ),
        ),
      ),
    );
  }
}

class _VenueGrid extends StatelessWidget {
  const _VenueGrid({required this.venues});
  final List<VenueDetail> venues;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final d = venues[i];
            return _VenueBrowseCard(
              detail: d,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VenueDetailScreen(venueId: d.venue.id),
                ),
              ),
            );
          },
          childCount: venues.length,
        ),
      ),
    );
  }
}

class _VenueBrowseCard extends StatelessWidget {
  const _VenueBrowseCard({required this.detail, required this.onTap});

  final VenueDetail detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = detail.venue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: WtvaColors.night200),
          boxShadow: WtvaColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    v.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
                  ),
                  if (detail.featured)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: WtvaColors.buttonGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                              fontSize: 14,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '★ ${v.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      [
                        detail.category,
                        if (detail.neighborhood != null) detail.neighborhood!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: WtvaColors.neutral300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
