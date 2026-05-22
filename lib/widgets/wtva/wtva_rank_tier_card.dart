import 'package:flutter/material.dart';
import '../../models/rank_tier.dart';
import '../../theme/figma_theme.dart';

class WtvaRankTierCard extends StatelessWidget {
  final RankTier tier;
  final bool isCurrent;

  const WtvaRankTierCard({super.key, required this.tier, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    final useGradientCard = tier.cardGradient != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: tier.cardGradient,
        color: useGradientCard ? null : WtvaColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: tier.iconGradient,
                  color: tier.iconGradient == null
                      ? Colors.white.withValues(alpha: 0.24)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tier.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrent)
                      const Text(
                        'MY RANK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WtvaColors.neutral100,
                        ),
                      ),
                    Text(
                      tier.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPoints(tier.pointsRequired),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: WtvaColors.neutral50,
                    ),
                  ),
                  const Text(
                    'POINTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WtvaColors.neutral100,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: WtvaColors.neutral50,
              ),
              children: [
                TextSpan(
                  text: tier.description,
                  style: TextStyle(
                    fontWeight: tier.payRate != null ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
                if (tier.payRate != null)
                  TextSpan(
                    text: tier.payRate,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(int n) {
    if (n >= 1000) {
      return n.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return '$n';
  }
}
