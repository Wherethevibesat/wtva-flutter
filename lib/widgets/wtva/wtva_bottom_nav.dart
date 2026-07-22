import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../theme/wtva_icons.dart';

class WtvaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCheckIn;

  const WtvaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCheckIn,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    icon: Icons.event_outlined,
                    label: 'Events',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _CheckInFab(onTap: onCheckIn),
                  _NavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Inbox',
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
              style: TextStyle(
                fontSize: 10,
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
                decoration: const BoxDecoration(color: WtvaColors.accentPurple, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckInFab extends StatefulWidget {
  final VoidCallback onTap;

  const _CheckInFab({required this.onTap});

  @override
  State<_CheckInFab> createState() => _CheckInFabState();
}

class _CheckInFabState extends State<_CheckInFab> {
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
        child: Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: WtvaColors.fabGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: WtvaColors.buttonShadow,
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, color: WtvaColors.onPrimary, size: 26),
        ),
      ),
    );
  }
}
