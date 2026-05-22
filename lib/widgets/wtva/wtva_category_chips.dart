import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class WtvaCategoryChips extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const WtvaCategoryChips({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? WtvaColors.buttonGradient : null,
                color: selected ? null : WtvaColors.dark400,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.2)
                      : WtvaColors.night200.withValues(alpha: 0.85),
                ),
                boxShadow: selected ? WtvaColors.buttonShadow : null,
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: selected ? WtvaColors.onPrimary : WtvaColors.neutral200,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
