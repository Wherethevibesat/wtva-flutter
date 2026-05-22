import 'package:flutter/material.dart';
import '../auth_wrapper.dart';

/// Routes to onboarding or main auth after splash.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}
