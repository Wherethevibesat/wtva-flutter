import 'supabase_bootstrap.dart';

class StripeSettingsRepository {
  StripeSettingsRepository._();
  static final StripeSettingsRepository instance = StripeSettingsRepository._();

  Future<String?> fetchPublishableKey() async {
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('stripe_settings')
          .select('publishable_key')
          .eq('id', 1)
          .maybeSingle();
      final key = row?['publishable_key'] as String?;
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}
    return null;
  }
}
