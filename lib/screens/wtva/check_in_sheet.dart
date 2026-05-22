import 'dart:ui';

import 'package:flutter/material.dart';
import '../../data/mock_check_in_data.dart';
import '../../data/mock_venue_store.dart';
import '../../theme/figma_theme.dart';
import 'check_in_options_sheet.dart';

/// Figma #06_01 — choose a place to check in (bottom sheet).
class CheckInSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark500),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: const Color(0x8004001A)),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: WtvaColors.dark400,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 63,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(100),
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
                          icon: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: WtvaColors.night500.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: WtvaColors.neutral200, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _SectionHeader(label: 'Nearby'),
                        const SizedBox(height: 12),
                        ...MockCheckInData.nearby.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child:                             _VenueCheckInRow(
                              venue: v,
                              onCheckIn: () {
                                final detail = MockVenueStore.fromCheckIn(v);
                                Navigator.pop(context);
                                CheckInOptionsSheet.show(
                                  context,
                                  venueId: detail.venue.id,
                                  venueName: detail.venue.name,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
        Container(height: 1, color: WtvaColors.night300.withValues(alpha: 0.8)),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: WtvaColors.neutral50,
                  ),
                ),
                Text(
                  '${venue.distanceMiles} mi',
                  style: const TextStyle(
                    fontSize: 14,
                    color: WtvaColors.neutral200,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onCheckIn,
            icon: const Icon(Icons.arrow_forward, size: 20, color: WtvaColors.neutral200),
            label: const Text(
              'Check In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: WtvaColors.neutral200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
