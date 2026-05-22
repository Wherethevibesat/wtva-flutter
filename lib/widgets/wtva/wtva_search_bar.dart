import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../theme/wtva_icons.dart';

class WtvaSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;

  const WtvaSearchBar({
    super.key,
    this.hint = 'Search venues, events, people...',
    this.onTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: WtvaColors.dark400,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.03),
              blurRadius: 0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: WtvaColors.neutral300, size: WtvaIcons.md),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WtvaColors.neutral300,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: WtvaColors.dark300,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.8)),
                ),
                child: Icon(Icons.tune_outlined, color: WtvaColors.neutral200, size: WtvaIcons.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
