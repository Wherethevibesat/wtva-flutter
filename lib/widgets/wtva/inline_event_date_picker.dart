import 'package:flutter/material.dart';
import '../../data/event_dates.dart';
import '../../theme/figma_theme.dart';

/// Compact date control for event browse — applies immediately (not via filters modal).
class InlineEventDatePicker extends StatelessWidget {
  const InlineEventDatePicker({
    super.key,
    required this.date,
    required this.onChanged,
  });

  final String? date;
  final ValueChanged<String?> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = date != null ? EventDates.parseIsoDate(date!) : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Filter by date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: WtvaColors.accentPurple,
              onPrimary: WtvaColors.onPrimary,
              surface: WtvaColors.dark400,
              onSurface: WtvaColors.neutral50,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: WtvaColors.dark400),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    onChanged(EventDates.toIsoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openPicker(context),
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(hasDate ? EventDates.shortLabel(date!) : 'Date'),
          style: OutlinedButton.styleFrom(
            foregroundColor: WtvaColors.neutral100,
            side: BorderSide(
              color: hasDate
                  ? WtvaColors.accentPurple
                  : WtvaColors.night200.withValues(alpha: 0.85),
            ),
            backgroundColor: WtvaColors.dark400,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (hasDate) ...[
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Clear date',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close, size: 18, color: WtvaColors.neutral300),
          ),
        ],
      ],
    );
  }
}
