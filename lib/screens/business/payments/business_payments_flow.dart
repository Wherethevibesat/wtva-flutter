import 'package:flutter/material.dart';
import '../../../services/business_service.dart';
import '../../../theme/figma_theme.dart';
import '../../../utils/wtva_feedback.dart';
import '../../../widgets/business/business_widgets.dart';
import '../../../widgets/wtva/wtva_gradient_button.dart';
import '../../../data/mock_business_data.dart';

/// #05 Payments — bank / PayPal flow.
class BusinessPaymentsScreen extends StatelessWidget {
  const BusinessPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusinessService.instance,
      builder: (context, _) {
        final method = BusinessService.instance.payoutMethod;
        return Scaffold(
          backgroundColor: WtvaColors.dark500,
          appBar: AppBar(
            backgroundColor: WtvaColors.dark500,
            title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (method != null)
                BusinessCard(
                  child: Row(
                    children: [
                      Icon(method == 'paypal' ? Icons.account_balance_wallet : Icons.account_balance, color: WtvaColors.neutral200),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method == 'paypal' ? 'PayPal connected' : 'Bank account connected',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.check_circle, color: WtvaColors.neutral50, size: 20),
                    ],
                  ),
                ),
              BusinessMenuTile(
                icon: Icons.add_card,
                title: 'Add a bank or PayPal',
                subtitle: 'Receive payouts for bookings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessAddPayoutScreen())),
              ),
              BusinessMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Earnings history',
                subtitle: 'Demo — no payouts yet',
                onTap: () => showWtvaSnack(context, 'No payouts yet (demo)', icon: Icons.receipt_long),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusinessAddPayoutScreen extends StatelessWidget {
  const BusinessAddPayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Add payout method', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BusinessMenuTile(
            icon: Icons.account_balance,
            title: 'Bank account',
            subtitle: 'ACH transfer',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessSelectBankScreen())),
          ),
          BusinessMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'PayPal',
            subtitle: 'Connect PayPal email',
            onTap: () {
              BusinessService.instance.setPayoutMethod('paypal');
              Navigator.pop(context);
              showWtvaSnack(context, 'PayPal connected (demo)', icon: Icons.check);
            },
          ),
        ],
      ),
    );
  }
}

class BusinessSelectBankScreen extends StatelessWidget {
  const BusinessSelectBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: const Text('Select your bank', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          for (final bank in MockBusinessData.banks)
            ListTile(
              title: Text(bank, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, color: WtvaColors.neutral300),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusinessBankDetailsScreen(bankName: bank)),
              ),
            ),
        ],
      ),
    );
  }
}

class BusinessBankDetailsScreen extends StatefulWidget {
  final String bankName;

  const BusinessBankDetailsScreen({super.key, required this.bankName});

  @override
  State<BusinessBankDetailsScreen> createState() => _BusinessBankDetailsScreenState();
}

class _BusinessBankDetailsScreenState extends State<BusinessBankDetailsScreen> {
  final _routing = TextEditingController(text: '111000025');
  final _account = TextEditingController(text: '000123456789');

  @override
  void dispose() {
    _routing.dispose();
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WtvaColors.dark500,
      appBar: AppBar(
        backgroundColor: WtvaColors.dark500,
        title: Text(widget.bankName, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _routing, decoration: const InputDecoration(labelText: 'Routing number')),
          const SizedBox(height: 16),
          TextField(controller: _account, decoration: const InputDecoration(labelText: 'Account number')),
          const SizedBox(height: 32),
          WtvaGradientButton(
            label: 'Save bank details',
            onPressed: () {
              BusinessService.instance.setPayoutMethod('bank');
              Navigator.popUntil(context, (r) => r.isFirst);
              showWtvaSnack(context, 'Bank account saved (demo)', icon: Icons.account_balance);
            },
          ),
        ],
      ),
    );
  }
}
