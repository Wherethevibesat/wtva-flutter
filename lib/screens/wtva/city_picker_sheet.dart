import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class CityOption {
  final String label;
  final String subtitle;

  const CityOption({required this.label, required this.subtitle});
}

class CityPickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CityPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const cities = [
    CityOption(label: 'Houston, TX', subtitle: 'Default · 128 venues nearby'),
    CityOption(label: 'Austin, TX', subtitle: 'Live music & rooftops'),
    CityOption(label: 'Dallas, TX', subtitle: 'Deep Ellum nightlife'),
    CityOption(label: 'San Antonio, TX', subtitle: 'River Walk & bars'),
  ];

  static Future<void> show(
    BuildContext context, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CityPickerSheet(selected: selected, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose city',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...cities.map((c) {
              final on = c.label == selected;
              return ListTile(
                leading: Icon(
                  Icons.location_city,
                  color: on ? WtvaColors.accentPurple : WtvaColors.neutral300,
                ),
                title: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.subtitle, style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300)),
                trailing: on ? const Icon(Icons.check_circle, color: WtvaColors.accentGreen) : null,
                onTap: () {
                  onSelected(c.label);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
