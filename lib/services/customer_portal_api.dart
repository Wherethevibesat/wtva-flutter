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
    this.mobilePayUrl,
  });

  final String clientSecret;
  final String paymentIntentId;
  final String packageName;
  final double amount;
  final int partySize;
  final int stopCount;
  /// Customer-site Payment Element URL (Apple Pay, bank, Cash App, card…).
  final String? mobilePayUrl;
}

class VibeSplitGroupCreated {
  const VibeSplitGroupCreated({
    required this.groupId,
    required this.inviteToken,
    required this.inviteUrl,
    required this.hostShareId,
    required this.amounts,
    required this.total,
  });

  final String groupId;
  final String inviteToken;
  final String inviteUrl;
  final String hostShareId;
  final List<double> amounts;
  final double total;
}

class VibeSplitShare {
  const VibeSplitShare({
    required this.id,
    required this.role,
    required this.amount,
    required this.status,
    this.userId,
    this.label,
    this.email,
  });

  final String id;
  final String role;
  final double amount;
  final String status;
  final String? userId;
  final String? label;
  final String? email;
}

class VibeSplitGroupStatus {
  const VibeSplitGroupStatus({
    required this.id,
    required this.status,
    required this.inviteToken,
    required this.packageTitle,
    required this.total,
    required this.paidCount,
    required this.shares,
    this.hostUserId,
    this.openGuestShareId,
  });

  final String id;
  final String status;
  final String inviteToken;
  final String packageTitle;
  final double total;
  final int paidCount;
  final String? hostUserId;
  final String? openGuestShareId;
  final List<VibeSplitShare> shares;

  /// Share the signed-in user should pay (host share for host, else claimed/open guest).
  VibeSplitShare? payableShareFor({
    required String? userId,
    String? userEmail,
    String? preferredShareId,
  }) {
    if (status != 'collecting') return null;

    VibeSplitShare? byId(String? id) {
      if (id == null || id.isEmpty) return null;
      for (final s in shares) {
        if (s.id == id && s.status == 'pending') return s;
      }
      return null;
    }

    final preferred = byId(preferredShareId);
    if (preferred != null) return preferred;

    for (final s in shares) {
      if (s.userId == userId && s.status == 'pending') return s;
    }

    if (userId != null && hostUserId == userId) {
      for (final s in shares) {
        if (s.role == 'host' && s.status == 'pending') return s;
      }
      return null;
    }

    final email = userEmail?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      for (final s in shares) {
        if (s.role == 'guest' &&
            s.status == 'pending' &&
            (s.email?.toLowerCase() == email)) {
          return s;
        }
      }
    }

    final openId = openGuestShareId;
    if (openId != null) {
      for (final s in shares) {
        if (s.id == openId && s.status == 'pending') return s;
      }
    }
    return null;
  }
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
    required String startsOn,
  }) async {
    late http.Response res;
    try {
      res = await http.post(
        _uri('/api/checkout/night-package/create-intent'),
        headers: await _headers(),
        body: jsonEncode({
          'packageId': packageId,
          'partySize': partySize,
          'stopOfferIds': stopOfferIds,
          'startsOn': startsOn,
        }),
      );
    } catch (e) {
      throw StateError(
        'Could not reach checkout (${CustomerPortalConfig.apiBaseUrl}). '
        'Check your connection and try again.',
      );
    }
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(
        body['error'] as String? ??
            'Could not start checkout (${res.statusCode})',
      );
    }
    final clientSecret = body['clientSecret'] as String?;
    final paymentIntentId = body['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw StateError('Invalid payment response');
    }
    return NightPackagePaymentIntent(
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
      packageName: body['packageName'] as String? ?? 'Your vibe',
      amount: _toDouble(body['amount']),
      partySize: (body['partySize'] as num?)?.toInt() ?? partySize,
      stopCount: (body['stopCount'] as num?)?.toInt() ?? stopOfferIds.length,
      mobilePayUrl: body['mobilePayUrl'] as String?,
    );
  }

  Future<VibeSplitGroupCreated> createVibeSplitGroup({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
    required String startsOn,
    required int payerCount,
    required List<String> guestEmails,
    String splitMode = 'even',
    List<int>? amountCents,
    int expiresInMinutes = 1440,
  }) async {
    final res = await http.post(
      _uri('/api/checkout/night-package/group/create'),
      headers: await _headers(),
      body: jsonEncode({
        'packageId': packageId,
        'partySize': partySize,
        'stopOfferIds': stopOfferIds,
        'startsOn': startsOn,
        'payerCount': payerCount,
        'guestEmails': guestEmails,
        'splitMode': splitMode,
        if (amountCents != null) 'amountCents': amountCents,
        'expiresInMinutes': expiresInMinutes,
      }),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Could not create split');
    }
    return VibeSplitGroupCreated(
      groupId: body['groupId'] as String,
      inviteToken: body['inviteToken'] as String? ?? '',
      inviteUrl: body['inviteUrl'] as String? ?? '',
      hostShareId: body['hostShareId'] as String,
      amounts: ((body['amounts'] as List?) ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      total: _toDouble(body['total']),
    );
  }

  Future<
      ({
        String clientSecret,
        String paymentIntentId,
        double amount,
        String? mobilePayUrl,
      })> createVibeShareIntent({
    required String groupId,
    required String shareId,
  }) async {
    late http.Response res;
    try {
      res = await http
          .post(
            _uri('/api/checkout/night-package/group/pay-share'),
            headers: await _headers(),
            body: jsonEncode({'groupId': groupId, 'shareId': shareId}),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw StateError(
        'Could not reach checkout (${CustomerPortalConfig.apiBaseUrl}). '
        'Check your connection and try again.',
      );
    }
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Could not start share payment');
    }
    final secret = body['clientSecret'] as String?;
    final pi = body['paymentIntentId'] as String?;
    if (secret == null || pi == null) {
      throw StateError('Invalid share payment response');
    }
    return (
      clientSecret: secret,
      paymentIntentId: pi,
      amount: _toDouble(body['amount']),
      mobilePayUrl: body['mobilePayUrl'] as String?,
    );
  }

  Future<String> confirmVibeSharePayment(String paymentIntentId) async {
    late http.Response res;
    try {
      res = await http
          .post(
            _uri('/api/checkout/night-package/group/confirm-share'),
            headers: await _headers(),
            body: jsonEncode({'paymentIntentId': paymentIntentId}),
          )
          .timeout(const Duration(seconds: 25));
    } catch (_) {
      throw StateError(
        'Payment may have gone through, but confirmation timed out. '
        'Check My Plans in a moment.',
      );
    }
    final body = _decode(res);
    if (res.statusCode != 200 && body['status'] != 'pending') {
      throw StateError(body['error'] as String? ?? 'Share confirm failed');
    }
    return body['status'] as String? ?? 'share_paid';
  }

  Future<VibeSplitGroupStatus> fetchVibeSplitGroup(String token) async {
    late http.Response res;
    try {
      res = await http
          .get(
            _uri('/api/checkout/night-package/group/$token'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw StateError('Could not load split — check your connection.');
    }
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Split not found');
    }
    final shares = ((body['shares'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (s) => VibeSplitShare(
            id: s['id'] as String,
            role: s['role'] as String? ?? 'guest',
            amount: _toDouble(s['amount']),
            status: s['status'] as String? ?? 'pending',
            userId: s['userId'] as String?,
            label: s['label'] as String?,
            email: s['email'] as String?,
          ),
        )
        .toList();
    return VibeSplitGroupStatus(
      id: body['id'] as String,
      status: body['status'] as String? ?? 'collecting',
      inviteToken: token,
      packageTitle: body['packageTitle'] as String? ?? 'Your vibe',
      total: _toDouble(body['total']),
      paidCount: (body['paidCount'] as num?)?.toInt() ?? 0,
      hostUserId: body['hostUserId'] as String?,
      openGuestShareId: body['openGuestShareId'] as String?,
      shares: shares,
    );
  }

  /// Confirms fulfillment after PaymentSheet. Retries briefly if Stripe is still pending.
  Future<void> confirmNightPackagePayment(String paymentIntentId) async {
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      late http.Response res;
      try {
        res = await http.post(
          _uri('/api/checkout/night-package/confirm'),
          headers: await _headers(),
          body: jsonEncode({'paymentIntentId': paymentIntentId}),
        );
      } catch (_) {
        if (i == attempts - 1) {
          throw StateError(
            'Payment went through, but we could not confirm your plan. '
            'Check My Plans or contact support.',
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
        continue;
      }

      final body = _decode(res);
      if (res.statusCode == 200 && body['status'] == 'confirmed') {
        return;
      }
      if (res.statusCode == 200 && body['status'] == 'pending') {
        if (i == attempts - 1) {
          throw StateError(
            'Payment is still processing. Check My Plans in a moment.',
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * (i + 1)));
        continue;
      }
      throw StateError(
        body['error'] as String? ??
            'Payment confirmation failed (${res.statusCode})',
      );
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
