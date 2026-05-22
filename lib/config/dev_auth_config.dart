import 'app_config.dart';

/// Development-only auth. Set [useDummyAuth] to false when using Supabase.
class DevAuthConfig {
  static bool get useDummyAuth => AppConfig.useDummyAuth;

  /// Shared password for all dummy accounts below.
  static const String dummyPassword = 'password';

  /// Email → role key: customer, admin, owner, business
  static const Map<String, String> dummyAccounts = {
    'customer@demo.com': 'customer',
    'business@demo.com': 'owner',
    'owner@demo.com': 'owner',
    'admin@demo.com': 'admin',
  };
}
