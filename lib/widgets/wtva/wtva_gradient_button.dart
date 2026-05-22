import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';

class WtvaGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;

  const WtvaGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active ? WtvaColors.buttonGradient : null,
          color: active ? null : WtvaColors.dark300,
          borderRadius: BorderRadius.circular(31),
          border: active
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : Border.all(color: WtvaColors.night200),
          boxShadow: active ? WtvaColors.buttonShadow : null,
        ),
        child: ElevatedButton(
          onPressed: active ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: active ? WtvaColors.onPrimary : WtvaColors.neutral300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(31)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: WtvaColors.onPrimary),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                ),
        ),
      ),
    );
  }
}
