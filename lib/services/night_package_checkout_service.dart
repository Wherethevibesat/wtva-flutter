import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import '../services/customer_portal_api.dart';
import '../services/stripe_settings_repository.dart';

class NightPackageCheckoutService {
  NightPackageCheckoutService._();
  static final NightPackageCheckoutService instance =
      NightPackageCheckoutService._();

  final _api = CustomerPortalApi.instance;
  final _stripeSettings = StripeSettingsRepository.instance;

  Future<NightPackagePaymentIntent> purchase({
    required String packageId,
    required int partySize,
    required List<String> stopOfferIds,
  }) async {
    if (stopOfferIds.isEmpty) {
      throw StateError('Add at least one stop to your plan');
    }

    final publishableKey = await _stripeSettings.fetchPublishableKey();
    if (publishableKey == null || publishableKey.isEmpty) {
      throw StateError('Checkout is not available yet.');
    }
    await _ensureStripe(publishableKey);

    final intent = await _api.createNightPackageIntent(
      packageId: packageId,
      partySize: partySize,
      stopOfferIds: stopOfferIds,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: AppBrand.name,
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

    await _api.confirmNightPackagePayment(intent.paymentIntentId);
    return intent;
  }

  Future<void> _ensureStripe(String publishableKey) async {
    if (Stripe.publishableKey != publishableKey) {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    }
  }
}
