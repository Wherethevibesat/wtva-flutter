import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import '../services/business_events_repository.dart';
import '../services/business_portal_api.dart';
import '../services/platform_settings.dart';

class BusinessEventSubmissionService {
  BusinessEventSubmissionService._();
  static final BusinessEventSubmissionService instance = BusinessEventSubmissionService._();

  final _api = BusinessPortalApi.instance;

  Future<EventPortalSettings> loadSettings() => _api.fetchEventSettings();

  Future<SubmitEventResult> submitForReview(BusinessEventDraft draft) {
    return _api.submitEvent(draft: draft, mode: 'review');
  }

  Future<SubmitEventResult> payAndPublish({
    required BusinessEventDraft draft,
    required String publishableKey,
  }) async {
    await _ensureStripe(publishableKey);

    final intent = await _api.createEventPaymentIntent();
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

    return _api.submitEvent(
      draft: draft,
      mode: 'paid',
      paymentIntentId: intent.paymentIntentId,
    );
  }

  Future<void> _ensureStripe(String publishableKey) async {
    if (publishableKey.isEmpty) {
      throw StateError('Stripe is not configured. Contact support or submit for review.');
    }
    if (Stripe.publishableKey != publishableKey) {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    }
  }

  void assertReviewAllowed(PlatformSettings settings, {bool stripeConfigured = true}) {
    if (settings.requirePayment && settings.eventSubmissionFee > 0 && stripeConfigured) {
      throw StateError(
        'Payment of \$${settings.eventSubmissionFee.toStringAsFixed(2)} is required to post events.',
      );
    }
  }
}
