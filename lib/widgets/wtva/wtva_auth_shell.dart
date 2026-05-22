import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import 'wtva_gradient_button.dart';

/// Shared layout for login / registration / forgot-password (Figma auth pattern).
class WtvaAuthShell extends StatelessWidget {
  final Widget body;
  final String? bottomButtonLabel;
  final VoidCallback? onBottomPressed;
  final bool bottomEnabled;
  final bool bottomLoading;
  final VoidCallback? onClose;
  final bool showBack;
  final VoidCallback? onBack;
  final String? bottomLinkLabel;
  final VoidCallback? onBottomLinkPressed;

  const WtvaAuthShell({
    super.key,
    required this.body,
    this.bottomButtonLabel,
    this.onBottomPressed,
    this.bottomEnabled = true,
    this.bottomLoading = false,
    this.onClose,
    this.showBack = false,
    this.onBack,
    this.bottomLinkLabel,
    this.onBottomLinkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          onPressed: onBack ?? () => Navigator.maybePop(context),
                          icon: _circleIcon(Icons.arrow_back),
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      if (onClose != null)
                        IconButton(
                          onPressed: onClose,
                          icon: _circleIcon(Icons.close),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(child: body),
                if (bottomButtonLabel != null) SizedBox(height: bottomLinkLabel != null ? 132 : 100),
              ],
            ),
            if (bottomButtonLabel != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: WtvaColors.dark500.withValues(alpha: 0.92),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WtvaGradientButton(
                        label: bottomButtonLabel!,
                        onPressed: onBottomPressed,
                        enabled: bottomEnabled,
                        loading: bottomLoading,
                      ),
                      if (bottomLinkLabel != null && onBottomLinkPressed != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: bottomLoading ? null : onBottomLinkPressed,
                          child: Text(
                            bottomLinkLabel!,
                            style: const TextStyle(
                              color: WtvaColors.neutral200,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: WtvaColors.neutral300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: WtvaColors.night500.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: WtvaColors.neutral200, size: 22),
    );
  }
}
