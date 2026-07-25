import 'package:flutter/material.dart';

import '../data/ticket_tier.dart';
import '../services/customer_portal_api.dart';
import '../services/stripe_bootstrap.dart';
import '../services/supabase_bootstrap.dart';
import '../widgets/wtva/stripe_collect_payment.dart';

class EventTicketCheckoutService {
  EventTicketCheckoutService._();
  static final EventTicketCheckoutService instance =
      EventTicketCheckoutService._();

  final _api = CustomerPortalApi.instance;

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
    required BuildContext context,
    required String eventId,
    required EventTicketTierRecord tier,
  }) async {
    if (tier.priceCents <= 0) {
      throw StateError('Use Free RSVP for this tier');
    }

    final token =
        SupabaseBootstrap.client?.auth.currentSession?.accessToken ?? '';
    if (token.isEmpty) {
      throw StateError('Sign in to continue.');
    }

    await StripeBootstrap.ensureReady();

    final intent = await _api.createEventTicketIntent(
      eventId: eventId,
      tierId: tier.id,
    );

    if (!context.mounted) throw StateError('Payment cancelled');
    final dollars = tier.priceCents / 100;
    final whole = dollars == dollars.roundToDouble();
    await collectStripePayment(
      context,
      clientSecret: intent.clientSecret,
      amountLabel: '\$${dollars.toStringAsFixed(whole ? 0 : 2)}',
    );

    await _api.confirmEventTicketPayment(intent.paymentIntentId);
  }
}
