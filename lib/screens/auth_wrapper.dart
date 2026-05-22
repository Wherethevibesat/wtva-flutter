import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/dev_auth_config.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/figma_theme.dart';
import 'wtva/app_shell.dart';
import 'wtva/wtva_login_screen.dart';

/// Wrapper that handles authentication state
/// Shows login screen if not authenticated, main app if authenticated
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  Future<void> _checkAuthState() async {
    await _userService.initializeUser();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenToAuthChanges() {
    if (DevAuthConfig.useDummyAuth) return;
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await _userService.initializeUser();
        if (mounted) {
          setState(() {});
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _userService.clearUser();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: WtvaColors.dark500,
        body: Center(
          child: CircularProgressIndicator(color: WtvaColors.neutral50),
        ),
      );
    }

    final user = _userService.currentUser;
    if (user != null &&
        (_userService.isLoggedIn || _userService.isGuest)) {
      final role = user.role;
      if (role == UserRole.customer || role == UserRole.admin || _userService.isGuest) {
        return const AppShell();
      }
    }

    // Show login screen if not authenticated
    return const WtvaLoginScreen();
  }
}

