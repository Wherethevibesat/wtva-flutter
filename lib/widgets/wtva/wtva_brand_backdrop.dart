import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

/// Full-bleed purple→magenta atmosphere matching the home hero.
class WtvaBrandBackdrop extends StatelessWidget {
  const WtvaBrandBackdrop({
    super.key,
    this.child,
    this.fadeToLight = false,
  });

  final Widget? child;

  /// When true, softens into the light page color at the bottom (good for forms).
  final bool fadeToLight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: WtvaColors.brandBackdropGradient),
        ),
        // Soft brand glows
        Positioned(
          top: -120,
          right: -80,
          child: _GlowBlob(
            size: 280,
            color: WtvaColors.accentPurple.withValues(alpha: 0.45),
          ),
        ),
        Positioned(
          top: 160,
          left: -100,
          child: _GlowBlob(
            size: 260,
            color: WtvaColors.accentPink.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          bottom: 80,
          right: -60,
          child: _GlowBlob(
            size: 220,
            color: const Color(0xFFA21CAF).withValues(alpha: 0.22),
          ),
        ),
        if (fadeToLight)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    WtvaColors.dark500.withValues(alpha: 0.35),
                    WtvaColors.dark500.withValues(alpha: 0.92),
                    WtvaColors.dark500,
                  ],
                  stops: const [0.0, 0.16, 0.36, 0.55],
                ),
              ),
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
