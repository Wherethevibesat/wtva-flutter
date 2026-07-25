import 'package:flutter/material.dart';

import '../../services/stripe_bootstrap.dart';
import '../../theme/figma_theme.dart';
import 'stripe_card_pay_sheet.dart';

/// Collect payment with the same method mix as web when possible.
///
/// 1. Prefer Stripe PaymentSheet (Apple Pay, Cash App, Link, bank, card, …)
/// 2. On iOS Simulator (or PaymentSheet failure), fall back to in-app card form
Future<void> collectStripePayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
}) async {
  await StripeBootstrap.ensureReady();
  if (!context.mounted) throw StateError('Payment cancelled');

  // Simulator: PaymentSheet often hangs invisible — use card UI (still works).
  if (StripeBootstrap.isIosSimulator) {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WtvaColors.dark400,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How do you want to pay?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: WtvaColors.neutral50,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'On a real iPhone you’ll get Apple Pay and other wallets '
                'automatically. Simulator is limited — pick an option:',
                style: TextStyle(fontSize: 13, color: WtvaColors.neutral300),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'sheet'),
                style: FilledButton.styleFrom(
                  backgroundColor: WtvaColors.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Try wallets & more (PaymentSheet)'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'card'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WtvaColors.neutral50,
                  side: BorderSide(
                    color: WtvaColors.night200.withValues(alpha: 0.9),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Pay $amountLabel with card'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: WtvaColors.neutral300),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) throw StateError('Payment cancelled');
    if (choice == null || choice == 'cancel') {
      throw StateError('Payment cancelled');
    }
    if (choice == 'card') {
      await collectCardPayment(
        context,
        clientSecret: clientSecret,
        amountLabel: amountLabel,
      );
      return;
    }
    // fall through to PaymentSheet
  }

  try {
    await StripeBootstrap.presentPaymentSheet(clientSecret: clientSecret);
  } catch (e) {
    final msg = e is StateError ? e.message : e.toString();
    if (msg == 'Payment cancelled' || msg.contains('Payment cancelled')) {
      rethrow;
    }
    debugPrint('PaymentSheet failed, falling back to card: $e');
    if (!context.mounted) throw StateError('Payment cancelled');

    final useCard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WtvaColors.dark400,
        title: const Text(
          'Open card payment?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: WtvaColors.neutral50,
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(color: WtvaColors.neutral200, height: 1.4),
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
              'Pay with card',
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
