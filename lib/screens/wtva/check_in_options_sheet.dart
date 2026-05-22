import 'package:flutter/material.dart';
import '../../utils/account_gate.dart';
import '../../theme/figma_theme.dart';
import 'active_check_in_screen.dart';
import 'go_live_screen.dart';
import 'check_in/check_in_flow_screens.dart';

/// Figma #09_06 — Create Post / Check In / Go Live options.
class CheckInOptionsSheet extends StatelessWidget {
  final String venueId;
  final String venueName;

  const CheckInOptionsSheet({
    super.key,
    required this.venueId,
    required this.venueName,
  });

  static Future<void> show(
    BuildContext context, {
    required String venueId,
    required String venueName,
  }) async {
    if (!await AccountGate.requireSignIn(context)) return;
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInOptionsSheet(venueId: venueId, venueName: venueName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WtvaColors.dark400,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 63,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Post',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: WtvaColors.neutral200),
                  ),
                ],
              ),
            ),
            _Option(
              title: 'Check In',
              subtitle: 'at $venueName',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveCheckInScreen(venueId: venueId),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: WtvaColors.night300),
            _Option(
              title: 'Create Post',
              subtitle: 'Camera, filters & share',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckInCameraScreen(venueId: venueId),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: WtvaColors.night300),
            _Option(
              title: 'Go Live',
              subtitle: 'Stream from the venue',
              onTap: () async {
                Navigator.pop(context);
                if (!await AccountGate.requireSignIn(context)) return;
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoLiveScreen(venueId: venueId),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: WtvaColors.neutral300)),
      trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral200),
    );
  }
}
