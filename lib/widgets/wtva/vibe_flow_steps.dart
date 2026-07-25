import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

/// Pill rail matching web `VibeFlowSteps` — Preview → Build → Pay.
class VibeFlowSteps extends StatelessWidget {
  const VibeFlowSteps({super.key, required this.step});

  /// 0 Preview, 1 Build, 2 Pay
  final int step;

  static const _labels = ['Preview', 'Build', 'Pay'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _labels.length; i++)
            _Pill(
              label: _labels[i],
              index: i,
              active: i == step,
              done: i < step,
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.index,
    required this.active,
    required this.done,
  });

  final String label;
  final int index;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (active) {
      bg = WtvaColors.accentPurple;
      fg = Colors.white;
    } else if (done) {
      bg = WtvaColors.accentPurple.withValues(alpha: 0.15);
      fg = WtvaColors.accentPurple;
    } else {
      bg = WtvaColors.dark400;
      fg = WtvaColors.neutral300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: active ? WtvaColors.buttonGradient : null,
        color: active ? null : bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check_rounded, size: 12, color: fg),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${index + 1}.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
