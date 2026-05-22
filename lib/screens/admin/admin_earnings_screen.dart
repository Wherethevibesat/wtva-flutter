import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_withdraw_screen.dart';
import 'admin_stripe_accounts_screen.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month'; // day, week, month, year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock earnings data
  final Map<String, double> _earnings = {
    'total': 12500.0,
    'thisMonth': 3200.0,
    'thisWeek': 850.0,
    'today': 150.0,
    'venueSubmissions': 7500.0,
    'eventSubmissions': 5000.0,
  };

  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'id': 't1',
      'type': 'venue_submission',
      'amount': 50.0,
      'description': 'Venue: The New Club',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'completed',
      'user': 'John Doe',
    },
    {
      'id': 't2',
      'type': 'event_submission',
      'amount': 25.0,
      'description': 'Event: Friday Night Party',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
      'status': 'completed',
      'user': 'Jane Smith',
    },
    {
      'id': 't3',
      'type': 'venue_submission',
      'amount': 50.0,
      'description': 'Venue: Rooftop Lounge',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'pending',
      'user': 'Mike Johnson',
    },
    {
      'id': 't4',
      'type': 'event_submission',
      'amount': 25.0,
      'description': 'Event: Live DJ Set',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'completed',
      'user': 'Sarah Williams',
    },
  ];

  final List<Map<String, dynamic>> _pendingPayments = [
    {
      'id': 'p1',
      'type': 'venue_submission',
      'amount': 50.0,
      'description': 'Venue: The New Club',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'user': 'John Doe',
      'submissionId': 'v1',
    },
    {
      'id': 'p2',
      'type': 'event_submission',
      'amount': 25.0,
      'description': 'Event: Weekend Party',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'user': 'Jane Smith',
      'submissionId': 'e1',
    },
  ];

  double get _pendingTotal => _pendingPayments.fold(0.0, (sum, p) => sum + (p['amount'] as double));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Earnings'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Total Earnings Card
              Card(
                color: theme.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Total Platform Earnings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(_earnings['total']),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminWithdrawScreen(
                                  availableBalance: _earnings['total']!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Withdraw to Stripe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Period Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Period',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _PeriodChip(
                            label: 'Today',
                            value: 'day',
                            selected: _selectedPeriod == 'day',
                            amount: _earnings['today']!,
                            onSelected: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
                          ),
                          _PeriodChip(
                            label: 'This Week',
                            value: 'week',
                            selected: _selectedPeriod == 'week',
                            amount: _earnings['thisWeek']!,
                            onSelected: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
                          ),
                          _PeriodChip(
                            label: 'This Month',
                            value: 'month',
                            selected: _selectedPeriod == 'month',
                            amount: _earnings['thisMonth']!,
                            onSelected: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
                          ),
                          _PeriodChip(
                            label: 'All Time',
                            value: 'year',
                            selected: _selectedPeriod == 'year',
                            amount: _earnings['total']!,
                            onSelected: (value) {
                              setState(() {
                                _selectedPeriod = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Revenue Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue Breakdown',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      _RevenueItem(
                        label: 'Venue Submissions',
                        amount: _earnings['venueSubmissions']!,
                        total: _earnings['total']!,
                        color: Colors.blue,
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 16),
                      _RevenueItem(
                        label: 'Event Submissions',
                        amount: _earnings['eventSubmissions']!,
                        total: _earnings['total']!,
                        color: Colors.purple,
                        icon: Icons.event,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stripe Accounts Quick Link
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminStripeAccountsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Stripe Accounts',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect or manage your Stripe accounts',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pending Payments
              if (_pendingPayments.isNotEmpty)
                Card(
                  color: Colors.orange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pending_actions, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Pending Payments',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currencyFormat.format(_pendingTotal),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_pendingPayments.length} payment(s) pending',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _tabController.animateTo(1);
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminWithdrawScreen(
                                        availableBalance: _earnings['total']!,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.account_balance_wallet),
                                label: const Text('Withdraw'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Transactions Tab
          Column(
            children: [
              // Pending Payments Section
              if (_pendingPayments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pending_actions, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Pending Payments',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._pendingPayments.map((payment) => _TransactionCard(
                            transaction: payment,
                            isPending: true,
                          )),
                    ],
                  ),
                ),

              // Recent Transactions
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Recent Transactions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._recentTransactions.map((transaction) => _TransactionCard(
                          transaction: transaction,
                          isPending: false,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final double amount;
  final Function(String) onSelected;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.amount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 12,
              color: selected ? theme.primaryColor : null,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: theme.primaryColor.withOpacity(0.2),
    );
  }
}

class _RevenueItem extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;

  const _RevenueItem({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final percentage = (amount / total * 100).toStringAsFixed(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: amount / total,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(amount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPending;

  const _TransactionCard({
    required this.transaction,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPending ? Colors.orange.withOpacity(0.05) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(transaction['type']).withOpacity(0.1),
          child: Icon(
            _getTypeIcon(transaction['type']),
            color: _getTypeColor(transaction['type']),
          ),
        ),
        title: Text(
          transaction['description'],
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${transaction['user']} • ${dateFormat.format(transaction['date'])}'),
            if (isPending)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(transaction['amount']),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: _getTypeColor(transaction['type']),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'venue_submission':
        return Icons.business;
      case 'event_submission':
        return Icons.event;
      default:
        return Icons.payment;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'venue_submission':
        return Colors.blue;
      case 'event_submission':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

