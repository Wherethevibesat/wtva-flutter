import 'package:flutter/material.dart';

import '../../services/stripe_bootstrap.dart';
import '../../theme/figma_theme.dart';
import 'stripe_card_pay_sheet.dart';

/// Collect payment with the same method mix as web when possible.
///
/// Real device → Stripe sheet (Apple Pay, Cash App, Link, bank, card, …).
/// Simulator → in-app card checkout (native sheet is unreliable in Simulator).
Future<void> collectStripePayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
}) async {
  await StripeBootstrap.ensureReady();
  if (!context.mounted) throw StateError('Payment cancelled');

  // Simulator: skip jargon chooser — card checkout just works here.
  if (StripeBootstrap.isIosSimulator) {
    await collectCardPayment(
      context,
      clientSecret: clientSecret,
      amountLabel: amountLabel,
    );
    return;
  }

  try {
    await StripeBootstrap.presentPaymentSheet(clientSecret: clientSecret);
  } catch (e) {
    final msg = e is StateError ? e.message : e.toString();
    if (msg == 'Payment cancelled' || msg.contains('Payment cancelled')) {
      rethrow;
    }
    debugPrint('Checkout sheet failed, falling back to card: $e');
    if (!context.mounted) throw StateError('Payment cancelled');

    final useCard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WtvaColors.dark400,
        title: const Text(
          'Couldn’t open checkout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: WtvaColors.neutral50,
          ),
        ),
        content: const Text(
          'Want to enter your card details instead?',
          style: TextStyle(color: WtvaColors.neutral200, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: WtvaColors.neutral300),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: WtvaColors.accentPurple),
            ),
          ),
        ],
      ),
    );

    if (useCard != true || !context.mounted) {
      throw StateError('Payment cancelled');
    }
    await collectCardPayment(
      context,
      clientSecret: clientSecret,
      amountLabel: amountLabel,
    );
  }
}
