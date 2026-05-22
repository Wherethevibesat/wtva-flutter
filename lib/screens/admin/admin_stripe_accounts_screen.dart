import 'package:flutter/material.dart';
import '../../services/stripe_service.dart';
import 'package:intl/intl.dart';
import 'admin_stripe_keys_screen.dart';

class AdminStripeAccountsScreen extends StatefulWidget {
  const AdminStripeAccountsScreen({super.key});

  @override
  State<AdminStripeAccountsScreen> createState() => _AdminStripeAccountsScreenState();
}

class _AdminStripeAccountsScreenState extends State<AdminStripeAccountsScreen> {
  bool _isLoading = true;
  final StripeService _stripeService = StripeService();

  // Connected Stripe accounts (loaded from database)
  List<Map<String, dynamic>> _stripeAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _stripeService.getConnectedAccounts();
      setState(() {
        _stripeAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading accounts: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToKeysScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminStripeKeysScreen(),
      ),
    ).then((_) {
      // Refresh accounts when returning
      _loadAccounts();
    });
  }


  Future<void> _setDefaultAccount(String accountId) async {
    try {
      await _stripeService.setDefaultAccount(accountId);
      await _loadAccounts(); // Refresh to get updated default status
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default account updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating default account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _disconnectAccount(String accountId) {
    final account = _stripeAccounts.firstWhere((a) => a['id'] == accountId);
    final isDefault = account['is_default'] == true || account['isDefault'] == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account?'),
        content: Text(
          isDefault
              ? 'This is your default account. You must set another account as default before disconnecting.'
              : 'Are you sure you want to disconnect ${account['name']}? You will no longer be able to receive payouts to this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isDefault && _stripeAccounts.length > 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please set another account as default first'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
                return;
              }

              try {
                await _stripeService.disconnectAccount(accountId);
                await _loadAccounts(); // Refresh accounts list
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account disconnected'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error disconnecting account: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Accounts'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Info
          Card(
            color: theme.primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'About Stripe Connect',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect your Stripe account to receive payouts from platform earnings. You can connect multiple accounts and set one as default.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Configure Stripe Keys Button
          Card(
            child: InkWell(
              onTap: _navigateToKeysScreen,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.vpn_key,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configure Stripe API Keys',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter your Stripe API keys to enable payouts',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Connected Accounts
          Text(
            'Connected Accounts',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_stripeAccounts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Stripe accounts connected',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect your first Stripe account to start receiving payouts',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._stripeAccounts.map((account) => _StripeAccountCard(
                  account: account,
                  onSetDefault: () => _setDefaultAccount(account['id']),
                  onDisconnect: () => _disconnectAccount(account['id']),
                )),
        ],
      ),
    );
  }
}

class _StripeAccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onSetDefault;
  final VoidCallback onDisconnect;

  const _StripeAccountCard({
    required this.account,
    required this.onSetDefault,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDefault = account['is_default'] == true || account['isDefault'] == true;
    final isActive = account['status'] == 'active';
    final accountName = account['account_name'] ?? account['name'] ?? 'Stripe Account';
    final last4 = account['last4'] ?? '****';
    final accountType = account['account_type'] ?? account['type'] ?? 'bank_account';
    final email = account['email'] ?? '';
    final stripeAccountId = account['stripe_account_id'] ?? account['stripeAccountId'] ?? '';
    final connectedAt = account['connected_at'] != null
        ? DateTime.parse(account['connected_at'])
        : (account['connectedAt'] != null
            ? account['connectedAt'] is DateTime
                ? account['connectedAt'] as DateTime
                : DateTime.parse(account['connectedAt'].toString())
            : DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                        Expanded(
                          child: Text(
                            accountName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                          if (isDefault)
                            Container(
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
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '****$last4 • $accountType',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 12),
            if (email.isNotEmpty)
              _AccountDetailRow(
                icon: Icons.email,
                label: 'Email',
                value: email,
              ),
            if (email.isNotEmpty) const SizedBox(height: 8),
            _AccountDetailRow(
              icon: Icons.tag,
              label: 'Stripe Account ID',
              value: stripeAccountId,
            ),
            const SizedBox(height: 8),
            _AccountDetailRow(
              icon: Icons.calendar_today,
              label: 'Connected',
              value: _formatDate(connectedAt),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSetDefault,
                      icon: const Icon(Icons.star_border),
                      label: const Text('Set as Default'),
                    ),
                  ),
                if (!isDefault) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    label: const Text(
                      'Disconnect',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}

class _AccountDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

