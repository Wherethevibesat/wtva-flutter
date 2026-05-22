import 'package:flutter/material.dart';
import '../config/app_brand.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../theme/figma_theme.dart';
import '../widgets/wtva/nightlife_video_background.dart';
import 'business/business_launcher.dart';
import 'wtva/app_launcher.dart' show CustomerLauncher;

/// Option A: first meaningful screen — choose customer vs business.
class ModePickerScreen extends StatelessWidget {
  const ModePickerScreen({super.key});

  Future<void> _select(BuildContext context, AppMode mode) async {
    await AppModeService.instance.setMode(mode);
    if (!context.mounted) return;
    final next = mode == AppMode.customer
        ? const CustomerLauncher()
        : const BusinessLauncher();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NightlifeVideoBackground(overlayOpacity: 0.7),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Text(
                        AppBrand.logoMark,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: WtvaColors.neutral50,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppBrand.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: WtvaColors.neutral300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'How will you use WTVA?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          height: 1.15,
                          color: WtvaColors.neutral50,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can switch anytime from settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: WtvaColors.neutral300, fontSize: 14),
                  ),
                  const SizedBox(height: 36),
                  _ModeCard(
                    mode: AppMode.customer,
                    onTap: () => _select(context, AppMode.customer),
                  ),
                  const SizedBox(height: 16),
                  _ModeCard(
                    mode: AppMode.business,
                    onTap: () => _select(context, AppMode.business),
                  ),
                  const Spacer(),
                  Text(
                    AppBrand.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: WtvaColors.neutral300),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onTap;

  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WtvaColors.dark400.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: WtvaColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(mode.pickerIcon, color: WtvaColors.onPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.pickerTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: WtvaColors.neutral50,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.pickerSubtitle,
                      style: const TextStyle(fontSize: 13, color: WtvaColors.neutral300),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
