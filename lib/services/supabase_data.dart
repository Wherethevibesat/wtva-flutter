import '../config/app_config.dart';
import '../config/dev_auth_config.dart';
import 'supabase_bootstrap.dart';

/// Whether reads/writes should hit Supabase (not dummy-auth sessions).
class SupabaseData {
  SupabaseData._();

  static bool get enabled =>
      AppConfig.useSupabaseData &&
      AppConfig.supabaseInitialized &&
      SupabaseBootstrap.initialized &&
      SupabaseBootstrap.client != null;

  static bool get syncAuth => enabled && !DevAuthConfig.useDummyAuth;
}
