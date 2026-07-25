import 'package:flutter/material.dart';

import '../../screens/wtva/stripe_payment_screen.dart';
import '../../services/stripe_bootstrap.dart';
import 'stripe_card_pay_sheet.dart';

/// Collect payment with the same methods as web (Card, Bank, Cash App, Apple Pay…).
///
/// Opens a full-screen Payment page — no “open card checkout?” modals.
Future<void> collectStripePayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
  String? mobilePayUrl,
}) async {
  await StripeBootstrap.ensureReady();
  if (!context.mounted) throw StateError('Payment cancelled');

  final url = mobilePayUrl?.trim();
  if (url != null && url.isNotEmpty) {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StripePaymentScreen(
          checkoutUrl: url,
          amountLabel: amountLabel,
        ),
      ),
    );
    if (paid == true) return;
    throw StateError('Payment cancelled');
  }

  // Backend hasn’t returned a checkout URL yet — try native PaymentSheet
  // (Apple Pay / Google Pay / card / etc.), then full-screen card.
  if (!context.mounted) throw StateError('Payment cancelled');
  try {
    await StripeBootstrap.presentPaymentSheet(clientSecret: clientSecret);
    return;
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      throw StateError('Payment cancelled');
    }
    debugPrint('PaymentSheet unavailable, using card screen: $e');
  }

  if (!context.mounted) throw StateError('Payment cancelled');
  await collectCardPayment(
    context,
    clientSecret: clientSecret,
    amountLabel: amountLabel,
  );
}
