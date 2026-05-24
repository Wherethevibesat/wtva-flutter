import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/customer_portal_config.dart';
import '../services/supabase_bootstrap.dart';

class EventTicketPaymentIntent {
  const EventTicketPaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.tierName,
    required this.amount,
  });

  final String clientSecret;
  final String paymentIntentId;
  final String tierName;
  final double amount;
}

class CustomerPortalApi {
  CustomerPortalApi._();
  static final CustomerPortalApi instance = CustomerPortalApi._();

  Uri _uri(String path) => Uri.parse('${CustomerPortalConfig.apiBaseUrl}$path');

  Future<String> _accessToken() async {
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to get tickets.');
    }
    return token;
  }

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _accessToken()}',
      };

  Future<EventTicketPaymentIntent> createEventTicketIntent({
    required String eventId,
    required String tierId,
  }) async {
    final res = await http.post(
      _uri('/api/checkout/event-intent'),
      headers: await _headers(),
      body: jsonEncode({'eventId': eventId, 'tierId': tierId}),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Could not start checkout');
    }
    final clientSecret = body['clientSecret'] as String?;
    final paymentIntentId = body['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw StateError('Invalid payment response');
    }
    return EventTicketPaymentIntent(
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
      tierName: body['tierName'] as String? ?? 'Ticket',
      amount: _toDouble(body['amount']),
    );
  }

  Future<void> confirmEventTicketPayment(String paymentIntentId) async {
    final res = await http.post(
      _uri('/api/checkout/event-confirm'),
      headers: await _headers(),
      body: jsonEncode({'paymentIntentId': paymentIntentId}),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Payment confirmation failed');
    }
    if (body['status'] != 'confirmed') {
      throw StateError('Payment has not completed yet');
    }
  }

  Future<void> freeRsvp({required String eventId, required String tierId}) async {
    final res = await http.post(
      _uri('/api/events/$eventId/register'),
      headers: await _headers(),
      body: jsonEncode({'tierId': tierId}),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Registration failed');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
