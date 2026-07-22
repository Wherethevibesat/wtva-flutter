import 'package:flutter/material.dart';
import '../../models/venue.dart';
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
  List<Venue> _venues = const [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final venues = await FavoritesService.instance.venuesReady();
    if (!mounted) return;
    setState(() {
      _venues = venues;
      _ready = true;
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

    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _venues.isEmpty
          ? WtvaEmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle: 'Save venues you love from Venues or venue pages.',
              actionLabel: 'Back',
              onAction: () => Navigator.pop(context),
            )
          : RefreshIndicator(
              color: WtvaColors.accentPurple,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _venues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final v = _venues[i];
                  return WtvaVenueCard(
                    venue: v,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VenueDetailScreen(venueId: v.id),
                        ),
                      ).then((_) => _load());
                    },
                  );
                },
              ),
            ),
    );
  }
}
