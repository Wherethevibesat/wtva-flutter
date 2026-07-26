import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../theme/wtva_icons.dart';

class WtvaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WtvaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: WtvaColors.navBlur,
            border: Border(
              top: const BorderSide(color: WtvaColors.night200, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.nightlife_outlined,
                    label: 'Tonight',
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _PlanFab(
                    selected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.event_outlined,
                    label: 'Events',
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    icon: Icons.storefront_outlined,
                    label: 'Venues',
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? WtvaColors.accentPurple : WtvaColors.neutral300;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: WtvaIcons.lg),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.1,
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: WtvaColors.accentPurple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanFab extends StatefulWidget {
  const _PlanFab({required this.onTap, required this.selected});

  final VoidCallback onTap;
  final bool selected;

  @override
  State<_PlanFab> createState() => _PlanFabState();
}

class _PlanFabState extends State<_PlanFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: WtvaColors.fabGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: widget.selected ? 0.4 : 0.22,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: WtvaColors.onPrimary,
                  size: WtvaIcons.lg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      widget.selected ? FontWeight.w800 : FontWeight.w600,
                  color: widget.selected
                      ? WtvaColors.accentPurple
                      : WtvaColors.neutral300,
                  letterSpacing: -0.1,
                ),
              ),
              if (widget.selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: WtvaColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
