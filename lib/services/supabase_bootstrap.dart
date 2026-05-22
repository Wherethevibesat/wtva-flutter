import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Tracks whether [Supabase.initialize] completed successfully.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool initialized = false;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      initialized = true;
    } catch (_) {
      initialized = false;
    }
  }

  static SupabaseClient? get client =>
      initialized ? Supabase.instance.client : null;
}
