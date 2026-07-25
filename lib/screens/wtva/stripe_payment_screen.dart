import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/stripe_bootstrap.dart';
import '../../theme/figma_theme.dart';

/// Full-screen Payment page (DoorDash-style): Stripe Payment Element with
/// Card, Bank, Cash App, Apple Pay, etc. — no intermediate modals.
class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.amountLabel,
  });

  final String checkoutUrl;
  final String amountLabel;

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(WtvaColors.dark500)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = err.description;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;

            if (uri.scheme == StripeBootstrap.urlScheme &&
                (uri.host == 'pay-complete' ||
                    uri.path.contains('pay-complete'))) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }

            // Stripe / our done page — success.
            if (uri.path.contains('/pay/mobile/done')) {
              // Let it load briefly, then complete.
              Future<void>.delayed(const Duration(milliseconds: 400), () {
                if (mounted) Navigator.of(context).pop(true);
              });
              return NavigationDecision.navigate;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
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
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Total ${widget.amountLabel}',
              style: const TextStyle(
                color: WtvaColors.neutral300,
                fontSize: 15,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFF87171)),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: WtvaColors.accentPurple,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
