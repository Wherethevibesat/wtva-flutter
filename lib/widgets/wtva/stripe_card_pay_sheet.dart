import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../services/stripe_bootstrap.dart';
import '../../theme/figma_theme.dart';

/// In-app card entry — avoids native PaymentSheet which can hang invisible on iOS.
Future<void> collectCardPayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
}) async {
  await StripeBootstrap.ensureReady();

  if (!context.mounted) {
    throw StateError('Payment cancelled');
  }

  final paid = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: WtvaColors.dark400,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: _StripeCardPaySheet(
        clientSecret: clientSecret,
        amountLabel: amountLabel,
      ),
    ),
  );

  if (paid != true) {
    throw StateError('Payment cancelled');
  }
}

class _StripeCardPaySheet extends StatefulWidget {
  const _StripeCardPaySheet({
    required this.clientSecret,
    required this.amountLabel,
  });

  final String clientSecret;
  final String amountLabel;

  @override
  State<_StripeCardPaySheet> createState() => _StripeCardPaySheetState();
}

class _StripeCardPaySheetState extends State<_StripeCardPaySheet> {
  var _complete = false;
  var _busy = false;
  String? _error;

  Future<void> _pay() async {
    if (!_complete || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        Navigator.of(context).pop(false);
        return;
      }
      setState(() {
        _error = e.error.localizedMessage ?? 'Payment failed';
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: WtvaColors.night200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Checkout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WtvaColors.neutral50,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total ${widget.amountLabel}',
              style: const TextStyle(
                fontSize: 14,
                color: WtvaColors.neutral300,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: WtvaColors.dark500,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WtvaColors.night200.withValues(alpha: 0.7),
                ),
              ),
              child: CardField(
                enablePostalCode: true,
                onCardChanged: (details) {
                  setState(() => _complete = details?.complete ?? false);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: WtvaColors.neutral50,
                  fontSize: 16,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (_complete && !_busy) ? _pay : null,
              style: FilledButton.styleFrom(
                backgroundColor: WtvaColors.accentPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    WtvaColors.accentPurple.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _busy ? 'Processing…' : 'Pay ${widget.amountLabel} now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: WtvaColors.neutral300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
