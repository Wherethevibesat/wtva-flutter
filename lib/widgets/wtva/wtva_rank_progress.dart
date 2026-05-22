import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class WtvaRankProgress extends StatelessWidget {
  final int currentPoints;
  final List<int> milestones;

  const WtvaRankProgress({
    super.key,
    required this.currentPoints,
    required this.milestones,
  });

  @override
  Widget build(BuildContext context) {
    final min = milestones.first.toDouble();
    final max = milestones.last.toDouble();
    final progress = ((currentPoints - min) / (max - min)).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0x80161826),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: WtvaColors.rankPinkGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(milestones.length, (i) {
                  final reached = currentPoints >= milestones[i];
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? WtvaColors.neutral50 : WtvaColors.neutral200.withValues(alpha: 0.4),
                      border: Border.all(
                        color: reached ? WtvaColors.neutral50 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: milestones.map((m) {
            final reached = currentPoints >= m;
            return Text(
              _format(m),
              style: TextStyle(
                fontSize: 12,
                fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
                color: reached ? WtvaColors.neutral50 : WtvaColors.neutral200,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000) {
      final s = n.toString();
      if (s.length > 3) {
        return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
      }
    }
    return '$n';
  }
}
