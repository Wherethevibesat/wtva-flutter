import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_brand.dart';
import '../data/ticket_tier.dart';
import '../services/customer_portal_api.dart';
import '../services/stripe_settings_repository.dart';

class EventTicketCheckoutService {
  EventTicketCheckoutService._();
  static final EventTicketCheckoutService instance = EventTicketCheckoutService._();

  final _api = CustomerPortalApi.instance;
  final _stripeSettings = StripeSettingsRepository.instance;

  Future<void> freeRsvp({
    required String eventId,
    required EventTicketTierRecord tier,
  }) async {
    if (tier.priceCents > 0) {
      throw StateError('This tier requires payment');
    }
    await _api.freeRsvp(eventId: eventId, tierId: tier.id);
  }

  Future<void> purchaseTicket({
    required String eventId,
    required EventTicketTierRecord tier,
  }) async {
    if (tier.priceCents <= 0) {
      throw StateError('Use Free RSVP for this tier');
    }

    final publishableKey = await _stripeSettings.fetchPublishableKey();
    if (publishableKey == null || publishableKey.isEmpty) {
      throw StateError('Ticket sales are not available yet.');
    }
    await _ensureStripe(publishableKey);

    final intent = await _api.createEventTicketIntent(
      eventId: eventId,
      tierId: tier.id,
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

    await _api.confirmEventTicketPayment(intent.paymentIntentId);
  }

  Future<void> _ensureStripe(String publishableKey) async {
    if (Stripe.publishableKey != publishableKey) {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
    }
  }
}
