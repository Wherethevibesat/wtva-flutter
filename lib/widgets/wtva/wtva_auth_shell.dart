import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import 'brand_logo.dart';
import 'wtva_brand_backdrop.dart';
import 'wtva_gradient_button.dart';

/// Shared layout for login / registration / forgot-password.
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
    final bottomReserve = bottomButtonLabel == null
        ? 0.0
        : (bottomLinkLabel != null ? 140.0 : 108.0);

    return Scaffold(
      body: WtvaBrandBackdrop(
        fadeToLight: true,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        if (showBack)
                          IconButton(
                            onPressed: onBack ?? () => Navigator.maybePop(context),
                            icon: _circleIcon(Icons.arrow_back_rounded, onDark: true),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: WtvaColors.accentPink.withValues(alpha: 0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const BrandLogo(height: 30),
                            ),
                          ),
                        ),
                        if (onClose != null)
                          IconButton(
                            onPressed: onClose,
                            icon: _circleIcon(Icons.close_rounded, onDark: true),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(child: body),
                  SizedBox(height: bottomReserve),
                ],
              ),
              if (bottomButtonLabel != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    decoration: BoxDecoration(
                      color: WtvaColors.dark400.withValues(alpha: 0.96),
                      border: const Border(
                        top: BorderSide(color: WtvaColors.night200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF101115).withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
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
                          const SizedBox(height: 10),
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
      ),
    );
  }

  Widget _circleIcon(IconData icon, {required bool onDark}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : WtvaColors.dark400,
        shape: BoxShape.circle,
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.35) : WtvaColors.night200,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101115).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: onDark ? Colors.white : WtvaColors.neutral50,
        size: 20,
      ),
    );
  }
}
