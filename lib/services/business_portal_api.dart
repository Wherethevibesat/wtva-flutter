import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/business_portal_config.dart';
import '../data/ticket_tier.dart';
import '../services/business_events_repository.dart';
import '../services/platform_settings.dart';
import '../services/supabase_bootstrap.dart';

class EventPortalSettings {
  const EventPortalSettings({
    required this.settings,
    this.publishableKey,
  });

  final PlatformSettings settings;
  final String? publishableKey;
}

class EventPaymentIntent {
  const EventPaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.fee,
  });

  final String clientSecret;
  final String paymentIntentId;
  final double fee;
}

class SubmitEventResult {
  const SubmitEventResult({
    required this.ids,
    required this.status,
  });

  final List<String> ids;
  final String status;
}

class BusinessPortalApi {
  BusinessPortalApi._();
  static final BusinessPortalApi instance = BusinessPortalApi._();

  Uri _uri(String path) => Uri.parse('${BusinessPortalConfig.apiBaseUrl}$path');

  Future<String> _accessToken() async {
    final session = SupabaseBootstrap.client?.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Sign in before submitting events.');
    }
    return token;
  }

  Future<Map<String, String>> _headers() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _accessToken()}',
    };
  }

  Future<EventPortalSettings> fetchEventSettings() async {
    final res = await http.get(_uri('/api/events/settings'), headers: await _headers());
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Failed to load event settings');
    }
    return EventPortalSettings(
      settings: PlatformSettings.fromJson(body['settings'] as Map<String, dynamic>? ?? {}),
      publishableKey: body['publishableKey'] as String?,
    );
  }

  Future<EventPaymentIntent> createEventPaymentIntent() async {
    final res = await http.post(_uri('/api/events/create-intent'), headers: await _headers());
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Failed to start payment');
    }
    final clientSecret = body['clientSecret'] as String?;
    final paymentIntentId = body['paymentIntentId'] as String?;
    if (clientSecret == null || paymentIntentId == null) {
      throw StateError('Invalid payment response from server');
    }
    return EventPaymentIntent(
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
      fee: _toDouble(body['fee']),
    );
  }

  Future<SubmitEventResult> submitEvent({
    required BusinessEventDraft draft,
    required String mode,
    String? paymentIntentId,
  }) async {
    final res = await http.post(
      _uri('/api/events'),
      headers: await _headers(),
      body: jsonEncode(_payload(draft, mode, paymentIntentId)),
    );
    final body = _decode(res);
    if (res.statusCode != 200) {
      throw StateError(body['error'] as String? ?? 'Failed to save event');
    }
    final ids = (body['ids'] as List<dynamic>? ?? const [])
        .map((id) => id as String)
        .toList();
    return SubmitEventResult(
      ids: ids,
      status: body['status'] as String? ?? 'pending_review',
    );
  }

  Map<String, dynamic> _payload(BusinessEventDraft draft, String mode, String? paymentIntentId) {
    final primaryDay = DateTime(draft.startsAt.year, draft.startsAt.month, draft.startsAt.day);
    final extraDates = draft.additionalDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => d != primaryDay)
        .map(_toIsoDate)
        .toSet()
        .toList()
      ..sort();

    return {
      if (draft.id != null) 'id': draft.id,
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'event_type': draft.eventType,
      'neighborhood': draft.neighborhood,
      'starts_at': _toLocalDatetime(draft.startsAt),
      if (draft.endsAt != null) 'ends_at': _toLocalDatetime(draft.endsAt!),
      if (draft.imageUrl.trim().isNotEmpty) 'image_url': draft.imageUrl.trim(),
      'additional_dates': extraDates,
      if (draft.recurrence != null) 'recurrence': draft.recurrence!.toJson(),
      'ticket_tiers': normalizeTicketTiers(draft.ticketTiers).map((t) => t.toJson()).toList(),
      'mode': mode,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
    };
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _toLocalDatetime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)}T${_pad(local.hour)}:${_pad(local.minute)}';
  }

  String _toIsoDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
