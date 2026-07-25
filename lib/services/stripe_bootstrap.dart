import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import 'stripe_settings_repository.dart';

/// Shared Stripe PaymentSheet setup for tickets, vibes, and business flows.
class StripeBootstrap {
  StripeBootstrap._();

  static const urlScheme = 'wherethevibesat';
  static const returnUrl = '$urlScheme://stripe-redirect';

  static bool _configured = false;
  static Future<void>? _readyFuture;

  /// Warm Stripe at app start so the first Pay tap isn’t cold.
  static Future<void> warmUp() {
    return ensureReady().catchError((Object e, StackTrace st) {
      debugPrint('StripeBootstrap.warmUp failed: $e');
    });
  }

  /// Loads publishable key + applies urlScheme. Throws a user-facing [StateError].
  static Future<void> ensureReady() {
    return _readyFuture ??= _ensureReadyImpl();
  }

  static Future<void> _ensureReadyImpl() async {
    try {
      debugPrint('StripeBootstrap: fetching publishable key…');
      final key = await StripeSettingsRepository.instance
          .fetchPublishableKey()
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => null,
          );
      if (key == null || key.isEmpty) {
        _readyFuture = null;
        throw StateError(
          'Checkout is not available yet — Stripe publishable key missing.',
        );
      }

      if (!_configured || Stripe.publishableKey != key) {
        debugPrint(
          'StripeBootstrap: applySettings ${key.substring(0, 10)}…',
        );
        Stripe.publishableKey = key;
        Stripe.urlScheme = urlScheme;
        await Stripe.instance.applySettings().timeout(
              const Duration(seconds: 12),
              onTimeout: () {
                throw StateError('Stripe setup timed out. Try again.');
              },
            );
        _configured = true;
      }
      debugPrint('StripeBootstrap: ready');
    } catch (e) {
      _readyFuture = null;
      rethrow;
    }
  }

  static Future<void> presentPaymentSheet({
    required String clientSecret,
  }) async {
    await ensureReady();

    // Yield so disabled-button rebuild finishes before the native modal.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    debugPrint('StripeBootstrap: initPaymentSheet…');
    try {
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: AppBrand.name,
              style: ThemeMode.system,
              returnURL: returnUrl,
              // Keep sheet simple — custom appearance has caused blank/hang issues.
              allowsDelayedPaymentMethods: false,
            ),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw StateError(
                'Payment form setup timed out. Try again in a moment.',
              );
            },
          );
    } on StripeException catch (e) {
      debugPrint('StripeBootstrap init error: ${e.error}');
      throw StateError(
        e.error.localizedMessage ?? 'Could not open payment form',
      );
    }

    debugPrint('StripeBootstrap: presenting PaymentSheet…');
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      debugPrint('StripeBootstrap present error: ${e.error}');
      if (e.error.code == FailureCode.Canceled) {
        throw StateError('Payment cancelled');
      }
      throw StateError(e.error.localizedMessage ?? 'Payment failed');
    }
    debugPrint('StripeBootstrap: PaymentSheet completed');
  }
}
