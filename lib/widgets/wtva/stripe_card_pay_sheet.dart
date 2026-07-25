import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../services/stripe_bootstrap.dart';
import '../../theme/figma_theme.dart';

/// Full-screen card entry — last resort when wallet checkout URL / PaymentSheet
/// are unavailable. No intermediate confirmation dialogs.
Future<void> collectCardPayment(
  BuildContext context, {
  required String clientSecret,
  required String amountLabel,
}) async {
  await StripeBootstrap.ensureReady();

  if (!context.mounted) {
    throw StateError('Payment cancelled');
  }

  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _StripeCardPayPage(
        clientSecret: clientSecret,
        amountLabel: amountLabel,
      ),
    ),
  );

  if (paid != true) {
    throw StateError('Payment cancelled');
  }
}

class _StripeCardPayPage extends StatefulWidget {
  const _StripeCardPayPage({
    required this.clientSecret,
    required this.amountLabel,
  });

  final String clientSecret;
  final String amountLabel;

  @override
  State<_StripeCardPayPage> createState() => _StripeCardPayPageState();
}

class _StripeCardPayPageState extends State<_StripeCardPayPage> {
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
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        foregroundColor: WtvaColors.neutral50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total ${widget.amountLabel}',
                style: const TextStyle(
                  fontSize: 15,
                  color: WtvaColors.neutral300,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Card',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: WtvaColors.neutral50,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: WtvaColors.dark400,
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
                  style:
                      const TextStyle(color: Color(0xFFF87171), fontSize: 13),
                ),
              ],
              const Spacer(),
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
                  _busy ? 'Processing…' : 'Pay ${widget.amountLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
