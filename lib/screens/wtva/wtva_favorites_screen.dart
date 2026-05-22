import 'package:flutter/material.dart';
import '../../data/mock_favorites_data.dart';
import '../../services/favorites_service.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_empty_state.dart';
import '../../widgets/wtva/wtva_venue_card.dart';
import 'venue_detail_screen.dart';

class WtvaFavoritesScreen extends StatefulWidget {
  const WtvaFavoritesScreen({super.key});

  @override
  State<WtvaFavoritesScreen> createState() => _WtvaFavoritesScreenState();
}

class _WtvaFavoritesScreenState extends State<WtvaFavoritesScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    FavoritesService.instance.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: WtvaColors.dark500,
        body: Center(child: CircularProgressIndicator(color: WtvaColors.accentPurple)),
      );
    }
    final venues = MockFavoritesData.venues;

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: venues.isEmpty
          ? WtvaEmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Save venues you love from Discover or venue pages.',
              actionLabel: 'Explore venues',
              onAction: () => Navigator.pop(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final v = venues[i];
                return WtvaVenueCard(
                  venue: v,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VenueDetailScreen(venueId: v.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
