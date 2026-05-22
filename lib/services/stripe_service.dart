import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'supabase_bootstrap.dart';

/// Service for handling Stripe operations
class StripeService {
  SupabaseClient get _supabase {
    final client = SupabaseBootstrap.client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }
    return client;
  }

  /// Save Stripe API keys to database
  Future<void> saveStripeKeys({
    required String publishableKey,
    required String secretKey,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('stripe_keys').upsert({
        'user_id': userId,
        'publishable_key': publishableKey,
        'secret_key': secretKey,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get stored Stripe API keys
  Future<Map<String, String>?> getStripeKeys() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('stripe_keys')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return {
        'publishable_key': response['publishable_key'] as String,
        'secret_key': response['secret_key'] as String,
      };
    } catch (e) {
      return null;
    }
  }

  /// Test Stripe connection with provided keys
  Future<bool> testStripeConnection({
    required String publishableKey,
    required String secretKey,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/account'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get connected Stripe accounts from database
  Future<List<Map<String, dynamic>>> getConnectedAccounts() async {
    try {
      final response = await _supabase
          .from('stripe_accounts')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Set default Stripe account
  Future<void> setDefaultAccount(String accountId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('stripe_accounts')
          .update({'is_default': false})
          .eq('user_id', userId);

      await _supabase
          .from('stripe_accounts')
          .update({'is_default': true})
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Disconnect Stripe account
  Future<void> disconnectAccount(String accountId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('stripe_accounts')
          .delete()
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Create withdrawal/payout using stored Stripe keys
  Future<Map<String, dynamic>> createWithdrawal({
    required double amount,
    required String destinationAccountId,
  }) async {
    try {
      final keys = await getStripeKeys();
      if (keys == null || keys['secret_key'] == null) {
        throw Exception('Stripe keys not configured. Please add your API keys in settings.');
      }

      final secretKey = keys['secret_key']!;

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/transfers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(),
          'currency': 'usd',
          'destination': destinationAccountId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          await _supabase.from('withdrawals').insert({
            'user_id': userId,
            'amount': amount,
            'status': 'pending',
            'stripe_transfer_id': data['id'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        return data as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to create withdrawal');
      }
    } catch (e) {
      rethrow;
    }
  }
}
