import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import '../theme/figma_theme.dart';
import 'stripe_settings_repository.dart';

/// Shared Stripe PaymentSheet setup for tickets, vibes, and business flows.
class StripeBootstrap {
  StripeBootstrap._();

  static const urlScheme = 'wherethevibesat';
  static const returnUrl = '$urlScheme://stripe-redirect';

  static bool _configured = false;

  /// Loads publishable key + applies urlScheme. Throws a user-facing [StateError].
  static Future<void> ensureReady() async {
    final key = await StripeSettingsRepository.instance.fetchPublishableKey();
    if (key == null || key.isEmpty) {
      throw StateError(
        'Checkout is not available yet — Stripe publishable key missing. '
        'Set it in Admin → Stripe, or NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY on the customer site.',
      );
    }

    final needsApply =
        !_configured || Stripe.publishableKey != key || Stripe.urlScheme != urlScheme;

    if (needsApply) {
      Stripe.publishableKey = key;
      Stripe.urlScheme = urlScheme;
      await Stripe.instance.applySettings();
      _configured = true;
    }
  }

  static PaymentSheetAppearance get lightAppearance => PaymentSheetAppearance(
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
      );

  static Future<void> presentPaymentSheet({
    required String clientSecret,
  }) async {
    await ensureReady();

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: AppBrand.name,
        style: ThemeMode.light,
        appearance: lightAppearance,
        returnURL: returnUrl,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        throw StateError('Payment cancelled');
      }
      throw StateError(e.error.localizedMessage ?? 'Payment failed');
    }
  }
}
