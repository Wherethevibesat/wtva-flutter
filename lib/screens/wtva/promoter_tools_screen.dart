import 'package:flutter/material.dart';
import '../../data/mock_discover_data.dart';
import '../../data/mock_venue_store.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';
import 'promotion_editor_screen.dart';
import 'settings/extended_settings_screens.dart';
import 'venue_detail_screen.dart';

class PromoterToolsScreen extends StatelessWidget {
  const PromoterToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Promoter tools', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: WtvaColors.rankPurpleGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Club promoter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage promoted spots, invites, and venue analytics',
                  style: TextStyle(fontSize: 13, color: WtvaColors.neutral100),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _StatRow(label: 'Active promotions', value: '2'),
          const _StatRow(label: 'Check-ins this week', value: '148'),
          const _StatRow(label: 'Invites sent', value: '36'),
          const SizedBox(height: 24),
          const Text(
            'Your venues',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...MockDiscoverData.venues.take(3).map(
            (v) {
              final detail = MockVenueStore.byId(v.id);
              return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VenuePromoTile(
                name: v.name,
                subtitle: detail?.category ?? 'Venue',
                imageUrl: v.imageUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailScreen(venueId: v.id),
                    ),
                  );
                },
              ),
            );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PromoterAddLocationScreen()),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add venue location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WtvaColors.neutral100,
              side: const BorderSide(color: WtvaColors.night200),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          WtvaGradientButton(
            label: 'Create promotion',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PromotionEditorScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: WtvaColors.neutral200)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}

class _VenuePromoTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _VenuePromoTile({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
