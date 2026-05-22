import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import '../../widgets/wtva/wtva_gradient_button.dart';

class MainTutorialOverlay extends StatefulWidget {
  final VoidCallback onDone;

  const MainTutorialOverlay({super.key, required this.onDone});

  static Future<void> showIfNeeded(BuildContext context, {required VoidCallback onDone}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MainTutorialOverlay(onDone: onDone),
    );
  }

  @override
  State<MainTutorialOverlay> createState() => _MainTutorialOverlayState();
}

class _MainTutorialOverlayState extends State<MainTutorialOverlay> {
  int _page = 0;

  static const _pages = [
    ('Discover venues', 'Browse nearby spots, promoted deals, and live stories.'),
    ('Check in & earn', 'Tap the center button to check in and rack up points.'),
    ('Climb the ranks', 'Compete on global and follower leaderboards.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Dialog(
      backgroundColor: WtvaColors.dark400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(p.$2, textAlign: TextAlign.center, style: const TextStyle(color: WtvaColors.neutral300, height: 1.4)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? WtvaColors.accentPurple : WtvaColors.night200,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            WtvaGradientButton(
              label: _page < _pages.length - 1 ? 'Next' : 'Got it',
              onPressed: () {
                if (_page < _pages.length - 1) {
                  setState(() => _page++);
                } else {
                  Navigator.pop(context);
                  widget.onDone();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
