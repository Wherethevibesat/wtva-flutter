import 'package:flutter/material.dart';
import '../../data/ranking_rules.dart';
import '../../theme/figma_theme.dart';

class PointsInfoSheet extends StatelessWidget {
  const PointsInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PointsInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = RankingRules.infoSheetItems();

    return Container(
      decoration: const BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 63,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How to get points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rank up to unlock paid venue invites and higher hourly rates.',
                style: TextStyle(fontSize: 13, color: WtvaColors.neutral300),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: WtvaColors.accentGreen, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.$1, style: const TextStyle(fontSize: 14)),
                      ),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: WtvaColors.lavender300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
