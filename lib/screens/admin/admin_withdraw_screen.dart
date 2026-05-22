import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_stripe_keys_screen.dart';

class AdminWithdrawScreen extends StatefulWidget {
  final double availableBalance;

  const AdminWithdrawScreen({
    super.key,
    required this.availableBalance,
  });

  @override
  State<AdminWithdrawScreen> createState() => _AdminWithdrawScreenState();
}

class _AdminWithdrawScreenState extends State<AdminWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedAccount;
  bool _isProcessing = false;

  String? _selectedBankAccount;
  
  // Mock bank accounts (in production, fetch from Stripe)
  final List<Map<String, dynamic>> _bankAccounts = [
    {
      'id': 'ba_1',
      'name': 'Primary Bank Account',
      'last4': '4242',
      'bank_name': 'Chase',
      'isDefault': true,
    },
    {
      'id': 'ba_2',
      'name': 'Business Account',
      'last4': '8888',
      'bank_name': 'Wells Fargo',
      'isDefault': false,
    },
  ];

  // Mock withdrawal history
  final List<Map<String, dynamic>> _withdrawalHistory = [
    {
      'id': 'w1',
      'amount': 5000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'account': 'Primary Account (****4242)',
      'stripePayoutId': 'po_1234567890',
    },
    {
      'id': 'w2',
      'amount': 3000.0,
      'status': 'pending',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'account': 'Primary Account (****4242)',
      'stripePayoutId': 'po_0987654321',
    },
    {
      'id': 'w3',
      'amount': 2000.0,
      'status': 'completed',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'account': 'Business Account (****8888)',
      'stripePayoutId': 'po_1122334455',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default account
    final defaultAccount = _bankAccounts.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => _bankAccounts.first,
    );
    _selectedBankAccount = defaultAccount['id'] as String;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _enteredAmount {
    if (_amountController.text.isEmpty) return null;
    return double.tryParse(_amountController.text);
  }

  bool get _canWithdraw {
    final amount = _enteredAmount;
    return amount != null &&
        amount > 0 &&
        amount <= widget.availableBalance &&
        _selectedBankAccount != null;
  }

  void _initiateWithdrawal() {
    if (!_formKey.currentState!.validate() || !_canWithdraw) return;

    final amount = _enteredAmount!;
    final account = _bankAccounts.firstWhere((a) => a['id'] == _selectedBankAccount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${NumberFormat('#,##0.00').format(amount)}'),
            const SizedBox(height: 8),
            Text('Account: ${account['name']} (****${account['last4']})'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Withdrawals typically take 2-5 business days to process.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isProcessing = true;
              });

              // TODO: Implement actual Stripe withdrawal API call
              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Withdrawal initiated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Clear form
                _amountController.clear();
                setState(() {});
              }
            },
            child: const Text('Confirm Withdrawal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Earnings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Available Balance Card
          Card(
            color: theme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Available Balance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.availableBalance),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to withdraw',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Withdrawal Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw to Stripe',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount to withdraw',
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: 'USD',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > widget.availableBalance) {
                          return 'Amount exceeds available balance';
                        }
                        if (amount < 10) {
                          return 'Minimum withdrawal is \$10';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimum withdrawal: \$10.00',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),

                    // Bank Account Selection
                    Text(
                      'Select Bank Account',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._bankAccounts.map((account) => RadioListTile<String>(
                          title: Text(account['name']),
                          subtitle: Text('${account['bank_name']} • ****${account['last4']}'),
                          value: account['id'] as String,
                          groupValue: _selectedBankAccount,
                          onChanged: (value) {
                            setState(() {
                              _selectedBankAccount = value;
                            });
                          },
                          secondary: account['isDefault']
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : null,
                        )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminStripeKeysScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure Stripe API Keys'),
                    ),
                    const SizedBox(height: 24),

                    // Withdraw Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _canWithdraw && !_isProcessing
                            ? _initiateWithdrawal
                            : null,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.account_balance_wallet),
                        label: Text(_isProcessing ? 'Processing...' : 'Withdraw to Stripe'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Withdrawal History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Withdrawal History',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: View all withdrawals
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_withdrawalHistory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No withdrawals yet',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._withdrawalHistory.take(5).map((withdrawal) => _WithdrawalHistoryItem(
                          withdrawal: withdrawal,
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalHistoryItem extends StatelessWidget {
  final Map<String, dynamic> withdrawal;

  const _WithdrawalHistoryItem({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final isCompleted = withdrawal['status'] == 'completed';
    final isPending = withdrawal['status'] == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPending ? Colors.orange.withOpacity(0.05) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.pending,
            color: isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          currencyFormat.format(withdrawal['amount']),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(withdrawal['account']),
            Text(dateFormat.format(withdrawal['date'])),
            if (withdrawal['stripePayoutId'] != null)
              Text(
                'Payout ID: ${withdrawal['stripePayoutId']}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            withdrawal['status'].toString().toUpperCase(),
            style: TextStyle(
              color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

