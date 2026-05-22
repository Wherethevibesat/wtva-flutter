import 'package:flutter/material.dart';
import '../../models/venue.dart';
import '../../theme/figma_theme.dart';

class WtvaPromotedCard extends StatelessWidget {
  final PromotedOffer offer;
  final VoidCallback? onTap;

  const WtvaPromotedCard({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            offer.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: WtvaColors.dark300),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  WtvaColors.dark500.withValues(alpha: 0.95),
                  WtvaColors.dark500.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WtvaColors.neutral50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PROMOTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: WtvaColors.onPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WtvaColors.neutral50,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.venueName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WtvaColors.neutral200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
