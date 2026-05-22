import 'package:flutter/material.dart';

import '../../theme/figma_theme.dart';
import '../../utils/account_gate.dart';

/// Empty state when a feature requires an account.
class GuestLockedView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GuestLockedView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: WtvaColors.neutral300),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: WtvaColors.neutral300,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => AccountGate.requireSignIn(context),
              style: FilledButton.styleFrom(
                backgroundColor: WtvaColors.accentGreen,
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Log in or sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
