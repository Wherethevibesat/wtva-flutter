import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/customer_portal_config.dart';
import 'supabase_bootstrap.dart';

class StripeSettingsRepository {
  StripeSettingsRepository._();
  static final StripeSettingsRepository instance = StripeSettingsRepository._();

  String? _cached;

  /// Publishable key from Supabase, then customer portal (DB + env fallback).
  Future<String?> fetchPublishableKey({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null && _cached!.isNotEmpty) {
      return _cached;
    }

    // Prefer customer API (DB + env fallback) — matches web checkout.
    final fromApi = await _fromCustomerPortal();
    if (fromApi != null && fromApi.isNotEmpty) {
      _cached = fromApi;
      return fromApi;
    }

    final fromDb = await _fromSupabase();
    if (fromDb != null && fromDb.isNotEmpty) {
      _cached = fromDb;
      return fromDb;
    }

    return null;
  }

  Future<String?> _fromSupabase() async {
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client
          .from('stripe_settings')
          .select('publishable_key')
          .eq('id', 1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      final key = (row?['publishable_key'] as String?)?.trim();
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}
    return null;
  }

  Future<String?> _fromCustomerPortal() async {
    try {
      final uri = Uri.parse(
        '${CustomerPortalConfig.apiBaseUrl}/api/checkout/stripe-config',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map) return null;
      final key = (body['publishableKey'] as String?)?.trim();
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}
    return null;
  }
}
