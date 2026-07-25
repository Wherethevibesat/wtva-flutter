import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import '../theme/figma_theme.dart';
import 'stripe_settings_repository.dart';

/// Shared Stripe setup for tickets, vibes, and business flows.
class StripeBootstrap {
  StripeBootstrap._();

  static const urlScheme = 'wherethevibesat';
  static const returnUrl = '$urlScheme://stripe-redirect';

  /// Must match Apple Developer → Identifiers → Merchant IDs + Runner.entitlements.
  static const merchantIdentifier = 'merchant.com.wherethevibesat';

  static bool _configured = false;
  static Future<void>? _readyFuture;

  /// iOS Simulator often can't present PaymentSheet / Apple Pay reliably.
  /// Dart may not inherit SIMULATOR_* env vars, so also treat debug iOS as sim-like.
  static bool get isIosSimulator {
    if (kIsWeb || !Platform.isIOS) return false;
    if (Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_UDID') ||
        Platform.environment.containsKey('SIMULATOR_HOST_HOME')) {
      return true;
    }
    // Fallback: debug/profile builds on iOS are usually the Simulator for us.
    return !kReleaseMode;
  }

  static Future<void> warmUp() {
    return ensureReady().catchError((Object e, StackTrace st) {
      debugPrint('StripeBootstrap.warmUp failed: $e');
    });
  }

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
        if (Platform.isIOS) {
          Stripe.merchantIdentifier = merchantIdentifier;
        }
        await Stripe.instance.applySettings().timeout(
              const Duration(seconds: 12),
              onTimeout: () {
                throw StateError('Stripe setup timed out. Try again.');
              },
            );
        _configured = true;
      }
      debugPrint('StripeBootstrap: ready (simulator=$isIosSimulator)');
    } catch (e) {
      _readyFuture = null;
      rethrow;
    }
  }

  /// Full PaymentSheet (wallets / bank / card) — same method mix as web Payment Element.
  static Future<void> presentPaymentSheet({
    required String clientSecret,
  }) async {
    await ensureReady();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    debugPrint('StripeBootstrap: initPaymentSheet…');
    try {
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: AppBrand.name,
              style: ThemeMode.system,
              returnURL: returnUrl,
              appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(
                  primary: WtvaColors.accentPurple,
                  background: WtvaColors.dark400,
                  componentBackground: WtvaColors.dark500,
                  componentBorder: WtvaColors.night200,
                  componentDivider: WtvaColors.night200,
                  primaryText: WtvaColors.neutral50,
                  secondaryText: WtvaColors.neutral200,
                  componentText: WtvaColors.neutral50,
                  placeholderText: WtvaColors.neutral300,
                  icon: WtvaColors.neutral200,
                  error: const Color(0xFFDC2626),
                ),
                shapes: const PaymentSheetShape(
                  borderRadius: 14,
                  borderWidth: 1,
                ),
              ),
              applePay: Platform.isIOS
                  ? const PaymentSheetApplePay(merchantCountryCode: 'US')
                  : null,
              googlePay: Platform.isAndroid
                  ? PaymentSheetGooglePay(
                      merchantCountryCode: 'US',
                      testEnv: !kReleaseMode,
                    )
                  : null,
              allowsDelayedPaymentMethods: true,
            ),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw StateError('Payment form setup timed out.');
            },
          );
    } on StripeException catch (e) {
      throw StateError(
        e.error.localizedMessage ?? 'Could not open payment form',
      );
    }

    debugPrint('StripeBootstrap: presenting PaymentSheet…');
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        throw StateError('Payment cancelled');
      }
      throw StateError(e.error.localizedMessage ?? 'Payment failed');
    }
    debugPrint('StripeBootstrap: PaymentSheet completed');
  }
}
