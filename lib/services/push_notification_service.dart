import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'supabase_bootstrap.dart';
import 'user_service.dart';

/// Registers FCM device tokens with Supabase for admin push broadcasts.
///
/// Requires Firebase native config (`google-services.json` / `GoogleService-Info.plist`).
/// If Firebase is not configured, this service no-ops safely.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _available = false;
  String? _token;

  bool get isAvailable => _available;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _available = true;
    } catch (e) {
      debugPrint('Push: Firebase not configured ($e)');
      _available = false;
      return;
    }

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push: permission denied');
      return;
    }

    // iOS: wait for APNs before getToken
    if (Platform.isIOS) {
      await messaging.getAPNSToken();
    }

    _token = await messaging.getToken();
    if (_token != null) {
      await _upsertToken(_token!);
    }

    messaging.onTokenRefresh.listen((token) async {
      _token = token;
      await _upsertToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Push foreground: ${message.notification?.title ?? message.data}',
      );
    });
  }

  /// Call after a real user signs in (not guest).
  Future<void> syncForSignedInUser() async {
    if (!_available) return;
    final user = UserService().currentUser;
    if (user == null || UserService().isGuest || !UserService().isLoggedIn) {
      return;
    }
    _token ??= await FirebaseMessaging.instance.getToken();
    if (_token != null) await _upsertToken(_token!);
  }

  Future<void> setEnabled(bool enabled) async {
    if (!_available) return;
    final client = SupabaseBootstrap.client;
    final user = UserService().currentUser;
    if (client == null || user == null || UserService().isGuest) return;

    if (!enabled) {
      await client
          .from('device_push_tokens')
          .update({
            'enabled': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', user.id);
      return;
    }

    await messagingEnsurePermissionAndToken();
  }

  Future<void> messagingEnsurePermissionAndToken() async {
    if (!_available) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    _token = await messaging.getToken();
    if (_token != null) await _upsertToken(_token!);
  }

  Future<void> clearForSignOut() async {
    if (!_available) return;
    final client = SupabaseBootstrap.client;
    final token = _token;
    if (client == null || token == null) return;
    try {
      await client.from('device_push_tokens').delete().eq('token', token);
    } catch (_) {
      // Best-effort cleanup
    }
  }

  Future<void> _upsertToken(String token) async {
    final client = SupabaseBootstrap.client;
    final user = UserService().currentUser;
    if (client == null || user == null || UserService().isGuest) return;
    if (!UserService().isLoggedIn) return;

    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'web';
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await client.from('device_push_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'app': 'customer',
          'enabled': true,
          'last_seen_at': now,
          'updated_at': now,
        },
        onConflict: 'token',
      );
    } catch (e) {
      debugPrint('Push: failed to upsert token ($e)');
    }
  }
}

/// Top-level handler required by firebase_messaging for background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Ignore — background delivery still surfaces via system tray when configured.
  }
}
