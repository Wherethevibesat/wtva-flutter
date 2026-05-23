import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

/// Compact entry points for secondary browse flows (events, areas, map).
class DiscoverQuickBrowse extends StatelessWidget {
  const DiscoverQuickBrowse({
    super.key,
    required this.onEvents,
    required this.onNeighborhoods,
    required this.onMap,
  });

  final VoidCallback onEvents;
  final VoidCallback onNeighborhoods;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickBrowseTile(
            icon: Icons.event_outlined,
            label: 'Events',
            onTap: onEvents,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickBrowseTile(
            icon: Icons.place_outlined,
            label: 'Areas',
            onTap: onNeighborhoods,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickBrowseTile(
            icon: Icons.map_outlined,
            label: 'Map',
            onTap: onMap,
          ),
        ),
      ],
    );
  }
}

class _QuickBrowseTile extends StatelessWidget {
  const _QuickBrowseTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark300,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WtvaColors.night200.withValues(alpha: 0.85)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: WtvaColors.neutral200),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WtvaColors.neutral100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
