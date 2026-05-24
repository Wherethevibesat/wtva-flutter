import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

/// Selectable pill chip — selected state matches [WtvaCategoryChips] (white fill, dark text).
class WtvaSelectChip extends StatelessWidget {
  const WtvaSelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? WtvaColors.buttonGradient : null,
          color: selected ? null : WtvaColors.dark300,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.2)
                : WtvaColors.night200.withValues(alpha: 0.85),
          ),
          boxShadow: selected ? WtvaColors.buttonShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? WtvaColors.onPrimary : WtvaColors.neutral100,
          ),
        ),
      ),
    );
  }
}
