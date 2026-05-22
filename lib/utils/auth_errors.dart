import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login')) {
      return 'Email or password is incorrect.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirm your email, then try again.';
    }
    if (msg.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    return error.message;
  }
  return error.toString().replaceAll('Exception: ', '');
}
