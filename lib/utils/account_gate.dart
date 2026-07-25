import 'package:flutter/material.dart';

import '../screens/wtva/registration/registration_flow.dart';
import '../screens/wtva/wtva_login_screen.dart';
import '../services/supabase_bootstrap.dart';
import '../services/user_service.dart';
import '../theme/figma_theme.dart';

/// Prompts guests to sign up or log in before account-only actions.
class AccountGate {
  static bool get isSignedIn => UserService().isLoggedIn;

  static bool get hasSupabaseSession {
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    return token != null && token.isNotEmpty;
  }

  /// Returns true if the user has a real account session (not guest browse).
  ///
  /// Set [requireSupabaseSession] for checkout — dummy/dev logins cannot pay.
  static Future<bool> requireSignIn(
    BuildContext context, {
    String message =
        'Create a free account or log in to check in, save favorites, and message venues.',
    bool requireSupabaseSession = false,
  }) async {
    if (requireSupabaseSession) {
      if (hasSupabaseSession) return true;
    } else if (UserService().isLoggedIn) {
      return true;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WtvaColors.dark400,
        title: const Text(
          'Account required',
          style: TextStyle(fontWeight: FontWeight.w700, color: WtvaColors.neutral50),
        ),
        content: Text(
          message,
          style: const TextStyle(color: WtvaColors.neutral200, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now', style: TextStyle(color: WtvaColors.neutral300)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'login'),
            child: const Text('Log in', style: TextStyle(color: WtvaColors.neutral50)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'signup'),
            child: const Text('Sign up', style: TextStyle(color: WtvaColors.accentGreen)),
          ),
        ],
      ),
    );

    if (!context.mounted || action == null) return false;

    if (action == 'signup') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RegistrationFlow()),
      );
    } else if (action == 'login') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WtvaLoginScreen()),
      );
    }

    if (requireSupabaseSession) return hasSupabaseSession;
    return UserService().isLoggedIn;
  }
}
