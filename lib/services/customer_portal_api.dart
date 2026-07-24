import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/customer_portal_config.dart';
import '../services/supabase_bootstrap.dart';

class ConciergeHistoryTurn {
  const ConciergeHistoryTurn({required this.role, required this.content});

  final String role;
  final String content;
}

class ConciergeRecommendation {
  const ConciergeRecommendation({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reason,
    this.priceHint,
    this.url,
  });

  final String kind;
  final String id;
  final String title;
  final String subtitle;
  final String reason;
  final String? priceHint;
  final String? url;

  factory ConciergeRecommendation.fromJson(Map<String, dynamic> json) {
    return ConciergeRecommendation(
      kind: json['kind'] as String? ?? 'event',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      priceHint: json['priceHint'] as String?,
      url: json['url'] as String?,
    );
  }
}

class ConciergeReply {
  const ConciergeReply({
    required this.reply,
    required this.needsClarification,
    required this.recommendations,
    required this.suggestedChips,
    this.clarificationQuestion,
  });

  final String reply;
  final bool needsClarification;
  final String? clarificationQuestion;
  final List<ConciergeRecommendation> recommendations;
  final List<String> suggestedChips;

  factory ConciergeReply.fromJson(Map<String, dynamic> json) {
    final recs = (json['recommendations'] as List?) ?? const [];
    final chips = (json['suggestedChips'] as List?) ?? const [];
    return ConciergeReply(
      reply: json['reply'] as String? ?? '',
      needsClarification: json['needsClarification'] as bool? ?? false,
      clarificationQuestion: json['clarificationQuestion'] as String?,
      recommendations: recs
          .whereType<Map>()
          .map((e) => ConciergeRecommendation.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      suggestedChips: chips.map((e) => e.toString()).toList(),
    );
  }
}

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

class NightPackagePaymentIntent {
  const NightPackagePaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.packageName,
    required this.amount,
    required this.partySize,
    required this.stopCount,
  });

  final String clientSecret;
  final String paymentIntentId;
  final String packageName;
  final double amount;
  final int partySize;
  final int stopCount;
}

class CustomerPortalApi {
  CustomerPortalApi._();
  static final CustomerPortalApi instance = CustomerPortalApi._();

  Uri _uri(String path) => Uri.parse('${CustomerPortalConfig.apiBaseUrl}$path');

  Future<String> _accessToken() async {
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to continue.');
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

  Future<NightPackagePaymentIntent> createNightPackageIntent({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
  }) async {
    final res = await http.post(
      _uri('/api/checkout/night-package/create-intent'),
      headers: await _headers(),
      body: jsonEncode({
        'packageId': packageId,
        'partySize': partySize,
        'stopOfferIds': stopOfferIds,
      }),
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
    return NightPackagePaymentIntent(
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
      packageName: body['packageName'] as String? ?? 'Night package',
      amount: _toDouble(body['amount']),
      partySize: (body['partySize'] as num?)?.toInt() ?? partySize,
      stopCount: (body['stopCount'] as num?)?.toInt() ?? stopOfferIds.length,
    );
  }

  Future<void> confirmNightPackagePayment(String paymentIntentId) async {
    final res = await http.post(
      _uri('/api/checkout/night-package/confirm'),
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

  /// City launch notify / request (auth optional).
  Future<void> requestCity({
    required String email,
    required String city,
    String? name,
    String? note,
    String source = 'request_form',
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final res = await http.post(
      _uri('/api/request-city'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'city': city,
        'source': source,
        if (name != null) 'name': name,
        if (note != null) 'note': note,
      }),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Could not submit');
    }
  }

  /// In-app Vibes Concierge (same backend as web widget).
  Future<ConciergeReply> askConcierge({
    required String query,
    required String sessionId,
    List<ConciergeHistoryTurn> history = const [],
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final http.Response res;
    try {
      res = await http.post(
        _uri('/api/ai/concierge'),
        headers: headers,
        body: jsonEncode({
          'query': query,
          'sessionId': sessionId,
          if (history.isNotEmpty)
            'history': [
              for (final t in history) {'role': t.role, 'content': t.content},
            ],
        }),
      );
    } catch (e) {
      throw StateError('Could not reach Concierge. Check your connection and try again.');
    }
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(
        body['error'] as String? ??
            'Concierge is unavailable (${res.statusCode})',
      );
    }
    return ConciergeReply.fromJson(body);
  }

  /// Public tip / notify-me capture (auth optional).
  Future<void> submitEventInterest({
    required String email,
    required String source,
    String? name,
    String? city,
    String? neighborhood,
    String? vibe,
    String? note,
    String? eventId,
    String? venueId,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SupabaseBootstrap.client?.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final res = await http.post(
      _uri('/api/event-interest'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'source': source,
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (vibe != null) 'vibe': vibe,
        if (note != null) 'note': note,
        if (eventId != null) 'eventId': eventId,
        if (venueId != null) 'venueId': venueId,
      }),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Could not submit');
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
