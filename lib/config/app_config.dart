import 'supabase_config.dart';

/// Runtime app flags. Override at build time:
/// `flutter run --dart-define=USE_DUMMY_AUTH=false`
class AppConfig {
  /// Demo login (customer@demo.com / password) without Supabase Auth.
  static const bool useDummyAuth = bool.fromEnvironment(
    'USE_DUMMY_AUTH',
    defaultValue: false,
  );

  /// Load venues & check-ins from Supabase when the client is initialized.
  static const bool useSupabaseData = bool.fromEnvironment(
    'USE_SUPABASE_DATA',
    defaultValue: true,
  );

  static bool get supabaseInitialized => SupabaseConfig.isConfigured;
}
