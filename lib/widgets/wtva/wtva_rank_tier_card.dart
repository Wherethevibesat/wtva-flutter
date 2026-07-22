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
    final ink = useGradientCard ? WtvaColors.onPrimary : WtvaColors.neutral50;
    final muted = useGradientCard
        ? WtvaColors.onPrimary.withValues(alpha: 0.85)
        : WtvaColors.neutral100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: tier.cardGradient,
        color: useGradientCard ? null : WtvaColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: useGradientCard
            ? null
            : Border.all(color: WtvaColors.night200.withValues(alpha: 0.8)),
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
                      ? (useGradientCard
                          ? Colors.white.withValues(alpha: 0.22)
                          : WtvaColors.accentPurple.withValues(alpha: 0.12))
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tier.icon,
                  color: useGradientCard || tier.iconGradient != null
                      ? WtvaColors.onPrimary
                      : WtvaColors.accentPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrent)
                      Text(
                        'MY RANK',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    Text(
                      tier.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ink,
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  Text(
                    'POINTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: ink,
              ),
              children: [
                TextSpan(
                  text: tier.description,
                  style: TextStyle(
                    fontWeight: tier.payRate != null ? FontWeight.w400 : FontWeight.w600,
                    color: muted,
                  ),
                ),
                if (tier.payRate != null)
                  TextSpan(
                    text: tier.payRate,
                    style: TextStyle(fontWeight: FontWeight.w700, color: ink),
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
