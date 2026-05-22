import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../services/app_mode_service.dart';
import '../../theme/figma_theme.dart';
import '../business/business_launcher.dart';
import '../mode_picker_screen.dart';
import 'auth_gate.dart';
import 'welcome_screen.dart';

/// After splash: mode picker (first time) or the saved mode's launcher.
class RootAppLauncher extends StatefulWidget {
  const RootAppLauncher({super.key});

  @override
  State<RootAppLauncher> createState() => _RootAppLauncherState();
}

class _RootAppLauncherState extends State<RootAppLauncher> {
  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    if (!AppModeService.instance.isLoaded) {
      await AppModeService.instance.load();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!AppModeService.instance.isLoaded) {
      return const Scaffold(
        backgroundColor: WtvaColors.dark500,
        body: Center(
          child: CircularProgressIndicator(color: WtvaColors.neutral50),
        ),
      );
    }

    final mode = AppModeService.instance.mode;
    if (mode == null) {
      return const ModePickerScreen();
    }
    switch (mode) {
      case AppMode.customer:
        return const CustomerLauncher();
      case AppMode.business:
        return const BusinessLauncher();
    }
  }
}

/// Customer onboarding → auth (existing flow).
class CustomerLauncher extends StatelessWidget {
  const CustomerLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: WelcomeScreen.hasCompleted(),
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
          return const AuthGate();
        }
        return const WelcomeScreen();
      },
    );
  }
}
