import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../screens/mode_picker_screen.dart';
import '../screens/wtva/app_launcher.dart' show CustomerLauncher;
import '../screens/business/business_launcher.dart';
import '../services/app_mode_service.dart';
import '../services/user_service.dart';

/// Switch between customer and business experiences.
class ModeNavigation {
  ModeNavigation._();

  static Future<void> openModePicker(BuildContext context) async {
    UserService().logout();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ModePickerScreen()),
      (_) => false,
    );
  }

  static Future<void> switchToMode(
    BuildContext context,
    AppMode mode, {
    bool signOut = true,
  }) async {
    if (signOut) {
      UserService().logout();
    }
    await AppModeService.instance.setMode(mode);
    if (!context.mounted) return;
    final next = mode == AppMode.customer
        ? const CustomerLauncher()
        : const BusinessLauncher();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => next),
      (_) => false,
    );
  }
}
