import 'package:flutter/material.dart';

import '../../services/stripe_bootstrap.dart';
import 'stripe_card_pay_sheet.dart';

/// Collect payment for vibes / tickets.
///
/// Always uses the in-app Checkout card form. Stripe's native PaymentSheet has
/// been hanging on iOS (Simulator and TestFlight) without presenting UI — card
/// form is the reliable path. Wallets remain available on web.
Future<void> collectStripePayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
}) async {
  await StripeBootstrap.ensureReady();
  if (!context.mounted) throw StateError('Payment cancelled');

  await collectCardPayment(
    context,
    clientSecret: clientSecret,
    amountLabel: amountLabel,
  );
}
