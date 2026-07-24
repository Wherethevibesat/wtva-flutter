import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

/// Home-parity pill search: white field + filter tune + gradient Search.
class WtvaPillSearchBar extends StatelessWidget {
  const WtvaPillSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onFilters,
    this.onChanged,
    this.onSubmitted,
    this.filterCount = 0,
    this.showSearchButton = true,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onFilters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int filterCount;
  final bool showSearchButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WtvaColors.night200),
        boxShadow: WtvaColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: WtvaColors.neutral50,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: WtvaColors.neutral300,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: WtvaColors.neutral300,
                  size: 20,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _FilterButton(count: filterCount, onPressed: onFilters),
          if (showSearchButton) ...[
            const SizedBox(width: 6),
            _SearchButton(
              onPressed: () {
                final q = controller.text;
                if (onSubmitted != null) {
                  onSubmitted!(q);
                } else {
                  onChanged?.call(q);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral50,
            side: const BorderSide(color: WtvaColors.night200),
            backgroundColor: WtvaColors.dark400,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: const Icon(Icons.tune_rounded, size: 18),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: WtvaColors.accentPurple,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: WtvaColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: WtvaColors.buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: WtvaColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 18, color: WtvaColors.onPrimary),
                SizedBox(width: 4),
                Text(
                  'Search',
                  style: TextStyle(
                    color: WtvaColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
