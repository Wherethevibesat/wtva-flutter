import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/dev_auth_config.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/figma_theme.dart';
import 'business_login_screen.dart';
import 'business_shell.dart';

class BusinessAuthWrapper extends StatefulWidget {
  const BusinessAuthWrapper({super.key});

  @override
  State<BusinessAuthWrapper> createState() => _BusinessAuthWrapperState();
}

class _BusinessAuthWrapperState extends State<BusinessAuthWrapper> {
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
    if (mounted) setState(() => _isLoading = false);
  }

  void _listenToAuthChanges() {
    if (DevAuthConfig.useDummyAuth) return;
    _authService.authStateChanges.listen((AuthState state) async {
      if (state.event == AuthChangeEvent.signedIn) {
        await _userService.initializeUser();
        if (mounted) setState(() {});
      } else if (state.event == AuthChangeEvent.signedOut) {
        _userService.clearUser();
        if (mounted) setState(() {});
      }
    });
  }

  bool get _canEnterShell {
    if (!_userService.isLoggedIn || _userService.currentUser == null) {
      return false;
    }
    return _userService.currentUser!.role == UserRole.venueOwner;
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

    if (_canEnterShell) {
      return const BusinessShell();
    }

    return const BusinessLoginScreen();
  }
}
