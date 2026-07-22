import 'package:flutter/material.dart';
import '../../data/mock_check_in_data.dart';
import '../../data/mock_venue_store.dart';
import '../../services/venue_repository.dart';
import '../../theme/figma_theme.dart';
import 'check_in_options_sheet.dart';

/// Choose a place to check in (bottom sheet) — venues from hydrated catalog.
class CheckInSheet extends StatefulWidget {
  const CheckInSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckInSheet(),
    );
  }

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  List<NearbyVenueCheckIn> _nearby = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await VenueRepository.instance.hydrate();
    final venues = MockVenueStore.all.map((d) => d.venue).toList()
      ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
    if (!mounted) return;
    setState(() {
      _nearby = [
        for (final v in venues.take(20))
          NearbyVenueCheckIn(
            id: v.id,
            name: v.name,
            distanceMiles: v.distanceMiles,
          ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: WtvaColors.dark400,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WtvaColors.night200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Check In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: WtvaColors.neutral200),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _nearby.isEmpty
                        ? ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(32),
                            children: const [
                              SizedBox(height: 24),
                              Icon(Icons.place_outlined, size: 40, color: WtvaColors.neutral300),
                              SizedBox(height: 12),
                              Text(
                                'No venues nearby yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'When venues are published, you’ll be able to check in from here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: WtvaColors.neutral300, height: 1.35),
                              ),
                            ],
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            children: [
                              const _SectionHeader(label: 'Venues'),
                              const SizedBox(height: 12),
                              for (final v in _nearby)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _VenueCheckInRow(
                                    venue: v,
                                    onCheckIn: () {
                                      Navigator.pop(context);
                                      CheckInOptionsSheet.show(
                                        context,
                                        venueId: v.id,
                                        venueName: v.name,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: WtvaColors.neutral200,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: WtvaColors.night200),
      ],
    );
  }
}

class _VenueCheckInRow extends StatelessWidget {
  final NearbyVenueCheckIn venue;
  final VoidCallback onCheckIn;

  const _VenueCheckInRow({required this.venue, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WtvaColors.dark300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WtvaColors.night200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: WtvaColors.neutral50,
                  ),
                ),
                if (venue.distanceMiles > 0)
                  Text(
                    '${venue.distanceMiles.toStringAsFixed(1)} mi',
                    style: const TextStyle(
                      fontSize: 13,
                      color: WtvaColors.neutral200,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onCheckIn,
            icon: const Icon(Icons.arrow_forward, size: 18, color: WtvaColors.accentPurple),
            label: const Text(
              'Check In',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: WtvaColors.accentPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
