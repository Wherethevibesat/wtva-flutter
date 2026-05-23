import 'package:flutter/material.dart';
import '../../data/mock_venue_store.dart';
import '../../models/venue_detail.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import 'venue_detail_screen.dart';

/// Venues filtered by admin-defined neighborhood name.
class NeighborhoodVenuesScreen extends StatelessWidget {
  final String neighborhoodName;

  const NeighborhoodVenuesScreen({
    super.key,
    required this.neighborhoodName,
  });

  List<VenueDetail> get _venues {
    final target = neighborhoodName.toLowerCase();
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
        title: Text(neighborhoodName, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: venues.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No venues in $neighborhoodName yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WtvaColors.neutral300),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final detail = venues[i];
                return WtvaVenueCard(
                  venue: detail.venue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailScreen(venueId: detail.venue.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
