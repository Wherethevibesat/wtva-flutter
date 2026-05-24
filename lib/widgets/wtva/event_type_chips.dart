import 'package:flutter/material.dart';
import '../../data/event_types.dart';
import '../../theme/figma_theme.dart';
import 'wtva_select_chip.dart';

class EventTypeChips extends StatelessWidget {
  const EventTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.label = 'Event type',
  });

  final String? selected;
  final ValueChanged<String?> onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: WtvaColors.neutral300,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: WtvaEventTypes.all.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _chip(context, label: 'All', active: selected == null, onTap: () => onSelected(null));
              }
              final type = WtvaEventTypes.all[i - 1];
              return _chip(
                context,
                label: type,
                active: selected == type,
                onTap: () => onSelected(type),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return WtvaSelectChip(
      label: label,
      selected: active,
      onTap: onTap,
    );
  }
}
