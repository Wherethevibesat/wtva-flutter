import 'package:flutter/material.dart';
import '../../theme/figma_theme.dart';
import 'business_auth_gate.dart';
import 'business_welcome_screen.dart';

/// Business onboarding → auth.
class BusinessLauncher extends StatelessWidget {
  const BusinessLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: BusinessWelcomeScreen.hasCompleted(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: WtvaColors.dark500,
            body: Center(
              child: CircularProgressIndicator(color: WtvaColors.neutral50),
            ),
          );
        }
        if (snapshot.data!) {
          return const BusinessAuthGate();
        }
        return const BusinessWelcomeScreen();
      },
    );
  }
}
